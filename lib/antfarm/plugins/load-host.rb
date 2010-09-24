module Antfarm
  module Plugin
    class FileDoesNotExistError < Antfarm::AntfarmError; end

    class LoadHost
      include Antfarm::Plugin

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
        print_message "Parsing file #{options[:input_file]}"

        begin
          File.open(options[:input_file]) do |file|
            file.each do |line|
              data = line.strip.split(' ')

              if data.length == 1
                iface = Antfarm::Model::IpInterface.find_by_address(data[0])

                if iface.nil?
                  Antfarm::Model::IpInterface.create(:address => data[0])
                else
                  node      = iface.layer3_interface.layer2_interface.node
                  node.name = data[0]
                  node.save
                end
              else
                name = data.shift
                node = Antfarm::Model::Node.find_by_name(name)

                if node.nil?
                  node      = Antfarm::Model::Node.new
                  node.name = name
                  node.save

                  for address in data
                    iface = Antfarm::Model::IpInterface.find_by_address(address)
                    if iface.nil?
                      Antfarm::Model::IpInterface.create(:address => address)
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
          raise FileDoesNotExistError, "The file '#{options[:input_file]}' doesn't exist"
        rescue Exception => e
          raise Antfarm::AntfarmError, e.message
        end
      end
    end
  end
end
