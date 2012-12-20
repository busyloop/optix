#!/usr/bin/env ruby

require 'optix'

module Example
  class Bare < Optix::Cli

    # Normally Optix would create a sub-command
    # called "main" for the method below. 
    #
    # But in this example we don't want any sub-commands,
    # thus we specify 'parent :none' and attach our options
    # directly to the root.
    parent :none
    desc "Print a string"
    text "Printer v1.0"
    text "I print a string to the screen, possibly many times."
    opt :count, "Print how many times?", :default => 1
    params "<string>"
    def main(cmd, opts, argv)
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

