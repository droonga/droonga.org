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

Doesn't match to:

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
                 ["body.success", :equal, true]
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
      "body": {
        "success": true
      }
    }


## Syntax {#syntax}

There are two typeos of matching patterns: "basic pattern" and "nested pattern".

### Basic pattern {#syntax-basic}

#### Structure {#syntax-basic-structure}

A basic pattern is described as an array including 2 or more elements, like following:

    ["type", :equal, "search"]

 * The first element is a *target path*. It means the location of the information to be checked, in the [message][].
 * The second element is an *operator*. It means how the information specified by the target path should be checked.
 * The third element is an *argument for the oeprator*. It is a primitive value (string, numeric, or boolean) or an array of values. Some operators require no argument.

#### Target path {#syntax-basic-target-path}

The target path is specified as a string.

#### Avialable operators {#syntax-basic-operators}

The operator is specified as a symbol.

`:equal`
: Returns `true`, if the target value is equal to the given value. Otherwise `false`.
  For example,
  
      ["type", :equal, "search"]
  
  The pattern above matches to a message like following:
  
      {
        "type": "search",
        ...
      }

`:in`
: Returns `true`, if the target value is in the given array of values. Otherwise `false`.
  For example,
  
      ["type", :in, ["search", "select"]]
  
  The pattern above matches to a message like following:
  
      {
        "type": "select",
        ...
      }
  
  But it doesn't match to:
  
      {
        "type": "find",
        ...
      }

`:include`
: Returns `true` if the target array of values includes the given value. Otherwise `false`.
  In other words, this is the opposite of the `:in` operator.
  For example,
  
      ["body.tags", :include, "News"]
  
  The pattern above matches to a message like following:
  
      {
        "type": "my.notification",
        "body": {
          "tags": ["News", "Groonga", "Droonga", "Fluentd"]
        }
      }

`:exist`
: Returns `true` if the target exists. Otherwise `false`.
  For example,
  
      ["body.comments", :exist, "News"]
  
  The pattern above matches to a message like following:
  
      {
        "type": "my.notification",
        "body": {
          "title": "Hello!",
          "comments": []
        }
      }
  
  But it doesn't match to:
  
      {
        "type": "my.notification",
        "body": {
          "title": "Hello!"
        }
      }

`:start_with`
: Returns `true` if the target string value starts with the given string. Otherwise `false`.
  For example,
  
      ["body.path", :start_with, "/archive/"]
  
  The pattern above matches to a message like following:
  
      {
        "type": "my.notification",
        "body": {
          "path": "/archive/2014/02/28.html"
        }
      }


### Nested pattern {#syntax-nested}

#### Structure {#syntax-nested-structure}

A nested pattern is described as an array including 3 elements, like following:

    [
      ["type", :equal, "table_create"],
      :or,
      ["type", :equal, "column_create"]
    ]

 * The first and the third elements are patterns, basic or nested. (In other words, you can nest patterns recursively.)
 * The second element is a *logical operator*.

#### Avialable operators {#syntax-nested-operators}

`:and`
: Returns `true` if both given patterns are evaluated as `true`. Otherwise `false`.

`:or`
: Returns `true` if one of given patterns (the first or the third element) is evaluated as `true`. Otherwise `false`.




  [message]:../../message/

