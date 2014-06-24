---
title: status
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

The `status` command reports current status of the clsuter itself.

## API types {#api-types}

### HTTP {#api-types-http}

Request endpoint
: `(Document Root)/droonga/status`

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
: `status`

`body` of the request
: Nothing.

`type` of the response
: `status.result`

## Parameter syntax {#syntax}

This command has no parameter.

## Usage {#usage}

On the version {{ site.droonga_version }}, this command just reports the list of nodes and their vital information.
For example:

    {
      "type" : "status",
      "body" : {}
    }
    
    => {
         "type" : "status.result",
         "body" : {
           "nodes": {
             "192.168.0.10:10031/droonga": {
               "live": true
             },
             "192.168.0.11:10031/droonga": {
               "live": false
             }
           }
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
      }
    }

`nodes`
: A hash including information of nodes in the cluster.
  Keys of the hash are identifiers of nodes defined in the `catalog.json`, with the format: `hostname:port/tag`.
  Each value indicates status information of corresponding node, and have following information:
  
  `live`
  : A boolean value indicating vital state of the node.
    If `true`, the node can process messages, and messages are delivered to it.
    Otherwise, the node doesn't process any message for now, because it is down or some reasons.


## Error types {#errors}

This command reports [general errors](/reference/message/#error).
