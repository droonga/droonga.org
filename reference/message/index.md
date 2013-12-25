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

### `type` {#request-type}

### `replyTo` {#request-replyTo}

### `dataset` {#request-dataset}

### `body` {#request-body}


## Response {#response}

The basic format of a response message is like following:

    {
      "type"       : "<Type of the message>",
      "inReplyTo"  : "<Route to the receiver>",
      "statusCode" : <Status code>,
      "body"       : <Body of the message>
    }

### `type` {#response-type}

### `inReplyTo` {#response-inReplyTo}

### `statusCode` {#response-statusCode}

Status codes of responses are similar to HTTP's one.

`200` and other `2xx` statuses
: The command is successfully processed.

### `body` {#response-body}


## Error response {#error}

Some commands can return an error response.

An error response has the `type` same to a regular response, but it has different `statusCode` and `body`. General type of the error is indicated by the `statusCode`, and details are reported as the `body`.

### Status codes of error responses {#error-status}

Status codes of error responses are similar to HTTP's one.

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
