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

 1. Define a module for your plugin (ex. `Droonga::Plugin::FooPlugin`) and register it as a plugin. (required)
 2. Define an adapter class (ex. `Droonga::Plugin::FooPlugin::Adapter`) inheriting [`Droonga::Adapter`](#classes-Droonga-Adapter). (required)
 3. Configure conditions to apply the adapter via [`.message`](#classes-Droonga-Adapter-class-message). (required)
 4. Define adaption logic for incoming messages as [`#adapt_input`](#classes-Droonga-Adapter-adapt_input). (optional)
 5. Define adaption logic for outgoing messages as [`#adapt_output`](#classes-Droonga-Adapter-adapt_output). (optional)

For more details, see also the [plugin development tutorial](../../../tutorial/plugin-development/adapter/).


### How an adapter works? {#how-works}

 1. The Droonga Engine starts.
    * A global instance of the adapter class (ex. `Droonga::Plugin::FooPlugin::Adapter`) is created and it is registered.
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


## Classes and methods {#classes}

### `Droonga::Adapter` {#classes-Droonga-Adapter}

This is the common base class of any adapter. Your plugin's adapter class must inherit the class.

#### `.message` {#classes-Droonga-Adapter-class-message}

Returns an instance of [`Droonga::Plugin::Metadata::AdapterMessage`](#classes-Droonga-Plugin-Metadata-AdapterMessage) for the class itself. You can configure your adapter via this, like a DSL. For example:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    message.input_pattern = ["type", :equal, "foo"]
    message.output_pattern = ["body.success", :exist?]
  end
end
~~~

Don't override this method because it is managed by the Droonga Engine itself.

#### `#adapt_input(input_message)` {#classes-Droonga-Adapter-adapt_input}



(under construction)

#### `#adapt_output(output_message)` {#classes-Droonga-Adapter-adapt_output}

(under construction)

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



