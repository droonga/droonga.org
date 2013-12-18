---
title: column_create
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `column_create` command creates a new column into the specified table..

This is compatible to [the `column_create` command of the Groonga](http://groonga.org/docs/reference/commands/column_create.html).

This is a request-response style command. One response message is always returned per one request.

## Syntax {#syntax}

    {
      "table"  : "<Name of the table>",
      "name"   : "<Name of the column>",
      "flags"  : "<Flags for the column>",
      "type"   : "<Type of the value>",
      "source" : "<Name of a column to be indexed>"
    }

## Parameters {#parameters}

All parameters except `table` and `name` are optional.

They are compatible to [the parameters of the `column_create` command of the Groonga](http://groonga.org/docs/reference/commands/column_create.html#parameters). See the linked document of the Groonga for details.

## Resposnes {#response}

This returns an array meaning the result of the operation.

    [
      [
        <Status code>,
        <Start time>,
        <Elapsed time>
      ],
      <Column is successfully created or not>
    ]

Details:

Status code
: An integer meaning the operation's result. Possible values are:
  
   * `0` (`Droonga::GroongaHandler::Status::SUCCESS`) : Successfully processed.
   * `-22` (`Droonga::GroongaHandler::Status::INVALID_ARGUMENT`) : There is any invalid argument.

Start time
: An UNIX time which the operation was started on.

Elapsed time
: A decimal of seconds meaning the elapsed time for the operation.

Column is successfully created or not
: A boolean value meaning the column was successfully created or not. Possible values are:
  
   * `true`：The column was successfully created.
   * `false`：The column was not created.
