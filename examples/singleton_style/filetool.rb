#!/usr/bin/env ruby
require 'optix'

#
# Example application to demonstrate Optix advanced usage.
#
module Example
  class FileTool
    # Declare the "root" command
    # Also declaring the first-level sub-commands right here.
    # Just like the root-command these commands can not be invoked
    # directly (because they have sub-commands). Their declaration
    # is not mandatory but by declaring them explicitly we can add
    # some useful help-texts to aid the user.
    Optix::command do
      # Let's have a nice description
      text "This is FileTool, a little example application to demonstrate Optix."
      text "It's safe to play around with. All operations are no-ops."
      text "Your filesystem is never actually modified!"
      text ""
      text "Invoke me with one of the sub-commands to perform a dummy-operation."

      # Note: Options are recursively inherited by sub-commands.
      # Thus, any option we declare here will also be available
      # in all sub-commands.
      opt :debug, "Enable debugging", :default => false
      opt :version, "Print version and exit"

      # Triggers fire immediately, before validation.
      #
      # This one short-circuits the '--version' and '-v' opts.
      # We want to print/exit immediately when we encounter
      # them, regardless of other opts or subcommands.
      #
      # NOTE: Triggers can only bind to existing opts.
      #       Make sure to always declare the 'opt' before
      #       creating a 'trigger' (just like in this example).
      trigger [:version] do
        puts "Version 1.0"
        # parsing stops after a trigger has fired.
      end

      # Filters are "pass-through", they fire for
      # every intermediate sub-command. We use it here
      # to set up a common debug-mechanism before the
      # subcommand is invoked.
      filter do |cmd, opts, argv|
        if opts[:debug]
          FileTool.enable_debug!
        end
      end

      # Note this command has no exec{}-block.
      # It would never fire because this command has sub-commands. 
      # When a command has sub-commands then it can no longer be
      # invoked directly (that would only lead to confusion and
      # bad accidents).
    end

    Optix::command 'file' do
      desc "Operations on files"
      text "Please invoke one of the sub-commands to perform a file-operation."
    end

    Optix::command 'dir' do
      desc "Operations on directories"
      text "Please invoke one of the sub-commands to perform a directory-operation."
    end

    def self.enable_debug!
      # enable debugging...
    end
  end
end

module Example
  class FileTool
    class Move
      # Here we declare the subcommand 'file move'
      Optix::command 'file move' do
        # Short one-liner for the sub-command list in parent help-screen
        desc "Move a file"

        # Verbose description for the help-screen
        text "Move a file from <source> to <dest>"
        text "The destination will not be overwritten unless --force is applied."

        opt :force, "Force overwrite", :default => false

        # This text is only used in the help-screen. Positional arguments are
        # *not* checked by Optix, you have to do that yourself in the exec{}-block.
        params "<source> <dest>"

        exec do |cmd, opts, argv|
          # bail if we didn't receive enough parameters
          if argv.length < 2
            puts "Error: #{cmd.join(' ')} must be invoked with 2 parameters."
            exit 1
          end
          
          puts "#{cmd.join(' ')} called with #{opts}, #{argv}"
        end
      end

      # Here we declare the subcommand 'dir move'
      Optix::command 'dir move' do
        desc "Move directory from A to B"

        text "Move a directory from <source> to <dest>"
        text "The destination will not be overwritten unless --force is applied."
        opt :force, "Force overwrite", :default => false
        params "<source> <dest>"

        exec do |cmd, opts, argv|
          if argv.length < 2
            puts "Error: #{cmd.join(' ')} must be invoked with 2 parameters."
            exit 1
          end
          puts "#{cmd.join(' ')} called with #{opts}, #{argv}"
        end
      end
    end

    class Copy
      # Here we declare the subcommand 'file copy'
      Optix::command 'file copy' do
        # Short one-liner for the sub-command list in parent help-screen
        desc "Copy a file"

        # Verbose description for the help-screen
        text "Copy a file from <source> to <dest>"
        text "The destination will not be overwritten unless --force is applied."

        opt :force, "Force overwrite", :default => false

        # This text is only used in the help-screen. Positional arguments are
        # *not* checked by Optix, you have to do that yourself in the exec{}-block.
        params "<source> <dest>"

        exec do |cmd, opts, argv|
          # bail if we didn't receive enough parameters
          if argv.length < 2
            puts "Error: #{cmd.join(' ')} must be invoked with 2 parameters."
            exit 1
          end
          
          puts "#{cmd.join(' ')} called with #{opts}, #{argv}"
        end
      end

      # Here we declare the subcommand 'dir copy'
      Optix::command 'dir copy' do
        desc "Copy directory from A to B"

        text "Copy a directory from <source> to <dest>"
        text "The destination will not be overwritten unless --force is applied."
        opt :force, "Force overwrite", :default => false
        params "<source> <dest>"

        exec do |cmd, opts, argv|
          if argv.length < 2
            puts "Error: #{cmd.join(' ')} must be invoked with 2 parameters."
            exit 1
          end
          puts "#{cmd.join(' ')} called with #{opts}, #{argv}"
        end 
      end
    end
  end
end

if __FILE__ == $0
  # Perform some configuration (optional!)
  Optix.configure do
    # override a help-text template
    # see the source-code for full list of available config keys
    text_header_usage 'Syntax: %0 %command %params'
  end

  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end

