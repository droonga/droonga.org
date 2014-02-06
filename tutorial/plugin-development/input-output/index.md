---
title: "Plugin: Modify requests and responses"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to develop a Droonga plugin by yourself.
This page focus on InputAdapter first, then OutputAdapter.

## Precondition

* You must complete [tutorial][].


## InputAdapter

We sometime need to modify requests incoming to Droonga Engine.
We can use InputAdapter for this purpose.
Let's see how to create InputAdapter in this section.

### Directory Structure

Assume that we are going to add `InputAdapterPlugin` to the system built in [tutorial][].
In that tutorial, Groonga engine was placed under `engine` directory.

Plugins need to be placed in an appropriate directory. For example, `InputAdapterPlugin` should be placed under `lib/droonga/plugin/input_adapter/` directory. Let's create the directory:

    # cd engine
    # mkdir -p lib/droonga/plugin/input_adapter

After creating the directory, the directory structure should be like this:

~~~
engine
├── catalog.json
├── fluentd.conf
└── lib
    └── droonga
        └── plugin
            └── input_adapter
~~~


### Create a plugin

Put a plugin code into `input_adapter` directory.

lib/droonga/plugin/input_adapter/example.rb:

~~~ruby
module Droonga
  class ExampleInputAdapterPlugin < Droonga::InputAdapterPlugin
    repository.register("example", self)
  end
end
~~~

This plugin does nothing except registering itself to Droonga.

### Activate plugin with `catalog.json`

You need to update `catalog.json` to activate your plugin.
Insert following at the last part of `catalog.json` in order to make `"input_adapter"` become a key of the top level hash:

catalog.json:

~~~
(snip)
  },
  "input_adapter": {
    "plugins": ["example", "groonga"]
  },
  "output_adapter": {
    "plugins": ["crud", "groonga"]
  },
  "collector": {
    "plugins": ["basic", "search"]
  },
  "distributor": {
    "plugins": ["search", "crud", "groonga", "watch"]
  }
}
~~~

TODO: the [tutorial][] needs to be updated. After tutorial update, explanation above should also be updated.

### Run

Let's Droonga get started. Note that you need to specify `./lib` directory in `RUBYLIB` environment variable in order to make ruby possible to find your plugin.

~~~
RUBYLIB=./lib fluentd --config fluentd.conf
~~~

### Test

In the previous [tutorial][], we have communicated with `fluent-plugin-droonga` via the protocol adapter built with `expres-droonga`.
For plugin development, sending requests directly to `fluent-plugin-droonga` can be more handy way to debug. We use `fluent-cat` command for this purpose.

Doing in this way also help us to understand internal structure of Droonga.

In the [tutorial][], we have used `fluent-cat` to setup database schema and import data. Do you remember? Sending search request can be done in the similar way.

First, create a request as a JSON.

search-columbus.json:

~~~json
{
  "id": "search:0",
  "dataset": "Starbucks",
  "type": "search",
  "replyTo":"localhost:24224/output",
  "body": {
    "queries": {
      "result": {
        "source": "Store",
        "condition": {
          "query": "Columbus",
          "matchTo": "_key"
        },
        "output": {
          "elements": [
            "startTime",
            "elapsedTime",
            "count",
            "attributes",
            "records"
          ],
          "attributes": ["_key"],
          "limit": -1
        }
      }
    }
  }
}
~~~

This is corresponding to the example to search "Columbus" in the [tutorial][]. Note that the request in `express-droonga` is encapsulated in `"body"` element.

`fluent-cat` expects one line per one JSON object. So we need to use `tr` command to remove line breaks before passing the JSON to `fluent-cat`:

    cat search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

