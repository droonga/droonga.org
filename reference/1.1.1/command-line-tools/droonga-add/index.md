---
title: droonga-add
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-add` adds a new record or updates an existing record, to the specified table in a Droonga cluster.

For example, if there is a Droonga node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to add a new record to the table `User` in the cluster is:

~~~
(on 192.168.100.10)
$ droonga-add --host 192.168.100.50 --receiver-host 192.168.100.10 \
    --table User --key id1 --name Adam --age 20
~~~

This command is just a shorthand of [`droonga-request`](../droonga-request/) with a message with the type [`add`](../../commands/add/).
The result produced by the following command line completely equals to the one of above:

~~~
(on 192.168.100.10)
$ echo '{"type":"key","key":"id1","values":{"name":"Adam","age":20}}' |
    droonga-request --host 192.168.100.50 --receiver-host 192.168.100.10
~~~

## Parameters {#parameters}

`--table=TABLE` *(required)*
: Name of the target table.

`--key=KEY`
: A unique key of the adding or updating record.

`--(COLUMN NAME)=(VALUE)`, `--value:(COLUMN NAME)=(VALUE)`
: Value of the column for the record.
  Columns with names same to other existing parameter like `host` must be specified with the prefix `--value:`.

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
: Host name of the computer you are running the command.
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

