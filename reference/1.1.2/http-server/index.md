---
title: HTTP Server
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The [Droonga HTTP Server][droonga-http-server] is as an HTTP protocol adapter for the Droonga Engine.

The Droonga Engine supports only the fluentd protocol, so you have to use `fluent-cat` or something, to communicate with the Drooga Engine.
This application provides ability to communicate with the Droonga Engine via HTTP.

## Install {#install}

It is released as the [droonga-http-server npm module][], a [Node.js][] module package.
You can install it via the `npm` command, like:

    # npm install -g droonga-http-server

## Usage {#usage}

### Command line options {#usage-command}

It includes a command `droonga-http-server` to start an HTTP server.
You can start it with command line options, like:

    # droonga-http-server --port 3003

Available options and their default values are:

`--port <13000>`
: The port number which the server receives HTTP requests at.

`--receive-host-name <127.0.0.1>`
: The host name (or the IP address) of the computer itself which the server is running.
  It is used by the Droonga Engine, to send response messages to the protocol adapter.

`--droonga-engine-host-name <127.0.0.1>`
: The host name (or the IP address) of the computer which the Droonga Engine is running on.

`--droonga-engine-port <24224>`
: The port number which the Droonga Engine receives messages at.

`--default-dataset <Droonga>`
: The name of the default dataset.
  It is used for requests triggered via built-in HTTP APIs.

`--tag <droonga>`
: The tag used for fluentd messages sent to the Droonga Engine.

`--enable-logging`
: If you specify this option, log messages are printed to the standard output.

`--cache-size <100>`
: The maximum size of the LRU response cache.
  Droonga HTTP server caches all responses for GET requests on the RAM, unthil this size.

You have to specify appropriate values for your Droonga Engine. For example, if the HTTP server is running on the host 192.168.10.90 and the Droonga engine is running on the host 192.168.10.100 with following configurations:

fluentd.conf:

    <source>
      type forward
      port 24324
    </source>
    <match books.message>
      name localhost:24224/books
      type droonga
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "version": 2,
      "effectiveDate": "2013-09-01T00:00:00Z",
      "datasets": {
        "Books": {
          ...
        }
      }
    }

Then, you'll start the HTTP server on the host 192.168.10.90, with options like:

    # droonga-http-server --receive-host-name 192.168.10.90 \
                          --droonga-engine-host-name 192.168.10.100 \
                          --droonga-engine-port 24324 \
                          --default-dataset Books \
                          --tag books

See also the [basic tutorial][].

## Built-in APIs {#usage-api}

The Droonga HTTP Server includes following APIs:

### REST API {#usage-rest}

#### `GET /tables/<table name>` {#usage-rest-get-tables-table}

This emits a simple [search request](../commands/search/).
The [`source`](../commands/search/#query-source) is filled by the table name in the path.
Available query parameters are:

`attributes`
: Corresponds to [`output.attributes`](../commands/search/#query-output).
  The value is a comma-separated list, like: `attributes=_key,name,age`.

`query`
: Corresponds to [`condition.*.query`](../commands/search/#query-condition-query-syntax-hash).
  The vlaue is a query string.

`match_to`
: Corresponds to [`condition.*.matchTo`](../commands/search/#query-condition-query-syntax-hash).
  The vlaue is an comma-separated list, like: `match_to=_key,name`.

`match_escalation_threshold`
: Corresponds to [`condition.*.matchEscalationThreshold`](../commands/search/#query-condition-query-syntax-hash).
  The vlaue is an integer.

`script`
: Corresponds to [`condition`](../commands/search/#query-condition-query-syntax-hash) in the script syntax.
  If you specity both `query` and `script`, then they work with an `and` logical condition.

`adjusters`
: Corresponds to `adjusters`.

`sort_by`
: Corresponds to [`sortBy`](../commands/search/#query-sortBy).
  The value is a column name string.

`limit`
: Corresponds to [`output.limit`](../commands/search/#query-output).
  The value is an integer.

`offset`
: Corresponds to [`output.offset`](../commands/search/#query-output).
  The value is an integer.

### Groonga HTTP server compatible API {#usage-groonga}

#### `GET /d/<command name>` {#usage-groonga-d}

(TBD)


  [basic tutorial]: ../../tutorial/basic/
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
  [droonga-http-server npm module]: https://npmjs.org/package/droonga-http-server
  [Node.js]: http://nodejs.org/
