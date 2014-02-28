---
title: "Plugin: Adapt requests and responses, to add a new command based on other existing commands"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to develop a Droonga plugin by yourself.

This page focuses on the adaption phase for Droonga plugins.
At the last, wraps up them to make a small practical plugin named `store-search`, for the adaption phase.

## Precondition

* You must complete the [basic tutorial][].


## Adaption for incoming messages

First, let's study basics with a simple logger plugin named `sample-logger` affects at the adaption phase.

We sometime need to modify incoming requests from outside to Droonga Engine.
We can use a plugin for this purpose.
Let's see how to create a plugin for the adaption phase, in this section.

### Directory Structure

Assume that we are going to add a new plugin to the system built in the [basic tutorial][].
In that tutorial, Groonga engine was placed under `engine` directory.

Plugins need to be placed in an appropriate directory. Let's create the directory:

~~~
# cd engine
# mkdir -p lib/droonga/plugins
~~~

After creating the directory, the directory structure should be like this:

~~~
engine
├── catalog.json
├── fluentd.conf
└── lib
    └── droonga
        └── plugins
~~~


### Create a plugin

You must put codes for a plugin into a file which has the name *same to the plugin itself*.
Because the plugin now you creating is `sample-logger`, put codes into a file `sample-logger.rb` in the `droonga/plugins` directory.

lib/droonga/plugins/sample-logger.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module SampleLoggerPlugin
      extend Plugin
      register("sample-logger")

      class Adapter < Droonga::Adapter
        # You'll put codes to modify messages here.
      end
    end
  end
end
~~~

This plugin does nothing except registering itself to Droonga.

 * The `sample-logger` is the name of the plugin itself. You'll use it in your `catalog.json`, to activate the plugin.
 * As the example above, you must define your plugin as a module.
 * Behaviors at the adaption phase is defined a class called *adapter*.
   An adapter class must be defined as a subclass of the `Droonga::Adapter`, under the namespace of the plugin module.


### Activate the plugin with `catalog.json`

You need to update `catalog.json` to activate your plugin.
Insert the name of the plugin `"sample-logger"` to the `"plugins"` list under the dataset, like:

catalog.json:

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["sample-logger", "groonga", "crud", "search"],
(snip)
~~~

Note: you must place `"sample-logger"` before `"search"`, because the `sample-logger` plugin depends on the `search`. Droonga Engine applies plugins at the adaption phase in the order defined in the `catalog.json`, so you must resolve plugin dependencies by your hand (for now).

### Run

Let's get Droonga started.
Note that you need to specify `./lib` directory in `RUBYLIB` environment variable in order to make ruby possible to find your plugin.

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

### Test

Check if the engine is working. First, create a request as a JSON.

search-columbus.json:

~~~json
{
  "dataset" : "Starbucks",
  "type"    : "search",
  "body"    : {
    "queries" : {
      "stores" : {
        "source"    : "Store",
        "condition" : {
          "query"   : "Columbus",
          "matchTo" : "_key"
        },
        "output" : {
          "elements"   : [
            "startTime",
            "elapsedTime",
            "count",
            "attributes",
            "records"
          ],
          "attributes" : ["_key"],
          "limit"      : -1
        }
      }
    }
  }
}
~~~

This is corresponding to the example to search "Columbus" in the [basic tutorial][]. Note that the request for the Protocol Adapter is encapsulated in `"body"` element.

Send the request to engine with `droonga-request`:

