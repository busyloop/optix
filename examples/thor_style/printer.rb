#!/usr/bin/env ruby

require 'optix'

module Example
  class Printer < Optix::CLI

    # Declare global options; the text-label that is printed
    # for the root-command and one option that is inherited by
    # all sub-commands.
    cli_root do
      text "I am printer. I print strings to the screen."
      text "Please invoke one of my not so many sub-commands."
      # Opts are inherited by all children
      opt :debug, "Enable debugging", :default => false
    end
    
    # Declare a sub-command called "print"
    desc "Print a string"
    text "Print a string to the screen"
    opt :count, "Print how many times?", :default => 1
    params "<string>"
    # Your CLI-methods always 
    def print(cmd, opts, argv)
      if argv.length < 1
        raise Optix::HelpNeeded
      end

      puts "DEBUGGING IS ENABLED!" if opts[:debug]
      (1..opts[:count]).each do
        puts argv.join(' ')
      end
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end
