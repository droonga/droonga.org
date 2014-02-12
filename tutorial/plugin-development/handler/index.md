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

* You must complete [Modify requests and responses][adapter] tutorial.


## Directory Structure

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
