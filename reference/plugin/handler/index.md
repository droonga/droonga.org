---
title: API set for plugins on the handling phase
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

Each Droonga Engine plugin can have its *handler*.
On the handling phase, handlers can process any incoming message and output various messages (ex. a "response" for a "request") as you like.


### How to define a handler? {#howto-define}

For example, here is a sample plugin named "foo" with a handler:

~~~ruby
require "droonga/plugin"

module Droonga::Plugins::FooPlugin
  Plugin.registry.register("foo", self)

  class Handler < Droonga::Handler
    # operations to configure this handler
    XXXXXX = XXXXXX

    def handle(message, messenger)
      # operations to process incoming messages
    end
  end
end
~~~

Steps to define a handler:

 1. Define a module for your plugin (ex. `Droonga::Plugins::FooPlugin`) and register it as a plugin. (required)
 2. Define a handler class (ex. `Droonga::Plugins::FooPlugin::Handler`) inheriting [`Droonga::Handler`](#classes-Droonga-Handler). (required)
 3. [Configure conditions for the handler](#howto-configure). (required)
 4. Define handling logic for incoming messages as [`#handle`](#classes-Droonga-Handler-handle). (optional)

See also the [plugin development tutorial](../../../tutorial/plugin-development/handler/).


### How a handler works? {#how-works}

A handler works like following:

 1. The Droonga Engine starts.
    * A global instance of the handler class (ex. `Droonga::Plugins::FooPlugin::Handler`) is created and it is registered.
      * The message type is registered.
    * The Droonga Engine starts to wait for incoming messages.
 2. An incoming message is transferred from the planning phase.
    Then, the handling phase starts.
    * The Droonga Engine finds the handler from the message type.
    * Found handler's [`#handle`](#classes-Droonga-Handler-handle) is called with the incoming message.
      * The method can process the given incoming message as you like.
      * The method can output any message as you like.
    * If no handler is found for the type, nothing happens.
 3. After the handler finishes (or no handler is found), the handling phase for the incoming message ends.

As described above, the Droonga Engine creates only one global instance of the handler class for each plugin.
You should not keep stateful information as instance variables of the handler itself.
Instead, you should use the body of messages.

Any error raised from the handler is handled by the Droonga Engine itself. See also [error handling][].


## Configurations {#config}

`message.type` (`String`, required)
: (TBD)

`action.synchronous` (boolean, optional, default=false)
: (TBD)


## Classes and methods {#classes}

### `Droonga::Handler` {#classes-Droonga-Handler}

This is the common base class of any handler. Your plugin's handler class must inherit this.

#### `#handle(message, messenger)` {#classes-Droonga-Handler-handle}

This method receives a [`Droonga::HandlerMessage`](#classes-Droonga-HandlerMessage) wrapped incoming message.

(TBD)

### `Droonga::HandlerMessage` {#classes-Droonga-HandlerMessage}

#### `#request` {#classes-Droonga-HandlerMessage-request}

(TBD)

  [error handling]: ../error/
