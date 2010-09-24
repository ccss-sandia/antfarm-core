module Antfarm
  module Plugin
    module Nmap
      class FileDoesNotExistError < Antfarm::AntfarmError; end

      class ParseXml
        include Antfarm::Plugin

        def initialize
          super({ :name   => 'Parse Nmap XML Output',
                  :desc   => 'Parses the XML result of an Nmap scan and creates an IP interface for each host',
                  :author => 'Bryan T. Richardson <btricha>' },
                [ { :name     => :input,
                    :desc     => 'Nmap XML output file or directory',
                    :type     => String,
                    :required => true }
                ])
        end

        def run(options)
          input   = options[:input]

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
            results = REXML::Document.new(File.new(file))
            results.elements.each('nmaprun') do |scan|
              scan.elements.each('host') do |host|
                Antfarm::Model::IpInterface.create :address => host.elements['address'].attributes['addr']
              end
            end
          rescue Errno::ENOENT
            raise FileDoesNotExistError, "The file #{file} doesn't exist"
          rescue Exception => e
            raise Antfarm::AntfarmError, e.message
          end
        end
      end
    end
  end
end
