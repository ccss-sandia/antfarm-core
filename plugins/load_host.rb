module Antfarm
  class LoadHost < Antfarm::Plugin

    def initialize
      super({ :name   => 'Load Host',
              :desc   => 'Given a file with one IP address per line, create a new IP Interface in the DB',
              :author => 'Bryan T. Richardson <btricha>' },
            { :name     => :input_file,
              :desc     => 'File with IP addresses in it',
              :type     => String,
              :required => true },
            { :name     => :tags,
              :desc     => 'Comma-separated list of tags for each interface',
              :type     => String,
              :required => false })
    end

    def run(options)
      begin
        File.open(options[:input_file]) do |file|
          file.each do |line|
            puts "Loading address #{line.strip}"
            unless Antfarm::Models::IpInterface.find_by_address line.strip
              Antfarm::Models::IpInterface.create :address => line.strip, :tag_list => 'hello, world'
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
