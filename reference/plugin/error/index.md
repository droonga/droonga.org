---
title: Error handling in plugins
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

Any unhandled error raised from a plugin is returned as an [error response][] for the corresponding incoming message, with the status code `500` (means "internal error").

If you want formatted error information to be returned, then rescue errors and raise your custom errors inheriting `Droonga::ErrorMessage::BadRequest` or `Droonga::ErrorMessage::InternalServerError` instead of raw errors.


## Built-in error classes {#builtin-errors}

There are some pre-defined error classes used by built-in plugins and the Droonga Engine itself.

### `Droonga::ErrorMessage::NotFound`

Means an error which the specified resource is not found in the dataset or any source. For example:

    # the second argument means "details" of the error. (optional)
    raise Droonga::NotFound.new("#{name} is not found!", :elapsed_time => elapsed_time)

### `Droonga::ErrorMessage::BadRequest`

Means any error originated from the incoming message itself, ex. syntax error, validation error, and so on. For example:

    # the second argument means "details" of the error. (optional)
    raise Droonga::NotFound.new("Syntax error in #{query}!", :detail => detail)

### `Droonga::ErrorMessage::InternalServerError`

Means other unknown error, ex. timed out, file I/O error, and so on. For example:

    # the second argument means "details" of the error. (optional)
    raise Droonga::MessageProcessingError.new("busy!", :elapsed_time => elapsed_time)


## Built-in status codes {#builtin-status-codes}

You should use following or other status codes as [a matter of principle](../../message/#error-status).

`Droonga::StatusCode::OK`
: Equals to `200`.

`Droonga::StatusCode::NOT_FOUND`
: Equals to `404`.

`Droonga::StatusCode::BAD_REQUEST`
: Equals to `400`.

`Droonga::StatusCode::INTERNAL_ERROR`
: Equals to `500`.


  [error response]: ../../message/#error
