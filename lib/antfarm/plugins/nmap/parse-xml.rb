################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

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
