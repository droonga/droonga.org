---
title: "Plugin: Handle requests"
layout: en
---

{% comment %}
##############################################
  THIS FILE IS AUTOMATICALLY GENERATED FROM
  "_po/ja/tutorial/plugin-development/handler/index.po"
  DO NOT EDIT THIS FILE MANUALLY!
##############################################
{% endcomment %}


!!! WORK IN PROGRESS !!!

* TOC
{:toc}

## チュートリアルのゴール

This tutorial aims to help you to learn how to develop plugins
which extends operations in handle phrase.

## 前提条件

* You must complete [Modify requests and responses tutorial][adapter].

## Handling phase

The handling phase is the phase that the actual storage access is happen.
As Droonga is a distributed system, handler phase is done in multiple partitions.

Here, in this tutorial, we are going to replace the handling phase of `search` command for explanation. This breaks the `search` command. So this is not useful in practice, but it will help you to learn how Droonga works.

In practice, we need to *extend* Droonga. In this case, we need to add a new command which does not conflict with the existing commands. To do so, you need to learn not only how to handle messages but also how to distribute messages to handlers and collect messages from them. Proceed to [Distribute requests and collect responses][] after this tutorial completed.

TODO fix the link to "Distribute requests and collect responses" tutorial

## Directory Structure

The directory structure for plugins are in same rule as explained in [Modify requests and responses tutorial][adapter].

Now let's create `sample-logger` plugin again. This will act almost same as [Modify requests and responses tutorial][adapter] version, except the phase in which the plugin works. We need to put `sample-logger.rb` to `lib/droonga/plugins/sample-logger.rb`. The directory tree will be like this:

~~~
lib
└── droonga
    └── plugins
            └── sample-logger.rb
~~~

## Create a plugin

Create a plugin as follows:

lib/droonga/plugins/sample-logger.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module SampleLoggerPlugin
      Plugin.registry.register("sample-logger", self)

      class Handler < Droonga::Handler
        message.type = "search"

        def handle(message, messenger)
          $log.info "Droonga::Plugins::SampleLoggerPlugin", :message => message
        end
      end
    end
  end
end
~~~

## Activate the plugin with `catalog.json`

Update catalog.json to activate this plugin. Add `"sample-logger"` to `"plugins"`.

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["sample-logger", "groonga", "crud", "search"],
(snip)
~~~

## Run

Let's get Droonga started. Note that you need to specify ./lib directory in RUBYLIB environment variable in order to make ruby possible to find your plugin.

    # kill $(cat fluentd.pid)
    # RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid

## Test

Send a search request to Droonga Engine. Use `search-columbus.json` same as of [Modify requests and responses tutorial][adapter].

~~~
# droonga-request --tag starbucks search-columbus.json
~~~

You will see no output for `droonga-request` execution because out `sample-logger` plugin traps the `add` request.

Instead, you will see something like these lines in `fluentd.log`:

