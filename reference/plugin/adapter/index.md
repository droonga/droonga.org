---
title: API set for plugins on the adaption phase
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

Each Droonga Engine plugin can have its *adapter*. On the adaption phase, adapters can modify both incoming messages (from the Protocol Adapter to the Droonga Engine, in other words, they are "request"s) and outgoing messages (from the Droonga Engine to the Protocol Adapter, in other words, they are "response"s).


## How to define an adapter? {#howto-define}

For example, here is a sample plugin named "foo" with an adapter:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module FooPlugin
      Plugin.registry.register("foo", self)

      class Adapter < Droonga::Adapter
        # operations to configure this behavior
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

 1. Define the module `FooPlugin` and register it as a plugin. (required)
 2. Define the adapter class `FooPlugin::Adapter` as a sub class of [`Droonga::Adapter`](#classes-Droonga-Adapter). (required)
 3. Configure conditions to apply the adapter via [`.message`](#classes-Droonga-Adapter-class-message). (required)
 4. Define adaption logic for incoming messages as [`#adapt_input`](#classes-Droonga-Adapter-adapt_input). (optional)
 5. Define adaption logic for outgoing messages as [`#adapt_output`](#classes-Droonga-Adapter-adapt_output). (optional)

For more details, see also the [plugin development tutorial](../../../tutorial/plugin-development/adapter/).


## How works an adapter? {#how-works}

 1. The Droonga Engine starts.
    * A global instance of the c (ex. `FooPlugin::Adapter`) is created and it is registered.
      * The input pattern and the output pattern are registered via [its `.message`](#classes-Droonga-Adapter-class-message).
    * The Droonga Engine starts to wait for incoming messages.
 2. An incoming message is transferred from the Protocol Adapter to the Droonga Engine.
    Then, the adaption phase (for an incoming message) starts.
    * The adapter's [`#adapt_input`](#classes-Droonga-Adapter-adapt_input) is called, if the message matches to the input pattern.
    * The method can modify the given incoming message, via [its methods](#classes-Droonga-InputMessage).
 3. After all adapters are applied, the adaption phase for an incoming message ends, and the message is transferred to the next "planning" phase.
 4. An outgoing message returns from the previous "collection" phase.
    Then, the adaption phase (for an outgoing message) starts.
    * The adapter's [`#adapt_output`](#classes-Droonga-Adapter-adapt_output) is called, if the corresponding incoming message was processed by the adapter and the outgoing message matches to the output pattern.
    * The method can modify the given outgoing message, via [its methods](#classes-Droonga-OutputMessage).
 5. After all adapters are applied, the adaption phase for an outgoing message ends, and the outgoing message is transferred to the Protocol Adapter.


## Classes {#classes}

(under construction)

### `Droonga::Adapter` {#classes-Droonga-Adapter}

(under construction)

#### `.message` {#classes-Droonga-Adapter-class-message}

(under construction)

#### `#adapt_input` {#classes-Droonga-Adapter-adapt_input}

(under construction)

#### `#adapt_output` {#classes-Droonga-Adapter-adapt_output}

(under construction)

### `Droonga::Plugin::Metadata::AdapterMessage` {#classes-Droonga-Plugin-Metadata-AdapterMessage}

(under construction)

#### `#input_pattern` {#classes-Droonga-Plugin-Metadata-AdapterMessage-input_pattern}

(under construction)

#### `#output_pattern` {#classes-Droonga-Plugin-Metadata-AdapterMessage-output_pattern}

(under construction)

### `Droonga::InputMessage` {#classes-Droonga-InputMessage}

(under construction)

#### `#command` {#classes-Droonga-InputMessage-command}

(under construction)

#### `#body` {#classes-Droonga-InputMessage-body}

(under construction)

### `Droonga::OutputMessage` {#classes-Droonga-OutputMessage}

(under construction)

#### `#status_code` {#classes-Droonga-OutputMessage-status_code}

(under construction)

#### `#errors` {#classes-Droonga-OutputMessage-errors}

(under construction)

#### `#body` {#classes-Droonga-OutputMessage-body}

(under construction)



