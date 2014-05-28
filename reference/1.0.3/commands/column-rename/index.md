---
title: column_rename
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `column_rename` command renames an existing column in a table.

This is compatible to [the `column_rename` command of the Groonga](http://groonga.org/docs/reference/commands/column_rename.html).

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/d/column_rename`

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
: `column_rename`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `column_rename.result`

## Parameter syntax {#syntax}

    {
      "table"    : "<Name of the table>",
      "name"     : "<Current name of the column>",
      "new_name" : "<New name of the column>"
    }

## Parameter details {#parameters}

All parameters are required.

They are compatible to [the parameters of the `column_rename` command of the Groonga](http://groonga.org/docs/reference/commands/column_rename.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <Column is successfully renamed or not>
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

Column is successfully renamed or not
: A boolean value meaning the column was successfully renamed or not. Possible values are:
  
   * `true`：The column was successfully renamed.
   * `false`：The column was not renamed.