~~~
2014-02-17 16:25:23 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007f9a7f0987a8 @raw={"dataset"=>"Starbucks", "type"=>"search", "body"=>{"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.011", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:50410/droonga"}, "id"=>"1392621923.903868", "date"=>"2014-02-17 16:25:23 +0900", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.011", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.011", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}>
2014-02-17 16:25:23 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007f9a7f060970 @raw={"dataset"=>"Starbucks", "type"=>"search", "body"=>{"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.020", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:50410/droonga"}, "id"=>"1392621923.903868", "date"=>"2014-02-17 16:25:23 +0900", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.020", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.020", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}>
2014-02-17 16:25:23 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007f9a7f069c50 @raw={"dataset"=>"Starbucks", "type"=>"search", "body"=>{"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"127.0.0.1:50410/droonga"}, "id"=>"1392621923.903868", "date"=>"2014-02-17 16:25:23 +0900", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "stores"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"stores"=>{"source"=>"Store", "condition"=>{"query"=>"Columbus", "matchTo"=>"_key"}, "output"=>{"elements"=>["startTime", "elapsedTime", "count", "attributes", "records"], "attributes"=>["_key"], "limit"=>-1}}}}, "type"=>"broadcast", "outputs"=>["errors", "stores"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.001", "localhost:24224/starbucks.011", "localhost:24224/starbucks.020"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "stores"=>["localhost:24224/starbucks.#0"]}}>
~~~

Note that three lines are shown for only one request. What is happening?

Remember that we have configured `Starbucks` dataset to use three partitions (and each has two replicas) in `catalog.json` of [the basic tutorial][basic].

The `search` request is dispatched to three partitions and passed into handling phase for each partition. That is because we saw three lines for one request.

The messages shown is in internal format, which is transformed from the request you've sent.
You can see your search request is distributed to partitions `localhost:24224/starbucks.001`, `localhost:24224/starbucks.011` and `localhost:24224/starbucks.020` from `"routes"`.

In `search` case, it is enough to use one replica per one partition because replicas for a partition are expected to have the exactly same contents.
So the planner ordered distributor to choose one replica randomly.

## Trap "add" command

We have seen how distributed search is done from the view point of handling phase so far.
How about `"add"` command?

Update `smaple-logger` plugin to trap `"add"` message instead of `"search"`.

lib/droonga/plugins/sample-logger.rb:

~~~
require "droonga/plugin"

module Droonga
  module Plugins
    module SampleLoggerPlugin
      Plugin.registry.register("sample-logger", self)

      class Handler < Droonga::Handler
        message.type = "add" # This was "search" in the previous version.

        def handle(message, messenger)
          $log.info "Droonga::Plugins::SampleLoggerPlugin", :message => message
        end
      end
    end
  end
end
~~~

Restart `fluentd`:

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
~~~

Let's send a request to Droonga Engine.
Here, we use the first line of `stores.json`.

add-store.json:

~~~
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1st Avenue & 75th St. - New York NY  (W)","values":{"location":"40.770262,-73.954798"}}}
~~~

Send it to the engine:

~~~
# droonga-request --tag starbucks add-store.json
~~~

You will see no output for `droonga-request` execution because out `sample-logger` plugin traps the `add` request.

Instead, you will see results like this in `fluentd.log`:

~~~
2014-02-17 16:29:18 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007f7f6a66c4c0 @raw={"dataset"=>"Starbucks", "type"=>"add", "body"=>{"id"=>"localhost:24224/starbucks.#2", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"add.result", "to"=>"127.0.0.1:50480/droonga"}, "id"=>"1392622158.374441", "date"=>"2014-02-17 16:29:18 +0900", "appliedAdapters"=>["Droonga::Plugins::CRUD::Adapter", "Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#2", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}>
2014-02-17 16:29:18 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007f7f6a65ff40 @raw={"dataset"=>"Starbucks", "type"=>"add", "body"=>{"id"=>"localhost:24224/starbucks.#2", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"add.result", "to"=>"127.0.0.1:50480/droonga"}, "id"=>"1392622158.374441", "date"=>"2014-02-17 16:29:18 +0900", "appliedAdapters"=>["Droonga::Plugins::CRUD::Adapter", "Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#2", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"add", "dataset"=>"Starbucks", "body"=>{"table"=>"Store", "key"=>"1st Avenue & 75th St. - New York NY  (W)", "values"=>{"location"=>"40.770262,-73.954798"}}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#2"], "success"=>["localhost:24224/starbucks.#2"]}}>
~~~

In `add` case, two log lines are shown for one request. This is because we have configured to have two replicas for each partition.

In order to be consistent, `add` command must reach all of the replicas of the partition, but not the other partitions.
As a consequence, `localhost:24224/starbucks.000` and `localhost:24224/starbucks.001` are chosen.


## まとめ

We have learned how to create plugins work in handling phrase.


  [adapter]: ../adapter
  [basic]: ../basic