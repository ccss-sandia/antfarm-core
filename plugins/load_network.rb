module Antfarm
  class LoadNetwork < Antfarm::Plugin

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
      begin
        File.open(options[:input_file]) do |file|
          file.each do |line|
            puts "Loading network #{line.strip}"
            unless Antfarm::Models::IpNetwork.find_by_address line.strip
              Antfarm::Models::IpNetwork.create :address => line.strip
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
