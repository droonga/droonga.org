---
title: "Plugin: Handle requests"
layout: en
---

!!! WORK IN PROGRESS !!!

* TOC
{:toc}

## The goal of this tutorial

This tutorial aims to help you to learn how to develop plugins which do something dispersively for/in each partition, around the handling phase.

## Precondition

* You must complete the [tutorial for the adaption phase][adapter].

## Handling of incoming messages

When an incoming message is transferred from the adaption phase, the Droonga Engine enters into the *processing phase*.

In the processing phase, the Droonga Engine processes incoming messages step by step.
One *step* is constructed from some sub phases: *planning phase*, *distribution phase*, *handling phase*, and *collection phase*.

 * At the *planning phase*, the Droonga Engine generates multiple sub steps to process an incoming message.
   In simple cases, you don't have to write codes for this phase, then there is just one sub step to handle the message.
 * At the *distribution phase*, the Droonga Engine distributes the message to multiple partitions.
   (It is completely done by the Droonga Engine itself, so this phase is not pluggable.)
 * At the *handling phase*, *each partition simply processes only one distributed message as its input, and returns a result.*
   This is the time that actual storage accesses happen.
   Actually, some commands (`search`, `add`, `create_table` and so on) access to the storage at the time.
 * At the *collection phase*, the Droonga Engine collects results from partitions to one unified result.
   There are some useful generic collectors, so you don't have to write codes for this phase in most cases.

After all steps are finished, the Droonga Engine transfers the result to the post adaption phase.

A class to define operations at the handling phase is called *handler*.
Put simply, adding of a new handler means adding a new command.


## Design a read-only command

Here, in this tutorial, we are going to add a new custom `countRecords` command.
At first, let's design it.

The command reports the number of records about a specified table, for each partition.
So it will help you to know how records are distributed in the cluster.
Nothing is changed by the command, so it is a *read-only command*.

The request must have the name of one table, like:

~~~json
{
  "dataset" : "Starbucks",
  "type"    : "countRecords",
  "body"    : {
    "table": "Store"
  }
}
~~~

Create a JSON file `count-records.json` with the content above.
We'll use it for testing.

The response must have number of records in the table, for each partition.
They can be appear in an array, like:

~~~json
{
  "inReplyTo": "(message id)",
  "statusCode": 200,
  "type": "countRecords.result",
  "body": [10, 10, 10]
}
~~~

We're going to create a plugin to accept such a request and return a response like above.


### Directory structure

The directory structure for plugins are in same rule as explained in the [tutorial for the adaption phase][adapter].
Now let's create the `count-records` plugin, as the file `count-records.rb`. The directory tree will be:

~~~
lib
└── droonga
    └── plugins
            └── count-records.rb
~~~

Then, create a slekton of a plugin as follows:

lib/droonga/plugins/count-records.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module CountRecordsPlugin
      Plugin.registry.register("count-records", self)
    end
  end
end
~~~

### Define a "step" for the command

Define a "step" for the new `countRecords` command, in your plugin. Like:

lib/droonga/plugins/count-records.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module CountRecordsPlugin
      Plugin.registry.register("count-records", self)

      define_single_step do |step|
        step.name = "countRecords"
      end
    end
  end
end
~~~

The `step.name` equals to the name of the command itself.
Currently we just define the name of the command.
That's all.

### Define the handling logic

The command has no handler, so it does nothing yet.
Let's define the behavior.

lib/droonga/plugins/count-records.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module CountRecordsPlugin
      Plugin.registry.register("count-records", self)

      define_single_step do |step|
        step.name = "countRecords"
        step.handler = :Handler
      end

      class Handler < Droonga::Handler
        def handle(message)
          [0]
        end
      end
    end
  end
end
~~~

The class `Handler` is a handler class for our new command.

 * It must inherit a builtin-class `Droonga::Handler`.
 * It implements the logic to handle requests.
   Its instance method `#handle` actually handles requests.

Currently the handler does nothing and returns an array of a number.
The returned value is used to construct the response body.

The handler is bound to the step with the configuration `step.handler`.
Because we define the class `Handler` after `define_single_step`, we specify the handler class with a symbol `:Handler`.
If you define the handler class before `define_single_step`, then you can write as `step.handler = Handler` simply.
Moreover, a class path string like `"OtherPlugin::Handler"` is also available.

Then, we also have to bind a collector to the step, with the configuration `step.collector`.

lib/droonga/plugins/count-records.rb:

~~~ruby
...
      define_single_step do |step|
        step.name = "countRecords"
        step.handler = :Handler
        step.collector = SumCollector
      end
...
~~~

The `SumCollector` is one of built-in collectors.
It merges results retuned from handler instances for each partition to one result.


### Activate the plugin with `catalog.json`

Update catalog.json to activate this plugin.
Add `"count-records"` to `"plugins"`.

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["count-records", "groonga", "crud", "search"],
(snip)
~~~

### Run

Let's get Droonga started.
Note that you need to specify ./lib directory in RUBYLIB environment variable in order to make ruby possible to find your plugin.

    # kill $(cat fluentd.pid)
    # RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid

### Test

Send a message for the `countRecords` command to the Droonga Engine.

~~~
# droonga-request --tag starbucks count-records.json
Elapsed time: 0.01494
[
  "droonga.message",
  1392621168,
  {
    "inReplyTo": "1392621168.0119512",
    "statusCode": 200,
    "type": "countRecords.result",
    "body": {
      "count": [0, 0, 0]
    }
  }
]
~~~

Then you'll get a response message like above.
Look at these points:

 * The `type` of the response becomes `countRecords.result`. It is automatically named by the Droonga Engine.
 * The format of the `body` is same to the returned value of the handler's `handle` method.

However, there are three elements in the `count` array. Why?

 * Remember that we have configured `Starbucks` dataset to use three partitions (and each has two replicas) in the `catalog.json` of [the basic tutorial][basic].
 * Because it is a read-only handler, the incoming message is distributed only to paritions, not to replicas.
   So there are only three results, not six.
 * The Droonga Engine automatically collects results from parititions.
   Those three results are joined to just one array.

(TODO: I have to add a figure to indicate active nodes: [000, 001, 010, 011, 020, 021] => [000, 011, 020])

As the result, just one array with three elements appears in the response message.



## Read-write handler

(TBD)

### Directory Structure

(TBD)

### Create a plugin

(TBD)

### Activate the plugin with `catalog.json`

(TBD)

### Run

(TBD)

### Test

(TBD)

### Design input and output

(TBD)


## Conclusion

We have learned how to create plugins work in handling phrase.


  [adapter]: ../adapter
  [basic]: ../basic
