---
title: system.statistics.object.count
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `system.statistics.object.count` command counts and reports numbers of physical objects in the dataset.

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/droonga/system/statistics/object/count`

Request methd
: `GET`

Request URL parameters
: See [parameters](#parameters).

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
: `system.statistics.object.count`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `system.statistics.object.count.result`

## Parameter syntax {#syntax}

    {
      "output": [
        "tables",
        "columns",
        "records"
      ]
    }

or

    {
      "output": [
        "total"
      ]
    }

## Usage {#usage}

This command counts and reports the physical numbers of specified targets.
For example:

    {
      "type" : "system.statistics.object.count",
      "body" : {
        "output": [
          "tables",
          "columns",
          "records",
          "total"
        ]
      }
    }
    
    => {
         "type" : "system.statistics.object.count.result",
         "body" : {
           "tables":  2,
           "columns": 0,
           "records": 1,
           "total":   3
         }
       }


## Parameter details {#parameters}

All parameters are optional.

### `output` {#parameter-output}

Abstract
: Targets to be reported their count.

Value
: An array of targets. Only specified targets are counted.
  Possible values are:
  
   * `tables`
   * `columns`
   * `records`
   * `total`

Default value
: `[]`


## Responses {#response}

This returns a hash like following as the response's `body`, with `200` as its `statusCode`.

    {
      "tables":  <The total number of tables>,
      "columns": <The total number of columns>,
      "records": <The total number of records>,
      "total":   <The total number of all objects>,
    }

`tables`
: The number of physical tables in the dataset.
  If there are multiple slices, the number of tables is also multiplied.
  For example, if there are two slices and you defined two tables, then this reports `4`.

`columns`
: The number of physical columns in the dataset.
  If there are multiple slices, the number of columns is also multiplied.
  For example, if there are two slices and you defined two tables with two columns for each, then this reports `8`.

`records`
: The number of physical records in the dataset.
  If there are multiple slices, the number of records in fact tables is also multiplied.
  For example, if there are two slices and you added one record for a regular table amd one record for a fact table, then this reports `3`.
  (One for the regular table, two for multiplied records in the fact table.)

`total`
: The total number of `tables`, `columns`, and `records`.
  If you just want to know the total number of all objects, this is faster than separate targets.

## Error types {#errors}

This command reports [general errors](/reference/message/#error).
