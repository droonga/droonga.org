---
title: load
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `load` command adds new records to the specified table.
Column values of existing records are updated by new values, if the table has a primary key and there are existing records with specified keys.

This is compatible to [the `load` command of the Groonga](http://groonga.org/docs/reference/commands/load.html).

## API types {#api-types}

### HTTP (GET) {#api-types-http-get}

Request endpoint
: `(Document Root)/d/load`

Request methd
: `GET`

Request URL parameters
: Same to the list of [parameters](#parameters).

Request body
: Nothing.

Response body
: A [response message](#response).

### HTTP (POST) {#api-types-http-post}

Request endpoint
: `(Document Root)/d/load`

Request methd
: `POST`

Request URL parameters
: Same to the list of [parameters](#parameters), except `values`.

Request body
: The value for the [parameter](#parameters) `values`.

Response body
: A [response message](#response).

### REST {#api-types-rest}

Not supported.

### Fluentd {#api-types-fluentd}

Not supported.

## Parameter syntax {#syntax}

    {
      "values"     : <Array of records to be loaded>,
      "table"      : "<Name of the table>",
      "columns"    : "<List of column names for values, separated by ','>",
      "ifexists"   : "<Grn_expr to determine records which should be updated>",
      "input_type" : "<Format type of the values>"
    }

## Parameter details {#parameters}

All parameters except `table` are optional.

On the version 1.1.0, only following parameters are available. Others are simply ignored because they are not implemented.

 * `values`
 * `table`
 * `columns`

They are compatible to [the parameters of the `load` command of the Groonga](http://groonga.org/docs/reference/commands/load.html#parameters). See the linked document for more details.

HTTP clients can send `values` as an URL parameter with `GET` method, or the request body with `POST` method.
The URL parameter `values` is always ignored it it is sent with `POST` method.
You should send data with `POST` method if there is much data.

## Responses {#response}

This returns an array meaning the result of the operation, as the `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      [<Number of loaded records>]
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

Number of loaded records
: An positive integer meaning the number of added or updated records.
