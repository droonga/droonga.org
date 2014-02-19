---
title: API set for plugins on the adaption phase
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

Each Droonga Engine plugin can have its *adapter*. On the adaption phase, adapters can modify both incoming messages (from the Protocol Adapter to the Droonga Engine, in other words, they are "request"s) and outgoing messages (from the Droonga Engine to the Protocol Adapter, in other words, they are "response"s).


### How to define an adapter? {#howto-define}

For example, here is a sample plugin named "foo" with an adapter:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module FooPlugin
      Plugin.registry.register("foo", self)

      class Adapter < Droonga::Adapter
        # operations to configure this adapter
        message.XXXXXX = XXXXXX

        def adapt_input(input_message)
          # operations to modify incoming messages
          input_message.XXXXXX = XXXXXX
        end

        def adapt_output(output_message)
          # operations to modify outgoing messages
          output_message.XXXXXX = XXXXXX
        end
      end
    end
  end
end
~~~

Steps to define an adapter:

 1. Define a module for your plugin (ex. `Droonga::Plugin::FooPlugin`) and register it as a plugin. (required)
 2. Define an adapter class (ex. `Droonga::Plugin::FooPlugin::Adapter`) inheriting [`Droonga::Adapter`](#classes-Droonga-Adapter). (required)
 3. [Configure conditions to apply the adapter](#howto-configure). (required)
 4. Define adaption logic for incoming messages as [`#adapt_input`](#classes-Droonga-Adapter-adapt_input). (optional)
 5. Define adaption logic for outgoing messages as [`#adapt_output`](#classes-Droonga-Adapter-adapt_output). (optional)

For more details, see also the [plugin development tutorial](../../../tutorial/plugin-development/adapter/).


### How an adapter works? {#how-works}

An adapter works like following:

 1. The Droonga Engine starts.
    * A global instance of the adapter class (ex. `Droonga::Plugin::FooPlugin::Adapter`) is created and it is registered.
      * The input pattern and the output pattern are registered.
    * The Droonga Engine starts to wait for incoming messages.
 2. An incoming message is transferred from the Protocol Adapter to the Droonga Engine.
    Then, the adaption phase (for an incoming message) starts.
    * The adapter's [`#adapt_input`](#classes-Droonga-Adapter-adapt_input) is called, if the message matches to the [input matching pattern](#config) of the adapter.
    * The method can modify the given incoming message, via [its methods](#classes-Droonga-InputMessage).
 3. After all adapters are applied, the adaption phase for an incoming message ends, and the message is transferred to the next "planning" phase.
 4. An outgoing message returns from the previous "collection" phase.
    Then, the adaption phase (for an outgoing message) starts.
    * The adapter's [`#adapt_output`](#classes-Droonga-Adapter-adapt_output) is called, if the corresponding incoming message was processed by the adapter itself and the outgoing message matches to the [output matching pattern](#config) of the adapter.
    * The method can modify the given outgoing message, via [its methods](#classes-Droonga-OutputMessage).
 5. After all adapters are applied, the adaption phase for an outgoing message ends, and the outgoing message is transferred to the Protocol Adapter.

As described above, the Droonga Engine creates only one global instance of the adapter class for each plugin.
You should not keep stateful information for a pair of incoming and outgoing messages as an instance variable of the adapter.
Instead, you should give stateful information as a part of the incoming message body, and receive it from the body of the corresponding outgoing message.

Any error raised from the adapter is handled by the Droonga Engine itself. See also [error handling][].


## Configurations {#config}

`input_message.pattern`
: A [matching pattern][] for incoming messages.
  Only messages matched to the given patten are processed by [`#adapt_input`](#classes-Droonga-Adapter-adapt_input).

`output_message.pattern`
: A [matching pattern][] for outgoing messages.
  Only messages matched to the given patten are processed by [`#adapt_output`](#classes-Droonga-Adapter-adapt_output).



## Classes and methods {#classes}

### `Droonga::Adapter` {#classes-Droonga-Adapter}

This is the common base class of any adapter. Your plugin's adapter class must inherit this.

#### `#adapt_input(input_message)` {#classes-Droonga-Adapter-adapt_input}

This method receives a [`Droonga::InputMessage`](#classes-Droonga-InputMessage) wrapped incoming message.
You can modify the incoming message via its methods.

This receives messages only matching to the `input_message.pattern`.
Other messages are ignored.

In this base class, this method is defined as just a placeholder and it does nothing.
To modify incoming messages, you have to override it by yours, like following:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    def adapt_input(input_message)
      input_message.body["query"] = "fixed query"
    end
  end
end
~~~

#### `#adapt_output(output_message)` {#classes-Droonga-Adapter-adapt_output}

This method receives a [`Droonga::OutputMessage`](#classes-Droonga-OutputMessage) wrapped outgoing message.
You can modify the outgoing message via its methods.

This receives messages only meeting both following requirements:

 * It is originated from an incoming message which was processed by this adapter itself.
 * It matches to the `output_message.pattern`.

Other messages are ignored.

In this base class, this method is defined as just a placeholder and it does nothing.
To modify outgoing messages, you have to override it by yours, like following:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    def adapt_output(output_message)
      output_message.status_code = StatusCode::OK
    end
  end
end
~~~

### `Droonga::Plugin::Metadata::AdapterMessage` {#classes-Droonga-Plugin-Metadata-AdapterMessage}

(under construction)

#### `#input_pattern`, `#input_pattern=(pattern)` {#classes-Droonga-Plugin-Metadata-AdapterMessage-input_pattern}

(under construction)

#### `#output_pattern`, `#output_pattern=(pattern)` {#classes-Droonga-Plugin-Metadata-AdapterMessage-output_pattern}

(under construction)

### `Droonga::InputMessage` {#classes-Droonga-InputMessage}

(under construction)

#### `#command`, `#command=(command)` {#classes-Droonga-InputMessage-command}

(under construction)

#### `#body`, `#body=(body)` {#classes-Droonga-InputMessage-body}

(under construction)

### `Droonga::OutputMessage` {#classes-Droonga-OutputMessage}

(under construction)

#### `#status_code`, `#status_code=(status_code)` {#classes-Droonga-OutputMessage-status_code}

(under construction)

#### `#errors`, `#errors=(errors)` {#classes-Droonga-OutputMessage-errors}

(under construction)

#### `#body`, `#body=(body)` {#classes-Droonga-OutputMessage-body}

(under construction)



  [matching pattern]: ../matching-pattern/
  [error handling]: ../error/
