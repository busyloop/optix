[![Build Status](https://travis-ci.org/busyloop/optix.png?branch=master)](https://travis-ci.org/busyloop/optix) [![Dependency Status](https://gemnasium.com/busyloop/optix.png)](https://gemnasium.com/busyloop/optix)

# Optix

Optix is an unobtrusive, composable command line parser based on Trollop.
It is intended to be a lighter weight alternative to [Thor](https://github.com/wycats/thor).


## Features

* Convenient, declarative syntax (similar to [Thor](https://github.com/wycats/thor))

* Nested subcommands such as `git remote show origin` may be composed at runtime in arbitrary order.

* Subcommands inherit from their parent. Common options (such as '--debug' or '--loglevel')
  need to be declared only once to make them available to an entire branch.

* Stands on the shoulders of [Trollop](http://trollop.rubyforge.org) (by William Morgan), one of the
  most advanced option-parser implementations available.

* Automatic validation and help-screens.

* Should work on all major Ruby versions (tested on 1.9.3, 1.9.2 and 1.8.7).


## Installation

    $ gem install optix

## Example

```ruby
#!/usr/bin/env ruby

require 'optix'

module Example
  class Printer < Optix::CLI

    # Declare global cli-options
    cli_root do
      # A label to be printed on the root help-screen
      text "I am printer. I print strings to the screen."
      text "Please invoke one of my not so many sub-commands."
      
      # An option that is inherited by all commands
      opt :debug, "Enable debugging", :default => false
    end
    
    # Declare a command called "print"
    desc "Print a string"
    text "Print a string to the screen"
    opt :count, "Print how many times?", :default => 1
    params "<string>"
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
```

The above code in action:

```
$ ./printer.rb --help

Usage: ./printer.rb <subcommand>
 
I am printer. I print strings to the screen.
Please invoke one of my not so many sub-commands.
 
Options:
  --debug, -d:   Enable debugging
   --help, -h:   Show this message

Commands:
   print   Print a string
 
```

See the `examples/`-folder for more elaborate examples.

## Documentation

A cli is built using the declarative Optix DSL inside the body
of at least one sub-class of `Optix::CLI`.

After the declarations have been loaded you invoke the parser
with a call to `Optix.invoke!(ARGV)`. It will parse and validate
the input (in this case: ARGV), create an instance of the class
that contains the requested command-method, and call said method
with the user-supplied opts and arguments.

In case of a validation error Optix displays an adequate
error-message and auto-generated help-screen.

If your program loads multiple sub-classes of `Optix::CLI`
then the resulting cli will be the sum of all declarations in
any of them.

Optix is agnostic towards the order of declarations; a sub-command
declaration is allowed to appear before its parent. This feature allows
for very dynamic user interfaces to be generated at runtime, e.g.
via conditionals or dynamic class-loading.


### Commands and Sub-Commands

In Optix all commands are created equal. In order to nest
commands you simply declare them with a `parent`. The minimum
code to create a program that can be invoked as `program.rb hello world`
would look like this:

```ruby
#!/usr/bin/env ruby

require 'optix'

module Example
  class HelloWorld < Optix::CLI

    # Declare a command called "world" as child of "hello"
    parent 'hello'
    def world(cmd, opts, argv)
      puts "Hello world!"
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end
```

You'll notice that we didn't actually declare the parent-command itself (`hello`).
In optix this isn't necessary, any gaps in the hierarchy are automatically filled in.

Commands may be nested to any depth, e.g. try this parent in the above code: `parent 'shout at the'`.

## Commands that have sub-commands can not be invoked

When you have a command `foo bar` then the parent command `foo` can not be invoked.
It will still appear in help-screens and behave as expected, though.
This is a deliberate constraint enforced by Optix in order to protect the sanity of your users.

## Helpers

Optix ignores all methods that aren't preceded by a DSL-directive
(e.g. `parent`, `desc` or `opt`). Thus you don't need to do anything
special to mix command-methods with helper-methods.

Example:

```ruby
module Example
  class HelperExample < Optix::CLI

    # This method becomes a command because it is
    # preceded by an optix-directive ('parent')
    parent 'hello'
    def world(cmd, opts, argv)
      puts "Hello world!"
    end

    # This method is ignored by Optix
    def iam_a_helper(yay)
      # ...
    end
  end
end
```


### Optix DSL

The following directives are available:

### desc

Short description, displayed in the subcommand-list on the help-screen of the *parent* command.

```ruby
module Example
  class Frobnitz < Optix::CLI

    desc 'Frobnicate a gizmo'
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

### text

Long description, displayed on the help-screen for this command.

```ruby
module Example
  class Frobnitz < Optix::CLI

    text "Frobnicate the gizmo by subtle twiddling."
    text "Please only apply this to 2-state devices or you might bork it."
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

* May be called multiple times for a multi-line description.

### parent

Specifies the parent for this command.

```ruby
module Example
  class Frobnitz < Optix::CLI

    parent 'foo bar', ['desc for foo', 'desc for bar']
    def batz(cmd, opts, argv)
      puts "foo bar batz was called!"
    end
  end
end
```

* Commands may be nested to any depth (delimited by whitespace), missing
  parts of the hierarchy are filled in automatically.

* The second argument to `parent` is an optional array of descriptions (`desc`) for
  the auto-generated parents.

* Use the special `parent :none` to describe the root-command in programs that
  should accept arguments directly (`foo.rb --debug=true`) without any
  commands (`foo.rb command --debug=true`). See `examples/thor_style/bare.rb`
  for an example of this.

### cli_root

Takes a block (DSL-enabled) to declare the root-command.

You normally use this to specify the help-text that is to be displayed
on the root-screen (`foo.rb --help`), default opts that should be inherited
by all commands, and any top-level filters and triggers.

```ruby
#!/usr/bin/env ruby

require 'optix'

module Example
  class Frobnitz < Optix::CLI

    # Declare the root-command
    cli_root do
      # A label to be printed on the root help-screen
      text "I am printer. I print strings to the screen."
      text "Please invoke one of my not so many sub-commands."
      
      # An option that is inherited by all commands
      opt :debug, "Enable debugging", :default => false

      # Support '--version' and '-v'
      opt :version, "Print version and exit"
      trigger :version do
        puts "Version 1.0"
      end
    end
    
    # Declare a command called "print"
    desc "Print a string"
    text "Print a string to the screen"
    opt :count, "Print how many times?", :default => 1
    params "<string>"
    def print(cmd, opts, argv)
      if argv.length < 1
        raise Optix::HelpNeeded
      end

      if opts[:debug]
        # ...
      end
    end
  end
end

if __FILE__ == $0
  # Perform the actual parsing and execution.
  Optix.invoke!(ARGV)
end
```

* If you're composing your cli from multiple Optix::Cli-subclasses
  then the `cli_root`-block probably feels a bit awkward because
  you're not sure in which class to put it. In that case please take
  a look at `examples/thor_style/kitchen_sink.rb` for the alternative
  singleton-style syntax that is usually a better fit in these scenarios.

### opt

Declares an option.

```ruby
module Example
  class Frobnitz < Optix::CLI

    opt :some_name, "some description", :default => 'some_default'
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

Takes the following optional arguments:

  * `:long` Specify the long form of the argument, i.e. the form with two dashes. 
    If unspecified, will be automatically derived based on the argument name by turning the name
    option into a string, and replacing any _'s by -'s.

  * `:short` Specify the short form of the argument, i.e. the form with one dash.
    If unspecified, will be automatically derived from argument name.

  * `:type` Require that the argument take a parameter or parameters of a given type. For a *single parameter*,
    the value can be one of **:int**, **:integer**, **:string**, **:double**, **:float**, **:io**, **:date**,
    or a corresponding Ruby class (e.g. **Integer** for **:int**).
    For *multiple-argument parameters*, the value can be one of **:ints**, **:integers**, **:strings**, **:doubles**,
    **:floats**, **:ios** or **:dates**. If unset, the default argument type is **:flag**, meaning that the argument
    does not take a parameter. The specification of `:type` is not necessary if a `:default` is given.

  * `:default` Set the default value for an argument. Without a default value, the opts-hash passed to `trigger{}`,
    `filter{}` and your command-method will have a *nil* value for this key unless the argument is given on the commandline.
    The argument type is derived automatically from the class of the default value given, so specifying a `:type`
    is not necessary if a `:default` is given. (But see below for an important caveat when `:multi` is specified too.)
    If the argument is a flag, and the default is set to **true**, then if it is specified on the the commandline
    the value will be **false**.

  * `:required` If set to **true**, the argument must be provided on the commandline.

  * `:multi` If set to **true**, allows multiple occurrences of the option on the commandline. 
    Otherwise, only a single instance of the option is allowed.

    Note that there are two types of argument multiplicity: an argument
    can take multiple values, e.g. "--arg 1 2 3". An argument can also
    be allowed to occur multiple times, e.g. "--arg 1 --arg 2".
    
    Arguments that take multiple values should have a `:type` parameter
    or a `:default` value of an array of the correct type (e.g. [String]).
    
    The value of this argument will be an array of the parameters on the
    commandline.
    
    Arguments that can occur multiple times should be marked with
    `:multi => true`. The value of this argument will also be an array.
    In contrast with regular non-multi options, if not specified on
    the commandline, the default value will be [], not nil.
    
    These two attributes can be combined (e.g. **:type => :strings**,
    **:multi => true**), in which case the value of the argument will be
    an array of arrays.
    
    There's one ambiguous case to be aware of: when `:multi` is **true** and a
    `:default` is set to an array (of something), it's ambiguous whether this
    is a multi-value argument as well as a multi-occurrence argument.
    In thise case, we assume that it's not a multi-value argument.
    If you want a multi-value, multi-occurrence argument with a default
    value, you must specify `:type` as well.

### params

Describes positional parameters that this command accepts.

```ruby
module Example
  class Frobnitz < Optix::CLI
    params "<foo> [bar]"
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

* Note: Optix does **not** validate or inspect positional parameters. This is up to you inside your method.
  The value of this command is only used by Optix to display a proper synopsis in the help-screen.

### depends

Marks two (or more!) options as requiring each other. Only handles
undirected (i.e., mutual) dependencies.

```ruby
module Example
  class Frobnitz < Optix::CLI

    opt :we,     ""
    opt :are,    ""
    opt :family, ""
    depends :we, :are, :family
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

### conflicts

Marks two (or more!) options as conflicting.

```ruby
module Example
  class Frobnitz < Optix::CLI

    opt :force, "Force this operation"
    opt :no_op, "Dry run, don't actually do anything"
    conflicts :force, :no_op
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

### trigger

Triggers short-circuit argument parsing for "action-options"
(options that directly trigger an action) such as `--version`.

```ruby
module Example
  class Frobnitz < Optix::CLI

    opt :version, "Print version and exit"
    trigger :version do
      puts "Version 1.0"
    end
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

* Triggers fire *before* validation.

* Parsing stops after a trigger has fired.

* A trigger can only be bound to an existing `opt`. I.e. you must first
  declare `opt :version` before you can bind a trigger with `trigger
  :version`.

* A trigger may be bound to multiple options like so: `trigger [:version,
  :other, :etc] do ...`

* You may raise `Optix::HelpNeeded` inside your trigger to abort
  parsing and display the help-screen.


### filter

Filters group functionality that is common to a branch of sub-commands.

```ruby
module Example
  class Frobnitz < Optix::CLI

    opt :debug, "Enable debugging"
    filter do |cmd, opts, argv|
      if opts[:debug]
        # .. enable debugging ..
      end
    end
    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

* Filters fire *after* validation, for each command in the chain.

* Parsing continues normally after a filter has fired.

* Your block receives three arguments:
    * `cmd` (Array) The full command that was executed, e.g.: ['foo', 'bar', 'baz']
    * `opts` (Hash) The options-hash, e.g.: { :debug => true }
    * `argv` (Array) Positional parameters that your command may have received, e.g.: ['a','b','c']

* You may raise `Optix::HelpNeeded` inside your filter to abort
  parsing and display the help-screen.


### Command-Method signature

```ruby
module Example
  class Frobnitz < Optix::CLI

    def frob(cmd, opts, argv)
      ...
    end
  end
end
```

* Your command-method receives three arguments:
    * `cmd` (Array) The full command that was executed, e.g.: ['foo', 'bar', 'baz']
    * `opts` (Hash) The options-hash, e.g.: { :debug => true }
    * `argv` (Array) Positional parameters that your command may have received, e.g.: ['a','b','c']

* You may raise `Optix::HelpNeeded` to display the help-screen and exit.

## Chain of execution

This is the chain of execution when you pass ['foo', 'bar', 'batz'] to `Optix.invoke!`:

  1. Triggers for `foo` (if any, execution stops if a trigger fires)
  1. Triggers for `bar` (if any, execution stops if a trigger fires)
  1. Triggers for `batz` (if any, execution stops if a trigger fires)
  1. Validation
  1. Filters for `foo` (if any)
  1. Filters for `bar` (if any)
  1. Filters for `batz` (if any)
  1. Your Command-method for `batz`

## Advanced usage

Optix can be shaped into many forms, this document
only describes the most common usage pattern.

Please see the specs, source-code and the examples in `examples/singleton_style`
for advanced usage examples (e.g. integrating Optix w/o sub-classing,
lower level API, scoping, etc.).


## Contributing

Patches are welcome, especially bugfixes.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (C) 2012, moe@busyloop.net

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, pulverize, distribute,
synergize, compost, defenestrate, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

If the Author of the Software (the "Author") needs a place to crash and
you have a sofa available, you should maybe give the Author a break and
let him sleep on your couch.

If you are caught in a dire situation wherein you only have enough time
to save one person out of a group, and the Author is a member of that
group, you must save the Author.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO BLAH BLAH BLAH ISN'T IT FUNNY HOW UPPER-CASE MAKES IT
SOUND LIKE THE LICENSE IS ANGRY AND SHOUTING AT YOU.

