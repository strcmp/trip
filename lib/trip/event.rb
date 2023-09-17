# frozen_string_literal: true

##
# {Trip::Event Trip::Event} represents an event generated by
# Trip. It is yielded to the callable set by {Trip#pause_when Trip#pause_when},
# and returned by {Trip#start Trip#start} and {Trip#resume Trip#resume}.
#
# An event is known by a name, which can be one of the following:
#
#  * `:c_call`:
#     when a method implemented in C is called.
#  * `:c_return`:
#     when a method implemented in C returns.
#  * `:call`:
#     when a method implemented in Ruby is called.
#  * `:return`:
#     when a method implemented in Ruby returns.
#  * `:class`:
#     when a module / class is defined or reopened.
#  * `:end`:
#     when a module / class definition or reopen ends.
#  * `:line`:
#     when starting a new expression or statement.
#  * `:raise`:
#     when an exception is raised.
#  * `:b_call`:
#     when a block is called.
#  * `:b_return`:
#     when a block returns.
#  * `:thread_begin`:
#     when a thread begins.
#  * `:thread_end`:
#     when a thread ends.
#  * `:fiber_switch`:
#     when a Fiber switches context.
#  * `:script_compiled`:
#     when Ruby code is compiled by `eval`, `require`, or `load`.
class Trip::Event
  require "json" unless {}.respond_to?(:to_json)

  ##
  # @param [Symbol] name
  #  The name of an event.
  #
  # @param [Hash] tp
  #  A hash from TracePoint.
  def initialize(name, tp)
    @name = name
    @tp = tp
    @epoch = Integer(Process.clock_gettime(Process::CLOCK_REALTIME))
  end

  ##
  # @group Event properties
  #
  # @return [Symbol]
  #  Returns the event name.
  attr_reader :name

  ##
  # @return [Integer]
  #  Returns the event's creation time as the number
  #  of seconds since epoch.
  attr_reader :epoch

  ##
  # @return [String]
  #  Returns the path associated with an event.
  def path
    @tp[:path]
  end

  ##
  # @return [Integer]
  #  Returns the line number associated with an event.
  def lineno
    @tp[:lineno]
  end

  ##
  # @return [Object, BasicObject]
  #  Returns the `self` where an event occurred.
  def self
    @tp[:self]
  end

  ##
  # @return [Symbol]
  #  Returns the method id associated with an event.
  def method_id
    @tp[:method_id]
  end

  ##
  # @return [Binding]
  #  Returns a Binding object bound to where an event occurred.
  def binding
    @tp[:binding]
  end
  # @endgroup

  ##
  # @group Event predicates
  #
  # @return [Boolean]
  #  Returns true when a module / class is opened.
  def module_opened?
    @name == :class
  end

  ##
  # @return [Boolean]
  #  Returns true when a module / class is closed.
  def module_closed?
    @name == :end
  end

  ##
  # @return [Boolean]
  #  Returns true when a block is called.
  def block_call?
    @name == :b_call
  end

  ##
  # @return [Boolean]
  #  Returns true when a block returns.
  def block_return?
    @name == :b_return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in Ruby is called.
  def rb_call?
    @name == :call
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in Ruby returns.
  def rb_return?
    @name == :return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in C is called.
  def c_call?
    @name == :c_call
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in C returns.
  def c_return?
    @name == :c_return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in either Ruby
  #  or C is called.
  def call?
    c_call? || rb_call?
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in either Ruby
  #  or C returns.
  def return?
    c_return? || rb_return?
  end

  ##
  # @return [Boolean]
  #  Returns true when a thread begins.
  def thread_begin?
    @name == :thread_begin
  end

  ##
  # @return [Boolean]
  #  Returns true when a thread ends.
  def thread_end?
    @name == :thread_end
  end

  ##
  # @return [Boolean]
  #  Returns true when a Fiber switches context.
  def fiber_switch?
    @name == :fiber_switch
  end

  ##
  # @return [Boolean]
  #  Returns true when a script is compiled.
  def script_compiled?
    @name == :script_compiled
  end

  ##
  # @return [Boolean]
  #  Returns true when an exception is raised.
  def raise?
    @name == :raise
  end

  ##
  # @return [Boolean]
  #  Returns true when starting a new expression or statement.
  def line?
    @name == :line
  end
  # @endgroup

  ##
  # @return [Hash]
  #  Returns a Hash object that can be serialized to JSON.
  def as_json
    {
      "event" => name.to_s, "path" => path,
      "lineno" => lineno, "method_id" => method_id.to_s,
      "method_type" => (Module === @tp[:self]) ? "singleton_method" : "instance_method",
      "module_name" => (Module === @tp[:self]) ? @tp[:self].name : @tp[:self].class.name
    }
  end

  ##
  # @return [String]
  #  Returns a string representation of a JSON object.
  def to_json(options = {})
    as_json.to_json(options)
  end

  ##
  # REPL support.
  #
  # @return [void]
  def pretty_print(q)
    q.text(inspect)
  end

  ##
  # REPL support.
  #
  # @return [String]
  def inspect
    ["#<",
      to_s.sub!("#<", "").sub!(">", ""),
      " @name=:#{@name}",
      " path='#{path}:#{lineno}'",
      ">"].join
  end

  # @return [Binding]
  #  Returns a binding object for an instance of {Trip::Event}.
  def __binding__
    ::Kernel.binding
  end
end
