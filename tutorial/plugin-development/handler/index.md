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

When an incoming message is transferred from the adaption phase, the Droonga Engine plans how distribute it to multiple partitions.
Then *each partition simply processes only one distributed message as its input, and returns a result.*
After that, the Droonga Engine collects results from partitions and transfer the unified result to the post adaption phase.

That operation in each partition is called *handling phase*.
A class to define operations at the phase is called *handler*.
Adding of a new handler means adding a new command.

The handling phase is the time that actual storage accesses happen.
Actually, handlers for some commands (`search`, `add`, `create_table` and so on) access to the storage at the time.


## Read-only handler

Here, in this tutorial, we are going to add a new handler for our custom `countRecords` command.
The command reports the number of records about a specified table, for each partition.
So this command helps you to know how records are distributed in the cluster.

The command doesn't change the storage, so it is *read-only* handler.

### Directory Structure

The directory structure for plugins are in same rule as explained in the [tutorial for the adaption phase][adapter].
Now let's create the `count-records` plugin, as the file `count-records.rb`. The directory tree will be:

~~~
lib
└── droonga
    └── plugins
            └── count-records.rb
~~~

### Create a plugin

Create a plugin as follows:

lib/droonga/plugins/count-records.rb:

~~~ruby
require "droonga/plugin"

module Droonga
  module Plugins
    module CountRecordsPlugin
      Plugin.registry.register("count-records", self)

      class Handler < Droonga::Handler
        # Declare that this handles incoming messages with the type "countRecords".
        message.type = "countRecords"

        def handle(message, messenger)
          # The returned value of this method will become the body of the response.
          { "count": [0] }
        end
      end
    end
  end
end
~~~

### Activate the plugin with `catalog.json`

Update catalog.json to activate this plugin. Add `"count-records"` to `"plugins"`.

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
First, create a JSON file for the message as `count-records.json`, like:

count-records.json:

~~~json
{
  "dataset" : "Starbucks",
  "type"    : "countRecords",
  "body"    : {}
}
~~~

The message body is blank for now.
OK, let's send it.

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


### Design input and output

(TBD)


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
