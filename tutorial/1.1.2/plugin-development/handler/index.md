---
title: "Plugin: Handle requests on all volumes, to add a new command working around the storage"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

This tutorial aims to help you to learn how to develop plugins which do something dispersively for/in each volume, around the handling phase.
In other words, this tutorial describes *how to add a new simple command to the Droonga Engine*.

## Precondition

* You must complete the [tutorial for the adaption phase][adapter].

## Handling of requests

When a request is transferred from the adaption phase, the Droonga Engine enters into the *processing phase*.

In the processing phase, the Droonga Engine processes the request step by step.
One *step* is constructed from some sub phases: *planning phase*, *distribution phase*, *handling phase*, and *collection phase*.

 * At the *planning phase*, the Droonga Engine generates multiple sub steps to process the request.
   In simple cases, you don't have to write codes for this phase, then there is just one sub step to handle the request.
 * At the *distribution phase*, the Droonga Engine distributes task messages for the request, to multiple volumes.
   (It is completely done by the Droonga Engine itself, so this phase is not pluggable.)
 * At the *handling phase*, *each single volume simply processes only one distributed task message as its input, and returns a result.*
   This is the time that actual storage accesses happen.
   Actually, some commands (`search`, `add`, `create_table` and so on) access to the storage at the time.
 * At the *collection phase*, the Droonga Engine collects results from volumes to one unified result.
   There are some useful generic collectors, so you don't have to write codes for this phase in most cases.

After all steps are finished, the Droonga Engine transfers the result to the post adaption phase.

A class to define operations at the handling phase is called *handler*.
Put simply, adding of a new handler means adding a new command.






## Design a read-only command `countRecords`

Here, in this tutorial, we are going to add a new custom `countRecords` command.
At first, let's design it.

The command reports the number of records about a specified table, for each single volume.
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

The response must have number of records in the table, for each single volume.
They can be appear in an array, like:

~~~json
{
  "inReplyTo": "(message id)",
  "statusCode": 200,
  "type": "countRecords.result",
  "body": [10, 10]
}
~~~

If there are 2 volumes and 20 records are stored evenly, the array will have two elements like above.
It means that a volume has 10 records and another one also has 10 records.

We're going to create a plugin to accept such requests and return such responses.


### Directory structure

The directory structure for plugins are in same rule as explained in the [tutorial for the adaption phase][adapter].
Now let's create the `count-records` plugin, as the file `count-records.rb`. The directory tree will be:

~~~
lib
└── droonga
    └── plugins
            └── count-records.rb
~~~

Then, create a skeleton of a plugin as follows:

lib/droonga/plugins/count-records.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module CountRecordsPlugin
      extend Plugin
      register("count-records")
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
      extend Plugin
      register("count-records")

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
      extend Plugin
      register("count-records")

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

Currently the handler does nothing and returns an result including an array of a number.
The returned value is used to construct the response body.

The handler is bound to the step with the configuration `step.handler`.
Because we define the class `Handler` after `define_single_step`, we specify the handler class with a symbol `:Handler`.
If you define the handler class before `define_single_step`, then you can write as `step.handler = Handler` simply.
Moreover, a class path string like `"OtherPlugin::Handler"` is also available.

Then, we also have to bind a collector to the step, with the configuration `step.collector`.

lib/droonga/plugins/count-records.rb:

~~~ruby
# (snip)
      define_single_step do |step|
        step.name = "countRecords"
        step.handler = :Handler
        step.collector = Collectors::Sum
      end
# (snip)
~~~

The `Collectors::Sum` is one of built-in collectors.
It merges results returned from handler instances for each volume to one result.


### Activate the plugin with `catalog.json`

Update catalog.json to activate this plugin.
Add `"count-records"` to `"plugins"`.

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["count-records", "groonga", "crud", "search", "dump", "status"],
(snip)
~~~

### Run and test

Let's get Droonga started.
Note that you need to specify ./lib directory in RUBYLIB environment variable in order to make ruby possible to find your plugin.

    # kill $(cat fluentd.pid)
    # RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid

Then, send a request message for the `countRecords` command to the Droonga Engine.

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
    "body": [
      0,
      0,
      0
    ]
  }
]
~~~

You'll get a response message like above.
Look at these points:

 * The `type` of the response becomes `countRecords.result`.
   It is automatically named by the Droonga Engine.
 * The format of the `body` is same to the returned value of the handler's `handle` method.

There are three elements in the array. Why?

 * Remember that the `Starbucks` dataset was configured with two replicas and three sub volumes for each replica, in the `catalog.json` of [the basic tutorial][basic].
 * Because it is a read-only command, a request is delivered to only one replica (and it is chosen at random).
   Then only three single volumes receive the command, so only three results appear, not six.
   (TODO: I have to add a figure to indicate active nodes: [000, 001, 002, 010, 011, 012] => [000, 001, 002])
 * The `Collectors::Sum` collects them.
   Those three results are joined to just one array by the collector.

As the result, just one array with three elements appears in the final response.

### Read-only access to the storage

Now, each instance of the handler class always returns `0` as its result.
Let's implement codes to count up the number of records from the actual storage.

lib/droonga/plugins/count-records.rb:

