---
title: "Plugin: Modify requests and responses"
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

First, let's study basics with a simple logger plugin named `sample-logger` affects on the adaption phase.

We sometime need to modify incoming requests from outside to Droonga Engine.
We can use a plugin for this purpose.
Let's see how to create a plugin for the adaption phase, in this section.

### Directory Structure

Assume that we are going to add a new plugin to the system built in the [basic tutorial][].
In that tutorial, Groonga engine was placed under `engine` directory.

Plugins need to be placed in an appropriate directory. Let's create the directory:

    # cd engine
    # mkdir -p lib/droonga/plugin

After creating the directory, the directory structure should be like this:

~~~
engine
├── catalog.json
├── fluentd.conf
└── lib
    └── droonga
        └── plugin
~~~


### Create a plugin

Put a plugin code into a file `sample_logger.rb` in the `plugin` directory.

lib/droonga/plugin/sample_logger.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module SampleLoggerPlugin
      Plugin.registry.register("sample-logger", self)

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


### Activate the plugin with `catalog.json`

You need to update `catalog.json` to activate your plugin.
Add the name of the plugin `"sample-logger"` to the `"plugins"` list under the dataset, like:

catalog.json:

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["crud", "search", "groonga", "sample-logger"],
(snip)
~~~

### Run

Let's Droonga get started.
Note that you need to specify `./lib` directory in `RUBYLIB` environment variable in order to make ruby possible to find your plugin.

~~~
RUBYLIB=./lib fluentd --config fluentd.conf
~~~

### Test

In the [basic tutorial][], we have communicated with the Droonga Engine based on `fluent-plugin-droonga`, via the Protocol Adapter built with `expres-droonga`. For plugin development, sending requests directly to the Droonga Engine can be more handy way to debug.
We use `fluent-cat` command for this purpose.

Doing in this way also help us to understand internal structure of Droonga.

In the [basic tutorial][], we have used `fluent-cat` to setup database schema and import data. Do you remember? Sending search request can be done in the similar way.

First, create a request as a JSON.

search-columbus.json:

