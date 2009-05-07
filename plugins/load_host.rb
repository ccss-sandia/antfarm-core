module Antfarm
  class LoadHost < Antfarm::Plugin
#   include Antfarm::Database

    def initialize
      super({ :name   => 'Load Host',
              :desc   => 'Given a file with one IP address per line, put each one in the DB',
              :author => 'Bryan T. Richardson <btricha>' },
            { :name     => :input_file,
              :desc     => 'File with IP addresses in it',
              :required => true })
    end

    # TODO: provide run command with hash containing options
    def run
      begin
        File.open(@data_store['INPUT_FILE'].to_s) do |file|
          file.each do |line|
            IpInterface.create :address => line.strip
          end
        end
      rescue Errno::ENOENT
        puts "The file '#{@data_store['INPUT_FILE']}' doesn't exist"
      rescue Exception => e
        puts e
        puts e.backtrace.join("\n")
      end
    end
  end
end
