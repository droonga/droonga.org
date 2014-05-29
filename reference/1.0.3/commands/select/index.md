---
title: select
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `select` command finds records from the specified table based on given conditions, and returns found records.

This is compatible to [the `select` command of the Groonga](http://groonga.org/docs/reference/commands/select.html).

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/d/select`

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
: `select`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `select.result`

## Parameter syntax {#syntax}

    {
      "table"            : "<Name of the table>",
      "match_columns"    : "<List of matching columns, separated by '||'>",
      "query"            : "<Simple search conditions>",
      "filter"           : "<Complex search conditions>",
      "scorer"           : "<An expression to be applied to matched records>",
      "sortby"           : "<List of sorting columns, separated by ','>",
      "output_columns"   : "<List of returned columns, separated by ','>",
      "offset"           : <Offset of paging>,
      "limit"            : <Number of records to be returned>,
      "drilldown"        : "<Column name to be drilldown-ed>",
      "drilldown_sortby" : "List of sorting columns for drilldown's result, separated by ','>",
      "drilldown_output_columns" :
                           "List of returned columns for drilldown's result, separated by ','>",
      "drilldown_offset" : <Offset of drilldown's paging>,
      "drilldown_limit"  : <Number of drilldown results to be returned>,
      "cache"            : "<Query cache option>",
      "match_escalation_threshold":
                           <Threshold to escalate search methods>,
      "query_flags"      : "<Flags to customize query parameters>",
      "query_expander"   : "<Arguments to expanding queries>"
    }

## Parameter details {#parameters}

All parameters except `table` are optional.

On the version 1.0.3, only following parameters are available. Others are simply ignored because they are not implemented.

 * `table`
 * `match_columns`
 * `query`
 * `filter`
 * `output_columns`
 * `offset`
 * `limit`
 * `drilldown`
 * `drilldown_output_columns`
 * `drilldown_sortby`
 * `drilldown_offset`
 * `drilldown_limit`

All parameters are compatible to [parameters for `select` command of the Groonga](http://groonga.org/docs/reference/commands/select.html#parameters). See the linked document for more details.

## Responses {#response}

This returns an array including search results as the response's `body`.

    [
      [
        <Groonga's status code>,
        <Start time>,
        <Elapsed time>
      ],
      <List of columns>
    ]

The structure of the returned array is compatible to [the returned value of the Groonga's `select` command](http://groonga.org/docs/reference/commands/select.html#id6). See the linked document for more details.

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

