module Antfarm
  module Plugin
    module Cisco
      class FileDoesNotExistError < Antfarm::AntfarmError; end

      class ParseArp
        include Antfarm::Plugin

        def initialize
          super({ :name   => 'Parse ARP',
                  :desc   => 'Parse an ARP dump from a Cisco network device',
                  :author => 'Bryan T. Richardson <btricha>' },
                [ { :name     => :input,
                    :desc     => 'Dump file or directory',
                    :type     => String,
                    :required => true }
                ])
        end

        def run(options)
          input = options[:input]

          if File.directory?(input)
            Find.find(input) do |path|
              if File.file?(path)
                parse(path)
              end
            end
          else
            parse(input)
          end
        end

        def parse(file)
          print_message "Parsing file #{file}"

          begin
            File.open(file) do |list|
              list.each do |line|
                (junk, ip_addr, ethernet_addr) = line.split(' ')
                ip_addr.strip!
                ethernet_addr.strip!

                Antfarm::Model::IpInterface.create(:address => ip_addr, :ethernet_address => ethernet_addr)
              end
            end

          # TODO: merge by ethernet address

          rescue Error::ENOENT
            raise FileDoesNotExistError, "The file '#{file}' doesn't exist"
          rescue Exception => e
            raise Antfarm::AntfarmError, e.message
          end
        end
      end
    end
  end
end
