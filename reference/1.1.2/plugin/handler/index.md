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
 3. Define a handler class (ex. `Droonga::Plugins::FooPlugin::Handler`) inheriting [`Droonga::Handler`](#classes-Droonga-Handler). (required)
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

#### `#name`, `#name=(name)` {#classes-Droonga-SingleStepDefinition-name}

Describes the name of the step itself.
Possible value is a string.

The Droonga Engine treats an incoming message as a request of a "command", if there is any step with the `name` which equals to the message's `type`.
In other words, this defines the name of the command corresponding to the step itself.


#### `#handler`, `#handler=(handler)` {#classes-Droonga-SingleStepDefinition-handler}

Associates a specific handler class to the step itself.
You can specify the class as any one of following choices:

 * A reference to a handler class itself, like `Handler` or `Droonga::Plugins::FooPlugin::Handler`.
   Of course, the class have to be already defined at the time.
 * A symbol which refers the name of a handler class in the current namespace, like `:Handler`.
   This is useful if you want to describe the step at first and define the actual class after that.
 * A class path string of a handler class, like `"Droonga::Plugins::FooPlugin::Handler"`.
   This is also useful to define the class itself after the description.

You must define the referenced class by the time the Droonga Engine actually processes the step, if you specify the name of the handler class as a symbol or a string.
If the Droonga Engine fails to find out the actual handler class, or no handler is specified, then the Droonga Engine does nothing for the request.

#### `#collector`, `#collector=(collector)` {#classes-Droonga-SingleStepDefinition-collector}

Associates a specific collector class to the step itself.
You can specify the class as any one of following choices:

 * A reference to a collector class itself, like `Collectors::Something` or `Droonga::Plugins::FooPlugin::MyCollector`.
   Of course, the class have to be already defined at the time.
 * A symbol which refers the name of a collector class in the current namespace, like `:MyCollector`.
   This is useful if you want to describe the step at first and define the actual class after that.
 * A class path string of a collector class, like `"Droonga::Plugins::FooPlugin::MyCollector"`.
   This is also useful to define the class itself after the description.

You must define the referenced class by the time the Droonga Engine actually collects results, if you specify the name of the collector class as a symbol or a string.
If the Droonga Engine fails to find out the actual collector class, or no collector is specified, then the Droonga Engine doesn't collect results and returns multiple messages as results.

See also [descriptions of collectors][collector].

#### `#write`, `#write=(write)` {#classes-Droonga-SingleStepDefinition-write}

Describes whether the step modifies any data in the storage or don't.
If a request aims to modify some data in the storage, the request must be processed for all replicas.
Otherwise the Droonga Engine can optimize handling of the step.
For example, caching of results, reducing of CPU/memory usage, and so on.

Possible values are:

 * `true`, means "this step can modify the storage."
 * `false`, means "this step never modifies the storage." (default)

#### `#inputs`, `#inputs=(inputs)` {#classes-Droonga-SingleStepDefinition-inputs}

(TBD)

#### `#output`, `#output=(output)` {#classes-Droonga-SingleStepDefinition-output}

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

This is a reference to the `Groonga::Context` instance for the storage of the corresponding volume.
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
  [collector]: ../collector/
  [Groonga::Context]: http://ranguba.org/rroonga/en/Groonga/Context.html
