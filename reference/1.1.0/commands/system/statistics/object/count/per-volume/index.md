---
title: system.statistics.object.count.per-volume
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `system.statistics.object.count.per-volume` command counts and reports numbers of physical objects in each volume.

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/droonga/system/statistics/object/count/per-volume`

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
: `system.statistics.object.count.per-volume`

`body` of the request
: A hash of [parameters](#parameters).

`type` of the response
: `system.statistics.object.count.per-volume.result`

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
      "type" : "system.statistics.object.count.per-volume",
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
         "type" : "system.statistics.object.count.per-volume.result",
         "body" : {
           "node0:10031/droonga.000": {
             "tables":  1,
             "columns": 0,
             "records": 1,
             "total":   2
           },
           "node0:10031/droonga.001": {
             "tables":  1,
             "columns": 0,
             "records": 1,
             "total":   2
           }
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
      "<Identifier of the volume 1>": {
        "tables":  <The total number of tables>,
        "columns": <The total number of columns>,
        "records": <The total number of records>,
        "total":   <The total number of all objects>
      },
      "<Identifier of the volume 2>": { ... },
      ...
    }

`tables`
: The number of physical tables in the dataset.

`columns`
: The number of physical columns in the dataset.

`records`
: The number of physical records in the dataset.

`total`
: The total number of `tables`, `columns`, and `records`.
  If you just want to know the total number of all objects, this is faster than separate targets.

## Error types {#errors}

This command reports [general errors](/reference/message/#error).
