---
title: droonga-send
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-send` sends any message to a Droonga cluster, without waiting of responses.

This command supports both Droonga native protocol and HTTP.
For Droonga Engine nodes you can send a Droonga native message directly.
And, for HTTP protocol adapter nodes you can send HTTP requests also.

When you hope to get responses for requests, see also [descriptions of the `droonga-request` command](../droonga-request/).

## Usage {#usage}

### Basic usage

For example, if there is a Droonga Engine node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to send an [`add`](../../commands/add/) command is:

~~~
(on 192.168.100.10)
$ echo '{"type":"add","body":{"key":"id1","values":{"name":"Adam","age":20}}}' |
    droonga-send --server droonga:192.168.100.50:10031/droonga
~~~

This command ordinarily reports nothing.
If you have to see requests are correctly processed or aren't, use [the `droonga-request` command](../droonga-request/) instead.

As described at the [message format reference](../../message/), `id`, `date`, and `dataset` are required fields of request messages.
If the given message doesn't have them, this command guesses or generates applicable values automatically by default.
You can see the completed message actually sent with the option `--report-request`, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"add","body":{"key":"id1","values":{"name":"Adam","age":20}}}' |
    droonga-send --server droonga:192.168.100.50:10031/droonga --report-request
Request: {
  "type": "add",
  "body": {
    "key": "id1",
    "values": {
      "name": "Adam",
      "age": 20
    }
  },
  "id": "1430990130.1114423",
  "date": "2015-05-07T09:15:30.111467Z",
  "dataset": "Default"
}
~~~

For the complete list of available commands, see also [the command reference](../../commands/).

### Combination with other commands

This command accepts messages to be sent via standard input.
As above, `echo`, `cat`, or any other command can be the source for this command.
For example, you'll be able to use [`drndump`](../drndump/)'s output as the source:

~~~
(on 192.168.100.10)
$ drndump --host 192.168.100.50 --receiver-host 192.168.100.10 | \
    droonga-send --server droonga:192.168.100.50:10031/droonga
~~~

### Input from file

You can use a text file as the source.
This command reads the file specified as an command line argument, like:

~~~
(on 192.168.100.10)
$ cat /tmp/message.json
{"type":"system.status"}
$ droonga-send --server droonga:192.168.100.50:10031/droonga /tmp/message.json
~~~

### Sending multiple messages at once

This command can send multiple messages at once.
To do it, you simply give multiple messages as the input, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"add","body":{"key":"id1","values":{"name":"Adam","age":20}}} {"type":"add","body":{"key":"id2","values":{"name":"Becky","age":30}}}' |
    droonga-send --server droonga:192.168.100.50:10031/droonga
~~~

Of course, you can include multiple messages to the source file like:

~~~
(on 192.168.100.10)
$ cat /tmp/messages.jsons
{"type":"add","body":{"key":"id1","values":{"name":"Adam","age":20}}}
{"type":"add","body":{"key":"id2","values":{"name":"Becky","age":30}}}
$ droonga-send --server droonga:192.168.100.50:10031/droonga /tmp/messages.jsons
~~~

To simulate a round-robbin type load balancer for too much messages, you can specify multiple `--server` options for multiple endpoints, like:

~~~
(on 192.168.100.10)
$ droonga-send --server droonga:192.168.100.50:10031/droonga \
               --server droonga:192.168.100.51:10031/droonga \
               --server droonga:192.168.100.52:10031/droonga \
               /tmp/messages.jsons
~~~

Then messages are scattered to all endpoints parallelly.

You can simulate overloaded too much requests with `--messages-per-second` option, like:

~~~
(on 192.168.100.10)
$ droonga-send --server droonga:192.168.100.50:10031/droonga \
               --server droonga:192.168.100.51:10031/droonga \
               --server droonga:192.168.100.52:10031/droonga \
               --messages-per-second=1000 \
               /tmp/messages.jsons
~~~

It is `100` by default but you can enlarge the limitation, if your computer is powerful enough to do it.
The limitation is applied for each endpoint, so your clsuter will receive 3000 or less messages per second, with the example above.


### Communication with the Droonga cluster in HTTP

This command can communicate not only with Droonga Engine nodes but with HTTP protocol adapters, like:

~~~
(on 192.168.100.10)
$ echo '{"type":"add","body":{"key":"id1","values":{"name":"Adam","age":20}}}' |
    droonga-send --server http:192.168.100.50:10041 --report-request
Request: {
  "method": "GET",
  "path": "/droonga/add?key=id1&values[name]=Adam&values[age]=20",
  "headers": {
    "Accept": "*/*",
    "User-Agent": "Ruby"
  },
  "body": null
}
~~~

For HTTP protocol adapters, there are some differences:

 * You have to specify `http:` protocol and correct port number of the HTTP protocol adapter via the `--server` option's value.
   The port number is `10031` by default for Droonga Engine nodes, but HTTP protocol adapters ordinarily listen with the port `10041`.

In this case you can use HTTP specific request message as the input.
Regular Droonga native protocol messages are automatically converted to HTTP request messages like above.

You can use such custom HTTP request messages as the input.
This is an example to send HTTP POST request with a custom user agent string:

~~~
(on 192.168.100.10)
$ echo '{"method":"POST","headers":{"User-Agent":"Droonga Client"},"path":"/droonga/add","body":{"key":"id1","values":{"name":"Adam","age":20}}}' |
    droonga-send --server http:192.168.100.50:10041 --report-request
Request: {
  "method": "POST",
  "path": "/droonga/add",
  "headers": {
    "User-Agent": "Droonga Client",
    "Accept": "*/*"
  },
  "body": "{\"key\":\"id1\",\"values\":{\"name\":\"Adam\",\"age\":20}}"
}
~~~


## Parameters {#parameters}


`--server=PROTOCOL:HOST:PORT/TAG`
: Protocol, host name, port number, and tag name to communicate with the endpoint of the Droonga cluster.
  You can specify this option multiple times.
  There is only one definition `(default protocol given via --default-protocol option):(a guessed host name of the computer you are running the command):(default port number given via --default-port option)/(default tag name given via --default-tag option)`, by default.

`--messages-per-second=N`
: Maximum number of messages to be sent in a second.
  `-1` means "no limit".
  `100` by default.

`--default-protocol=PROTOCOL`
: Default protocol to communicate with the endpoint of the Droonga cluster.
  Possible values:
  
  * `droonga` (default): the native protocol of Droonga Engine nodes.
  * `http`: for HTTP protocol adapters.

`--default-port=PORT`
: Default protocol number to communicate with the endpoint of the Droonga cluster.
  `10031` by default.

`--default-tag=TAG`
: Default tag name to communicate with the endpoint of the Droonga cluster.
  `droonga` by default.

`--[no-]report-request`
: Reports request messages actually sent or don't.
  `--no-report-request` is given by default.
  To report actually sent messages, you have to specify the option `--report-request` manually.

`--[no-]report-throughput`
: Reports throughput by messages per second or don't.
  `--no-report-throughput` is given by default.
  To report throughput, you have to specify the option `--report-throughput` manually.

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

