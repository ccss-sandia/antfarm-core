# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'optparse'

module SCParse

  class TakesNoCommandsError < RuntimeError

    def message
      return "This command takes no other commands"
    end

  end

  class TakesNoOptionsError < RuntimeError

    def message
      return "This command takes no options"
    end

  end

  class CommandHash < Hash

    def [](name)
      possible = keys.select {|key| key =~ /^#{name}.*/}
      fetch(possible[0]) if possible.length == 1
    end

  end

  class Command

    attr_reader :name
    attr_reader :commands
    attr_accessor :options
    attr_accessor :parent

    def initialize(name, execute_prerequisites = true)
      @name = name
      @execute_prerequisites = execute_prerequisites
    end

    def add_command(command)
      @commands = CommandHash.new unless @commands
      @commands[command.name] = command
      command.parent = self
      command.init
    end

    def scparser
      cmd = parent
      cmd = cmd.parent while !cmd.nil? && !cmd.is_a?(ScriptCommandParser)
      return cmd
    end

    def parents
      cmd = self
      parents = [cmd]
      begin
        cmd = cmd.parent
        parents << cmd
      end until cmd.parent.is_a?(ScriptCommandParser)
      return parents
    end

    def has_commands?
      return @commands.nil? ? false : true
    end

    def init; end

    def set_prerequisites_block(&block)
      @prerequisites_block = block
    end

    def prerequisites
      @prerequisites_block.call(self) if @prerequisites_block
    end

    def execute_prerequisites?
      return @execute_prerequisites
    end

    def set_execution_block(&block)
      @execution_block = block
    end

    def execute(args)
      parents.reverse_each {|parent| parent.prerequisites} if execute_prerequisites?
      @execution_block.call(self, args) if @execution_block
    end

    def usage
      usage = "Usage: #{scparser.name}"
      usage << " [options] "
      usage << parents.reverse.collect do |parent|
        unless parent.name == "main"
          use = parent.name
          use << " [options]"
        end
      end.join('')
      usage << (has_commands? ? " COMMAND [options] [ARGS]" : " [ARGS] ")
      return usage
    end

    def show_help
      puts "#{@name}"
      puts
      puts usage
      puts
      if has_commands?
        list_commands
        puts
      end
      unless options.nil? || options.summarize.empty?
        puts "Available options:"
        puts options.summarize
      end
    end

    #######
    private
    #######

    def list_commands(command = self, level = 1)
      puts "Available commands:" if level == 1
      command.commands.sort.each do |name,cmd|
        puts "  " * level + name
        list_commands(cmd, level + 1) if cmd.has_commands?
      end
    end

  end

  class Script < Command

    attr_reader :path

    def initialize(name, path, execute_prerequisites = true)
      super(name, execute_prerequisites)
      @path = path
    end

    def add_command(command)
      raise TakesNoCommandsError
    end

    def options
      return nil
    end

    def options=(options)
      raise TakesNoOptionsError
    end

    def show_help
      puts "#{@name}"
      puts

      ARGV.clear
      ARGV << '--help'
      load @path
    end

  end

  class HelpCommand < Command
    
    def initialize
      super('help')
    end

    def execute(args)
      super(args)

      if args.length > 0
        cmd = scparser.main
        arg = args.shift

        while !arg.nil? && cmd.commands[arg]
          cmd = cmd.commands[arg]
          arg = args.shift
        end
        
        if arg.nil?
          cmd.show_help
        else
          puts "Command not valid"
        end
      else
        show_help
      end
    end

    #######
    private
    #######

    def show_help
      puts "Usage: #{scparser.name} [options] COMMAND [options] [COMMAND [options] ...] [ARGS]"
      puts
      list_commands(scparser.main)
      puts
      unless scparser.main.options.nil? || scparser.main.options.summarize.empty?
        puts "Available options:"
        puts scparser.main.options.summarize
      end
    end

  end

  class ScriptCommandParser

    attr_reader :main
    attr_reader :name

    def initialize(name = $0)
      @main = Command.new('main')
      @main.parent = self
      @name = name
    end

    def add_command(command)
      @main.add_command(command)
    end

    def options
      @main.options
    end

    def options=(options)
      @main.options = options
    end

    def set_prerequisites_block(&block)
      @main.set_prerequisites_block(&block)
    end

    def parse!(argv = ARGV)
      cmd = @main
      opts = Array.new
      args = Array.new(argv)

      while !cmd.nil?
        if cmd.has_commands?
          arg = args.shift
          
          if arg
            if cmd.commands[arg]
              cmd.options.parse!(opts) unless cmd.options.nil?
              cmd = cmd.commands[arg]
              opts.clear
            else
              opts << arg
            end
          else
            raise RuntimeError
          end
        else
          cmd.options.parse!(args) unless cmd.options.nil? || cmd.is_a?(Script)
          cmd.execute(args)
          cmd = nil
        end
      end

    rescue RuntimeError, OptionParser::ParseError => error
      raise
      @main.commands['help'].execute([]) if @main.commands['help']
      exit
    end

  end

end
