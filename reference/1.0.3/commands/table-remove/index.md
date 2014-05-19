---
title: table_remove
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `table_remove` command removes an existing table.

This is compatible to [the `table_remove` command of the Groonga](http://groonga.org/docs/reference/commands/table_remove.html).

Style
: Request-Response. One response message is always returned per one request.

`type` of the request
: `table_remove`

`body` of the request
: A hash of parameters.

`type` of the response
: `table_remove.result`

## Parameter syntax {#syntax}

    {
      "name" : "<Name of the table>"
    }

## Parameter details {#parameters}

The only one parameter `name` is required.

They are compatible to [the parameters of the `table_remove` command of the Groonga](http://groonga.org/docs/reference/commands/table_remove.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <Table is successfully removed or not>
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

Table is successfully removed or not
: A boolean value meaning the table was successfully removed or not. Possible values are:
  
   * `true`：The table was successfully removed.
   * `false`：The table was not removed.
