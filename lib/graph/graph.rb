module Antfarm
  
  module Graph

    class NodeAlreadyExistsError < ArgumentError
      def message
        return "node already exists"
      end
    end

    class NodeDoesNotExistError < ArgumentError
      def message
        return "node does not exist"
      end
    end

    class EdgeAlreadyExistsError < ArgumentError
      def message
        return "edge already exists"
      end
    end

    class EdgeDoesNotExistError < ArgumentError
      def message
        return "edge does not exist"
      end
    end

    class Graph
      def initialize(args = nil)
        @nodes = Hash.new
        @edges = Hash.new
      end

      def add(args)
        if args[:node]
          add_single_node args[:node]
        elsif args[:nodes]
          add_multiple_nodes args[:nodes]
        elsif args[:edge] && args[:endpoints]
          add_single_edge args[:edge], args[:endpoints]
        elsif args[:edges]
          add_multiple_edges args[:edges]
        end
      end

      def nodes(edge)
        raise EdgeDoesNotExistError unless @edges[edge]
        return @edges[edge]
      end

      def all_nodes
        return @nodes.keys
      end

      def edges(node)
        raise NodeDoesNotExistError unless @nodes[node]
        return @nodes[node]
      end

      def all_edges
        return @edges.keys
      end

      def degree(node)
        return edges(node).length
      end

      #######
      private
      #######

      def add_single_node(node)
        raise NodeAlreadyExistsError if @nodes[node]
        @nodes[node] = Array.new
      end

      def add_multiple_nodes(nodes)
        nodes.each do |node|
          add_single_node node
        end
      end

      def add_single_edge(edge, endpoints)
        raise EdgeAlreadyExistsError if @edges[edge]
        raise NodeDoesNotExistError unless @nodes[endpoints[0]]
        raise NodeDoesNotExistError unless @nodes[endpoints[1]]

        @edges[edge] = endpoints
        @nodes[endpoints[0]] << edge
        @nodes[endpoints[1]] << edge
      end

      def add_multiple_edges(edges)
        edges.each do |edge|
          add_single_edge edge[:edge], edge[:endpoints]
        end
      end
    end

  end

end

#graph = Sandia::Graph.new
#from = Object.new
#to = Object.new
#edge = Object.new

#graph.add :nodes => [from, to]
#graph.add :edge => edge, :endpoints => [from, to]

#puts graph.degree(Object.new)

