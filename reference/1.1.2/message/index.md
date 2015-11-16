---
title: Message format
layout: en
---

* TOC
{:toc}


## Request {#request}

The basic format of a request message is like following:

    {
      "id"      : "<ID of the message>",
      "type"    : "<Type of the message>",
      "replyTo" : "<Route to the receiver>",
      "dataset" : "<Name of the target dataset>",
      "timeout" : <Seconds to wait for the result>,
      "targetRole" : "<Name of the target role>",
      "body"    : <Body of the message>
    }

### `id` {#request-id}

Abstract
: The unique identifier for the message.

Value
: An identifier string. You can use any string with any format as you like, if only it is unique. The given id of a request message will be used for the ['inReplyTo`](#response-inReplyTo) information of its response.

Default value
: Nothing. This is required information.

### `type` {#request-type}

Abstract
: The type of the message.

Value
: A type string of [a command](/reference/commands/).

Default value
: Nothing. This is required information.

### `replyTo` {#request-replyTo}

Abstract
: The route to the response receiver.

Value
: An path string in the format: `<hostname>:<port>/<tag>`, for example: `localhost:24224/output`.

Default value
: Nothing. This is optional. If you specify no `replyTo`, then the response message will be thrown away.

### `dataset` {#request-dataset}

Abstract
: The target dataset.

Value
: A name string of a dataset.

Default value
: Nothing. This is required information.

### `timeout` {#request-timeout}

Abstract
: Time to expire the request message, in seconds.
  If no result for the request is returned until this period, system aborts all tracking for messages originated from the request, and the client can report it as "operation timed out".

Value
: A float number, for example: `0.5`.

Default value
: `60` (means one minute)

### `targetRole` {#request-targetRole}

Abstract
: The role of the target engine node.
  If the node received the message has a role different to this field, the message will be bounced to another engine node with the role.
  Messages with no `targetRole` or the special value `"any"` will be processed by the receiver node with any role.

Value
: `null`, `"any"`, or one of following role:
  
   * `"service-provider"`
   * `"absorb-source"`
   * `"absorb-destination"`

Default value
: `null`

### `body` {#request-body}

Abstract
: The body of the message.

Value
: Object, string, number, boolean, or `null`.

Default value
: Nothing. This is optional.

## Response {#response}

The basic format of a response message is like following:

    {
      "type"       : "<Type of the message>",
      "inReplyTo"  : "<ID of the related request message>",
      "statusCode" : <Status code>,
      "body"       : <Body of the message>,
      "errors"     : <Errors from nodes>
    }

### `type` {#response-type}

Abstract
: The type of the message.

Value
: A type string. Generally it is a suffixed version of the type string of the request message, with the suffix ".result".

### `inReplyTo` {#response-inReplyTo}

Abstract
: The identifier of the related request message.

Value
: An identifier string of the related request message.

### `statusCode` {#response-statusCode}

Abstract
: The result status for the request message.

Value
: A status code integer.

Status codes of responses are similar to HTTP's one. Possible values:

`200` and other `2xx` statuses
: The command is successfully processed.

### `body` {#response-body}

Abstract
: The result information for the request message.

Value
: Object, string, number, boolean, or `null`.

### `errors` {#response-errors}

Abstract
: All errors from nodes.

Value
: Object.

This information will appear only when the command is distributed to multiple volumes and they returned errors. Otherwise, the response message will have no `errors` field. For more details, see [the "Error response" section](#error).

## Error response {#error}

Some commands can return an error response.

An error response has the `type` same to a regular response, but it has different `statusCode` and `body`. General type of the error is indicated by the `statusCode`, and details are reported as the `body`.

If a command is distributed to multiple volumes and they return errors, then the response message will have an `error` field. All errors from all nodes are stored to the field, like:

    {
      "type"       : "add.result",
      "inReplyTo"  : "...",
      "statusCode" : 400,
      "body"       : {
        "name":    "UnknownTable",
        "message": ...
      },
      "errors"     : {
        "/path/to/the/node1" : {
          "statusCode" : 400,
          "body"       : {
            "name":    "UnknownTable",
            "message": ...
          }
        },
        "/path/to/the/node2" : {
          "statusCode" : 400,
          "body"       : {
            "name":    "UnknownTable",
            "message": ...
          }
        }
      }
    }

In this case, one of all errors will be exported as the main message `body`, as a representative.


### Status codes of error responses {#error-status}

Status codes of error responses are similar to HTTP's one. Possible values:

`400` and other `4xx` statuses
: An error of the request message.

`500` and other `5xx` statuses
: An internal error of the Droonga Engine.

### Body of error responses {#error-body}

The basic format of the body of an error response is like following:

    {
      "name"    : "<Type of the error>",
      "message" : "<Human readable details of the error>",
      "detail"  : <Other extra information for the error, in various formats>
    }

If there is no detail, `detial` can be missing.

#### Error types {#error-type}

There are some general error types for any command.

`MissingDatasetParameter`
: Means you've forgotten to specify the `dataset`. The status code is `400`.

`UnknownDataset`
: Means you've specified a dataset which is not existing. The status code is `404`.

`UnknownType`
: Means there is no handler for the command given as the `type`. The status code is `400`.
