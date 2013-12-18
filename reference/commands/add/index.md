---
title: add
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `add` command adds a new record to the specified table. Column values of the existing record are updated by given values, if the table has a primary key and there is existing record with the specified key.

`add` is a request-response style command. One response message is always returned per one request.

## Syntax {#syntax}

If the table has a primary key column:

    {
      "table"  : "Name of the table",
      "key"    : "The primary key of the record",
      "values" : {
        "Name of the column 1" : value1,
        "Name of the column 2" : value2,
        ...
      }
    }

If the table has no primary key column:

    {
      "table"  : "Name of the table",
      "values" : {
        "Name of the column 1" : value1,
        "Name of the column 2" : value2,
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

    add
    {
      "table"  : "Person",
      "values" : {
        "name" : "Bob Dylan",
        "job"  : "musician"
      }
    }
    
    => add.result
       true

The `add` command works recursively. If there is no existing record with the key in the referred table, then it is also automatically added silently so you'll see no error response. For example this will add a new Person record with a new Job record named `doctor`.

    add
    {
      "table"  : "Person",
      "values" : {
        "name" : "Alice Miller",
        "job"  : "doctor"
      }
    }
    
    => add.result
       true

By the command above, a new record will be automatically added to the Job table like;

|_key|label|
|announcer|announcer|
|musician|musician|
|doctor|(blank)|


### Adding a new record to a table with primary key {#adding-record-to-table-with-key}

Specify all parameters `table`, `values` and `key`, if the table has a primary key column.

    add
    {
      "table"  : "Job",
      "key"    : "writer",
      "values" : {
        "label" : "writer"
      }
    }
    
    => add.result
       true

### Updating column values of an existing record {#updating}

This command works as "updating" operation, if the table has a primary key column and there is an existing record for the specified key.

    add
    {
      "table"  : "Job",
      "key"    : "doctor",
      "values" : {
        "label" : "医師"
      }
    }
    
    => add.result
       true


You cannot update column values of existing records, if the table has no primary key column. Then this command will always work as "adding" operation for the table.


## Parameters {#parameters}

### `table` {#parameter-table}

Abstract
: The name of a table which a record is going to be added to.

Value
: A name string of an existing table.

Required
: Yes.

### `key` {#parameter-key}

Abstract
: The primary key for the record going to be added.

Value
: A primary key string.

Required
: Yes, if the table has a primary key column. Otherwise no.

Existing column values will be updated, if there is an existing record for the key.

This parameter will be ignored if the table has no primary key column.

### `values` {#parameter-values}

Abstract
: New values for columns of the record.

Value
: A hash. Keys of the hash are column names, values of the hash are new values for each column.

Required
: No. This is optional.

Default value
: `null`

Value of unspecified columns will not be changed.


## Responses {#response}

This returns an array including a boolean value which means the operation has been successfully done or not.

 * `[true]`：The record is successfully added or updated.
 * `[false]`：Failed to add or update a record.
