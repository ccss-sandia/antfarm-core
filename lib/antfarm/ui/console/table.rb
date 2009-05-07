module Antfarm
  module UI
    module Console
      class Table
        attr_writer :header
        attr_writer :margin
        attr_writer :separator

        def initialize
          @header    = Array.new
          @rows      = Array.new
          @margin    = 5
          @separator = '='
        end

        def add_header_column(string)
          @header << string
        end

        def add_row(data)
          @rows << data
        end

        def print
          formatter  = build_formatter
          separators = build_separators
          puts
          puts formatter % @header
          puts formatter % separators
          @rows.each do |row|
            puts formatter % row
          end
          puts
        end

        #######
        private
        #######

        def build_formatter
          columns = @header.length
          formatter = String.new
          (0...(columns - 1)).each do |column|
            formatter += "%-#{column_width(column)}s "
          end
          formatter += "%s"
          return formatter
        end

        def build_separators
          separators = Array.new
          @header.each_index do |i|
            separators << @separator * (column_width(i) - @margin)
          end
          return separators
        end

        def column_width(column)
          return @widths[column] if @widths
          @widths = Array.new
          @header.each_index do |i|
            max = @header[i].length
            @rows.each do |row|
              length = row[i].length
              max    = length > max ? length : max
            end
            @widths << max + @margin
          end
          return @widths[column]
        end
      end
    end
  end
end