This will output something like below to fluentd's log:

    2014-02-03 14:22:54 +0900 output.message: {"inReplyTo":"search:0","statusCode":200,"type":"search.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}

This is the search result.

If you have [jq][] installed, you can use `jq` instead of `tr`:

    jq -c . search-columbus.json | fluent-cat starbucks.message

### Do something in the plugin: take logs

The plugin we have created do nothing so far. Let's get the plugin to do some interesting.

First of all, trap `search` request and log it. Update the plugin like below:

lib/droonga/plugin/input_adapter/example.rb:

~~~ruby
module Droonga
  class ExampleInputAdapterPlugin < Droonga::InputAdapterPlugin
    repository.register("example", self)

    command "search" => :adapt_request
    def adapt_request(input_message)
      $log.info "ExampleInputAdapterPlugin", :message => input_message
    end
  end
end
~~~

And restart fluentd, then send the request same as the previous. You will see something like below fluentd's log:

~~~
2014-02-03 16:56:27 +0900 [info]: ExampleInputAdapterPlugin message=#<Droonga::InputMessage:0x007ff36a38cb28 @raw_message={"body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-03 16:56:27 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

This shows the message is received by our `ExampleInputAdapterPlugin` and then passed to Droonga. Here we can modify the message before the actual data processing.

### Modify messages with InputAdapter

Suppose that we want to restrict the number of records returned in the response, say `1`. What we need to do is set `limit` to be `1` for every request. Update plugin like below:

lib/droonga/plugin/input_adapter/example.rb:

~~~ruby
module Droonga
  class ExampleInputAdapterPlugin < Droonga::InputAdapterPlugin
    repository.register("example", self)

    command "search" => :adapt_request
    def adapt_request(input_message)
      $log.info "ExampleInputAdapterPlugin", message: input_message
      input_message.body["queries"]["result"]["output"]["limit"] = 1
    end
  end
end
~~~

And restart fluentd. After restart, the response always includes only one record in `records` section:

~~~
2014-02-03 18:47:54 +0900 [info]: ExampleInputAdapterPlugin message=#<Droonga::InputMessage:0x007f913ca6e918 @raw_message={"body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-03 18:47:54 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"]]}}}
~~~

Note that `count` is still `2` because `limit` does not affect `count`. See [search][] for details of `search` command.



## OutputAdapter

In case we need to modify the output, we can define `OutputAdapter`.
In this section, we are going to create an `OutputAdapter`.

### Directory structure

`OutputAdapterPlugin` should be placed in directory `lib/droonga/plugin/output_adapter/` directory.

~~~
engine
├── catalog.json
├── fluentd.conf
└── lib
    └── droonga
        └── plugin
            └── output_adapter
~~~


### Create a plugin

Put a plugin code into `output_adapter` directory.

lib/droonga/plugin/output_adapter/example.rb:

~~~ruby
module Droonga
  class ExampleOutputAdapterPlugin < Droonga::OutputAdapterPlugin
    repository.register("example", self)
  end
end
~~~

This plugin does nothing except registering itself to Droonga.

### Activate plugin with `catalog.json`

You need to update `catalog.json` to activate your plugin.
Insert following at the last part of `catalog.json` in order to make `"output_adapter"` become a key of the top level hash:

Remove previously created `"example"` adapter from `"input_adapter"` for simplicity.

catalog.json:

~~~
(snip)
  },
  "input_adapter": {
    "plugins": ["groonga"]
  },
  "output_adapter": {
    "plugins": ["example", "crud", "groonga"]
  },
  "collector": {
    "plugins": ["basic", "search"]
  },
  "distributor": {
    "plugins": ["search", "crud", "groonga", "watch"]
  }
}
~~~

### Run

Let's get fluentd started:

~~~
RUBYLIB=./lib fluentd --config fluentd.conf
~~~

This OutputAdapterPlugin does not make any differences so far.

### Log messages incoming to OutputAdapter

Let's get the plugin to work.
Take logs of results of `search` command.

Update `ExampleOutputAdapterPlugin` as follows:

~~~ruby
module Droonga
  class ExampleOutputAdapterPlugin < Droonga::OutputAdapterPlugin
    repository.register("example", self)

    command "search" => :adapt_result,
            :patterns => [["replyTo.type", :equal, "search.result"]]
    def adapt_result(output_message)
      $log.info "ExampleOutputAdapterPlugin", :message => output_message
    end
  end
end
~~~

Then restart fluentd, and send search request (Use the same JSON for request as in the previous section):

    cat search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

The fluentd's log should be like as follows:

~~~
2014-02-05 17:37:37 +0900 [info]: ExampleOutputAdapter message=#<Droonga::OutputMessage:0x007f8da265b698 @raw_message={"body"=>{"result"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-05 17:37:37 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

This shows that the result of `search` is passed to `ExampleOutputAdapter` (and logged), then outputted.


### Modify results with OutputAdapter

Let's modify the result.
For example, add `completedAt` attribute that shows the time completed the request.
Update your plugin as follows:

~~~ruby
module Droonga
  class ExampleOutputAdapter < Droonga::OutputAdapterPlugin
    repository.register("example", self)

    command "search" => :adapt_result,
            :patterns => [["replyTo.type", :equal, "search.result"]]
    def adapt_result(output_message)
      $log.info "ExampleOutputAdapter", :message => output_message
      output_message.body["result"]["completedAt"] = Time.now
    end
  end
end
~~~

Then restart fluentd and send the same search request.
The results will be like this:

