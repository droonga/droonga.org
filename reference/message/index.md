---
title: Message format
layout: documents
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
      "body"       : <Body of the message>
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


## Error response {#error}

Some commands can return an error response.

An error response has the `type` same to a regular response, but it has different `statusCode` and `body`. General type of the error is indicated by the `statusCode`, and details are reported as the `body`.

### Status codes of error responses {#error-status}

Status codes of error responses are similar to HTTP's one. Possible values:

`400` and other `4xx` statuses
: An error of the request message.

`500` and other `5xx` statuses
: An internal error of the Droonga Engine.

### Body of error responses {#error-body}

The basic format of the body of an error response is like following:

    {
      "name"    : "<Name of the error>",
      "message" : "<Human readable details of the error>",
      "detail"  : <Other extra information for the error, in various formats>
    }
