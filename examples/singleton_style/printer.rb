#!/usr/bin/env ruby

require 'optix'

module Example
  module Printer
    # Declare the "root"-command 
    Optix::command do
      text "I am printer. I print strings to the screen."
      text "Please invoke one of my not so many sub-commands."
  
      # Declare a global option (all subcommands inherit this)
      opt :debug, "Enable debugging", :default => false
    end
  
    # Declare sub-command 
    Optix::command 'print' do
      desc "Print a string"
      text "Print a string to the screen"
      params "<string>"
  
      opt :count, "Print how many times?", :default => 1
  
      # This block is invoked when validations pass.
      exec do |cmd, opts, argv|
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
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end

