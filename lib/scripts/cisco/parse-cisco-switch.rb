#!/usr/bin/ruby

# Copyright 2008 -- Sandia National Laboratories
# by Aura Morris (almorri@sandia.gov)

module Aura

  class SwParser
    # Define regular expressions to use for parsing (ALM)
    def initialize
      @switch = Switch.new

      @hostname_regexp = /^hostname (\S+)/
        @re_newline = Regexp.new("\n")
      @re_vlan_id = Regexp.new('\d+')
      @re_vlan_interface = Regexp.new('interface Vlan(\d+)')
      @re_interface = Regexp.new('interface ([\w-]+)(\d+)((/\d+)+)')
      @re_ip_address = Regexp.new('^\s*ip address ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
      @re_mac_address = Regexp.new('((\d){1,4}\:(\d){1,4}\:(\d){1,4})') # Wrong -- need to fix
      @re_ip = Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
      @re_description = Regexp.new('description ((\S+\s)+)$')

      @re_switchport_mode = Regexp.new('switchport mode (access|trunk)')
      @re_vlan_membership = Regexp.new('switchport access vlan (%s)' %[@re_vlan_id])
      @re_switchport_trunk_encaps = Regexp.new('switchport trunk encapsulation ([\w-]+)')
      @re_switchport_trunk_native = Regexp.new('switchport trunk native vlan ([\w-]+)')
      @re_switchport_port_security = Regexp.new('^\sswitchport port-security(\s?)$')	
      @re_switchport_mac_address = Regexp.new('switchport port-security mac-address (%s)'%[@re_mac_address])
      @re_switchport_mode = Regexp.new('switchport mode ([\w-]+)')
      @re_switchport_allowed = Regexp.new('switchport trunk allowed vlan ((\d+)(,(\d+))+)')

      @re_shutdown = Regexp.new('^\sshutdown')
      @re_dot1x_guest_vlan = Regexp.new('^\s*dot1x guest-vlan (\d+)')

      @re_span_portfast = Regexp.new('^\sspanning-tree portfast(\s?)$')
      @re_span_portfast_trunk = Regexp.new('^\sspanning-tree portfast trunk')
      @re_span_bpdu_guard_enable = Regexp.new('^\sspanning-tree bpduguard enable')
      @re_span_bpdu_guard_disable = Regexp.new('^\sspanning-tree bpduguard disable')
      @re_span_bpdu_filter_enable = Regexp.new('^\sspanning-tree bpdufilter enable')
      @re_span_bpdu_filter_disable = Regexp.new('^\sspanning-tree bpdufilter disable')
      @re_span_guard_enable = Regexp.new('^\sspanning-tree guard (loop|none|root)')
      @re_span_guard_disable = Regexp.new('^\sno spanning-tree guard')

      @re_cdp_enable_int = Regexp.new('^\scdp enable')
      @re_cdp_disable_int = Regexp.new('^\sno cdp enable')
      @re_cdp_enable_global = Regexp.new('^cdp run')
      @re_cdp_disable_global = Regexp.new('^no cdp run')

      # Regular expression patterns to match CISCO PIX rules
      @pat = Hash.new
      @current_interface = ""
      @hostname = ""

#     @pat['interface'] = Regexp.compile('(%s)' % [, @re_vlan_membership])
      # Assumes switchport line is first line after interface
#     @pat['interface'] = Regexp.compile('(^(%s)(%s)\s+(%s)(%s))+' % [@re_interface, @re_newline, @re_vlan_membership, @re_newline])

      # Assumes interface descr ends with "!"
#     @pat['interface'] = Regexp.compile('((%s)[^!]+(%s))+' % [@re_interface, @re_newline, @re_vlan_membership])

    end	# initialize

    # Parses line looking for routing entries
    def parse_file!(file, vlans, modes, ips)

      list = File.open(file)
      found_interface = false
      int_is_vlan = false

      list.each do |line|
        # Get hostname for SW
        if name = @hostname_regexp.match(line)
          @switch.hostname = name[1]
        end

        if cdp_enabled = @re_cdp_enable_global.match(line)
          @switch.cdp = true
        end

        if cdp_disabled = @re_cdp_disable_global.match(line)
          @switch.cdp = false
        end

        # Once an interface is found, check for all relevant settings
        if found_interface
          if dot1x_guest_vlan = @re_dot1x_guest_vlan.match(line)
            @switch.interfaces.last.dot1x_guest_vlan = dot1x_guest_vlan[1]

          # Check for membership in vlan
          elsif vlan_membership = @re_vlan_membership.match(line)
            # Add entry for this interface under this vlan
            vlanID = vlan_membership[1]
#           puts "vlan: " + vlanID.to_s
            if !vlans.has_key?(vlanID)
              vlans[vlanID] = Array.new
            end
            vlans[vlanID].push(@current_interface)

            # Should always be true
            if(!int_is_vlan)	
              @switch.interfaces.last.member_of_vlan=vlanID
            end

          # Check for port mode
          elsif switchport_mode = @re_switchport_mode.match(line)
            mode = switchport_mode[1]
#           puts "mode: " + mode.to_s
            if !modes.has_key?(mode)
              modes[mode] = Array.new
            end
            modes[mode].push(@current_interface)

            # Should always be true
            if(!int_is_vlan)
              if(mode.to_s == "trunk")	
                @switch.interfaces.last.trunk = true
              elsif(mode.to_s == "access")
                @switch.interfaces.last.trunk = false
              end
            end	

          # Check for encapsulation type
          elsif switchport_encaps = @re_switchport_trunk_encaps.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.trunk_encaps= switchport_encaps[1]
            end

          # Check for native vlan
          elsif native_vlan = @re_switchport_trunk_native.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.switchport_native_vlan= native_vlan[1]
            end

          # Check for allowed vlan list
          elsif allowed_vlans = @re_switchport_allowed.match(line)
            if(!int_is_vlan)
#             @switch.interfaces.last.allowed_vlans.push(allowed_vlans[1])
              vlanString = allowed_vlans[1]
#             puts vlanString			
              vlanList = vlanString.split(",")
              for vlan in vlanList
                @switch.interfaces.last.allowed_vlans.push(vlan)
              end
            end

          # Look for description
          elsif description = @re_description.match(line)
            if(int_is_vlan)
              @switch.vlans.last.desc = description[1]
            else
              @switch.interfaces.last.desc = description[1]
            end

          # Look for shutdown
          elsif shut = @re_shutdown.match(line)
            if(int_is_vlan)
              @switch.vlans.last.shutdown = true
            else
              @switch.interfaces.last.shutdown = true
            end

          # Look for port-security
          elsif port_security = @re_switchport_port_security.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.switchport_port_security = true
            end

          # Look for MAC addresses
          elsif port_security = @re_switchport_mac_address.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.switchport_mac_configured = true
              @switch.interfaces.last.switchport_mac.push(port_security[1])
            end

          # Look for portfast
          elsif portfast = @re_span_portfast.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_portfast_active = true
            end

          # Look for portfast trunk
          elsif port_security = @re_span_portfast_trunk.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_portfast_trunk = true
            end

          # Look for bpdu_guard enable
          elsif bpdu_guard_enable = @re_span_bpdu_guard_enable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_bpdu_guard = true
            end

          # Look for bpdu_guard disable
          elsif bpdu_guard_disable = @re_span_bpdu_guard_disable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_bpdu_guard = false
            end

          # Look for bpdu_filter enable
          elsif bpdu_filter_enable = @re_span_bpdu_filter_enable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_bpdu_filter = true
            end

          # Look for bpdu_filter disable
          elsif bpdu_filter_disable = @re_span_bpdu_filter_disable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_bpdu_filter = false
            end

          # Look for bpdu_guard enable
          elsif span_guard_enable = @re_span_guard_enable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_guard = true
            end

          # Look for bpdu_guard disable
          elsif span_guard_disable = @re_span_guard_disable.match(line)
            if(!int_is_vlan)
              @switch.interfaces.last.span_guard = false
            end

          # Look for cdp on interface
          elsif cdp_enable = @re_cdp_enable_int.match(line)
            # no cdp on vlan ints
            if(!int_is_vlan)		
              @switch.interfaces.last.cdp = true
            end

          elsif cdp_disable = @re_cdp_disable_int.match(line)
            # no cdp on vlan ints	
            if(!int_is_vlan)		
              @switch.interfaces.last.cdp = false
            end

          # Look for IP address 
          elsif ip_addr = @re_ip_address.match(line)
#           puts "Current interface: " + @current_interface + ", IP address: " + ip_addr.to_s
            if !ips.has_key?(ip_addr)
              ips[ip_addr] = Array.new
            end
            ips[ip_addr].push(@current_interface)

            if(int_is_vlan)
              @switch.vlans.last.ip_address = ip_addr[1].to_s
            else
              @switch.interfaces.last.ip_address = ip_addr[1].to_s
            end

            int_is_vlan = false
            found_interface = false	# goes in last test

          # New vlan interface line found
          elsif vlan_interface = @re_vlan_interface.match(line)
            @current_interface = ('Vlan%s' % [vlan_interface[1]])   
            int_is_vlan = true
            new_vlan = Vlan.new
            new_vlan.number = vlan_interface[1]
            new_vlan.name = @current_interface
            @switch.vlans.push(new_vlan)

            new_interface = Interface.new
            new_interface.name = @current_interface
            new_interface.cdp = @switch.cdp
            new_interface.member_of_vlan = new_vlan.number
            @switch.interfaces.push(new_interface)	

          # New regular interface line found
          elsif interface = @re_interface.match(line)
            @current_interface = ('%s%s%s' % [interface[1],interface[2],interface[3]])   
#           interfaces.push(@current_interface)
#           puts "Current interface: " + @current_interface.to_s

            new_interface = Interface.new
            new_interface.name = @current_interface
            new_interface.cdp = @switch.cdp
            @switch.interfaces.push(new_interface)	
          end
        else
          # Found regular interface
          if interface = @re_interface.match(line)
            @current_interface = ('%s%s%s' % [interface[1], interface[2], interface[3]])
            new_interface = Interface.new
            new_interface.name = @current_interface
            new_interface.cdp = @switch.cdp
            @switch.interfaces.push(new_interface)	

            found_interface = true

          # Found vlan interface
          elsif vlan_interface = @re_vlan_interface.match(line)
            @current_interface = ('Vlan%s' % [vlan_interface[1]])   
            int_is_vlan = true
            new_vlan = Vlan.new
            new_vlan.number = vlan_interface[1]
            new_vlan.name = @current_interface
            @switch.vlans.push(new_vlan)

            new_interface = Interface.new
            new_interface.name = @current_interface
            new_interface.cdp = @switch.cdp
            new_interface.member_of_vlan = new_vlan.number
            @switch.interfaces.push(new_interface)	

            found_interface = true	      	
          end
        end
      end	# loop

      list.close

      return @switch
    end	# parse_file 
  end  # class Parser

  class Switch
    attr_accessor :hostname
    attr_accessor :interfaces
    attr_accessor :vlans
    attr_accessor :cdp

    def initialize
      @hostname = ''
      @interfaces = Array.new
      @vlans = Array.new
      @cdp = true
    end

    def to_string
      string = "\nHostname: " + @hostname + "\nNum Interfaces: " + @interfaces.length.to_s + "\nNum Vlans: " + @vlans.length.to_s
      return string
    end

  end	# class Switch


  class Interface
    attr_accessor :name
    attr_accessor :desc
    attr_accessor :cdp
    attr_accessor :allowed_vlans

    attr_accessor :span_portfast_active
    attr_accessor :span_portfast_trunk
    attr_accessor :span_guard
    attr_accessor :span_bpdu_filter
    attr_accessor :span_bpdu_guard

    attr_accessor :switchport_port_security
    attr_accessor :switchport_mac_configured
    attr_accessor :switchport_mac
    attr_accessor :trunk
    attr_accessor :trunk_encaps
    attr_accessor :switchport_native_vlan

    attr_accessor :ip_address
    attr_accessor :member_of_vlan

    attr_accessor :shutdown
    attr_accessor :dot1x_guest_vlan

    def initialize()
      @name = ''
      @desc = ''
      @cdp = false
      @allowed_vlans = Array.new # from switchport_trunk_allowed_vlans

      @span_portfast_active = false
      @span_portfast_trunk = false
      @span_guard = 'none'
      @span_bpdu_filter = false
      @span_bpdu_guard = false

      @switchport_port_security = false
      @switchport_mac_configured = false
      @switchport_mac = Array.new
      @trunk = false
      @trunk_encaps = ''
      @switchport_native_vlan = ''

      @ip_address = ''
      @member_of_vlan = ''
      @shutdown = false
      @dot1x_guest_vlan = ''

    end

    def to_string
      string  = "\nName: " + @name + "\nDescription: " + @desc + "\nIP: " + @ip_address + "\nVLAN: " + @member_of_vlan
      string += "\nTrunk: " + @trunk.to_s + "\nEncapsulation: " + @trunk_encaps + "\nPort-security: " + @switchport_port_security.to_s
      string += "\nNative vlan: " + @switchport_native_vlan + "\nMac-secured: " + @switchport_mac_configured.to_s

      for mac in @switchport_mac
        string += "\nMac address: " + mac.to_s
      end

      string += "Allowed VLANs: "
      for vlan in @allowed_vlans
        string += vlan + ", "
      end

      string += "\nSpan portfast active: " + @span_portfast_active.to_s + "\nSpan portfast trunk: " + @span_portfast_trunk.to_s
      string += "\nSpan guard: " + @span_guard + "\nBPDU filter: " + @span_bpdu_filter.to_s + "\nBPDU Guard: "+@span_bpdu_guard.to_s

      return string
    end

  end	# class Interface

  class Vlan

    attr_accessor :number
    attr_accessor :name
    attr_accessor :desc
    attr_accessor :ip_address
    attr_accessor :interfaces
    attr_accessor :shutdown

    def initialize()
      @name = ''
      @desc = ''
      @ip_address = ''
      @interfaces = Array.new
      @shutdown = false
    end
    
    def to_string
      string = "\nName: " + @name + "\nDescription: " + @desc + "\nIP: " + @ip_address
      return string
    end	

  end	# class Vlan

end

ARGV.each do |arg|
  if File.directory?(arg)
    Find.find(arg) do |path|
      if File.file?(path)
        vlans = Hash.new
        modes = Hash.new
        ips = Hash.new

        p = Aura::SwParser.new
        switch = p.parse_file!(path, vlans, modes, ips)
        puts switch.to_string

        device = Device.create :name => switch.hostname

        switch.vlans.each do |vlan|
#         puts vlan.to_string
          Vlan.create :name => vlan.name, :number => vlan.number, :description => vlan.desc, :address => vlan.ip_address, :shutdown => vlan.shutdown
        end

        switch.interfaces.each do |interface|
#         puts interface.to_string
          vlan = Vlan.find_by_number(interface.member_of_vlan)
          iface = Interface.new :name => interface.name, :device => device, :vlan => vlan
          iface.description = interface.desc
          iface.address = interface.ip_address
          iface.shutdown = interface.shutdown
          iface.dot1x_guest_vlan = interface.dot1x_guest_vlan
          iface.trunk = interface.trunk
          iface.switchport_trunk_encapsulation = interface.trunk_encaps
          iface.switchport_port_security_active = interface.switchport_port_security
          iface.switchport_port_security_address_assigned = interface.switchport_mac_configured
          iface.cdp_enabled = interface.cdp
          iface.spanning_tree_portfast_active = interface.span_portfast_active
          iface.spanning_tree_portfast_trunk = interface.span_portfast_trunk
          iface.spanning_tree_guard = interface.span_guard
          iface.spanning_tree_bpdufilter = interface.span_bpdu_filter
          iface.spanning_tree_bpduguard = interface.span_bpdu_guard
          iface.save

          interface.allowed_vlans.each do |allowed_vlan|
            vlan_allowed = Vlan.find_by_number(allowed_vlan)
            iface.switchport_trunk_allowed_vlans << vlan_allowed unless vlan_allowed.nil?
          end
        end
      end
    end
  else
    vlans = Hash.new
    modes = Hash.new
    ips = Hash.new

    p = Aura::SwParser.new
    switch = p.parse_file!(arg, vlans, modes, ips)

    puts switch.to_string
    switch.interfaces.each do |interface|
      puts interface.to_string
    end
    switch.vlans.each do |vlan|
      puts vlan.to_string
    end
  end
end
