# Optix

Optix is an unobtrusive, composable command line parser based on Trollop.


## Features

* Lightweight, unobtrusive syntax.
  No subclassing or introduction of dependencies.

* Supports subcommands such as `git remote show origin` with arbitrary nesting.

* Subcommands inherit from their parent. Common options (such as '--debug' or '--loglevel')
  need to be declared only once to make them available to an entire branch.

* Stands on the shoulders of [Trollop](http://trollop.rubyforge.org) (by William Morgan), one of the most complete and robust
  option-parser implementations ever created.

* Automatic validation and help-screens.

* Strong test-suite.

## Installation

    $ gem install optix

## Example

```ruby
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

### Commands and Sub-Commands

Commands may be declared anywhere, at any time, in any order.
Declaring the "root"-command looks like this:

```ruby
require 'optix'

Optix::command do
  # opts, triggers, etc
end
```

Now, let's add a sub-command:

```ruby
Optix::command 'sub' do
  # opts, triggers, etc
end
```

And finally, a sub-sub command:

```ruby
Optix::command 'sub sub' do
  # opts, triggers, etc
end
```

Remember: Optix doesn't care about the order of declarations.
The `sub sub` command may be declared prior to the `sub` command.
 
A common pattern is to insert your `Optix::command` blocks directly
at the module level so they get invoked during class-loading.
This way your CLI assembles itself automatically and the
command-hierarchy mirrors the modules/classes that
are actually loaded.


### Optix::command DSL

Within `Optix::command` the following directives are available:

### desc

Short description, displayed in the subcommand-list on the help-screen of the *parent* command.

```ruby
Optix::command "frobnitz" do
  desc "Frobnicates the gizmo"
end
```

### text

Long description, displayed on the help-screen for this command.

```ruby
Optix::command "frobnitz" do
  text "Frobnicate the gizmo by subtle twiddling."
  text "Please only apply this to 2-state devices or you might bork it."
end
```

* May be called multiple times for a multi-line description.


### opt

Declares an option.

```ruby
Optix::command do
  opt :some_name, "some description", :default => 'some_default'
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

  * `:default` Set the default value for an argument. Without a default value, the opts-hash passed to `exec{}`
    and `filter{}` will have a *nil* value for this key unless the argument is given on the commandline.
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
Optix::command do
  params "<foo> [bar]"
end
```

* Note: Optix does **not** validate or inspect positional parameters at all (this is your job, inside exec{}).
  The value of this command is only used to display a proper synopsis in the help-screen.

### depends

Marks two (or more!) options as requiring each other. Only handles
undirected (i.e., mutual) dependencies.

```ruby
Optix::command do
  opt :we,     ""
  opt :are,    ""
  opt :family, ""
  depends :we, :are, :family
end
```

### conflicts

Marks two (or more!) options as conflicting.

```ruby
Optix::command do
  opt :force, "Force this operation"
  opt :no_op, "Dry run, don't actually do anything"
  conflict :force, :no_op
end
```

### trigger

Triggers allow to short-circuit argument parsing for "action-options"
(options that directly trigger an action) such as `--version`.

```ruby
Optix::command do
  opt :version, "Print version and exit"
  trigger :version do
    puts "Version 1.0"
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

Filters allow to group functionality that is common to a branch of subcommands.

```ruby
Optix::command do
  opt :debug, "Enable debugging"
  filter do |cmd, opts, argv|
    if opts[:debug]
      # .. enable debugging ..
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


### exec

The exec-block is called when your command is invoked, after validation
passed. It should contain (or invoke) your actual business logic.

```ruby
Optix::command do
  exec do |cmd, opts, argv|
    if opts[:debug]
      # .. enable debugging ..
    end
  end
end
```

* Your block receives three arguments:
    * `cmd` (Array) The full command that was executed, e.g.: ['foo', 'bar', 'baz']
    * `opts` (Hash) The options-hash, e.g.: { :debug => true }
    * `argv` (Array) Positional parameters that your command may have received, e.g.: ['a','b','c']

* You may raise `Optix::HelpNeeded` inside your exec-block to abort
  parsing and display the help-screen.


## Chain of execution

This is the chain of execution when you pass ['foo', 'bar', 'batz'] to `Optix.invoke!`:

  1. Triggers for `foo` (if any, execution stops if a trigger fires)
  1. Triggers for `bar` (if any, execution stops if a trigger fires)
  1. Triggers for `batz` (if any, execution stops if a trigger fires)
  1. Validation
  1. Filters for `foo` (if any)
  1. Filters for `bar` (if any)
  1. Filters for `batz` (if any)
  1. Exec{}-block for `batz`



## Scopes

In rare cases you may want to have multiple independent Optix command-trees in a single app.
This can be achieved by passing a scope-name to your command-declarations, like so:

```ruby
# Declare root-command in the :default scope
Optix::command '', :default do
  # opts, triggers, etc
end

# Declare root-command in another, independent scope
Optix::command '', :other_scope do
end

# Declare a sub-command in the other scope
Optix::command 'sub', :other_scope do
end

# Then either invoke the :default scope
Optix.invoke!(ARGV)
# ...or...
Optix.invoke!(ARGV, :other_scope)
```

## Re-initialization

In even rarer cases you may need to reset Optix at runtime.
To make Optix forget all scopes, configuration and commands, invoke:

`Optix.reset!`


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

