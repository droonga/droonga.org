---
title: column_remove
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `column_remove` command removes an existing column in a table.

This is compatible to [the `column_remove` command of the Groonga](http://groonga.org/docs/reference/commands/column_remove.html).

Style
: Request-Response. One response message is always returned per one request.

`type` of the request
: `column_remove`

`body` of the request
: A hash of parameters.

`type` of the response
: `column_remove.result`

## Parameter syntax {#syntax}

    {
      "table" : "<Name of the table>",
      "name"  : "<Name of the column>"
    }

## Parameter details {#parameters}

All parameters are required.

They are compatible to [the parameters of the `column_remove` command of the Groonga](http://groonga.org/docs/reference/commands/column_remove.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <Column is successfully removed or not>
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

Column is successfully removed or not
: A boolean value meaning the column was successfully removed or not. Possible values are:
  
   * `true`：The column was successfully removed.
   * `false`：The column was not removed.
