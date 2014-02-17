---
title: Matching pattern for messages
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

The Droonga Engine provides a tiny language to specify patterns of messages, called *matching pattern*.
It is used to specify target messages of various operations, ex. plugins.


## Examples {#examples}

### Simple matching

    pattern = ["type", :equal, "search"]

This matches to messages like:

    {
      "type": "search",
      ...
    }

### Matching for a deep target

    pattern = ["body.success", :equal, true]

This matches to messages like:

    {
      "type": "add.result",
      "body": {
        "success": true
      }
    }

Not matches to:

    {
      "type": "add.result",
      "body": {
        "success": false
      }
    }

### Nested patterns

    pattern = [
                 ["type", :equal, "table_create"],
                 :or,
                 ["type", :equal, "column_create"]
              ]

This matches to both:

    {
      "type": "table_create",
      ...
    }

and:

    {
      "type": "column_create",
      ...
    }


## Syntax {#syntax}


 * `PATTERN` = [`TARGET_PATH`, `OPERATOR`, `ARGUMENTS*`]
 * `PATTERN` = [`PATTERN, LOGICAL_OPERATOR`, `PATTERN`]
 * `TARGET_PATH` = `"COMPONENT(.COMPONENT)*"`
 * `OPERATOR` = `:equal`, `:in`, `:include`, `:exist`, `:start_with`
 * `ARGUMENTS` = `OBJECT_DEFINED_IN_JSON*`
 * `LOGICAL_OPERATOR` = `:or`

