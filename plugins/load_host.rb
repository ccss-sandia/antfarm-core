module Antfarm
  class LoadHost < Antfarm::Plugin

    def initialize
      super({ :name   => 'Load Host',
              :desc   => 'Given a file with one IP address per line, put each one in the DB',
              :author => 'Bryan T. Richardson <btricha>' },
            { :name     => :input_file,
              :desc     => 'File with IP addresses in it',
              :type     => String,
              :required => true })
    end

    def run(options)
      begin
        File.open(options[:input_file]) do |file|
          file.each do |line|
            unless Antfarm::Models::IpInterface.find_by_address line.strip
              Antfarm::Models::IpInterface.create :address => line.strip
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
