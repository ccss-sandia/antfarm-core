# TODO <scrapcoder>: create tests, DRY up code
module Antfarm
  module Models
    class IpInterface
      include DataMapper::Resource

      property :id,      Serial
      property :address, String, :nullable => false

      belongs_to :layer3_interface, :child_key => [:id]

      validates_present :address

      # Overriding the address setter in order to create an instance variable for an
      # Antfarm::IPAddrExt object ip_addr.  This way the rest of the methods in this
      # class can confidently access the ip address for this interface.  IPAddr also
      # validates the address.
      #
      # the method 'address=' is called by the constructor of this class.
      def address=(ip_addr) #:nodoc:
        @ip_addr = Antfarm::IPAddrExt.new(ip_addr)
        attribute_set :address, @ip_addr.to_s
      end

      before :save do
        # TODO <scrapcoder>: move to before :create?
        # Not sure if both before :create and before :save get called
        # when a new record is created. If so, the stuff below in the
        # else section will get called unnecessarily when a new record
        # is created.
        #
        # NOTE <scrapcoder>: looks like 'before :create' and 'before :save' are hooked
        # directly into create and save methods, rather than being associated with
        # new/existing records. Thus, the way we're doing things below is the best way.
        if new_record?
          Antfarm::Helpers.log :debug, "This is a new IpInterface object - #{self.address}"

          # Will not have already created an IpNetwork object, so create one
          # This automatically creates a Layer3Network object
          Antfarm::Helpers.log :debug, 'Creating new IpNetwork object'
          l3net = create_ip_network
#         self.layer3_interface.layer3_network = l3net

          # This will cause the l3net just created to get assigned to the
          # Layer3Interface being created below...
          DataStore[:layer3_network] = l3net

          # If a MAC Address was provided, create an EthernetInterface object
          # This automatically creates a Layer2Interface object
          if DataStore[:mac_address]
            Antfarm::Helpers.log :debug, 'Creating new EthernetInterface object'
            ethif = EthernetInterface.create
#           self.layer3_interface.layer2_interface = ethif.layer2_interface

            # This will cause the layer2_interface from the ethif just created
            # to get assigned to the Layer3Interface being created below...
            DataStore[:layer2_interface] = ethif.layer2_interface
          else
            DataStore[:layer2_interface] = Layer2Interface.create
          end

          # Will not have already created a Layer3Interface object, so create one
          Antfarm::Helpers.log :debug, 'Creating new Layer3Interface object'
          self.layer3_interface = Layer3Interface.create

          # Save the resulting Layer3Interface object
          self.layer3_interface.save
        else
          Antfarm::Helpers.log :debug, "This is an existing IpInterface object - #{self.address}"
          # Since this is an existing record, we need to see if the given IP Address
          # or MAC Address have changed. If they have, we need to make sure things
          # get tidied up appropriately.
          #
          # In the case of a change of IP Address, we'll need to make sure we're still
          # assigned to the correct IpNetwork/Layer3Network at the Layer3Interface level.
          # TODO <scrapcoder>: We'll also want to see if any networks can be destroyed if empty.
          #
          # In the case of a change of MAC Address, we'll need to create a new EthernetInterface
          # object, assign the Layer3Interface to the new Layer2Interface, and destroy the
          # old EthernetInterface object and corresponding Layer2Interface object.

          # Check to see what network the current IP Address belongs to.
          l3net = Layer3Network.network_containing(self.address)
          # If no network exists that would contain the current IP Address, create a new one
          # and reassign Layer3Interface object to new Layer3Network object.
          if l3net.nil?
            Antfarm::Helpers.log :debug, 'No Layer3Network exists that would contain this IpInterface'
            Antfarm::Helpers.log :debug, 'Creating new IpNetwork object'
            l3net = create_ip_network
            self.layer3_interface.layer3_network = l3net
            self.layer3_interface.save
            # If a network does exist, check to see if its the same as the one currently assigned.
            # If not, reassign Layer3Interface object to correct Layer3Network object.
          elsif l3net.id != self.layer3_interface.layer3_network.id
            Antfarm::Helpers.log :debug, 'Reassigning Layer3Interface to correct Layer3Network'
            self.layer3_interface.layer3_network = l3net
            self.layer3_interface.save
          end

          # Check to see if a new MAC Address has been specified.
          if DataStore[:mac_address]
            # If no EthernetInterface object currently exists or the existing EthernetInterface
            # object's assigned MAC Address doesn't match the one specified, create a new
            # EthernetInterface object and destroy the existing one (if it exists).
            #
            # TODO <scrapcoder>: what about the Node object belonging to the Layer2Interface
            # object being destroyed?! The Layer2Interface object belongs to the Node object,
            # which means the Node object will not be destroyed.  However, it will be 'left
            # to hang' so-to-speak. We should probably grab the Node object before destroying
            # the Layer2Interface object, and reassign it to the new Layer2Interface object.
            ethif = self.layer3_interface.layer2_interface.ethernet_interface
            if ethif.nil? or ethif.address != @args[:mac_address]
              Antfarm::Helpers.log :debug, 'New or different MAC Address detected'
              node = self.layer3_interface.layer2_interface.node
              Antfarm::Helpers.log :debug, "Old Node is #{node.id}"
              Antfarm::Helpers.log :debug, "Old Layer2Interface id is #{self.layer3_interface.layer2_interface.id}"
              self.layer3_interface.layer2_interface.destroy

              Antfarm::Helpers.log :debug, 'Creating new EthernetInterface object'
              ethif = EthernetInterface.create :address => @args[:mac_address]
              ethif.layer2_interface.node = node

              Antfarm::Helpers.log :debug, 'Reassigning Layer3Interface to correct Layer2Interface'
              self.layer3_interface.layer2_interface = ethif.layer2_interface
              Antfarm::Helpers.log :debug, "New Layer2Interface id is #{self.layer3_interface.layer2_interface.id}"
              Antfarm::Helpers.log :debug, "New Node is #{self.layer3_interface.layer2_interface.node.id}"
              self.layer3_interface.save
            end
          end
        end
      end

      private

      def create_ip_network
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        layer3_network = Layer3Network.network_containing(@ip_addr.to_cidr_string)
        unless layer3_network
          network = @ip_addr.clone
          if network == network.network
            network.netmask = network.netmask << 2
          end
          ip_network = IpNetwork.new :address => network.to_cidr_string
          if ip_network.save
            Antfarm::Helpers.log :info, "IpInterface: Created IP Network"
          else
            Antfarm::Helpers.log :warn, "IpInterface: Errors occured while creating IP Network"
            ip_network.errors.each do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end
          layer3_network = ip_network.layer3_network
        end
        return layer3_network
      end
    end
  end
end