~~~ruby
# (snip)
      class Handler < Droonga::Handler
        def handle(message)
          request = message.request
          table_name = request["table"]
          table = @context[table_name]
          count = table.size
          [count]
        end
      end
# (snip)
~~~

Look at the argument of the `handle` method.
It is different from the one an adapter receives.
A handler receives a message meaning a distributed task.
So you have to extract the request message from the distributed task by the code `request = message.request`.

The instance variable `@context` is an instance of `Groonga::Context` for the storage of the corresponding single volume.
See the [class reference of Rroonga][Groonga::Context].
You can use any feature of Rroonga via `@context`.
For now, we simply access to the table itself by its name and read the value of its `size` method - it returns the number of records.

Then, test it.
Restart the Droonga Engine and send the request again.

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
# droonga-request --tag starbucks count-records.json
Elapsed time: 0.01494
[
  "droonga.message",
  1392621168,
  {
    "inReplyTo": "1392621168.0119512",
    "statusCode": 200,
    "type": "countRecords.result",
    "body": [
      14,
      15,
      11
    ]
  }
]
~~~

Because there are totally 40 records, they are stored evenly like above.

## Design a read-write command `deleteStores`

Next, let's add another new custom command `deleteStores`.

The command deletes records of the `Store` table, from the storage.
Because it modifies something in existing storage, it is a *read-write command*.

The request must have the condition to select records to be deleted, like:

~~~json
{
  "dataset" : "Starbucks",
  "type"    : "deleteStores",
  "body"    : {
    "keyword": "Broadway"
  }
}
~~~

Any record including the given keyword `"Broadway"` in its `"key"` is deleted from the storage of all volumes.

Create a JSON file `delete-stores-broadway.json` with the content above.
We'll use it for testing.

The response must have a boolean value to indicate "success" or "fail", like:

~~~json
{
  "inReplyTo": "(message id)",
  "statusCode": 200,
  "type": "deleteStores.result",
  "body": true
}
~~~

If the request is successfully processed, the `body` becomes `true`. Otherwise `false`.
The `body` is just one boolean value, because we don't have to receive multiple results from volumes.


### Directory Structure

Now let's create the `delete-stores` plugin, as the file `delete-stores.rb`. The directory tree will be:

~~~
lib
└── droonga
    └── plugins
            └── delete-stores.rb
~~~

Then, create a skeleton of a plugin as follows:

lib/droonga/plugins/delete-stores.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module DeleteStoresPlugin
      extend Plugin
      register("delete-stores")
    end
  end
end
~~~


### Define a "step" for the command

Define a "step" for the new `deleteStores` command, in your plugin. Like:

lib/droonga/plugins/delete-stores.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module DeleteStoresPlugin
      extend Plugin
      register("delete-stores")

      define_single_step do |step|
        step.name = "deleteStores"
        step.write = true
      end
    end
  end
end
~~~

Look at a new configuration `step.write`.
Because this command modifies the storage, we must indicate it clearly.

### Define the handling logic

Let's define the handler.

lib/droonga/plugins/delete-stores.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module DeleteStoresPlugin
      extend Plugin
      register("delete-stores")

      define_single_step do |step|
        step.name = "deleteStores"
        step.write = true
        step.handler = :Handler
        step.collector = Collectors::And
      end

      class Handler < Droonga::Handler
        def handle(message)
          request = message.request
          keyword = request["keyword"]
          table = @context["Store"]
          table.delete do |record|
            record.key =~ keyword
          end
          true
        end
      end
    end
  end
end
~~~

Remember, you have to extract the request message from the received task message.

The handler finds and deletes existing records which have the given keyword in its "key", by the [API of Rroonga][Groonga::Table_delete].

And, the `Collectors::And` is bound to the step by the configuration `step.collector`.
It is is also one of built-in collectors, and merges boolean values returned from handler instances for each volume, to one boolean value.

### Activate the plugin with `catalog.json`

Update catalog.json to activate this plugin.
Add `"delete-stores"` to `"plugins"`.

~~~
(snip)
      "datasets": {
        "Starbucks": {
          (snip)
          "plugins": ["delete-stores", "count-records", "groonga", "crud", "search", "dump", "status"],
(snip)
~~~

### Run and test

Restart the Droonga Engine and send the request.

~~~
# kill $(cat fluentd.pid)
# RUBYLIB=./lib fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
# droonga-request --tag starbucks count-records.json
Elapsed time: 0.01494
[
  "droonga.message",
  1392621168,
  {
    "inReplyTo": "1392621168.0119512",
    "statusCode": 200,
    "type": "deleteStores.result",
    "body": true
  }
]
~~~

Because results from volumes are unified to just one boolean value, the response's `body` is a `true`.
As the verification, send the request of `countRecords` command.

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
    "body": [
      7,
      13,
      6
    ]
  }
]
~~~

Note, the number of records are smaller than the previous result.
This means that four or some records are deleted from each volume.

## Conclusion

We have learned how to add a new simple command working around the data.
In the process, we also have learned how to create plugins working in the handling phrase.


  [adapter]: ../adapter
  [basic]: ../basic
  [Groonga::Context]: http://ranguba.org/rroonga/en/Groonga/Context.html
  [Groonga::Table_delete]: http://ranguba.org/rroonga/en/Groonga/Table.html#delete-instance_method
