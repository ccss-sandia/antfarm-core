module Antfarm
  module Plugin
    class FileDoesNotExistError < Antfarm::AntfarmError; end

    class LoadNetwork
      include Antfarm::Plugin

      def initialize
        super({ :name   => 'Load Network',
                :desc   => 'Given a file with one IP network address per line, create a new IP Network in the DB',
                :author => 'Bryan T. Richardson <btricha>' },
              [ { :name     => :input_file,
                  :desc     => 'File with IP networks in it',
                  :type     => String,
                  :required => true }
              ])
      end

      def run(options)
        print_message "Parsing file #{options[:input_file]}"

        begin
          File.open(options[:input_file]) do |file|
            file.each do |line|
              print_message "Loading network #{line.strip}"

              unless Antfarm::Model::IpNetwork.find_by_address line.strip
                Antfarm::Model::IpNetwork.create :address => line.strip
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
