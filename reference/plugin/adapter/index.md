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
        XXXXXX = XXXXXX

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
    * The adapter's [`#adapt_output`](#classes-Droonga-Adapter-adapt_output) is called, if the message meets following both requirements:
      - It is originated from an incoming message which was processed by the adapter itself.
      - It matches to the [output matching pattern](#config) of the adapter.
    * The method can modify the given outgoing message, via [its methods](#classes-Droonga-OutputMessage).
 5. After all adapters are applied, the adaption phase for an outgoing message ends, and the outgoing message is transferred to the Protocol Adapter.

As described above, the Droonga Engine creates only one global instance of the adapter class for each plugin.
You should not keep stateful information for a pair of incoming and outgoing messages as an instance variable of the adapter.
Instead, you should give stateful information as a part of the incoming message body, and receive it from the body of the corresponding outgoing message.

Any error raised from the adapter is handled by the Droonga Engine itself. See also [error handling][].


## Configurations {#config}

`input_message.pattern` (optional, default=`nil`)
: A [matching pattern][] for incoming messages.
  If no pattern (`nil`) is given, any message is regarded as "matched".

`output_message.pattern` (optional, default=`nil`)
: A [matching pattern][] for outgoing messages.
  If no pattern (`nil`) is given, any message is regarded as "matched".


## Classes and methods {#classes}

### `Droonga::Adapter` {#classes-Droonga-Adapter}

This is the common base class of any adapter. Your plugin's adapter class must inherit this.

#### `#adapt_input(input_message)` {#classes-Droonga-Adapter-adapt_input}

This method receives a [`Droonga::InputMessage`](#classes-Droonga-InputMessage) wrapped incoming message.
You can modify the incoming message via its methods.

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

### `Droonga::InputMessage` {#classes-Droonga-InputMessage}

#### `#command`, `#command=(command)` {#classes-Droonga-InputMessage-command}

This returns the `"type"` of the incoming message.

You can override it by assigning a new string value, like:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "my-search"]

    def adapt_input(input_message)
      p input_message.command
      # => "my-search"
      #    This message will be handled by a plugin
      #    for the custom "my-search" command.

      input_message.command = "search"

      p input_message.command
      # => "search"
      #    The messge type (command) is changed.
      #    This message will be handled by the "search" plugin,
      #    as a regular search request.
    end
  end
end
~~~

#### `#body`, `#body=(body)` {#classes-Droonga-InputMessage-body}

This returns the `"body"` of the incoming message.

You can override it by assigning a new value, partially or fully. For example:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "search"]

    MAXIMUM_LIMIT = 10

    def adapt_input(input_message)
      input_message.body["queries"].each do |name, query|
        query["output"] ||= {}
        query["output"]["limit"] ||= MAXIMUM_LIMIT
        query["output"]["limit"] = [query["output"]["limit"], MAXIMUM_LIMIT].min
      end
      # Now, all queries have "output.limit=10".
    end
  end
end
~~~

Another case:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "my-search"]

    def adapt_input(input_message)
      # Extract the query string from the custom command.
      query_string = input_message["body"]["query"]

      # Construct internal search request for the "search" command.
      input_message.command = "search"
      input_message.body = {
        "queries" => {
          "source"    => "Store",
          "condition" => {
            "query"   => query_string,
            "matchTo" => ["name"],
          },
          "output" => {
            "elements" => ["records"],
            "limit"    => 10,
          },
        },
      }
      # Now, both "type" and "body" are completely replaced.
    end
  end
end
~~~

### `Droonga::OutputMessage` {#classes-Droonga-OutputMessage}

#### `#status_code`, `#status_code=(status_code)` {#classes-Droonga-OutputMessage-status_code}

This returns the `"statusCode"` of the outgoing message.

You can override it by assigning a new status code. For example: 

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "search"]

    def adapt_output(output_message)
      unless output_message.status_code == StatusCode::InternalServerError
        output_message.status_code = StatusCode::OK
        output_message.body = {}
        output_message.errors = nil
        # Now any internal server error is ignored and clients
        # receive regular responses.
      end
    end
  end
end
~~~

#### `#errors`, `#errors=(errors)` {#classes-Droonga-OutputMessage-errors}

This returns the `"errors"` of the outgoing message.

You can override it by assigning new error information, partially or fully. For example:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "search"]

    def adapt_output(output_message)
      output_message.errors.delete(secret_database)
      # Delete error information from secret database

      output_message.body["errors"] = {
        "records" => output_message.errors.collect do |database, error|
          {
            "database" => database,
            "error" => error
          }
        end,
      }
      # Convert error informations to a fake search result named "errors".
    end
  end
end
~~~

#### `#body`, `#body=(body)` {#classes-Droonga-OutputMessage-body}

This returns the `"body"` of the outgoing message.

You can override it by assigning a new value, partially or fully. For example:

~~~ruby
module FooPlugin
  class Adapter < Droonga::Adapter
    input_message.pattern = ["type", :equal, "search"]

    def adapt_output(output_message)
      output_message.body.each do |name, result|
        next unless result["records"]
        result["records"] << ad_entry
      end
      # Now all search results include advertising.
    end

    def ad_entry
      {
        "title"=> "Buy Now!!",
        "url"=>   "http://..."
      }
    end
  end
end
~~~


  [matching pattern]: ../matching-pattern/
  [error handling]: ../error/
