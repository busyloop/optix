#!/usr/bin/env ruby

require 'optix'

# A kitchen sink example, demonstrating most Optix functionality

module KitchenSink
  # We declare the root-command ("global options") right here
  # NOTE: This is an alternative (equivalent) syntax to using 'cli_root'
  #       inside a sub-class of Optix::CLI
  Optix::command do
    # Help-screen text
    text "Kitchen-sink-multi-tool. I can print text, calculate, sing and dance!"
    text "Please invoke one of my sub-commands."

    # A global option that is inherited by all sub-commands
    opt :debug, "Enable debugging", :default => false

    # Declare a filter on the :debug-option. All sub-commands
    # inherit this filter as well so you will see the text printed
    # when you use the '-d' option on any command.
    filter do |cmd, opts, argv|
      puts "DEBUG: '#{cmd.join(' ')}' was called with opts=#{opts}, argv=#{argv}" if opts[:debug]
    end

  end

  # This is our Printer again.
  # You probably remember him from the first example. ;)
  class Printer < Optix::CLI
    desc "Print a string"
    text "Print a string to the screen"
    params "<string>"
    opt :count, "Print how many times?", :default => 1
    def print(cmd, opts, argv)
      if argv.length < 1
        raise Optix::HelpNeeded
      end

      (1..opts[:count]).each do
        puts argv.join(' ') 
      end
    end
  end

  # A simple Calculator
  class Calculator < Optix::CLI
    # We want all commands in here to be subcommands of
    # 'calc'. Since 'calc' itself is not declared anywhere
    # it is implicitly created, and we also pass a description.
    parent 'calc', 'Calculator'
    desc "Multiply some numbers"
    text "Multiplication is ohsom!"
    params "<int> <int> [int] ..."
    def multi(cmd, opts, argv)
      if argv.length < 2
        puts "Error: Need at least two parameters!"
        raise Optix::HelpNeeded
      end
  
      o = 1
      argv.each do |i|
        o *= i.to_i
      end
      puts o
    end

    # Hint: Don't forget to specify the parent again, 
    #       otherwise the method would become a child
    #       of root. We can leave out the description
    #       here because we already provided one above
    #       the 'multi'-method.
    parent 'calc' #, 'Calculator'
    desc "Add some numbers"
    text "Addition is ohsom!"

    # Demonstrate a trigger here (makes no sense, but heck)
    opt :argh, "Just say 'ARGH!' and exit"
    trigger :argh do |cmd, opts, argv|
      puts "ARGH!"
    end

    params "<int> <int> [int] ..."
    def add(cmd, opts, argv)
      if argv.length < 2
        puts "Error: Need at least two parameters!"
        raise Optix::HelpNeeded
      end
  
      o = 0
      argv.each do |i|
        o += i.to_i
      end
      puts o
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end

