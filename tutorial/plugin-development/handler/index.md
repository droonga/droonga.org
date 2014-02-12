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

~~~
lib
└── droonga
    └── plugins
            └── sample-logger.rb
~~~

## Create a plugin

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

## Run


~~~
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5e17bb38 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.010", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5a2044f0 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.000", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
2014-02-12 12:09:09 +0900 [info]: Droonga::Plugins::SampleLoggerPlugin message=#<Droonga::HandlerMessage:0x007fee5e173ca8 @raw={"body"=>{"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, "replyTo"=>{"type"=>"search.result", "to"=>"localhost:24224/output"}, "type"=>"search", "dataset"=>"Starbucks", "id"=>"search", "appliedAdapters"=>["Droonga::Plugins::Error::Adapter"]}, @body={"id"=>"localhost:24224/starbucks.#1", "task"=>{"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, "descendants"=>{"errors"=>["localhost:24224/starbucks"], "result"=>["localhost:24224/starbucks"]}}, @task={"route"=>"localhost:24224/starbucks.021", "step"=>{"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}, "n_of_inputs"=>0, "values"=>{}}, @step={"command"=>"search", "dataset"=>"Starbucks", "body"=>{"queries"=>{"result"=>{"output"=>{"limit"=>-1, "attributes"=>["_key"], "elements"=>["startTime", "elapsedTime", "count", "attributes", "records"]}, "condition"=>{"matchTo"=>"_key", "query"=>"Columbus"}, "source"=>"Store"}}}, "type"=>"broadcast", "outputs"=>["errors", "result"], "replica"=>"random", "routes"=>["localhost:24224/starbucks.000", "localhost:24224/starbucks.010", "localhost:24224/starbucks.021"], "n_of_expects"=>0, "descendants"=>{"errors"=>["localhost:24224/starbucks.#1"], "result"=>["localhost:24224/starbucks.#1"]}}>
~~~

  [adapter]: ../adapter
