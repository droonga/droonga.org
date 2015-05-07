---
title: droonga-request
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-request` sends any message to a Droonga cluster, and reports the response.

This command supports both Droonga native protocol and HTTP.
For Droonga Engine nodes you can send a Droonga native message directly.
And, for HTTP protocol adapter nodes you can send HTTP requests also.

When you hope to send too much messages at once, see also [descriptions of the `droonga-send` command](../droonga-send/).

## Usage {#usage}

### Basic usage

For example, if there is a Droonga Engine node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to send a [`system.status`](../../commands/system/status/) command is:

~~~
(on 192.168.100.10)
$ echo '{"type":"system.status"}' |
    droonga-request --host 192.168.100.50 --receiver-host 192.168.100.10
Elapsed time: 0.00900742
{
  "inReplyTo": "1430963525.9829412",
  "statusCode": 200,
  "type": "system.status.result",
  "body": {
    "nodes": {
      "node0:10031/droonga": {
        "status": "active"
      },
      "node1:10031/droonga": {
        "status": "active"
      }
    },
    "reporter": "node0:55329/droonga @ node0:10031/droonga"
  }
}
~~~

The first line is the elapsed time to get the response.
Following lines are the response message.

As described at the [message format reference](../../message/), `id`, `date`, and `dataset` are required fields of request messages.
If the given message doesn't have them, this command guesses or generates applicable values automatically by default.
You can see the completed message actually sent with the option `--report-request`, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"system.status"}' |
    droonga-request --report-request --host 192.168.100.50 --receiver-host 192.168.100.10
Request: {
  "type": "system.status",
  "id": "1430963525.9829412",
  "date": "2015-05-07T02:39:50.334377Z",
  "dataset": "Default"
}
Elapsed time: 0.00900742
...
~~~

For the complete list of available commands, see also [the command reference](../../commands/).

### Combination with other commands

This command accepts messages to be sent via standard input.
As above, `echo`, `cat`, or any other command can be the source for this command.
For example, you'll be able to use [`drndump`](../drndump/)'s output as the source:

~~~
(on 192.168.100.10)
$ drndump --host 192.168.100.50 --receiver-host 192.168.100.10 | \
    droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 \
    > /dev/null
~~~

### Input from file

You can use a text file as the source.
This command reads the file specified as an command line argument, like:

~~~
(on 192.168.100.10)
$ cat /tmp/message.json
{"type":"system.status"}
$ droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 /tmp/message.json
Elapsed time: 0.00900742
{
  "inReplyTo": "1430963525.9829412",
  "statusCode": 200,
  "type": "system.status.result",
  "body": {
    "nodes": {
      "node0:10031/droonga": {
        "status": "active"
      },
      "node1:10031/droonga": {
        "status": "active"
      }
    },
    "reporter": "node0:55329/droonga @ node0:10031/droonga"
  }
}
~~~

### Sending multiple messages at once

This command can send multiple messages sequentially.
To do it, you simply give multiple messages as the input, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"system.status"} {"type":"system.statistics.object.count","body":{"output":["total"]}}' |
    droonga-request --host 192.168.100.50 --receiver-host 192.168.100.10
Elapsed time: 0.007365724
{
  "inReplyTo": "1430964599.844579",
  "statusCode": 200,
  "type": "system.status.result",
  "body": {
    "nodes": {
      "node0:10031/droonga": {
        "status": "active"
      },
      "node1:10031/droonga": {
        "status": "active"
      }
    },
    "reporter": "node0:55329/droonga @ node0:10031/droonga"
  }
}
Elapsed time: 0.014172429
{
  "inReplyTo": "1430964599.8521488",
  "statusCode": 200,
  "type": "system.statistics.object.count.result",
  "body": {
    "total": 549
  }
}
~~~

All results with responses are printed to the standard output sequentially like above.

Of course, you can include multiple messages to the source file like:

~~~
(on 192.168.100.10)
$ cat /tmp/messages.jsons
{"type":"system.status"}
{"type":"system.statistics.object.count",
 "body":{"output":["total"]}}
$ droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 /tmp/messages.jsons
Elapsed time: 0.007365724
{
  "inReplyTo": "1430964599.844579",
  "statusCode": 200,
  "type": "system.status.result",
  "body": {
    "nodes": {
      "node0:10031/droonga": {
        "status": "active"
      },
      "node1:10031/droonga": {
        "status": "active"
      }
    },
    "reporter": "node0:55329/droonga @ node0:10031/droonga"
  }
}
Elapsed time: 0.014172429
{
  "inReplyTo": "1430964599.8521488",
  "statusCode": 200,
  "type": "system.statistics.object.count.result",
  "body": {
    "total": 549
  }
}
~~~

Because each request is sent after the response for the previous request is got, it takes too much time to send very large number of messages.
So there is an alternative: [the `droonga-send` command](../droonga-send/).


### Communication with the Droonga cluster in HTTP

This command can communicate not only with Droonga Engine nodes but with HTTP protocol adapters, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"system.statistics.object.count","body":{"output":["total"]}}' |
    droonga-request --report-request --protocol http --host 192.168.100.50 --port 10041
Request: {
  "method": "GET",
  "path": "/droonga/system/statistics/object/count?output[]=total",
  "headers": {
    "Accept": "*/*",
    "User-Agent": "Ruby"
  },
  "body": null
}
Elapsed time: 0.026170325
{
  "total": 549
}
~~~

For HTTP protocol adapters, there are some differences:

 * You have to give a new option `--protocol http` (`--protocol=http`).
 * You have to specify correct port number of the HTTP protocol adapter via the `--port` option.
   (It is `10031` by default for Droonga Engine nodes, but HTTP protocol adapters ordinarily listen with the port `10041`.)
 * The option `--receiver-host` is never been used.

In this case you can use HTTP specific request message as the input.
Regular Droonga native protocol messages are automatically converted to HTTP request messages like above.

You can use such custom HTTP request messages as the input.
This is an example to send HTTP POST request with a custom user agent string:

~~~
(on 192.168.100.10)
$ echo '{"method":"POST","path": "/droonga/system/statistics/object/count","headers":{"User-Agent":"Droonga Client"},"body":{"output":["total"]}}' |
    droonga-request --report-request --protocol http --host 192.168.100.50 --port 10041
Request: {
  "method": "POST",
  "path": "/droonga/system/statistics/object/count",
  "headers": {
    "User-Agent": "Droonga Client",
    "Accept": "*/*"
  },
  "body": "{\"output\":[\"total\"]}"
}
Elapsed time: 0.026170325
{
  "total": 549
}
~~~


## Parameters {#parameters}


`--host=NAME`
: Host name of the endpoint of the Droonga cluster.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with the endpoint of the Droonga cluster.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with the endpoint of the Droonga cluster.
  `droonga` by default.

`--protocol=PROTOCOL`
: Protocol to communicate with the endpoint of the Droonga cluster.
  Possible values:
  
  * `droonga` (default): the native protocol of Droonga Engine nodes.
  * `http`: for HTTP protocol adapters.

`--timeout=SECONDS`
: Time to terminate unresponsive connections, in seconds.
  `1` by default.

`--[no-]exit-on-response`
: Exits when just one response is received or don't.
  `--exit-on-response` is given by default.
  For any subscription type command (it returns multiple response messages for a request message with delay), you have to keep connected for a while with the option `--no-exit-on-response`.
  Then the connection is kept until disconnected from the Droonga Engine node.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--[no-]report-request`
