---
title: select
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `select` command finds records from the specified table based on given conditions, and returns found records.

This is compatible to [the `select` command of the Groonga](http://groonga.org/docs/reference/commands/select.html).

Style
: Request-Response. One response message is always returned per one request.

`type`
: `select`

`body`
: A hash of parameters.

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

On the version {{ site.droonga_version }}, only following paramters are available. Others are simply ignored because they are not implemented.

 * `table`
 * `match_columns`
 * `query`
 * `output_columns`
 * `offset`
 * `limit`

All parameters are compatible to [parameters for `select` command of the Groonga](http://groonga.org/docs/reference/commands/select.html#parameters). See the linked document for more details.



## Resposnes {#response}

This returns an array including search results.

The structure of the returned array is compatible to [the returned value of the Groonga's `select` command](http://groonga.org/docs/reference/commands/select.html#id6). See the linked document for more details.

