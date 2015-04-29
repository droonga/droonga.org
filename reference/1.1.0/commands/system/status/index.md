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
               "status": "active"
             },
             "192.168.0.11:10031/droonga": {
               "status": "dead"
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
          "status" : "<Vital status of the node>"
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
  
  `status`
  : A string indicating vital status of the node.
    Possible values are:
    
    * `active`:
      The node is working, and in service.
      Messages are delivered to it normally.
    * `inactive`:
      The node is working, but not in service temporarily.
      Messages are not delivered to it just in time.
      The node is ignored for read-only messages completely.
      Messages modifying the database (like `add`) are buffered and delivered to the node after it is back to `active`.
    * `dead`:
      The node is not working permanently. For example, the service is down.
    
    Those statuses are relatively detected by each node.
    For example, two nodes can detect themselves as `active` and detect as `inactive` each other, when they have different role.

`reporter`
: A string indicating who returns the result.
  It is useful for finding a broken node which detect status of other nodes wrongly.

## Error types {#errors}

This command reports [general errors](/reference/message/#error).
