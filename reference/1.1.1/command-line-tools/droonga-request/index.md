---
title: droonga-request
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-request` sends any message to a Droonga cluster and reports the response.

For example, if there is a Droonga node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to send a [`system.status`](../../commands/system/status/) command is:

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

## Usage {#usage}

### How to give message for this command?

This command accepts messages to be sent via standard input or a file.
As above, `echo`, `cat`, or any other command can be the source for this command.
For example, you'll be able to use [`drndump`](../drndump/)'s output as the source:

~~~
(on 192.168.100.10)
$ drndump --host 192.168.100.50 --receiver-host 192.168.100.10 | \
    droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 \
    > /dev/null
~~~

Another case, you can use a text file as the source.
This command reads the file specified as an command line argument, like:

~~~
(on 192.168.100.10)
$ cat /tmp/message
{"type":"system.status"}
$ droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 /tmp/message
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

This command can send multiple messages at once.
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
$ cat /tmp/messages
{"type":"system.status"}
{"type":"system.statistics.object.count",
 "body":{"output":["total"]}}
$ droonga-request --host 192.168.100.60 --receiver-host 192.168.100.10 /tmp/messages
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




## Parameters {#parameters}

(TBD)


## How to install {#install}

This is installed as a part of a rubygems package `droonga-client`.

~~~
# gem install droonga-client
~~~

