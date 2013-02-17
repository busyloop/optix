#!/usr/bin/env ruby

require 'chronic'
require 'optix/trollop'

class Optix
  class HelpNeeded < StandardError; end

  @@tree = {}
  attr_reader :parser, :node, :filters, :triggers, :command, :subcommands

  def self.command cmd=nil, scope=:default, &b
    @@tree[scope] ||= {}
    Command.new(@@tree[scope], @@config, cmd, &b)
  end

  def self.reset!
    @@config = {
      :text_help => 'Show this message', # set to nil to suppress help option
      :text_required => ' (required)',
      :text_header_usage => 'Usage: %0 %command %params',
      :text_header_subcommands => 'Subcommands:',
      :text_header_topcommands => 'Commands:',
      :text_header_options => 'Options:',
      :text_param_subcommand => '<command>'
    }
    @@tree = {}
  end
  reset!

  def self.configure &b
    Configurator.new(@@config, &b)
  end

  def initialize(argv=ARGV, scope=:default)
    unless @@tree.include? scope
      raise RuntimeError, "Scope '#{scope}' is not defined"
    end
    o = @@tree[scope]

    parent_calls = o[:calls] || []
    filters = o[:filters] || []
    triggers = o[:triggers] || {}
    cmdpath = []
    while o.include? argv[0]
      cmdpath << cmd = argv.shift
      o = o[cmd]
      parent_calls += o[:calls] if o.include? :calls
      filters += o[:filters] if o.include? :filters
      triggers.merge! o[:triggers] if o.include? :triggers
    end

    o[:header] ||= "\n#{@@config[:text_header_usage]}\n"
    o[:params] ||= ''

    subcmds = o.keys.reject{|x| x.is_a? Symbol}

    if 0 < subcmds.length
      o[:params] = @@config[:text_param_subcommand]
    end

    text = o[:header].gsub('%0', File.basename($0)).gsub('%command', cmdpath.join(' ')).gsub('%params', o[:params]).gsub(/ +/, ' ')

    calls = []
    calls << [:nowrap, [text], nil]

    calls << [:banner, [' '], nil]
    unless o[:text].nil?
      calls << [:banner, [o[:text]], nil]
      calls << [:banner, [' '], nil]
    end

    # sort opts and move non-opt calls to the end
    non_opt = parent_calls.select {|x| x[0] != :opt }
    parent_calls = parent_calls.select {|x| x[0] == :opt }
    parent_calls.sort! {|a,b| ; a[1][0].to_s <=> b[1][0].to_s }
    parent_calls += non_opt
    parent_calls.unshift([:banner, [@@config[:text_header_options]], nil])
    calls += parent_calls

    unless @@config[:text_help].nil?
      calls << [:opt, [:help, @@config[:text_help]], nil]
    end

    if 0 < subcmds.length
      prefix = cmdpath.join(' ')

      text = ""
      wid = 0
      subcmds.each do |k|
        len = k.length + prefix.length + 1
        wid = len if wid < len
      end

      #calls << [:no_help_help, [], nil]

      subcmds.each do |k|
        cmd = "#{prefix} #{k}"
        text += "  #{cmd.ljust(wid)}"
        unless o[k][:description].nil?
          text += "   #{o[k][:description]}"
        end
        text += "\n"
      end

      if 0 < cmdpath.length
        calls << [:banner, ["\n#{@@config[:text_header_subcommands]}\n#{text}"], nil]
      else
        calls << [:banner, ["\n#{@@config[:text_header_topcommands]}\n#{text}"], nil]
      end
    end

    calls << [:banner, [" \n"], nil]

    parser = Trollop::Parser.new

    lastmeth = nil
    begin
      calls.each do |e|
        lastmeth = e[0]
        parser.send(e[0], *e[1])
      end
    rescue NoMethodError => e
      raise RuntimeError, "Unknown Optix command: '#{lastmeth}'"
    end

    # expose our goodies
    @parser = parser
    @node = o
    @filters = filters
    @triggers = triggers
    @command = cmdpath
    @subcommands = subcmds
  end

  def self.invoke!(argv=ARGV, scope=:default)
    optix = Optix.new(argv, scope)

    # If you need more flexibility than this block provides
    # then you may want to create your own Optix instance 
    # and perform the parsing manually.
    opts = Trollop::with_standard_exception_handling optix.parser do

      # Process triggers first
      triggers = optix.triggers
      opts = optix.parser.parse argv, triggers
      return if opts.nil?

      # Always show help-screen if the invoked command has subcommands.
      if 0 < optix.subcommands.length
        raise Trollop::HelpNeeded # show help screen
      end

      begin
        # Run filter-chain
        optix.filters.each do |filter|
          filter.call(optix.command, opts, argv)
        end

        # Run exec-block
        if optix.node[:exec].nil?
          raise RuntimeError, "Command '#{optix.command.join(' ')}' has no exec{}-block!"
        end
        optix.node[:exec].call(optix.command, opts, argv)
      rescue HelpNeeded
        raise Trollop::HelpNeeded
      end
    end
  end

  class Configurator
    def initialize(config, &b)
      @config = config
      cloak(&b).bind(self).call
    end

    def method_missing(meth, *args, &block)
      unless @config.include? meth
        raise ArgumentError, "Unknown configuration key '#{meth}'"
      end
      @config[meth] = args[0]
    end

    def cloak &b
      (class << self; self; end).class_eval do
        define_method :cloaker_, &b
        meth = instance_method :cloaker_
        remove_method :cloaker_
        meth
      end
    end
  end
 
  class Command
    attr_reader :tree
    def initialize(tree, config, cmd, &b)
      @tree = tree
      @config = config
      @cmd = cmd || ''
      node
      cloak(&b).bind(self).call
    end

    def node
      path = @cmd.split
      o = @tree
      path.each do |e|
        o = o[e] ||= {}
      end
      o
    end

    def push_call(meth, args, block)
      node[:calls] ||= []
      node[:calls] << [meth, args, block]
    end

    def method_missing(meth, *args, &block)
      push_call(meth, args, block)
    end

    def opt(cmd, desc='', args={})
      if args.fetch(:default, false)
        args.delete :required
      end
      if args.fetch(:required, false)
        desc += @config[:text_required]
      end
      push_call(:opt, [cmd, desc, args], nil)
    end

    def params(text)
      node[:params] = text
    end

    def exec(&block)
      node[:exec] = block
    end

    def filter(&block)
      node[:filters] ||= []
      node[:filters] << block
    end

    def trigger(opts, &block)
      node[:triggers] ||= {}
      node[:triggers][opts] = block
    end


    def desc(text)
      node[:description] = text
    end

    def text(text)
      node[:text] ||= ''
      if 0 < node[:text].length
        node[:text] += "\n"
      end
      node[:text] += text
    end
  
    def cloak &b
      (class << self; self; end).class_eval do
        define_method :cloaker_, &b
        meth = instance_method :cloaker_
        remove_method :cloaker_
        meth
      end
    end
  end
