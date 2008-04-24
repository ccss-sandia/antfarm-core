require 'graph/graph'
require 'tk/canvas'

class TkcOval
  attr_accessor :center
  attr_accessor :delta

  def initialize(*args)
    super(*args)

    @center = [0,0]
    @delta = [0,0]
  end

  # when moving the object, change the center coordinates
  def move(dx, dy)
    super(dx, dy)

    @center[0] += dx
    @center[1] += dy
  end
end

module Antfarm

  module Graph

    class SpringObject
      attr_accessor :color

      def initialize(color = 'orange')
        @color = color
      end
    end

    class SpringLayout
      def initialize(graph, size = [600,600])
        puts "Graph Size: #{graph.all_nodes.length} nodes and #{graph.all_edges.length} edges"
        puts "Please wait while the graph 'spreads'..."

        @graph = graph
        @size = size
        @tk_objects = Hash.new

        @canvas = TkCanvas.new
        @canvas.width = @size[0]
        @canvas.height = @size[1]
        @canvas.pack :fill => :both, :expand => true

        init

  #     @canvas.update

        (1..50).each do
  #       sleep 0.25
          relax
  #       @canvas.update
        end

        puts "Okay, it's done! :)"

        @canvas.update
      end

      # randomly assign the coordinates
      def init
        @graph.all_nodes.each do |node|
          x = rand(@size[0])
          y = rand(@size[1])
          coords = [x - 5, y + 5, x + 5, y - 5]
          oval = TkcOval.new(@canvas, coords) # { fill 'orange' }
          if node.is_a?(Antfarm::Graph::SpringObject)
            oval.fill = node.color
          else
            oval.fill = 'orange'
          end
          oval.center = [x,y]
          @tk_objects[node] = oval
        end

        @graph.all_edges.each do |edge|
          nodes = @graph.nodes(edge)
          coords = @tk_objects[nodes[0]].center + @tk_objects[nodes[1]].center
          line = TkcLine.new(@canvas, coords) { fill 'black' }
          @tk_objects[edge] = line
        end
      end

      def relax
        @graph.all_edges.each do |edge|
          source = @tk_objects[@graph.nodes(edge)[0]]
          target = @tk_objects[@graph.nodes(edge)[1]]
          vx = target.center[0] - source.center[0]
          vy = target.center[1] - source.center[1]
          length = Math.sqrt(vx * vx + vy * vy)
          length = (length == 0) ? 0.0001 : length
          f = (50 - length) / (length * 3)
          dx = f * vx
          dy = f * vy

          source.delta[0] += -dx
          source.delta[1] += -dy
          target.delta[0] += dx
          target.delta[1] += dy
        end

        @graph.all_nodes.each do |vertex|
          dx = 0
          dy = 0

          source = @tk_objects[vertex]

          @graph.all_nodes.each do |neighbor|
            target = @tk_objects[neighbor]

            next if target == source

            vx = source.center[0] - target.center[0]
            vy = source.center[1] - target.center[1]
            length = Math.sqrt(vx * vx + vy * vy)
            if length == 0
              dx += rand
              dy += rand
            elsif length < 100 * 100
              dx += vx / length
              dy += vy / length
            end
          end

          delta_length = dx * dx + dy * dy
          if delta_length > 0
            delta_length = Math.sqrt(delta_length) / 2
            source.delta[0] += (dx / delta_length)
            source.delta[1] += (dy / delta_length)
          end
        end

        @graph.all_nodes.each do |node|
          oval = @tk_objects[node]

          dx = [-5, [5, oval.delta[0]].min].max
          dy = [-5, [5, oval.delta[1]].min].max

          move(node, dx, dy)

          oval.delta[0] /= 2
          oval.delta[1] /= 2
        end
      end

      # When moving a node, the end of any edges connected
      # to the node needs to be moved as well.
      def move(node, dx, dy)
        # move the node
        oval = @tk_objects[node]
        oval.move(dx, dy)

        # check to see if it stayed on the screen
        # what if screen is maximized?!
        if oval.center[0] < 5
          dx = 5 - oval.center[0]
          oval.move(dx, 0)
        elsif oval.center[0] > (@size[0] - 5)
          dx = (@size[0] - 5) - oval.center[0]
          oval.move(dx, 0)
        end

        if oval.center[1] < 5
          dy = 5 - oval.center[0]
          oval.move(0, dy)
        elsif oval.center[1] > (@size[1] - 5)
          dy = (@size[1] - 5) - oval.center[1]
          oval.move(0, dy)
        end

        @graph.edges(node).each do |edge|
          nodes = @graph.nodes(edge)
          source = @tk_objects[nodes[0]]
          target = @tk_objects[nodes[1]]
          coords = source.center + target.center
          @tk_objects[edge].coords = coords
        end
      end
    end

  end

end

# graph = Sandia::Graph.new
# graph.add :nodes => Array.new(25) { |i| Object.new }

# (1..30).each do
#   source = graph.all_nodes[rand(25)]
#   begin
#     target = graph.all_nodes[rand(25)]
#   end while target == source
#   graph.add :edge => Object.new, :endpoints => [source, target]
# end

# root = TkRoot.new { title 'Spring Layout' }
# Sandia::SpringLayout.new(graph)
# Tk.mainloop

