---
title: droonga-system-status
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-system-status` reports current status of a Droonga cluster.

For example, if there is a Droonga node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to report status of the cluster is:

~~~
(on 192.168.100.10)
$ droonga-system-status --host 192.168.100.50 --receiver-host 192.168.100.10 --pretty
{
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
~~~

This command is just a shorthand of [`droonga-request`](../droonga-request/) with a message with the type [`system.status`](../../commands/system/status/).
The result produced by the following command line completely equals to the one of above:

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

See also [the reference of the `system.status` command](../../commands/system/status/).

## Parameters {#parameters}

`--pretty`
: Output result as a pretty printed JSON.

`--host=NAME`
: Host name of the engine node.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with the engine.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with the engine.
  `droonga` by default.

`--dataset=NAME`
: Dataset name for the sending message.
  `Default` by default.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--target-role=ROLE`
: Role of engine nodes which should process the message.
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

`--timeout=SECONDS`
: Time to terminate unresponsive connections, in seconds.
  `3` by default.

`-h`, `--help`
: Shows the usage of the command.


## How to install {#install}

This is installed as a part of a rubygems package `droonga-client`.

~~~
# gem install droonga-client
~~~

