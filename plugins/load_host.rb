module Antfarm
  class LoadHost < Antfarm::Plugin

    def initialize
      super({ :name   => 'Load Host',
              :desc   => 'Given a file with one IP address per line, create a new IP Interface in the DB',
              :author => 'Bryan T. Richardson <btricha>' },
            [ { :name     => :input_file,
                :desc     => 'File with IP addresses in it',
                :type     => String,
                :required => true },
              { :name     => :tags,
                :desc     => 'Comma-separated list of tags for each interface',
                :type     => String,
                :required => false }
            ])
    end

    def run(options)
      begin
        File.open(options[:input_file]) do |file|
          file.each do |line|
            data = line.strip.split(' ')
            if data.length == 1
              puts "Loading address #{data[0]}"
              iface = Antfarm::Models::IpInterface.find_by_address(data[0])
              if iface.nil?
                DataStore[:node_name] = data[0]
                DataStore[:node_tags] = options[:tags] unless options[:tags].nil?
                Antfarm::Models::IpInterface.create(:address => data[0], :tag_list => options[:tags] || 'default')
              else
                node          = iface.layer3_interface.layer2_interface.node
                node.name     = data[0]
                node.tag_list = options[:tags] unless options[:tags].nil?
                node.save
              end
            else
              name = data.shift
              node = Antfarm::Models::Node.find_by_name(name)

              if node.nil?
                node          = Antfarm::Models::Node.new
                node.name     = name
                node.tag_list = options[:tags] unless options[:tags].nil?
                node.save

                DataStore[:node] = node

                for address in data
                  iface = Antfarm::Models::IpInterface.find_by_address(address)
                  if iface.nil?
                    Antfarm::Models::IpInterface.create(:address => address, :tag_list => options[:tags] || 'default')
                  else
                    l2iface      = iface.layer3_interface.layer2_interface
                    l2iface.node = node
                    l2iface.save
                  end
                end
              else
                # TODO
              end
            end
          end
        end
      rescue Errno::ENOENT
        puts "The file '#{options[:input_file]}' doesn't exist"
      rescue Exception => e
        puts e
        puts e.backtrace.join("\n")
      end
    end
  end
end
