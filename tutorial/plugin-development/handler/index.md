---
title: "Plugin: Handle requests"
layout: en
---

!!! WORK IN PROGRESS !!!

* TOC
{:toc}

## The goal of this tutorial

This tutorial aims to help you to learn how to develop plugins
which extends operations in handle phrase.

## Precondition

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
# cat search-columbus.json | tr -d "\n" | fluent-cat starbucks.message
~~~

You will see something like these lines in `fluentd.log`:

~~~
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5e17bb38 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5a2044f0 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5e173ca8 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
~~~

Note that three lines are shown for only one request. What is happening?

Remember that we have configured `Starbucks` dataset to use three partitions (and each has two replicas) in `catalog.json` of [the basic tutorial][basic].

The `search` request is dispatched to three partitions and passed into handling phase for each partition. That is because we saw three lines for one request.

The messages shown is in internal format, which is transformed from the request you've sent.
You can see your search request is distributed to partitions `localhost:24224/starbucks.000`, `localhost:24224/starbucks.010` and `localhost:24224/starbucks.021` from `"routes"`.

In `search` case, it is enough to use one replica per one partition because replicas for a partition are expected to have the exactly same contents.
So the planner ordered distributor to choose one replica randomly.

## Trap "add" command

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


~~~
{"id":"stores:0","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1st Avenue & 75th St. - New York NY  (W)","values":{"location":"40.770262,-73.954798"}}}
~~~

~~~
2014-02-12 17:02:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fdd224ed700 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, "type"=>"add", "dataset"=>"Starbucks", "replyTo"=>{"type"=>"add.result", "to"=>"localhost:24224/output"}, "id"=>"stores:0", "appliedAdapters"=>["Droonga::Plugins::CRUD::Adapter", "Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.001", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}>
2014-02-12 17:02:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fdd2251f778 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, "type"=>"add", "dataset"=>"Starbucks", "replyTo"=>{"type"=>"add.result", "to"=>"localhost:24224/output"}, "id"=>"stores:0", "appliedAdapters"=>["Droonga::Plugins::CRUD::Adapter", "Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#0", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "success"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"add", "dataset"=>"Starbucks", "body"=>{"values"=>{"location"=>"40.770262,-73.954798"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "table"=>"Store"}, "key"=>"1st Avenue & 75th St. - New York NY  (W)", "type"=>"scatter", "outputs"=>["errors", "success"], "replica"=>"all", "post"=>true, "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.001"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#0"], "success"=>["localhost:24224/starbucks.#0"]}}>
~~~


  [adapter]: ../adapter
  [basic]: ../basic
