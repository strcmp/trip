## About

trip.rb is a concurrent tracer that can pause and resume the code
it is tracing. The tracer yields control between two threads - typically
the main thread and a thread that Trip creates. The process of yielding
control back and forth between the two threads is repeated until the tracer
thread exits.

trip.rb is implemented using [TracePoint](https://docs.w3cub.com/ruby~3/tracepoint) -
and before that trip.rb used ["Thread#set_trace_func"](https://docs.w3cub.com/ruby~3/thread#method-i-set_trace_func).
From v3.0.0 onwards Trip uses TracePoint, and older versions use `Thread#set_trace_func`.

## Examples

### Concurrency

#### What is a concurrent tracer ?

In the context of Trip - it can be explained as a tracer that spawns a new thread
to run (and trace) a piece of Ruby code. The tracer then pauses the new thread
when a condition is met, and then yields control back to the calling thread
(normally the main thread).

The main thread can then resume the tracer, and repeat this process until the
tracer thread exits. While the tracer thread is paused, the main thread can examine
event information - and evaluate code in the [Binding (context)](https://rubydoc.info/stdlib/core/Binding) of where an event
occurred. The following example hopes to provide a clearer picture of what that means
in practice:

```ruby
require "trip"

module Stdout
  def self.write(message)
    puts(message)
  end
end

##
# Create a new Trip.
# Pause for events coming from "Stdout.write".
trip = Trip.new { Stdout.write("Ruby is") }
trip.pause_when { |event| event.self == Stdout && event.method_id == :write }

##
# Enter "Stdout.write" - then mutate a local
# variable while the tracer thread is paused.
event = trip.start
event.binding.eval("message << ' cool.'")

##
# Execute the "puts(message)" line, and pause
# for the return of "Stdout.write".
event = trip.resume

##
# Exit the "Stdout.write" method, and the
# tracer thread.
event = trip.resume

##
# Ruby is cool.
```

### Filter

#### Events

Trip will listen for method call and return events from methods
implemented in either C or Ruby by default. The `events:` keyword
argument can be used to narrow or extend the scope of what events the
tracer will listen for.

The `events:` keyword argument uses a TracePoint feature
that allows certain events to be included or excluded from
the trace. When the `events:` keyword argument is used, Trip
does not generate events that are not explicitly included by name.

All events can be listened for by using `Trip.new(events: :all) { ... }`,
or `Trip.new(events: '*') { ... }`. A full list of event names can be found in the
[Trip::Event docs](https://0x1eef.github.io/x/trip.rb/Trip/Event.html). The following example
uses `trip.resume` to both start and resume the tracer - without calling `trip.start`, and only listens for call and return events from methods
implemented in Ruby:

```ruby
require "trip"

def add(x, y)
  puts(x + y)
end

trip = Trip.new(events: %i[call return]) { add(20, 50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

##
# call add
# 70
# return add
```

#### `Trip#pause_when`

In the previous example we saw how to filter events.
**The events specified by the `events:` keyword argument
decide what events will be made available to `Trip#pause_when`.**
By default `Trip#pause_when` will pause the tracer on method call
and return events from methods implemented in either C or Ruby.

The following example demonstrates how to customize the logic for pausing
the tracer. The following example will pause the tracer when a new module / class
is defined with the `module Name` or `class Name` syntax:

```ruby
require "trip"

trip = Trip.new(events: %i[class]) do
  class Foo
  end

  class Bar
  end

  class Baz
  end
end

trip.pause_when(&:module_opened?)
while event = trip.resume
  print event.self, " class opened", "\n"
end

##
# Foo class opened
# Bar class opened
# Baz class opened
```

### Rescue

#### IRB

Trip can listen for the `raise` event, and then pause the tracer when
it is encountered. Afterwards - an IRB session can be started in the [Binding (context)](https://rubydoc.info/stdlib/core/Binding)
of where an exception has been raised. The following example provides a
demonstration:

```ruby
require "trip"

module Stdout
  def self.write(message)
    putzzz(message)
  end
end

trip = Trip.new(events: %i[raise]) { Stdout.write("hello") }
trip.pause_when(&:raise?)
event = trip.start
event.binding.irb
```

## Resources

* [Homepage](https://0x1eef.github.io/x/trip.rb)
* [Source code](https://github.com/0x1eef/trip.rb)

## Install

trip.rb is available as a RubyGem:

    gem install trip.rb

## <a id='license'>License</a>

This project is released under the terms of the MIT license. <br>
See [LICENSE.txt](./LICENSE.txt) for details.
