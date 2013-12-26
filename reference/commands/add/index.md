---
title: add
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `add` command adds a new record to the specified table. Column values of the existing record are updated by given values, if the table has a primary key and there is existing record with the specified key.

Style
: Request-Response. One response message is always returned per one request.

`type`
: `add`

`body`
: A hash of parameters.

## Parameter syntax {#syntax}

If the table has a primary key column:

    {
      "table"  : "<Name of the table>",
      "key"    : "<The primary key of the record>",
      "values" : {
        "<Name of the column 1>" : <value 1>,
        "<Name of the column 2>" : <value 2>,
        ...
      }
    }

If the table has no primary key column:

    {
      "table"  : "<Name of the table>",
      "values" : {
        "<Name of the column 1>" : <value 1>,
        "<Name of the column 2>" : <value 2>,
        ...
      }
    }

## Usage {#usage}

This section describes how to use the `add` command, via a typical usage with following two tables:

Person table (without primary key):

|name|job (referring the Job table)|
|Alice Arnold|announcer|
|Alice Cooper|musician|

Job table (with primary key)

|_key|label|
|announcer|announcer|
|musician|musician|


### Adding a new record to a table without primary key {#adding-record-to-table-without-key}

Specify only `table` and `values`, without `key`, if the table has no primary key.

    {
      "type" : "add",
      "body" : {
        "table"  : "Person",
        "values" : {
          "name" : "Bob Dylan",
          "job"  : "musician"
        }
      }
    }
    
    => {
         "type" : "add.result",
         "body" : [true]
       }

The `add` command works recursively. If there is no existing record with the key in the referred table, then it is also automatically added silently so you'll see no error response. For example this will add a new Person record with a new Job record named `doctor`.

    {
      "type" : "add",
      "body" : {
        "table"  : "Person",
        "values" : {
          "name" : "Alice Miller",
          "job"  : "doctor"
        }
      }
    }
    
    => {
         "type" : "add.result",
         "body" : [true]
       }

By the command above, a new record will be automatically added to the Job table like;

|_key|label|
|announcer|announcer|
|musician|musician|
|doctor|(blank)|


### Adding a new record to a table with primary key {#adding-record-to-table-with-key}

Specify all parameters `table`, `values` and `key`, if the table has a primary key column.

    {
      "type" : "add",
      "body" : {
        "table"  : "Job",
        "key"    : "writer",
        "values" : {
          "label" : "writer"
        }
      }
    }
    
    => {
         "type" : "add.result",
         "body" : [true]
       }

### Updating column values of an existing record {#updating}

This command works as "updating" operation, if the table has a primary key column and there is an existing record for the specified key.

    {
      "type" : "add",
      "body" : {
        "table"  : "Job",
        "key"    : "doctor",
        "values" : {
          "label" : "doctor"
        }
      }
    }
    
    => {
         "type" : "add.result",
         "body" : [true]
       }


You cannot update column values of existing records, if the table has no primary key column. Then this command will always work as "adding" operation for the table.


## Parameter details {#parameters}

### `table` {#parameter-table}

Abstract
: The name of a table which a record is going to be added to.

Value
: A name string of an existing table.

Default value
: Nothing. This is a required parameter.

### `key` {#parameter-key}

Abstract
: The primary key for the record going to be added.

Value
: A primary key string.

Default value
: Nothing. This is required if the table has a primary key column. Otherwise, this is ignored.

Existing column values will be updated, if there is an existing record for the key.

This parameter will be ignored if the table has no primary key column.

### `values` {#parameter-values}

Abstract
: New values for columns of the record.

Value
: A hash. Keys of the hash are column names, values of the hash are new values for each column.

Default value
: `null`

Value of unspecified columns will not be changed.


## Responses {#response}

This returns an array with including a boolean value `true` like following as the response's `body`, with `200` as its `statusCode`, if a record is successfully added or updated.

    [true]

## Error types {#errors}

This command reports errors not only [general errors](/reference/message/#error) but also followings.

### `MissingTableParameter`

Means you've forgotten to specify the `table` parameter. The status code is `400`.

### `MissingPrimaryKeyParameter`

Means you've forgotten to specify the `key` parameter, for a table with the primary key column. The status code is `400`.

### `MismatchedValueType`

Means you've specified mismatched type value for a column. For example, a string for a geolocation column, a string for an integer column, etc. The status code is `400`.

### `UnknownTable`

Means you've specified a table which is not existing in the specified dataset. The status code is `404`.

### `UnknownColumn`

Means you've specified any column which is not existing in the specified table. The status code is `404`.

