---
title: table_list
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `table_list` command reports the list of all existing tables in the dataset.

This is compatible to [the `table_list` command of the Groonga](http://groonga.org/docs/reference/commands/table_list.html).

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/d/table_list`

Request methd
: `GET`

Request URL parameters
: Nothing.

Request body
: Nothing.

Response body
: A [response message](#response).

### REST {#api-types-rest}

Not supported.

### Fluentd {#api-types-fluentd}

Style
: Request-Response. One response message is always returned per one request.

`type` of the request
: `table_list`

`body` of the request
: `null` or a blank hash.

`type` of the response
: `table_list.result`

## Responses {#response}

This returns an array including list of tables as the response's `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <List of tables>
    ]

The structure of the returned array is compatible to [the returned value of the Groonga's `table_list` command](http://groonga.org/docs/reference/commands/table_list.html#id5). See the linked document for more details.

This command always returns a response with `200` as its `statusCode`, because this is a Groonga compatible command and errors of this command must be handled in the way same to Groonga's one.

Response body's details:

Status code
: An integer which means the operation's result. Possible values are:
  
   * `0` (`Droonga::GroongaHandler::Status::SUCCESS`) : Successfully processed.
   * `-22` (`Droonga::GroongaHandler::Status::INVALID_ARGUMENT`) : There is any invalid argument.

Start time
: An UNIX time which the operation was started on.

Elapsed time
: A decimal of seconds meaning the elapsed time for the operation.

