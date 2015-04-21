---
title: system.status
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `system.status` command reports current status of the clsuter itself.

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/droonga/system/status`

Request methd
: `GET`

Request URL parameters
: Nothing.

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
: `system.status`

`body` of the request
: Nothing.

`type` of the response
: `system.status.result`

## Parameter syntax {#syntax}

This command has no parameter.

## Usage {#usage}

This command reports the list of nodes and their vital information.
For example:

    {
      "type" : "system.status",
      "body" : {}
    }
    
    => {
         "type" : "system.status.result",
         "body" : {
           "nodes": {
             "192.168.0.10:10031/droonga": {
               "live": true
             },
             "192.168.0.11:10031/droonga": {
               "live": false
             }
           },
           "reporter": "192.168.0.10:49707/droonga @ 192.168.0.10:10031/droonga"
         }
       }


## Responses {#response}

This returns a hash like following as the response's `body`, with `200` as its `statusCode`.

    {
      "nodes" : {
        "<Identifier of the node 1>" : {
          "live" : <Vital status of the node>
        },
        "<Identifier of the node 2>" : { ... },
        ...
      },
      "reporter": "<Internal identifier of the reporter> @ <Identifier of the reporter node>"
    }

`nodes`
: A hash including information of nodes in the cluster.
  Keys of the hash are identifiers of nodes defined in the `catalog.json`, with the format: `hostname:port/tag`.
  Each value indicates status information of corresponding node, and have following information:
  
  `live`
  : A boolean value indicating vital state of the node.
    If `true`, the node can process messages, and messages are delivered to it.
    Otherwise, the node doesn't process any message for now, because it is down or some reasons.

`reporter`
: A string indicating who returns the result.
  It is useful for finding a broken node which detect status of other nodes wrongly.

## Error types {#errors}

This command reports [general errors](/reference/message/#error).
