---
title: droonga-groonga
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-groonga` provides ability to communicate a Droonga cluster like a Groonga server, via the command line interface.

For example, if there is a Droonga Engine node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to list all tables is:

~~~
(on 192.168.100.10)
$ droonga-groonga --host 192.168.100.50 --receiver-host 192.168.100.10 --pretty \
    table_list
[
  [
    0,
    1431000097.1314175,
    0.00024175643920898438
  ],
  [
    [
      [
        "id",
        "UInt32"
      ],
      [
        "name",
        "ShortText"
  ...
  ]
]
~~~

This command is just a shorthand of [`droonga-request`](../droonga-request/) with a message of Groonga compatible commands.
The result produced by the following command line almost equals to the one of above:

~~~
(on 192.168.100.10)
$ echo '{"type":"table_list"}' |
    droonga-request --report-request --host 192.168.100.50 --receiver-host 192.168.100.10
Request: {
  "type": "table_list",
  "id": "1431000097.1242323",
  "date": "2015-05-07T12:01:37.124254Z",
  "dataset": "Default"
}
Elapsed time: 0.011710191
{
  "inReplyTo": "1431000097.1242323",
  "statusCode": 200,
  "type": "table_list.result",
  "body": [
    [
      0,
      1431000097.1314175,
      0.00024175643920898438
    ],
    [
      [
        [
          "id",
          "UInt32"
        ],
        [
          "name",
          "ShortText"
    ...
    ]
  ]
}
~~~

See also [references of Groonga compatible command](../../commands/) and [Groonga's reference manual](http://groonga.org/docs/reference/command.html).

## Compatibility to the `groonga` command {#compatibility}

This command is designed to work like ["client mode" and "standalone mode" of the `groonga` command](http://groonga.org/docs/reference/executables/groonga.html).
All command line arguments given to this command except Droonga specific options will work like command line arguments for the `groonga` command.
For example:

~~~
(on 192.168.100.10)
$ GROONGA="droonga-groonga --host 192.168.100.50 --receiver-host 192.168.100.10 --pretty "
$ $GROONGA table_list
$ $GROONGA column_list --table Store
$ $GROONGA select --table Store --match_columns name --query ave --limit 5 --output_columns _key,name
~~~

However, currently these features of the `groonga` command are not supported yet:

 * Executing multiple commands via the standard input.
 * `load` command with values given as separate lines following to main command line arguments.
 * Features not supported by Droonga itself.


## Parameters {#parameters}

Groonga like command line arguments and following Droonga specific options are available.

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

