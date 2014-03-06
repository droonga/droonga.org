---
title: API set for plugins on the handling phase
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

Each Droonga Engine plugin can have its *handler*.
On the handling phase, handlers can process a request and return a result.


### How to define a handler? {#howto-define}

For example, here is a sample plugin named "foo" with a handler:

~~~ruby
require "droonga/plugin"

module Droonga::Plugins::FooPlugin
  extend Plugin
  register("foo")

  define_single_step do |step|
    step.name = "foo"
    step.handler = :Handler
    step.collector = Collectors::And
  end

  class Handler < Droonga::Handler
    def handle(message)
      # operations to process a request
    end
  end
end
~~~

Steps to define a handler:

 1. Define a module for your plugin (ex. `Droonga::Plugins::FooPlugin`) and register it as a plugin. (required)
 2. Define a "single step" corresponding to the handler you are going to implement, via [`Droonga::SingleStepDefinition`](#class-Droonga-SingleStepDefinition). (required)
 2. Define a handler class (ex. `Droonga::Plugins::FooPlugin::Handler`) inheriting [`Droonga::Handler`](#classes-Droonga-Handler). (required)
 4. Define handling logic for requests as [`#handle`](#classes-Droonga-Handler-handle). (optional)

See also the [plugin development tutorial](../../../tutorial/plugin-development/handler/).


### How a handler works? {#how-works}

A handler works like following:

 1. The Droonga Engine starts.
    * Your custom steps are registered.
      Your custom handler classes also.
    * Then the Droonga Engine starts to wait for request messages.
 2. A request message is transferred from the adaption phase.
    Then, the processing phase starts.
    * The Droonga Engine finds a step definition from the message type.
    * The Droonga Engine builds a "single step" based on the registered definition.
    * A "single step" creates an instance of the registered handler class.
      Then the Droonga Engine enters to the handling phase.
      * The handler's [`#handle`](#classes-Droonga-Handler-handle) is called with a task massage including the request.
        * The method can process the given incoming message as you like.
        * The method returns a result value, as the output.
      * After the handler finishes, the handling phase for the task message (and the request) ends.
    * If no "step" is found for the type, nothing happens.
    * All "step"s finish their task, the processing phase for the request ends.

As described above, the Droonga Engine creates an instance of the handler class for each request.

Any error raised from the handler is handled by the Droonga Engine itself. See also [error handling][].


## Configurations {#config}

`action.synchronous` (boolean, optional, default=`false`)
: Indicates that the request must be processed synchronously.
  For example, a request to define a new column in a table must be processed after a request to define the table itself, if the table does not exist yet.
  Then handlers for these requests have the configuration `action.synchronous = true`.


## Classes and methods {#classes}

### `Droonga::SingleStepDefinition` {#classes-Droonga-SingleStepDefinition}

This provides methods to describe the "step" corresponding to the handler.

#### `#name=(name)` {#classes-Droonga-SingleStepDefinition-name}

Describes the name of the step itself.
The Droonga Engine treats an incoming message as a request of a "command", if there is any step with the `name` which equals to the message's `type`.
In other words, this defines the name of the command corresponding to the step itself.


#### `#handler=(handler)` {#classes-Droonga-SingleStepDefinition-handler}

(TBD)

#### `#collector=(collector)` {#classes-Droonga-SingleStepDefinition-collector}

(TBD)

#### `#write=(write)` {#classes-Droonga-SingleStepDefinition-write}

(TBD)

#### `#inputs=(inputs)` {#classes-Droonga-SingleStepDefinition-inputs}

(TBD)

#### `#output=(output)` {#classes-Droonga-SingleStepDefinition-output}

(TBD)

### `Droonga::Handler` {#classes-Droonga-Handler}

This is the common base class of any handler.
Your plugin's handler class must inherit this.

#### `#handle(message)` {#classes-Droonga-Handler-handle}

This method receives a [`Droonga::HandlerMessage`](#classes-Droonga-HandlerMessage) wrapped task message.
You can read the request information via its methods.

In this base class, this method is defined as just a placeholder and it does nothing.
To process messages, you have to override it by yours, like following:

~~~ruby
module Droonga::Plugins::MySearch
  class Handler < Droonga::Handler
    def handle(message)
      search_query = message.request["body"]["query"]
      ...
      { ... } # the result
    end
  end
end
~~~

The Droonga Engine uses the returned value of this method as the result of the handling.
It will be used to build the body of the unified response, and delivered to the Protocol Adapter.


### `Droonga::HandlerMessage` {#classes-Droonga-HandlerMessage}

This is a wrapper for a task message.

The Droonga Engine analyzes a transferred request message, and build multiple task massages to process the request.
A task massage has some information: a request, a step, descendant tasks, and so on.

#### `#request` {#classes-Droonga-HandlerMessage-request}

This returns the request message.
You can read request body via this method. For example:

~~~ruby
module Droonga::Plugins::MySearch
  class Handler < Droonga::Handler
    def handle(message)
      request = message.request
      search_query = request["body"]["query"]
      ...
    end
  end
end
~~~

#### `@context` {#classes-Droonga-HandlerMessage-context}

This is a reference to the `Groonga::Context` instance for the storage of the partition.
See the [class reference of Rroonga][Groonga::Context].

You can use any feature of Rroonga via `@context`.
For example, this code returns the number of records in the specified table:

~~~ruby
module Droonga::Plugins::CountRecords
  class Handler < Droonga::Handler
    def handle(message)
      request = message.request
      table_name = request["body"]["table"]
      count = @context[table_name].size
    end
  end
end
~~~

  [error handling]: ../error/
  [Groonga::Context]: http://ranguba.org/rroonga/en/Groonga/Context.html