~~~
2014-02-05 17:41:02 +0900 [info]: ExampleOutputAdapter message=#<Droonga::OutputMessage:0x007fb3c5291fc8 @raw_message={"body"=>{"result"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search"}>
2014-02-05 17:41:02 +0900 output.message: {"inReplyTo":"search","statusCode":200,"type":"search.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]],"completedAt":"2014-02-05T08:41:02.824361Z"}}}
~~~

Now you can see `completedAt` attribute containing the time completed the request.

## Combination of InputAdapter and OutputAdapter

We have learned the basics of Adapter so far.
Let's try to build more practical plugin.

You may feel the Droonga's `search` command is too flexible for your purpose. Here, we're going to add our own `storeSearch` command to wrap the `search` command in order to provide an application-specific and simple interface.

### Accept simple requests

First, create `StoreSearchAdapterInputPlugin`.

Create your `StoreSearchAdapterPlugin` as follows:

lib/droonga/plugin/input_adapter/store_search.rb:

~~~ruby
module Droonga
  class StoreSearchInputAdapterPlugin < Droonga::InputAdapterPlugin
    repository.register("store_search", self)

    command "storeSearch" => :adapt_request
    def adapt_request(input_message)
      $log.info "StoreSearchInputAdapterPlugin", :message => input_message

      query = input_message.body["query"]
      $log.info "storeSearch", :query => query

      body = {
        "queries" => {
          "result" => {
            "source" => "Store",
            "condition" => {
              "query" => query,
              "matchTo" => "_key"
            },
            "output" => {
              "elements" => [
                "startTime",
                "elapsedTime",
                "count",
                "attributes",
                "records"
              ],
              "attributes" => [
                "_key"
              ],
              "limit" => -1
            }
          }
        }
      }

      input_message.command = "search"
      input_message.body = body
    end
  end
end
~~~

The update catalog.json to activate the plugin. Remove the example plugin previously created.

catalog.json:

~~~
(snip)
  },
  "input_adapter": {
    "plugins": ["store_search"]
  },
  "output_adapter": {
    "plugins": ["crud", "groonga"]
  },
  "collector": {
    "plugins": ["basic", "search"]
  },
  "distributor": {
    "plugins": ["search", "crud", "groonga", "watch"]
  }
}
~~~


Now you can use this by the following request:

store-search-columbus.json:

~~~json
{
  "id": "storeSearch:0",
  "dataset": "Starbucks",
  "type": "storeSearch",
  "replyTo":"localhost:24224/output",
  "body": {
    "query": "Columbus"
  }
}
~~~

In order to issue this request, you need to run:

    cat store-search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

And you will see the result on fluentd's log:

~~~
2014-02-06 15:20:07 +0900 [info]: StoreSearchInputAdapterPlugin message=#<Droonga::InputMessage:0x007fe36e9ef0f8 @raw_message={"body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"storeSearch", "dataset"=>"Starbucks", "id"=>"storeSearch:0"}>
2014-02-06 15:20:07 +0900 [info]: storeSearch query="Columbus"
2014-02-06 15:20:07 +0900 output.message: {"inReplyTo":"storeSearch:0","statusCode":200,"type":"storeSearch.result","body":{"result":{"count":2,"records":[["2 Columbus Ave. - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"]]}}}
~~~

Now we can perform store search with simple requests.

### Return simple response

Second, let's return results in more simple way: just an array of the names of stores.

Define `StoreSearchOutputAdapter` as follows.

lib/droonga/plugin/output_adapter/store_search.rb:

~~~ruby
module Droonga
  class StoreSearchOutputAdapter < Droonga::OutputAdapterPlugin
    repository.register("store_search", self)

    command "search" => :adapt_result,
            :patterns => [["originalTypes", :include?, "storeSearch"]]

    def adapt_result(output_message)
      $log.info "StoreSearchOutputAdapter", :message => output_message

      records = output_message.body["result"]["records"]
      simplified_results = records.flatten

      output_message.body = simplified_results
    end
  end
end
~~~

Activate OutputAdapter with catalog.json:

~~~
(snip)
  },
  "input_adapter": {
    "plugins": ["store_search"]
  },
  "output_adapter": {
    "plugins": ["store_search", "crud", "groonga"]
  },
  "collector": {
    "plugins": ["basic", "search"]
  },
  "distributor": {
    "plugins": ["search", "crud", "groonga", "watch"]
  }
}
~~~

Then restart fluentd. Send the request:

    cat store-search-columbus.json | tr -d "\n" | fluent-cat starbucks.message

The log will be like this:

~~~
2014-02-06 16:04:45 +0900 [info]: StoreSearchInputAdapterPlugin message=#<Droonga::InputMessage:0x007f99eb602a20 @raw_message={"body"=>{"query"=>"Columbus"}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"storeSearch", "dataset"=>"Starbucks", "id"=>"storeSearch:0"}>
2014-02-06 16:04:45 +0900 [info]: storeSearch query="Columbus"
2014-02-06 16:04:45 +0900 [info]: StoreSearchOutputAdapter message=#<Droonga::OutputMessage:0x007f99eb5d16a0 @raw_message={"body"=>{"result"=>{"count"=>2, "records"=>[["2 Columbus Ave. - New York NY  (W)"], ["Columbus @ 67th - New York NY  (W)"]]}}, "replyTo"=>{"type"=>"storeSearch.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"storeSearch:0", "originalTypes"=>["storeSearch"]}>
2014-02-06 16:04:45 +0900 output.message: {"inReplyTo":"storeSearch:0","statusCode":200,"type":"storeSearch.result","body":["2 Columbus Ave. - New York NY  (W)","Columbus @ 67th - New York NY  (W)"]}
~~~

Now you've got the simplified response.

In the way just described, we can use adapter to implement the application specific search logic.

## Conclusion

We have learned how to create InputAdapter and OutputAdapter, how to receive and modify messages in the adapters, both of InputAdapter and OutputAdapter.


  [tutorial]: ../../
  [overview]: ../../../overview/
  [jq]: http://stedolan.github.io/jq/
  [search]: ../../../reference/commands/select/