end

class Optix
  class Cli
    class << self
      def add_context(key, value, &block)
        @optix_context ||= []
        @optix_context << [key, value, block]
      end

      [:desc, :text, :opt, :params, :filter,
       :trigger, :depends, :conflicts, :parent].each do |meth|
        define_method(meth) do |*value, &block|
          add_context(meth, value, &block)
        end
      end

      def parent(path, label=nil)
        @optix_context ||= []
        if label
          label = [label] if label.is_a? String
          p = path.split
          (0..p.length-1).each do |i|
            _path = p[0..i].join(' ')
            Optix::command(_path) do
              desc label[i]
            end
          end
        end

        @optix_parent = path
      end

      def rename_to(name)
        @optix_method_name = name
      end

      def cli_root(&block)
        if block
          add_context(:cli_root, '', &block)
        else
          @optix_parent = :none
        end
      end

      def method_added(meth)
        return if @optix_context.nil?
        @optix_method_name ||= meth.to_s
        if @optix_parent == :none
          cmd_path = nil
        elsif @optix_parent
          cmd_path = "#{@optix_parent} #{@optix_method_name}"
        else
          cmd_path = @optix_method_name
        end
        cmd = Optix::command(cmd_path) {}
        @optix_context.each do |e|
          if :cli_root == e[0]
            Optix::command *e[1], &e[2]
            next
          end
          cmd.send(e[0], *e[1], &e[2])
        end
        me = self

        cmd.send(:exec) do |cmd, opts, argv|
          self.new.send(meth, cmd, opts, argv)
        end
        @optix_parent = ''
        @optix_method_name = nil
        @optix_context = nil
      end
    end
  end

  # For backwards compatibility
  class CLI < Cli
    def self.inherited(klass)
      warn "[DEPRECATION WARNING] Optix::CLI is deprecated. Please use Optix::Cli instead."
      super
    end
  end
end