~~~
# droonga-request --tag starbucks search-columbus.json
Elapsed time: 0.021544
[
  "droonga.message",
  1392617533,
  {
    "inReplyTo": "1392617533.9644868",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

This is the search result.


### Do something in the plugin: take logs

The plugin we have created do nothing so far. Let's get the plugin to do some interesting.

First of all, trap `search` request and log it. Update the plugin like below:

lib/droonga/plugins/sample-logger.rb:

~~~ruby
(snip)
    module SampleLoggerPlugin
      extend Plugin
      register("sample-logger")

      class Adapter < Droonga::Adapter
        input_message.pattern = ["type", :equal, "search"]

        def adapt_input(input_message)
          logger.info("SampleLoggerPlugin::Adapter", :message => input_message)
        end
      end
    end
(snip)
~~~

The line beginning with `input_message.pattern` is a configuration.
This example defines a plugin for any incoming message with `"type":"search"`.
See the [reference manual's configuration section](../../../reference/plugin/adapter/#config)

(Note: `input_message.pattern` is for Droonga 1.0.0 and later. On Droonga 0.9.9, you have to use a deprecated configuration `message.input_pattern` instead.)

The method `adapt_input` is called for every incoming message matching to the pattern.
The argument `input_message` is a wrapped version of the incoming message.

Restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

Send the request same as the previous section:

~~~
# droonga-request --tag starbucks search-columbus.json
Elapsed time: 0.014714
[
  "droonga.message",
  1392618037,
  {
    "inReplyTo": "1392618037.935901",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

You will see something like below fluentd's log in `fluentd.log`:

~~~
2014-02-17 15:20:37 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::InputMessage:0x007f8ae3e1dd98 @raw_message={"dataset"=>"Starbucks", "type"=>"search", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:64591/droonga"}, "id"=>"1392618037.935901", "date"=>"2014-02-17 15:20:37 +0900", "appliedAdapters"=>[]}>
~~~

This shows the message is received by our `SampleLoggerPlugin::Adapter` and then passed to Droonga. Here we can modify the message before the actual data processing.

### Modify messages with the plugin

Suppose that we want to restrict the number of records returned in the response, say `1`.
What we need to do is set `limit` to be `1` for every request.
Update plugin like below:

lib/droonga/plugins/sample-logger.rb:

~~~ruby
(snip)
        def adapt_input(input_message)
          logger.info("SampleLoggerPlugin::Adapter", :message => input_message)
          input_message.body["queries"]["stores"]["output"]["limit"] = 1
        end
(snip)
~~~

Like above, you can modify the incoming message via methods of the argument `input_message`.
See the [reference manual for the message class](../../../reference/plugin/adapter/#classes-Droonga-InputMessage).

Restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

After restart, the response always includes only one record in `records` section.

Send the request same as the previous:

~~~
# droonga-request --tag starbucks search-columbus.json
Elapsed time: 0.017343
[
  "droonga.message",
  1392618279,
  {
    "inReplyTo": "1392618279.0578449",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

Note that `count` is still `2` because `limit` does not affect to `count`. See [search][] for details of the `search` command.

You will see something like below fluentd's log in `fluentd.log`:

~~~
2014-02-17 15:24:39 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::InputMessage:0x007f956685c908 @raw_message={"dataset"=>"Starbucks", "type"=>"search", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:64616/droonga"}, "id"=>"1392618279.0578449", "date"=>"2014-02-17 15:24:39 +0900", "appliedAdapters"=>[]}>
~~~


## Adaption for outgoing messages

In case we need to modify outgoing messages from Droonga Engine, for example, search results, then we can do it simply by another method.
In this section, we are going to define a method to adapt outgoing messages.


### Add a method to adapt outgoing messages

Let's take logs of results of `search` command.
Define the `adapt_output` method to process outgoing messages.
Remove `adapt_input` at this moment for the simplicity.

lib/droonga/plugins/sample-logger.rb:

~~~ruby
(snip)
    module SampleLoggerPlugin
      extend Plugin
      register("sample-logger")

      class Adapter < Droonga::Adapter
        (snip)

        def adapt_output(output_message)
          logger.info("SampleLoggerPlugin::Adapter", :message => output_message)
        end
      end
    end
(snip)
~~~

The method `adapt_output` is called only for outgoing messages triggered by incoming messages processed by the plugin itself.
See the [reference manual for plugin developers](../../../reference/plugin/adapter/) for more details.

### Run

Let's restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

And send search request (Use the same JSON for request as in the previous section):

~~~
# droonga-request --tag starbucks search-columbus.json
Elapsed time: 0.015491
[
  "droonga.message",
  1392619269,
  {
    "inReplyTo": "1392619269.184789",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

The fluentd's log should be like as follows:

~~~
2014-02-17 15:41:09 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::OutputMessage:0x007fddcad4d5a0 @raw_message={"dataset"=>"Starbucks", "type"=>"dispatcher", "body"=>{"stores"=>{"count"=>2, "records"=>[["Columbus @ 67th - New York NY  (W)"], ["2 Columbus Ave. - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:64724/droonga"}, "id"=>"1392619269.184789", "date"=>"2014-02-17 15:41:09 +0900", "appliedAdapters"=>["Droonga::Plugins::SampleLoggerPlugin::Adapter", "Droonga::Plugins::Error::Adapter"]}>
~~~

This shows that the result of `search` is passed to the `adapt_output` method (and logged), then outputted.


### Modify results in the adaption phase

Let's modify the result.
For example, add `completedAt` attribute that shows the time completed the request.
Update your plugin as follows:

lib/droonga/plugins/sample-logger.rb:

~~~ruby
(snip)
        def adapt_output(output_message)
          logger.info("SampleLoggerPlugin::Adapter", :message => output_message)
          output_message.body["stores"]["completedAt"] = Time.now
        end
(snip)
~~~

Like above, you can modify the outgoing message via methods of the argument `output_message`. 
See the [reference manual for the message class](../../../reference/plugin/adapter/#classes-Droonga-OutputMessage).

Restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

Send the same search request:

~~~
# droonga-request --tag starbucks search-columbus.json
Elapsed time: 0.013983
[
  "droonga.message",
  1392619528,
  {
    "inReplyTo": "1392619528.235121",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ],
        "completedAt": "2014-02-17T06:45:28.247669Z"
      }
    }
  }
]
~~~

Now you can see `completedAt` attribute containing the time completed the request.
The results in `fluentd.log` will be like this:

~~~
2014-02-17 15:45:28 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::OutputMessage:0x007fd384f3ab60 @raw_message={"dataset"=>"Starbucks", "type"=>"dispatcher", "body"=>{"stores"=>{"count"=>2, "records"=>[["Columbus @ 67th - New York NY  (W)"], ["2 Columbus Ave. - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:64849/droonga"}, "id"=>"1392619528.235121", "date"=>"2014-02-17 15:45:28 +0900", "appliedAdapters"=>["Droonga::Plugins::SampleLoggerPlugin::Adapter", "Droonga::Plugins::Error::Adapter"]}>
~~~


## Translation for both incoming and outgoing messages

We have learned the basics of plugins for the adaption phase so far.
Let's try to build more practical plugin.

You may feel the Droonga's `search` command is too flexible for your purpose.
Here, we're going to add our own `storeSearch` command to wrap the `search` command in order to provide an application-specific and simple interface, with a new plugin named `store-search`.

### Accept simple requests

First, create the `store-searach` plugin. Remember, you must put codes into a file which has the name same to the plugin now you are creating. So, the file is `store-search.rb` in the `droonga/plugins` directory. Then define your `StoreSearchPlugin` as follows:

lib/droonga/plugins/store-search.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module StoreSearchPlugin
      extend Plugin
      register("store-search")

      class Adapter < Droonga::Adapter
        input_message.pattern = ["type", :equal, "storeSearch"]

        def adapt_input(input_message)
          logger.info("StoreSearchPlugin::Adapter", :message => input_message)

          query = input_message.body["query"]
          logger.info("storeSearch", :query => query)

          body = {
            "queries" => {
              "stores" => {
                "source"    => "Store",
                "condition" => {
                  "query"   => query,
                  "matchTo" => "_key",
                },
                "output"    => {
                  "elements"   => [
                    "startTime",
                    "elapsedTime",
                    "count",
                    "attributes",
                    "records",
                  ],
                  "attributes" => [
                    "_key",
                  ],
                  "limit"      => -1,
                }
              }
            }
          }

          input_message.type = "search"
          input_message.body = body
        end
      end
    end
  end
end
~~~

(Note: `input_message.pattern` is for Droonga 1.0.0 and later. On Droonga 0.9.9, you have to use a deprecated configuration `message.input_pattern` instead.)

Then update catalog.json to activate the plugin. Remove the `sample-logger` plugin previously created.

catalog.json:

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["store-search", "groonga", "crud", "search"],
(snip)
~~~

Remember, you must place your plugin `"store-search"` before the `"search"` because yours depends on it.

Restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

Now you can use this new command by the following request:

store-search-columbus.json:

~~~json
{
  "dataset" : "Starbucks",
  "type"    : "storeSearch",
  "body"    : {
    "query" : "Columbus"
  }
}
~~~

In order to issue this request, you need to run:

~~~
# droonga-request --tag starbucks store-search-columbus.json
Elapsed time: 0.01494
[
  "droonga.message",
  1392621168,
  {
    "inReplyTo": "1392621168.0119512",
    "statusCode": 200,
    "type": "storeSearch.result",
    "body": {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

And you will see the result on fluentd's log in `fluentd.log`:

~~~
2014-02-17 16:12:48 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::InputMessage:0x007fe4791d3958 @raw_message={"dataset"=>"Starbucks", "type"=>"storeSearch", "body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"127.0.0.1:49934/droonga"}, "id"=>"1392621168.0119512", "date"=>"2014-02-17 16:12:48 +0900", "appliedAdapters"=>[]}>
2014-02-17 16:12:48 +0900 [info]: storeSearch query="Columbus"
~~~

Now we can perform store search with simple requests.

Note: look at the `"type"` of the response message. Now it became `"storeSearch.result"`, from `"search.result"`. Because it is triggered from the incoming message with the type `"storeSearch"`, the outgoing message has the type `"(incoming command).result"` automatically. In other words, you don't have to change the type of the outgoing messages, like `input_message.type = "search"` in the method `adapt_input`.

### Return simple response

Second, let's return results in more simple way: just an array of the names of stores.

Define the `adapt_output` method as follows.

lib/droonga/plugins/store-search.rb:

~~~ruby
(snip)
    module StoreSearchPlugin
      extend Plugin
      register("store-search")

      class Adapter < Droonga::Adapter
        (snip)

        def adapt_output(output_message)
          logger.info("StoreSearchPlugin::Adapter", :message => output_message)

          records = output_message.body["stores"]["records"]
          simplified_results = records.flatten

          output_message.body = simplified_results
        end
      end
    end
(snip)
~~~

The `adapt_output` method receives outgoing messages only corresponding to the incoming messages processed by the `adapt_input` method.

Restart fluentd:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

Send the request:

~~~
# droonga-request --tag starbucks store-search-columbus.json
Elapsed time: 0.014859
[
  "droonga.message",
  1392621288,
  {
    "inReplyTo": "1392621288.158763",
    "statusCode": 200,
    "type": "storeSearch.result",
    "body": [
      "Columbus @ 67th - New York NY  (W)",
      "2 Columbus Ave. - New York NY  (W)"
    ]
  }
]
~~~

The log in `fluentd.log` will be like this:

~~~
2014-02-17 16:14:48 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::InputMessage:0x007ffb8ada9d68 @raw_message={"dataset"=>"Starbucks", "type"=>"storeSearch", "body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"127.0.0.1:49960/droonga"}, "id"=>"1392621288.158763", "date"=>"2014-02-17 16:14:48 +0900", "appliedAdapters"=>[]}>
2014-02-17 16:14:48 +0900 [info]: storeSearch query="Columbus"
2014-02-17 16:14:48 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::OutputMessage:0x007ffb8ad78e48 @raw_message={"dataset"=>"Starbucks", "type"=>"dispatcher", "body"=>{"stores"=>{"count"=>2, "records"=>[["Columbus @ 67th - New York NY  (W)"], ["2 Columbus Ave. - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"127.0.0.1:49960/droonga"}, "id"=>"1392621288.158763", "date"=>"2014-02-17 16:14:48 +0900", "appliedAdapters"=>["Droonga::Plugins::StoreSearchPlugin::Adapter", "Droonga::Plugins::Error::Adapter"], "originalTypes"=>["storeSearch"]}>
~~~

Now you've got the simplified response.

In the way just described, we can use adapter to implement the application specific search logic.

## Conclusion

We have learned how to create an addon working around the adaption phase, how to receive and modify messages, both of incoming and outgoing. See also the [reference manual](../../../reference/plugin/adapter/) for more details.


  [basic tutorial]: ../../basic/
  [overview]: ../../../overview/
  [search]: ../../../reference/commands/select/
