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