: Reports request messages actually sent or don't.
  `--no-report-request` is given by default.
  To report actually sent messages, you have to specify the option `--report-request` manually.

`--[no-]report-elapsed-time`
: Reports elapsed time between a request and a response or don't.
  `--report-elapsed-time` is given by default.
  To remove the `Elapsed time:` line from the output, you have to specify the option `--no-report-elapsed-time` manually.

`--default-dataset=NAME`
: Default dataset name for sending messages.
  `Default` by default.

`--default-target-role=ROLE`
: Default role of engine nodes which should process messages.
  Possible values:
  
  * `service-provider`:
    The message is processed by service provider nodes in the cluster.
    For absorb-source nodes and absrob-destination nodes, the message will be dispatched later.
  * `absorb-source`:
    The message is processed by absorb-source nodes in the cluster.
    For service provider nodes and absrob-destination nodes, the message is never dispatched.
  * `absorb-destination`:
    The message is processed by absorb-destination nodes in the cluster.
    For service provider nodes and absrob-source nodes, the message is never dispatched.
  * `any`:
    The message is always processed by the node specified via the option `--host`.
  
  `any` by default.

`--[no-]completion`
: Do completion of required fields for input messages or not.
  `--completion` is given by default.
  To send broken message (missing any required field) intentionally, you have to specify the option `--no-completion` manually.

`--[no-]validation`
: Do validation for input messages or not.
  `--validation` is given by default.
  To send invalid message intentionally, you have to specify the option `--no-validation` manually.

`--help`
: Shows the usage of the command.



## How to install {#install}

This is installed as a part of a rubygems package `droonga-client`.

~~~
# gem install droonga-client
~~~

