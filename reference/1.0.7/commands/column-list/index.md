---
title: column_list
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `column_list` command reports the list of all existing columns in a table.

This is compatible to [the `column_list` command of the Groonga](http://groonga.org/docs/reference/commands/column_list.html).

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/d/column_list`

Request methd
: `GET`

Request URL parameters
: Same to the list of [parameters](#parameters).

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
: `column_list`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `column_list.result`

## Parameter syntax {#syntax}

    {
      "table" : "<Name of the table>"
    }

## Parameter details {#parameters}

The only one parameter `table` is required.

They are compatible to [the parameters of the `column_list` command of the Groonga](http://groonga.org/docs/reference/commands/column_list.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <List of columns>
    ]

The structure of the returned array is compatible to [the returned value of the Groonga's `table_list` command](http://groonga.org/docs/reference/commands/column_list.html#return-value). See the linked document for more details.

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

