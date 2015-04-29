---
title: delete
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `delete` command removes records in a table.

This is compatible to [the `delete` command of the Groonga](http://groonga.org/docs/reference/commands/delete.html).

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/d/delete`

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
: `delete`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `delete.result`

## Parameter syntax {#syntax}

    {
      "table" : "<Name of the table>",
      "key"   : "<Key of the record>"
    }

or

    {
      "table" : "<Name of the table>",
      "id"    : "<ID of the record>"
    }

or

    {
      "table"  : "<Name of the table>",
      "filter" : "<Complex search conditions>"
    }

## Parameter details {#parameters}

All parameters except `table` are optional.
However, you must specify one of `key`, `id`, or `filter` to specify the record (records) to be removed.

They are compatible to [the parameters of the `delete` command of the Groonga](http://groonga.org/docs/reference/commands/delete.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <Records are successfully removed or not>
    ]

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

Records are successfully removed or not
: A boolean value meaning specified records were successfully removed or not. Possible values are:
  
   * `true`：Records were successfully removed.
   * `false`：Records were not removed.
