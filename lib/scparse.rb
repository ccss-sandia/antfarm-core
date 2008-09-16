# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
#
# This script is modeled after the open-source Ruby project 'CommandParse'.

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

    # Find first key that begins with the name passed
    def [](name)
      possible = keys.select {|key| key =~ /^#{name}.*/}
      fetch(possible[0]) if possible.length == 1
    end

  end

  # A command is a block of code that should have its options
  # parsed before being executed.  A command can also be a
  # parent to subcommands.
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
    end

    # Return the uber-parent, which is a ScriptCommandParser object.
    def scparser
      cmd = parent
      cmd = cmd.parent while !cmd.nil? && !cmd.is_a?(ScriptCommandParser)
      return cmd
    end

    # Return an array of parents for this command, up to but not
    # including the uber-parent ScriptCommandParser object.
    def parents
      cmd = self
      parents = [cmd]
      begin
        cmd = cmd.parent
        parents << cmd
      end until cmd.parent.is_a?(ScriptCommandParser)
      return parents
    end

    # Does this command have any subcommands it's a parent to?
    def has_commands?
      return @commands.nil? ? false : true
    end

    # Set the block of code to run as a prerequisite to executing
    # the command (such as bootstrapping code).
    def set_prerequisites_block(&block)
      @prerequisites_block = block
    end

    # Run the prerequisite block of code
    def prerequisites
      @prerequisites_block.call(self) if @prerequisites_block
    end

    # Is this command supposed to run its prerequisiste block of
    # code before executing (as defined in the constructor)?
    def execute_prerequisites?
      return @execute_prerequisites
    end

    # Set the main block of code for this command.
    def set_execution_block(&block)
      @execution_block = block
    end

    # Run the main block of code for this command, first running
    # the prerequisite block of code if supposed to do so.
    def execute(args)
      parents.reverse_each {|parent| parent.prerequisites} if execute_prerequisites?
      @execution_block.call(self, args) if @execution_block
    end

    # Define the usage of this command, using the name of the command and
    # the uber-parent ScriptCommandParser.
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

    # Along with showing the usage for the command, this also displays
    # any and all the child subcommands that belong to this command.
    def show_help
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
      puts "Available commands: (type 'help <command>' for command-specific help)" if level == 1
      command.commands.sort.each do |name,cmd|
        puts "  " * level + name
        list_commands(cmd, level + 1) if cmd.has_commands?
      end
    end

  end

  # A script does not execute a block of code.  Rather it loads
  # an existing Ruby script to be executed.  Any arguments passed
  # to the script command are passed on to the script being loaded.
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

    # Clears out any original arguments passed for the script
    # and instead passes '--help' to the script.  Hopefully the
    # script knows how to respond to that (hint hint)!
    def show_help
      ARGV.clear
      ARGV << '--help'
      load @path
    end

  end

  # Special custom command for displaying help messages.
  class HelpCommand < Command
    
    def initialize
      super('help')
    end

    def execute(args)
      super(args)

      if args.length > 0
        cmd = scparser.main
        arg = args.shift

        puts "cmd: #{cmd.name}, arg: #{arg}"

        while !arg.nil? && cmd.commands[arg]
          cmd = cmd.commands[arg]
          arg = args.shift
          puts "cmd: #{cmd.name}, arg: #{arg}"
        end
        
        puts "cmd: #{cmd.name}, arg: #{arg}"

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

  # Super-duper uber-parent class for all commands.
  class ScriptCommandParser

    attr_reader :main
    attr_reader :name

    # Creates a new command object with the name 'main'
    # and sets itself as the parent of the command.
    def initialize(name = $0)
      @main = Command.new('main')
      @main.parent = self
      @name = name
    end

    # Adds a subcommand to the main command object.
    def add_command(command)
      @main.add_command(command)
    end

    # Returns any options in the main command object.
    def options
      @main.options
    end

    # Sets the options for the main command object.
    def options=(options)
      @main.options = options
    end

    # Sets the prerequisites block for the main command
    # object.
    def set_prerequisites_block(&block)
      @main.set_prerequisites_block(&block)
    end

    # Runs the main command object using the given arguments
    # (which by default is ARGV).
    def parse!(argv = ARGV)
      cmd = @main
      opts = Array.new
      args = Array.new(argv)

      # The cmd variable is set to nil once we've reached the
      # last child command and it's executed.
      while !cmd.nil?
        # If the command has subcommands, then it should not
        # be executed on.  Rather, look to see if a subcommand
        # is specified or if options have been passed.
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
          # This command has no subcommands, which means it
          # is the command to execute on.
          cmd.options.parse!(args) unless cmd.options.nil? || cmd.is_a?(Script)
          cmd.execute(args)
          cmd = nil
        end
      end

    rescue RuntimeError, OptionParser::ParseError => error
      # OptionParser will raise an exception of an option is passed
      # that isn't recognized.  Thus, show the help screen!
      @main.commands['help'].execute([]) if @main.commands['help']
      exit
    end

  end

end
