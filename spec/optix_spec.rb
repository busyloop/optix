require 'spec_helper'
require 'optix'

describe Optix do
  describe "with fresh context" do
    before :each do
      $n ||= 0
      $n += 1
      @context = "test#{$n}"
    end

    after :each do
      Optix::reset!
    end

    it "raises ArgumentError on invalid option type" do
      Optix::command('', @context) do
        opt :a, '', :type => :frobnitz
      end
      lambda {
        Optix.invoke!([], @context)
      }.should raise_error(ArgumentError, "unsupported argument type 'frobnitz'")
    end

    it "raises RuntimeError on non existing command" do
      Optix::command('', @context) do
        non_existing_command
      end
      lambda {
        Optix.invoke!([], @context)
      }.should raise_error(RuntimeError, "Unknown Optix command: 'non_existing_command'")
    end

    it "prints basic help screen" do
      Optix::command('', @context) do
        opt :test
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /^  --help, -h/
      out[:stdout].should match /^  --test, -t/
    end

    it "prints complex help screen"  do
      Optix::command('', @context) do
        opt :test, "Description", :long => 'longtest', :short => 'x', :type => :int, :default => 5, :required => true
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
      out[:stdout].should match /^  --longtest, -x <i>:   Description \(default: 5\)/
    end

    it "prints correct help for all known Symbol opt-types"  do
      Optix::command('', @context) do
        opt :a, '', :type => :boolean
        opt :b, '', :type => :integer
        opt :c, '', :type => :integers
        opt :d, '', :type => :double
        opt :e, '', :type => :doubles
        opt :f, '', :type => :string
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
      out[:stdout].should match /--a, -a:/
      out[:stdout].should match /--b, -b <i>:/
      out[:stdout].should match /--c, -c <i\+>:/
      out[:stdout].should match /--d, -d <f>:/
      out[:stdout].should match /--e, -e <f\+>:/
      out[:stdout].should match /--f, -f <s>:/
    end

    it "prints correct help for all known Class opt-types"  do
      Optix::command('', @context) do
        opt :a, '', :type => TrueClass
        opt :b, '', :type => Integer
        opt :c, '', :type => Float
        opt :d, '', :type => IO
        opt :e, '', :type => Date
        opt :f, '', :type => String
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
      out[:stdout].should match /--a, -a:/
      out[:stdout].should match /--b, -b <i>:/
      out[:stdout].should match /--c, -c <f>:/
      out[:stdout].should match /--d, -d <filename\/uri>:/
      out[:stdout].should match /--e, -e <date>:/
      out[:stdout].should match /--f, -f <s>:/
    end

    it "infers correct type from default for all known opt-types"  do
      Optix::command('', @context) do
        opt :a, '', :default => true
        opt :b, '', :default => 1
        opt :c, '', :default => 1.0
        opt :d, '', :default => File.new('/')
        opt :e, '', :default => Date.new
        opt :f, '', :default => "foo"
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
      out[:stdout].should match /--no-a, -a:/
      out[:stdout].should match /--b, -b <i>:/
      out[:stdout].should match /--c, -c <f>:/
      out[:stdout].should match /--d, -d <filename\/uri>:/
      out[:stdout].should match /--e, -e <date>:/
      out[:stdout].should match /--f, -f <s>:/
    end

    it "infers correct type from Array-default for all known opt-types"  do
      Optix::command('', @context) do
        opt :b, '', :default => [1]
        opt :c, '', :default => [1.0]
        opt :d, '', :default => [File.new('/tmp')]
        opt :e, '', :default => [Date.new]
        opt :f, '', :default => ["foo"]
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
      out[:stdout].should match /--b, -b <i\+>:/
      out[:stdout].should match /--c, -c <f\+>:/
      out[:stdout].should match /--d, -d <filename\/uri\+>:/
      out[:stdout].should match /--e, -e <date\+>:/
      out[:stdout].should match /--f, -f <s\+>:/
    end

    it "prints correct help screen for composed command" do
      Optix::command('', @context) do
        opt :foo
      end

      Optix::command('', @context) do
        opt :bar
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--foo, -f/
      out[:stdout].should match /--bar, -b/
    end


    it "raises ArgumentError for unsupported argument type"  do
      Optix::command('', @context) do
        opt :a, '', :default => Class
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "unsupported argument type 'Class'")
      end
    end

    it "raises ArgumentError for unsupported multi-argument type"  do
      Optix::command('', @context) do
        opt :a, '', :default => [true]
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "unsupported multiple argument type 'TrueClass'")
      end
    end

    it "raises ArgumentError for opt with no type and empty array default"  do
      Optix::command('', @context) do
        opt :a, '', :default => []
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "multiple argument type cannot be deduced from an empty array for 'NilClass'")
      end
    end

    it "raises ArgumentError for opt with no type and unknown type array default"  do
      Optix::command('', @context) do
        opt :a, '', :default => [Class]
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "unsupported multiple argument type 'Class'")
      end
    end

    it "raises ArgumentError for unknown opt-type (Symbol)"  do
      Optix::command('', @context) do
        opt :a, '', :type => :foobar
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "unsupported argument type 'foobar'")
      end
    end

    it "raises ArgumentError for unknown opt-type (Class)"  do
      Optix::command('', @context) do
        opt :a, '', :type => Time
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, "unsupported argument type 'Class'")
      end
    end

    it "disambiguates :multi with Array-default"  do
      Optix::command('', @context) do
        opt :a, '', :multi => true, :default => [1,2]
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      #out[:stdout].should match /--a, -a <i\+>:    \(default: 1, 2\)/
      out[:stdout].should match /--a, -a <i>:    \(default: 1, 2\)/
    end

    it "raises ArgumentError on invalid long option name"  do
      Optix::command('', @context) do
        opt :a, '', :long => '-orr'
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, 'invalid long option name "-orr"')
      end
    end

    it "raises ArgumentError on invalid short option name"  do
      Optix::command('', @context) do
        opt :a, '', :short => '--orr'
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(ArgumentError, 'invalid short option name \'"--orr"\'')
      end
    end


    it "prepends/removes dashes on long-option as needed"  do
      Optix::command('', @context) do
        opt :a, '', :long => 'orr'
        opt :b, '', :long => '--urr'
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--orr, -o/
      out[:stdout].should match /--urr, -u/
    end

    it "prepends/removes dash on short-option as needed"  do
      Optix::command('', @context) do
        opt :a, '', :short => 'o'
        opt :b, '', :short => '-u'
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /-o/
      out[:stdout].should match /-u/
    end

    it "raises ArgumentError on dependency towards non-existing option" do
      Optix::command('', @context) do
        opt :a, ''
        depends :a, :b
      end

      argv = ['--help']

      lambda {
        Optix.invoke!(argv, @context)
      }.should raise_error(ArgumentError, "unknown option 'b'")
    end

    it "enforces option inter-dependency (or displays error)" do
      Optix::command('', @context) do
        opt :a, ''
        opt :b, ''
        depends :a, :b
      end

      argv = ['-a']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stderr].should match /Error: --a requires --b/
    end

    it "raises ArgumentError on conflicts-declaration towards non-existing option" do
      Optix::command('', @context) do
        opt :a, ''
        conflicts :a, :b
      end

      argv = ['--help']

      lambda {
        Optix.invoke!(argv, @context)
      }.should raise_error(ArgumentError, "unknown option 'b'")
    end

    it "displays error upon option conflict" do
      Optix::command('', @context) do
        opt :a, ''
        opt :b, ''
        conflicts :a, :b
      end

      argv = ['-a', '-b']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stderr].should match /Error: --a conflicts with --b/
    end

    it "displays error on invalid argv syntax (triple-dash)" do
      Optix::command('', @context) do
        opt :a, ''
        opt :b, ''
      end

      argv = ['---a']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stderr].should match /Error: invalid argument syntax: '---a'/
    end

    it "displays error on duplicate argv" do
      Optix::command('', @context) do
        opt :a, ''
        opt :b, ''
      end

      argv = ['-a', '-a']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stderr].should match /Error: option '-a' specified multiple times/
    end

    it "displays :desc in help"  do
      Optix::command('', @context) do
      end

      Optix::command('sub', @context) do
        desc "fancy subcommand"
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /^   sub   fancy subcommand/
    end

    it "displays :text in help"  do
      Optix::command('', @context) do
        text "Verbose explanation"
      end

      Optix::command('sub', @context) do
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /^Verbose explanation/
    end

    it "multiple :text are concatenated with newlines"  do
      Optix::command('', @context) do
        text "Verbose explanation"
        text "More text"
      end

      Optix::command('sub', @context) do
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /^Verbose explanation\nMore text/
    end


    it "displays :params in help"  do
      Optix::command('', @context) do
        params "<foo> [bar]"
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: .*<foo> \[bar\]/
    end

    it "displays :params in help on subcommand"  do
      Optix::command('', @context) do
      end

      Optix::command('sub', @context) do
        params "<foo> [bar]"
      end

      argv = ['sub', '--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: .* sub <foo> \[bar\]/
    end

    #it "does not display :help-help when there is a subcommand"  do
    #  Optix::command('', @context) do
    #    text "Verbose explanation"
    #  end

    #  Optix::command('sub', @context) do
    #  end

    #  argv = ['--help']

    #  out = capture_streams do
    #    lambda {
    #      Optix.invoke!(argv, @context)
    #    }.should raise_error(SystemExit)
    #  end
    #  out[:stdout].should match /^Usage: /
    #  out[:stdout].should_not match /--help, -h/
    #end

    #it "displays :help-help when there are no subcommands"  do
    #  Optix::command('', @context) do
    #    text "Verbose explanation"
    #  end

    #  argv = ['--help']

    #  out = capture_streams do
    #    lambda {
    #      Optix.invoke!(argv, @context)
    #    }.should raise_error(SystemExit)
    #  end
    #  out[:stdout].should match /^Usage: /
    #  out[:stdout].should match /--help, -h/
    #end

    it "displays :help-help"  do
      Optix::command('', @context) do
        text "Verbose explanation"
      end

      argv = ['--help']

      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
    end

    it "raises RuntimeError on missing exec{} block"  do
      Optix::command('', @context) do
      end

      argv = []
      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(RuntimeError, "Command '' has no exec{}-block!")
      end
    end

    it "raises RuntimeError on missing exec{} block (for subcommand)"  do
      Optix::command('', @context) do
      end

      Optix::command('sub', @context) do
      end

      argv = ['sub']
      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(RuntimeError, "Command 'sub' has no exec{}-block!")
      end
    end

    it "runs the exec{}-block"  do
      dummy = double("exec{}")
      dummy.should_receive(:call).once.with([], {:help=>false}, [])

      Optix::command('', @context) do
        exec do |cmd,args,argv|
          dummy.call(cmd, args, argv)
        end
      end

      argv = []
      Optix.invoke!(argv, @context)
    end

    it "runs the exec{}-block (on subcommand)"  do
      Optix::command('', @context) do
      end

      dummy = double("exec{}")
      dummy.should_receive(:call).once.with(['sub'], {:help=>false}, [])

      Optix::command('sub', @context) do
        exec do |cmd,args,argv|
          dummy.call(cmd, args, argv)
        end
      end

      argv = ['sub']
      Optix.invoke!(argv, @context)
    end

    it "fires :version-trigger when invoked with -v"  do
      exec_dummy = double('exec')
      trigger_dummy = double('trigger')
      trigger_dummy.should_receive(:call).once
      Optix::command('', @context) do
        opt :version, "Print version and exit"
        trigger :version do
          trigger_dummy.call(cmd, args, argv)
        end
        exec do |cmd,args,argv|
          exec_dummy.call(cmd, args, argv)
        end
      end

      argv = ['-v']
      Optix.invoke!(argv, @context)
    end

    it "fires :version-trigger when invoked with --version"  do
      exec_dummy = double('exec')
      trigger_dummy = double('trigger')
      trigger_dummy.should_receive(:call).once
      Optix::command('', @context) do
        opt :version, "Print version and exit"
        trigger :version do
          trigger_dummy.call(cmd, args, argv)
        end
        exec do |cmd,args,argv|
          exec_dummy.call(cmd, args, argv)
        end
      end

      argv = ['--version']
      Optix.invoke!(argv, @context)
    end

    it "fires [:version,:foobar]-trigger when invoked with --version"  do
      exec_dummy = double('exec')
      trigger_dummy = double('trigger')
      trigger_dummy.should_receive(:call).once
      Optix::command('', @context) do
        opt :version, "Print version and exit"
        trigger [:version, :foobar] do
          trigger_dummy.call(cmd, args, argv)
        end
        exec do |cmd,args,argv|
          exec_dummy.call(cmd, args, argv)
        end
      end

      argv = ['--version']
      Optix.invoke!(argv, @context)
    end

    it "runs the filter{}-block on command path"  do
      filter_root = double()
      filter_root.should_receive(:call).once.with(['a','b'], {:help=>false}, [])
      exec_root = double()
      Optix::command('', @context) do
        filter do |cmd,args,argv|
          filter_root.call(cmd, args, argv)
        end
        exec do |cmd,args,argv|
          exec_root.call(cmd, args, argv)
        end
      end

      filter_a = double()
      filter_a.should_receive(:call).once.with(['a', 'b'], {:help=>false}, [])
      filter_a2 = double()
      filter_a2.should_receive(:call).once.with(['a', 'b'], {:help=>false}, [])
      exec_a = double()
      Optix::command('a', @context) do
        filter do |cmd,args,argv|
          filter_a.call(cmd, args, argv)
        end
        filter do |cmd,args,argv|
          filter_a2.call(cmd, args, argv)
        end
        exec do |cmd,args,argv|
          exec_a.call(cmd, args, argv)
        end
      end

      filter_a_b = double()
      exec_a_b = double()
      exec_a_b.should_receive(:call).once.with(['a','b'], {:help=>false}, [])
      Optix::command('a b', @context) do
        exec do |cmd,args,argv|
          exec_a_b.call(cmd, args, argv)
        end
      end

      argv = ['a', 'b']
      Optix.invoke!(argv, @context)
    end

    it "shows help-screen when HelpNeeded is raised in filter{}"  do
      exec_root = double()
      Optix::command('', @context) do
        filter do |cmd,args,argv|
          raise Optix::HelpNeeded
        end
        exec do |cmd,args,argv|
          exec_root.call(cmd, args, argv)
        end
      end
      argv = []
      out = capture_streams do
        lambda {
          Optix.invoke!(argv, @context)
        }.should raise_error(SystemExit)
      end
      out[:stdout].should match /^Usage: /
      out[:stdout].should match /--help, -h/
    end

    it "exec{} receives remaining argv"  do
      Optix::command('', @context) do
      end

      dummy = double("exec{}")
      dummy.should_receive(:call).once.with(['sub'], {:help=>false}, ['foo', 'bar'])

      Optix::command('sub', @context) do
        exec do |cmd,args,argv|
          dummy.call(cmd, args, argv)
        end
      end

      argv = ['sub', 'foo', 'bar']
      Optix.invoke!(argv, @context)
    end

    describe "Configurator" do
      it "raises ArgumentError on unknown configuration key" do
        lambda {
          Optix::configure do
            unknown_key
          end
        }.should raise_error(ArgumentError, "Unknown configuration key 'unknown_key'")
      end

      it "honors text_header_usage" do
        Optix::configure do
          text_header_usage 'Ouzo: %0 %subcommands %params'
        end

        Optix::command('', @context) do
          opt :test
        end

        argv = ['--help']

        out = capture_streams do
          lambda {
            Optix.invoke!(argv, @context)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /^Ouzo: /
        out[:stdout].should match /--help, -h/
        out[:stdout].should match /^  --test, -t/
      end

      it "honors text_required" do
        Optix::configure do
          text_required ' (mandatory)'
        end

        Optix::command('', @context) do
          opt :test, "testing", :required => true
        end

        argv = ['--help']

        out = capture_streams do
          lambda {
            Optix.invoke!(argv, @context)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /^  --test, -t:   testing \(mandatory\)/
        out[:stdout].should match /--help, -h/
      end

      it "honors text_help" do
        Optix::configure do
          text_help 'HALP!'
        end

        Optix::command('', @context) do
          opt :test, "testing"
        end

        argv = ['--help']

        out = capture_streams do
          lambda {
            Optix.invoke!(argv, @context)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /--help, -h:   HALP/
      end

      it "honors text_header_topcommands" do
        Optix::configure do
          text_header_topcommands 'TOPCMD'
        end

        Optix::command('', @context) do
          opt :test, "testing"
        end

        Optix::command('sub', @context) do
          opt :test, "testing"
        end

        argv = ['--help']

        out = capture_streams do
          lambda {
            Optix.invoke!(argv, @context)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /^TOPCMD/
      end

      it "honors text_header_subcommands" do
        Optix::configure do
          text_header_subcommands 'SUBCMD'
        end

        Optix::command('', @context) do
          opt :test, "testing"
        end

        Optix::command('sub', @context) do
        end

        Optix::command('sub sub', @context) do
        end

        argv = ['sub', '--help']

        out = capture_streams do
          lambda {
            Optix.invoke!(argv, @context)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /^SUBCMD/
      end
    end
  end

  describe "with shared context" do
    before :all do
      @context = :shared1
    end
    it "raises ArgumentError on duplicate option" do
      Optix::command('', @context) do
        opt :a, ''
      end
      Optix::command('', @context) do
        opt :a, ''
      end
      lambda {
        Optix.invoke!([], @context)
      }.should raise_error(ArgumentError, "you already have an argument named 'a'")
    end
  end

  it "defaults to context :default" do
    lambda {
      Optix.invoke!([])
    }.should raise_error(RuntimeError, "Scope 'default' is not defined")
  end

  it "raises RuntimeError on undefined context" do
    lambda {
      Optix.invoke!([], :i_dont_exist)
    }.should raise_error(RuntimeError, "Scope 'i_dont_exist' is not defined")
  end

  describe "Examples" do
    before :each do
      Optix::reset!
    end

    describe "FileTool" do
      before :each do
        load 'examples/singleton_style/filetool.rb'
      end

      it "prints version when invoked with -v" do
        argv = ['-v']
        out = capture_streams do
          #lambda {
            Optix.invoke!(argv)
          #}.should raise_error(SystemExit)
        end
        #out[:stdout].should match /^Version 1.0\n/
        out[:stdout].should == "Version 1.0\n"
      end

      it "prints version when invoked with --version" do
        argv = ['--version']
        out = capture_streams do
          #lambda {
            Optix.invoke!(argv)
          #}.should raise_error(SystemExit)
        end
        out[:stdout].should == "Version 1.0\n"
      end

      it "prints help when invoked with -h" do
        argv = ['-h']
        out = capture_streams do
          lambda {
            Optix.invoke!(argv)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /Commands:/
      end

      it "prints help when invoked without arguments" do
        argv = []
        out = capture_streams do
          lambda {
            Optix.invoke!(argv)
          }.should raise_error(SystemExit)
        end
        out[:stdout].should match /Commands:/
      end
    end
  end
end