~~~json
{
  "id"      : "search:0",
  "dataset" : "Starbucks",
  "type"    : "search",
  "replyTo" : "localhost:24224/output",
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

`fluent-cat` expects one line per one JSON object. So we need to use `tr` command to remove line breaks before passing the JSON to `fluent-cat`:

    cat search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

This will output something like below to fluentd's log:

    2014-02-03 14:22:54 +0900 output.message: {"inReplyTo":"search:0","statusCode":200,"type":"search.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}

This is the search result.

If you have [jq][] installed, you can use `jq` instead of `tr`:

    jq -c . search-columbus.json | fluent-cat starbucks.message

### Do something in the plugin: take logs

The plugin we have created do nothing so far. Let's get the plugin to do some interesting.

First of all, trap `search` request and log it. Update the plugin like below:

lib/droonga/plugin/sample_logger.rb:

~~~ruby
(snip)
    module SampleLoggerPlugin
      Plugin.registry.register("sample-logger", self)

      class Adapter < Droonga::Adapter
        message.input_pattern = ["type", :equal, "search"]

        def adapt_input(input_message)
          $log.info("SampleLoggerPlugin::Adapter", :message => input_message)
        end
      end
    end
(snip)
~~~

And restart fluentd, then send the request same as the previous. You will see something like below fluentd's log:

~~~
2014-02-03 16:56:27 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::InputMessage:0x007ff36a38cb28 @raw_message={"body"=>{"queries"=>{"stores"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-03 16:56:27 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

This shows the message is received by our `SampleLoggerPlugin::Adapter` and then passed to Droonga. Here we can modify the message before the actual data processing.

### Modify messages with the plugin

Suppose that we want to restrict the number of records returned in the response, say `1`. What we need to do is set `limit` to be `1` for every request. Update plugin like below:

lib/droonga/plugin/sample_logger.rb:

~~~ruby
(snip)
        def adapt_input(input_message)
          $log.info("SampleLoggerPlugin::Adapter", :message => input_message)
          input_message.body["queries"]["stores"]["output"]["limit"] = 1
        end
(snip)
~~~

And restart fluentd. After restart, the response always includes only one record in `records` section:

~~~
2014-02-03 18:47:54 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::InputMessage:0x007f913ca6e918 @raw_message={"body"=>{"queries"=>{"stores"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-03 18:47:54 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"]]}}}
~~~

Note that `count` is still `2` because `limit` does not affect to `count`. See [search][] for details of the `search` command.



## Adaption for outgoing messages

In case we need to modify outgoing messages from Droonga Engine, for example, search results, then we can do it simply by another method.
In this section, we are going to define a method to adapt outgoing messages.


### Add a method to adapt outgoing messages

Let's take logs of results of `search` command.
Define the `adapt_output` method to process outgoing messages, like below:

lib/droonga/plugin/sample_logger.rb:

~~~ruby
(snip)
    module SampleLoggerPlugin
      Plugin.registry.register("sample-logger", self)

      class Adapter < Droonga::Adapter
        (snip)

        def adapt_output(output_message)
          $log.info("SampleLoggerPlugin::Adapter", :message => output_message)
        end
      end
    end
(snip)
~~~

### Run

Let's restart fluentd:

~~~
RUBYLIB=./lib fluentd --config fluentd.conf
~~~

And send search request (Use the same JSON for request as in the previous section):

    cat search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

The fluentd's log should be like as follows:

~~~
2014-02-05 17:37:37 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::OutputMessage:0x007f8da265b698 @raw_message={"body"=>{"stores"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-05 17:37:37 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

This shows that the result of `search` is passed to the `adapt_output` method (and logged), then outputted.


### Modify results in the adaption phase

Let's modify the result.
For example, add `completedAt` attribute that shows the time completed the request.
Update your plugin as follows:

lib/droonga/plugin/sample_logger.rb:

~~~ruby
(snip)
        def adapt_output(output_message)
          $log.info("SampleLoggerPlugin::Adapter", :message => output_message)
          output_message.body["stores"]["completedAt"] = Time.now
        end
(snip)
~~~

Then restart fluentd and send the same search request.
The results will be like this:

~~~
2014-02-05 17:41:02 +0900 [info]: SampleLoggerPlugin::Adapter message=#<Droonga::OutputMessage:0x007fb3c5291fc8 @raw_message={"body"=>{"stores"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-05 17:41:02 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]],"completedAt":"2014-02-05T08:41:02.824361Z"}}}
~~~

Now you can see `completedAt` attribute containing the time completed the request.

## Translation for both incoming and outgoing messages

We have learned the basics of plugins for the adaption phase so far.
Let's try to build more practical plugin.

You may feel the Droonga's `search` command is too flexible for your purpose.
Here, we're going to add our own `storeSearch` command to wrap the `search` command in order to provide an application-specific and simple interface, with a new plugin named `store-search`.

### Accept simple requests

First, create `StoreSearchPlugin`. Create your `StoreSearchPlugin` as follows:

lib/droonga/plugin/store_search.rb:

~~~ruby
module Droonga
  module Plugins
    module StoreSearchPlugin
      Plugin.registry.register("store-search", self)

      class Adapter < Droonga::Adapter
        message.input_pattern = ["type", :equal, "storeSearch"]

        def adapt_input(input_message)
          $log.info("StoreSearchPlugin::Adapter", :message => input_message)

          query = input_message.body["query"]
          $log.info("storeSearch", :query => query)

          body = {
            "queries" => {
              "stores" => {
                "source"    => "Store",
                "condition" => {
                  "query"   => query,
                  "matchTo" => "_key"
                },
                "output"    => {
                  "elements"   => [
                    "startTime",
                    "elapsedTime",
                    "count",
                    "attributes",
                    "records"
                  ],
                  "attributes" => [
                    "_key"
                  ],
                  "limit"      => -1
                }
              }
            }
          }

          input_message.command = "search"
          input_message.body    = body
        end
      end
    end
  en
end
~~~

Then update catalog.json to activate the plugin. Remove the `sample-logger` plugin previously created.

catalog.json:

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["crud", "search", "groonga", "store-search"],
(snip)
~~~

Now you can use this new command by the following request:

store-search-columbus.json:

~~~json
{
  "id"      : "storeSearch:0",
  "dataset" : "Starbucks",
  "type"    : "storeSearch",
  "replyTo" : "localhost:24224/output",
  "body"    : {
    "query" : "Columbus"
  }
}
~~~

In order to issue this request, you need to run:

    cat store-search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

And you will see the result on fluentd's log:

~~~
2014-02-06 15:20:07 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::InputMessage:0x007fe36e9ef0f8 @raw_message={"body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"storeSearch", "dataset"=>"Starbucks", "id"=>"storeSearch:0"}>
2014-02-06 15:20:07 +0900 [info]: storeSearch query="Columbus"
2014-02-06 15:20:07 +0900 output.message: {"inReplyTo":"storeSearch:0","statusCode":200,"type":"storeSearch.result","body":{"stores":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

Now we can perform store search with simple requests.

Note: look at the `"type"` of the response message. Now it became `"storeSearch.result"`, from `"search.result"`. Because it is triggered from the incoming message with the type `"storeSearch"`, the outgoing message has the type `"(incoming command).result"` automatically. In other words, you don't have to change the type of the outgoing messages, like `input_message.command = "search"` in the method `adapt_input`.

### Return simple response

Second, let's return results in more simple way: just an array of the names of stores.

Define the `adapt_output` method as follows.

lib/droonga/plugin/store_search.rb:

~~~ruby
module Droonga
  module Plugins
    module StoreSearchPlugin
      Plugin.registry.register("store-search", self)

      class Adapter < Droonga::Adapter
        (snip)

        def adapt_output(output_message)
          $log.info("StoreSearchPlugin::Adapter", :message => output_message)

          records = output_message.body["stores"]["records"]
          simplified_results = records.flatten

          output_message.body = simplified_results
        end
      end
    end
(snip)
~~~

The `adapt_output` method receives outgoing messages only corresponding to the incoming messages processed by the `adapt_input` method.

Then restart fluentd. Send the request:

    cat store-search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

The log will be like this:

~~~
2014-02-06 16:04:45 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::InputMessage:0x007f99eb602a20 @raw_message={"body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"storeSearch", "dataset"=>"Starbucks", "id"=>"storeSearch:0"}>
2014-02-06 16:04:45 +0900 [info]: storeSearch query="Columbus"
2014-02-06 16:04:45 +0900 [info]: StoreSearchPlugin::Adapter message=#<Droonga::OutputMessage:0x007f99eb5d16a0 @raw_message={"body"=>{"stores"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"storeSearch:0", "originalTypes"=>["storeSearch"]}>
2014-02-06 16:04:45 +0900 output.message: {"inReplyTo":"storeSearch:0","statusCode":200,"type":"storeSearch.result","body":["2 Columbus Ave. - New York NY  (W)","Columbus @ 67th - New York NY  (W)"]}
~~~

Now you've got the simplified response.

In the way just described, we can use adapter to implement the application specific search logic.

## Conclusion

We have learned how to create an addon working around the adaption phase, how to receive and modify messages, both of incoming and outgoing.


  [basic tutorial]: ../../basic/
  [overview]: ../../../overview/
  [jq]: http://stedolan.github.io/jq/
  [search]: ../../../reference/commands/select/
