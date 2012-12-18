#!/usr/bin/env ruby

# Minimum hello-world example.
#
# Note: In a real program you'd want to at least
#       provide some label and help-text using
#       "desc" and "text".

require 'optix'

module Example
  class HelloWorld < Optix::CLI

    # Declare a command called "world" as child of "hello"
    parent 'hello', "Try me!"
    def world(cmd, opts, argv)
      puts "Hello world!"
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end
