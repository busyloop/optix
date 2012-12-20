#!/usr/bin/env ruby

require 'optix'

module Example
  class Frobnitz < Optix::Cli

    parent 'foo bar', ['desc for foo', 'desc for bar']

    desc 'i am foobarbaz' # label for 'foo bar baz'
    text 'hell yea, i am foobarbaz' # help-screen for 'foo bar baz'
    def baz(cmd, opts, argv)
      puts "foo bar baz was called!"
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end

