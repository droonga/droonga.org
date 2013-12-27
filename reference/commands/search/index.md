---
title: search
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `search` command finds records from the specified table based on given conditions, and returns found records and/or related information.

This is designed as the most basic (low layer) command on Droonga, to search information from a database. When you want to add a new plugin including "search" feature, you should develop it as just a wrapper of this command, instead of developing something based on more low level technologies.

Style
: Request-Response. One response message is always returned per one request.

`type` of the request
: `search`

`body` of the request
: A hash of parameters.

`type` of the response
: `search.result`

## Parameter syntax {#syntax}

    {
      "timeout" : <Seconds to be timed out>,
      "queries" : {
        "<Name of the query 1>" : {
          "source"    : "<Name of a table or another query>",
          "condition" : <Search conditions>,
          "sortBy"    : <Sort conditions>,
          "groupBy"   : <Group conditions>,
          "output"    : <Output conditions>
        },
        "<Name of the query 2>" : { ... },
        ...
      }
    }

## Usage {#usage}

This section describes how to use this command, via a typical usage with following table:

Person table (with primary key):

|_key|name|age|sex|job|note|
|Alice Arnold|Alice Arnold|20|female|announcer||
|Alice Cooper|Alice Cooper|30|male|musician||
|Alice Miller|Alice Miller|25|female|doctor||
|Bob Dole|Bob Dole|42|male|lawer||
|Bob Cousy|Bob Cousy|38|male|basketball player||
|Bob Wolcott|Bob Wolcott|36|male|baseball player||
|Bob Evans|Bob Evans|31|male|driver||
|Bob Ross|Bob Ross|54|male|painter||
|Lewis Carroll|Lewis Carroll|66|male|writer|the author of Alice's Adventures in Wonderland|

Note: `name` and `note` are indexed with `TokensBigram`.

### Basic usage {#usage-basic}

This is a simple example to output all records of the Person table:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source" : "Person",
            "output" : {
              "elements"   : ["count", "records"],
              "attributes" : ["_key", "name", "age", "sex", "job", "note"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 9,
             "records" : [
               ["Alice Arnold", "Alice Arnold", 20, "female", "announcer", ""],
               ["Alice Cooper", "Alice Cooper", 30, "male", "musician", ""],
               ["Alice Miller", "Alice Miller", 25, "male", "doctor", ""],
               ["Bob Dole", "Bob Dole", 42, "male", "lawer", ""],
               ["Bob Cousy", "Bob Cousy", 38, "male", "basketball player", ""],
               ["Bob Wolcott", "Bob Wolcott", 36, "male", "baseball player", ""],
               ["Bob Evans", "Bob Evans", 31, "male", "driver", ""],
               ["Bob Ross", "Bob Ross", 54, "male", "painter", ""],
               ["Lewis Carroll", "Lewis Carroll", 66, "male", "writer",
                "the author of Alice's Adventures in Wonderland"]
             ]
           }
         }
       }

The name `people` is a temporary name for the search query and its result.
A response of a `search` command will be returned as a hash, and the keys are same to keys of the given `queries`.
So, this means: "name the search result of the query as `people`".

Why the command above returns all informations of the table? Because:

 * There is no search condition. This command matches to all records in the specified table, if no condition is specified.
 * [`output`](#query-output)'s `elements` contains `records` (and `count`) column(s). The parameter `elements` controls the returned information. Matched records are returned as `records`, the total number of matched records are returned as `count`.
 * [`output`](#query-output)'s `limit` is `-1`. The parameter `limit` controls the number of returned records, and `-1` means "return all records".
 * [`output`](#query-output)'s `attributes` contains all columns of the Person table. The parameter `attributes` controls which columns' value are returned.


#### Search conditions {#usage-condition}

Search conditions are specified via the `condition` parameter. There are two styles of search conditions: "script syntax" and "query syntax". See [`condition` parameter](#query-condition) for more details.

##### Search conditions in Script syntax {#usage-condition-script-syntax}

Search conditions in script syntax are similar to ECMAScript. For example, following query means "find records that `name` contains `Alice` and `age` is larger than `25`":

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source"    : "Person",
            "condition" : "name @ 'Alice' && age >= 25"
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          }
        }
      }
    }

    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 2,
             "records" : [
               ["Alice Arnold", 20],
               ["Alice Cooper", 30],
               ["Alice Miller", 25]
             ]
           }
         }
       }

[Script syntax is compatible to Groonga's one](http://groonga.org/docs/reference/grn_expr/script_syntax.html). See the linked document for more details.

##### Search conditions in Query syntax {#usage-condition-query-syntax}

The query syntax is mainly designed for search boxes in webpages. For example, following query means "find records that `name` or `note` contain the given word, and the word is `Alice`":

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source"    : "Person",
            "condition" : {
              "query"   : "Alice",
              "matchTo" : ["name", "note"]
            },
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "note"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 4,
             "records" : [
               ["Alice Arnold", ""],
               ["Alice Cooper", ""],
               ["Alice Miller", ""],
               ["Lewis Carroll",
                "the author of Alice's Adventures in Wonderland"]
             ]
           }
         }
       }

[Query syntax is compatible to Groonga's one](http://groonga.org/docs/reference/grn_expr/query_syntax.html). See the linked document for more details.


#### Sorting of search results {#usage-sort}

Returned records can be sorted by conditions specified as the `sortBy` parameter. For example, following query means "sort results by their `age`, in ascending order":

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source"    : "Person",
            "condition" : "name @ 'Alice'"
            "sortBy"    : ["age"],
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 8,
             "records" : [
               ["Alice Arnold", 20],
               ["Alice Miller", 25],
               ["Alice Cooper", 30]
             ]
           }
         }
       }

If you add `-` before name of columns, then search results are returned in descending order. For example:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source"    : "Person",
            "condition" : "name @ 'Alice'"
            "sortBy"    : ["-age"],
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 8,
             "records" : [
               ["Alice Cooper", 30],
               ["Alice Miller", 25],
               ["Alice Arnold", 20]
             ]
           }
         }
       }

See [`sortBy` parameter](#query-sortBy) for more details.

#### Paging of search results {#usage-paging}

Search results can be retuned partially via `offset` and `limit` under the [`output`](#query-output) parameter. For example, following queries will return 20 or more search results by 10's.

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source" : "Person",
            "output" : {
              "elements"   : ["count", "records"],
              "attributes" : ["name"],
              "offset"     : 0,
              "limit"      : 10
            }
          }
        }
      }
    }
    
    => returns 10 results from the 1st to the 10th.
    
    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source" : "Person",
            "output" : {
              "elements"   : ["count", "records"],
              "attributes" : ["name"],
              "offset"     : 10,
              "limit"      : 10
            }
          }
        }
      }
    }
    
    => returns 10 results from the 11th to the 20th.
    
    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source" : "Person",
            "output" : {
              "elements"   : ["count", "records"],
              "attributes" : ["name"],
              "offset"     : 20,
              "limit"      : 10
            }
          }
        }
      }
    }
    
    => returns 10 results from the 21th to the 30th.

The value `-1` is not recommended  for the `limit` parameter, in regular use. It will return too much results and increase traffic loads. Instead `100` or less value is recommended for the `limit` parameter. Then you should do paging by the `offset` parameter.

See [`output` parameter](#query-output) for more details.

Moreover, you can do paging via [the `sortBy` parameter](#query-sortBy-hash) and it will work faster than the paging by the `output` parameter. You should do paging via the `sortBy` parameter instead of `output` as much as possible.


#### Output format {#usage-format}

Search result records in examples above are shown as arrays of arrays, but they can be returned as arrays of hashes by the [`output`](#query-output)'s `format` parameter. If you specify `complex` for the `format`, then results are returned like:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source" : "Person",
            "output" : {
              "elements"   : ["count", "records"],
              "attributes" : ["_key", "name", "age", "sex", "job", "note"],
              "limit"      : 3,
              "format"     : "complex"
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 9,
             "records" : [
               { "_key" : "Alice Arnold",
                 "name" : "Alice Arnold",
                 "age"  : 20,
                 "sex"  : "female",
                 "job"  : "announcer",
                 "note" : "" },
               { "_key" : "Alice Cooper",
                 "name" : "Alice Cooper",
                 "age"  : 30,
                 "sex"  : "male",
                 "job"  : "musician",
                 "note" : "" },
               { "_key" : "Alice Miller",
                 "name" : "Alice Miller",
                 "age"  : 25,
                 "sex"  : "female",
                 "job"  : "doctor",
                 "note" : "" }
             ]
           }
         }
       }

Search result records will be returned as an array of hashes, when you specify `complex` as the value of the `format` parameter.
Otherwise - `simple` or nothing is specified -, records are returned as an array of arrays.

See [`output` parameters](#query-output) and [responses](#response) for more details.


### Advanced usage {#usage-advanced}

#### Grouping {#usage-group}

You can group search results by a column, via the [`groupBy`](#query-groupBy) parameters. For example, following query returns a result grouped by the `sex` column, with the count of original search results:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "sexuality" : {
            "source"  : "Person",
            "groupBy" : "sex",
            "output"  : {
              "elements"   : ["count", "records"],
              "attributes" : ["_key", "_nsubrecs"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "sexuality" : {
             "count" : 2,
             "records" : 
               ["female", 2],
               ["male", 7]
             ]
           }
         }
       }

The result means: "There are two `female` records and seven `male` records, moreover there are two types for the column `sex`.

You can also extract the ungrouped record by the `maxNSubRecords` parameter and the `_subrecs` virtual column. For example, following query returns the result grouped by `sex` and extract two ungrouped records:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "sexuality" : {
            "source"  : "Person",
            "groupBy" : {
              "keys"           : "sex",
              "maxNSubRecords" : 2
            }, 
            "output"  : {
              "elements"   : ["count", "records"],
              "attributes" : [
                "_key",
                "_nsubrecs",
                { "label"      : "subrecords",
                  "source"     : "_subrecs",
                  "attributes" : ["name"] }
              ],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "sexuality" : {
             "count" : 2,
             "records" : 
               ["female", 2, [["Alice Arnold"], ["Alice Miller"]]],
               ["male",   7, [["Alice Cooper"], ["Bob Dole"]]]
             ]
           }
         }
       }


See [`groupBy` parameters](#query-groupBy) for more details.


#### Multiple search queries in one request {#usage-multiple-queries}

Multiple queries can be appear in one `search` command. For example, following query searches people yanger than 25 or older than 40:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "junior" : {
            "source"    : "Person",
            "condition" : "age <= 25",
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          },
          "senior" : {
            "source"    : "Person",
            "condition" : "age >= 40",
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "junior" : {
             "count" : 2,
             "records" : [
               ["Alice Arnold", 20],
               ["Alice Miller", 25]
             ]
           },
           "senior" : {
             "count" : 3,
             "records" : [
               ["Bob Dole", 42],
               ["Bob Ross", 54],
               ["Lewis Carroll", 66]
             ]
           }
         }
       }

Each search result can be identified by the temporary name given for each query.

#### Chained search queries {#usage-chain}

You can specify not only an existing table, but search result of another query also, as the value of the "source" parameter. Chained search queries can do flexible search in just one request.

For example, the following query returns two results: records that their `name` contains `Alice`, and results grouped by their `sex` column:

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "people" : {
            "source"    : "Person",
            "condition" : "name @ 'Alice'"
            "output"    : {
              "elements"   : ["count", "records"],
              "attributes" : ["name", "age"],
              "limit"      : -1
            }
          },
          "sexuality" : {
            "source"  : "people",
            "groupBy" : "sex",
            "output"  : {
              "elements"   : ["count", "records"],
              "attributes" : ["_key", "_nsubrecs"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "people" : {
             "count" : 8,
             "records" : [
               ["Alice Cooper", 30],
               ["Alice Miller", 25],
               ["Alice Arnold", 20]
             ]
           },
           "sexuality" : {
             "count" : 2,
             "records" : 
               ["female", 2],
               ["male", 1]
             ]
           }
         }
       }

You can use search queries just internally, without output. For example, the following query does: 1) group records of the Person table by their `job` column, and 2) extract grouped results which have the text `player` in their `job`. (*Note: The second query will be done without indexes, so it can be slow.)

    {
      "type" : "search",
      "body" : {
        "queries" : {
          "allJob" : {
            "source"  : "Person",
            "groupBy" : "job"
          },
          "playerJob" : {
            "source"    : "allJob",
            "condition" : "_key @ `player`",
            "output"  : {
              "elements"   : ["count", "records"],
              "attributes" : ["_key", "_nsubrecs"],
              "limit"      : -1
            }
          }
        }
      }
    }
    
    => {
         "type" : "search.result",
         "body" : {
           "playerJob" : {
             "count" : 2,
             "records" : [
               ["basketball player", 1],
               ["baseball player", 1]
             ]
           }
         }
       }


## Parameter details {#parameters}

### Container parameters {#container-parameters}

#### `timeout` {#parameter-timeout}

*Note: This parameter is not implemented yet on the version {{ site.droonga_version }}.

Abstract
: Threshold to time out for the request.

Value
: An integer in milliseconds.

Default value
: `10000` (10 seconds)

Droonga Engine will return an error response instead of a search result, if the search operation take too much time, longer than the given `timeout`.
Clients may free resources for the search operation after the timeout.

#### `queries` {#parameter-queries}

Abstract
: Search queries.

Value
: A hash. Keys of the hash are query names, values of the hash are [queries (hashes of query parameters)](#query-parameters).

Default value
: Nothing. This is a required parameter.

You can put multiple search queries in a `search` request.

On the {{ site.droonga_version }}, all search results for a request are returned in one time. In the future, as an optional behaviour, each result can be returned as separated messages progressively.

### Parameters of each query {#query-parameters}

#### `source` {#query-source}

Abstract
: A source of a search operation.

Value
: A name string of an existing table, or a name of another query.

Default value
: Nothing. This is a required parameter.

You can do a facet search, specifying a name of another search query as its source.

The order of operations is automatically resolved by Droonga itself.
You don't have to write queries in the order they should be operated in.

#### `condition` {#query-condition}

Abstract
: Conditions to search records from the given source.

Value
: Possible pattenrs:
  
  1. A [script syntax](http://groonga.org/docs/reference/grn_expr/script_syntax.html) string.
  2. A hash including [script syntax](http://groonga.org/docs/reference/grn_expr/script_syntax.html) string.
  3. A hash including [query syntax](http://groonga.org/docs/reference/grn_expr/query_syntax.html) string.
  4. An array of conditions from 1 to 3 and an operator.

Default value
: Nothing.

If no condition is given, then all records in the source will appear as the search result, for following operations and the output.

##### Search condition in a Script syntax string {#query-condition-script-syntax-string}

This is a sample condition in the script syntax:

    "name == 'Alice' && age >= 20"

It means "the value of the `name` column equals to `"Alice"`, and the value of the `age` column is `20` or more".

See [the reference document of the script syntax on Groonga](http://groonga.org/docs/reference/grn_expr/script_syntax.html) for more details.

##### Search condition in a hash based on the Script syntax {#query-condition-script-syntax-hash}

In this pattern, you'll specify a search condition as a hash based on a 
[script syntax string](#query-condition-script-syntax-string), like:

    {
      "script"      : "name == 'Alice' && age >= 20",
      "allowUpdate" : true
    }

(*Note: under construction because the specification of the `allowUpdate` parameter is not defined yet.)

##### Search condition in a hash based on the Query syntax {#query-condition-query-syntax-hash}

In this pattern, you'll specify a search condition as a hash like:

    {
      "query"                    : "Alice",
      "matchTo"                  : ["name * 2", "job * 1"],
      "defaultOperator"          : "&&",
      "allowPragma"              : true,
      "allowColumn"              : true,
      "matchEscalationThreshold" : 10
    }

`query`
: A string to specify the main search query. In most cases, a text posted via a search box in a webpage will be given.
  See [the document of the query syntax in Groonga](http://groonga.org/docs/reference/grn_expr/query_syntax.html) for more details.
  This parameter is always required.

`matchTo`
: An array of strings, meaning the list of column names to be searched by default. If you specify no column name in the `query`, it will work as a search query for columns specified by this parameter.
  You can apply weighting for each column, like `name * 2`.
  This parameter is optional.

`defaultOperator`
: A string to specify the default logical operator for multiple queries listed in the `query`. Possible values:
  
   * `"&&"` : means "AND" condition.
   * `"||"` : means "OR" condition.
   * `"-"`  : means ["NOT" condition](http://groonga.org/docs/reference/grn_expr/query_syntax.html#logical-not).
  
  This parameter is optional, the default value is `"&&"`.

`allowPragma`
: A boolean value to allow (`true`) or disallow (`false`) to use "pragma" like `*E-1`, on the head of the `query`.
  This parameter is optional, the default value is `true`.

`allowColumn`
: A boolean value to allow (`true`) or disallow (`false`) to specify column name for each query in the `query`, like `name:Alice`.
  This parameter is optional, the default value is `true`.

`matchEscalationThreshold`
: An integer to specify the threshold to escalate search methods.
  When the number of search results by indexes is smaller than this value, then Droonga does the search based on partial matching, etc.
  See also [the specification of the search behavior of Groonga](http://groonga.org/docs/spec/search.html) for more details.
  This parameter is optional, the default value is `0`.


##### Complex search condition as an array {#query-condition-array}

In this pattern, you'll specify a search condition as an array like:

    [
      "&&",
      <search condition 1>,
      <search condition 2>,
      ...
    ]

The fist element of the array is an operator string. Possible values:

 * `"&&"` : means "AND" condition.
 * `"||"` : means "OR" condition.
 * `"-"`  : means ["NOT" condition](http://groonga.org/docs/reference/grn_expr/query_syntax.html#logical-not).

Rest elements are logically operated based on the operator.
For example this is an "AND" operated condition based on two conditions, means "the value of the `name` equals to `"Alice"`, and, the value of the `age` is `20` or more":

    ["&&", "name == 'Alice'", "age >= 20"]

Nested array means more complex conditions. For example, this means "`name` equals to `"Alice"` and `age` is `20` or more, but `job` does not equal to `"engineer"`":

    [
      "-",
      ["&&", "name == 'Alice'", "age >= 20"],
      "job == 'engineer'"
    ]

#### `sortBy` {#query-sortBy}

Abstract
: Conditions for sorting and paging.

Value
: Possible patterns:
  
  1. An array of column name strings.
  2. A hash including an array of sort column name strings and paging conditions.

Default value
: Nothing.

If sort conditions are not specified, then all results will appear as-is, for following operations and the output.

##### Basic sort condition {#query-sortBy-array}

Sort condition is given as an array of column name strings.

At first Droonga tries to sort records by the value of the first given sort column. After that, if there are multiple records which have same value for the column, then Droonga tries to sort them by the secondary given sort column. These processes are repeated for all given sort columns.

You must specify sort columns as an array, even if there is only one column.

Records are sorted by the value of the column value, in an ascending order. Results can be sorted in descending order if sort column name has a prefix `-`.

For example, this condition means "sort records by the `name` at first in an ascending order, and sort them by their `age~ column in the descending order":

    ["name", "-age"]

##### Paging of sorted results {#query-sortBy-hash}

Paging conditions can be specified as a part of a sort condition hash, like:

    {
      "keys"   : [<Sort columns>],
      "offset" : <Offset of paging>,
      "limit"  : <Number of results to be extracted>
    }

`keys`
: Sort conditions same to [the basic sort condition](#query-sortBy-array).
  This parameter is always required.

`offset`
: An integer meaning the offset to the paging of sorted results. Possible values are `0` or larger integers.
  
  This parameter is optional and the default value is `0`.

`limit`
: An integer meaning the number of sorted results to be extracted. Possible values are `-1`, `0`, or larger integers. The value `-1` means "return all results".
  
  This parameter is optional and the default value is `-1`.

For example, this condition extracts 10 sorted results from 11th to 20th:

    {
      "keys"   : ["name", "-age"],
      "offset" : 10,
      "limit"  : 10
    }

In most cases, paging by a sort condition is faster than paging by `output`'s `limit` and `output`, because this operation reduces the number of records.


#### `groupBy` {#query-groupBy}

Abstract
: A condition for grouping of (sorted) search results.

Value
: Possible patterns:
  
  1. A condition string to do grouping. (a column name or an expression)
  2. A hash to specify a condition for grouping with details.

Default value
: Nothing.

If a condition for grouping is given, then grouped result records will appear as the result, for following operations and the output.

##### Basic condition of grouping {#query-groupBy-string}

A condition of grouping is given as a string of a column name or an expression.

Droonga groups (sorted) search result records, based on the value of the specified column. Then the result of the grouping will appear instead of search results from the `source`. Result records of a grouping will have following columns:

`_key`
: A value of the grouped column.

`_nsubrecs`
: An integer meaning the number of grouped records.

For example, this condition means "group records by their `job` column's value, with the number of grouped records for each value":

    "job"

##### Condition of grouping with details {#query-groupBy-hash}

A condition of grouping can include more options, like:

    {
      "key"            : "<Basic condition for grouping>",
      "maxNSubRecords" : <Number of sample records included into each grouped result>
    }

`key`
: A string meaning [a basic condition of grouping](#query-groupBy-string).
  This parameter is always required.

`maxNSubRecords`
: An integer, meaning maximum number of sample records included into each grouped result. Possible values are `0` or larger. `-1` is not acceptable.
  
  This parameter is optional, the default value is `0`.
  
  For example, this condition will return results grouped by their `job` column with one sample record per a grouped result:
  
      {
        "key"            : "job",
        "maxNSubRecords" : 1
      }
  
  Grouped results will have all columns of [the result of the basic conditions for grouping](#query-groupBy-string), and following extra columns:
  
  *Note: On the version {{ site.droonga_version }}, too many records can be returned larger than the specified `maxNSubRecords`, if the dataset has multiple partitions. This is a known problem and to be fixed in a future version.

`_subrecs`
: An array of sample records which have the value in its grouped column.


#### `output` {#query-output}

Abstract
: A output definition for a search result

Value
: A hash including information to control output format.

Default value
: Nothing.

If no `output` is given, then search results of the query won't be exported to the returned message.
You can reduce processing time and traffic via omitting of `output` for temporary tables which are used only for grouping and so on.

An output definition is given as a hash like:

    {
      "elements"   : [<Names of elements to be exported>],
      "format"     : "<Format of each record>",
      "offset"     : <Offset of paging>,
      "limit"      : <Number of records to be exported>,
      "attributes" : <Definition of columnst to be exported for each record>
    }

`elements`
: An array of strings, meaning the list of elements exported to the result of the search query in a [search response](#response).
  Possible values are following, and you must specify it as an array even if you export just one element:
  
   * `"startTime"` *Note: This will be ignored because it is not implemented on the version {{ site.droonga_version }} yet.
   * `"elapsedTime"` *Note: This will be ignored because it is not implemented on the version {{ site.droonga_version }} yet.
   * `"count"`
   * `"attributes"` *Note: This will be ignored because it is not implemented on the version {{ site.droonga_version }} yet.
   * `"records"`
  
  This parameter is optional, there is not default value. Nothing will be exported if no element is specified.

`format`
: A string meaning the format of exported each record.
  Possible values:
  
   * `"simple"`  : Each record will be exported as an array of column values.
   * `"complex"` : Each record will be exported as a hash.
  
  This parameter is optional, the default value is `"simple"`.

`offset`
: An integer meaning the offset to the paging of exported records. Possible values are `0` or larger integers.
  
  This parameter is optional and the default value is `0`.

`limit`
: An integer meaning the number of exported records. Possible values are `-1`, `0`, or larger integers. The value `-1` means "export all records".
  
  This parameter is optional and the default value is `0`.

`attributes` 
: Definition of columns to be exported for each record.
  Possible patterns:
  
   1. An array of column definitions.
   2. A hash of column definitions.
  
  Each column can be defined in one of following styles:
  
   * A name string of a column.
     * `"name"` : Exports the value of the `name` column, as is.
     * `"age"`  : Exports the value of the `age` column, as is.
   * A hash with details:
     * This exports the value of the `name` column as a column with different name `realName`.
       
           { "label" : "realName", "source" : "name" }
       
     * This exports the snippet in HTML fragment as a column with the name `html`.
       
           { "label" : "html", "source": "snippet_html(name)" }
       
     * This exports a static value `"Japan"` for the `country` column of all records.
       (This will be useful for debugging, or a use case to try modification of APIs.)
       
           { "label" : "country", "source" : "'Japan'" }
       
     * This exports a number of grouped records as the `"itemsCount"` column of each record (grouped result).
       
           { "label" : "itemsCount", "source" : "_nsubrecs", }
       
     * This exports samples of the source records of grouped records, as the `"items"` column of grouped records.
       The format of the `"attributes"` is jsut same to this section.
       
           { "label" : "items", "source" : "_subrecs",
             "attributes": ["name", "price"] }
  
  An array of column definitions can contain any type definition described above, like:
  
      [
        "name",
        "age",
        { "label" : "realName", "source" : "name" }
      ]
  
  A hash of column definitions can contain any type definition described above except `label` of hashes, because keys of the hash means `label` of each column, like:
  
      {
        "name"     : "name",
        "age"      : "age",
        "realName" : { "source" : "name" },
        "country"  : { "source" : "'Japan'" }
      }
  
  This parameter is optional, there is no default value. No column will be exported if no column is specified.


## Responses {#response}

This command returns a hash as the result as the `body`, with `200` as the `statusCode`.

Keys of the result hash is the name of each query (a result of a search query), values of the hash is the result of each [search query](#query-parameters), like:

    {
      "<Name of the query 1>" : {
        "startTime"   : "<Time to start the operation>",
        "elapsedTime" : <Elapsed time to process the query, in milliseconds),
        "count"       : <Number of records searched by the given conditions>,
        "attributes"  : <Array or hash of exported columns>,
        "records"     : [<Array of search result records>]
      },
      "<Name of the query 2>" : { ... },
      ...
    }

A hash of a search query's result can have following elements, but only some elements specified in the `elements` of the [`output` parameter](#query-output) will appear in the response.

### `startTime` {#response-query-startTime}

A local time string meaning the search operation is started.

It is formatted in the [W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats"), with the time zone like:

    2013-11-29T08:15:30+09:00

### `elapsedTime` {#response-query-elapsedTime}

An integer meaning the elapsed time of the search operation, in milliseconds.

### `count` {#response-query-count}

An integer meaning the total number of search result records.
Paging options `offset` and `limit` in [`sortBy`](#query-sortBy) or [`output`](#query-output) will not affect to this count.

### `attributes` and `records` {#response-query-attributes-and-records}

 * `attributes` is an array or a hash including information of exported columns for each record.
 * `records` is an array of search result records.

There are two possible patterns of `attributes` and `records`, based on the [`output`](#query-output)'s `format` parameter.

#### Simple format result {#response-query-simple-attributes-and-records}

A search result with `"simple"` as the value of `output`'s `format` will be returned as a hash like:

    {
      "startTime"   : "<Time to start the operation>",
      "elapsedTime" : <Elapsed time to process the query),
      "count"       : <Total number of search result records>,
      "attributes"  : [
        { "name"   : "<Name of the column 1>",
          "type"   : "<Type of the column 1>",
          "vector" : <It this column is a vector column?> },
        { "name"   : "<Name of the column 2>",
          "type"   : "<Type of the column 2>",
          "vector" : <It this column is a vector column?> },
        ...
      ],
      "records"     : [
        [<Value of the column 1 of the record 1>,
         <Value of the column 2 of the record 1>,
         ...],
        [<Value of the column 1 of the record 2>,
         <Value of the column 2 of the record 2>,
         ...],
        ...
      ]
    }

This format is designed to reduce traffic with small responses, instead of useful rich data format.
Recommended for cases when the response can include too much records, or the service can accept too much requests.

##### `attributes` {#response-query-simple-attributes}

*Note: This is not implemented on the version {{ site.droonga_version }}. This information is never exported.

An array of column informations for each exported search result, ordered by [the `output` parameter](#query-output)'s `attributes`.

Each column information is returned as a hash with following keys:

`name`
: A string meaning the name (label) of the exported column. It is just same to labels defined in [the `output` parameter](#query-output)'s `attributes`.

`type`
: A string meaning the value type of the column.
  The type is indicated as one of [Groonga's primitive data formats](http://groonga.org/docs/reference/types.html), or a name fo an existing table for referring columns.

`vector`
: A boolean value meaning it is a [vector column](http://groonga.org/docs/tutorial/data.html#vector-types) or not.
  Possible values:
  
   * `true`  : It is a vector column.
   * `false` : It is not a vector column, but a scalar column.

##### `records` {#response-query-simple-records}

An array of exported search result records.

Each record is exported as an array of column values, ordered by the [`output` parameter](#query-output)'s `attributes`.

A value of [date time type](http://groonga.org/docs/tutorial/data.html#date-and-time-type) column will be returned as a string formatted in the [W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats"), with the time zone.

#### Complex format result {#response-query-complex-attributes-and-records}

A search result with `"complex"` as the value of `output`'s `format` will be returned as a hash like:

    {
      "startTime"   : "<Time to start the operation>",
      "elapsedTime" : <Elapsed time to process the query),
      "count"       : <Total number of search result records>,
      "attributes"  : {
        "<Name of the column 1>" : { "type"   : "<Type of the column 1>",
                                     "vector" : <It this column is a vector column?> },
        "<Name of the column 2>" : { "type"   : "<Type of the column 2>",
                                     "vector" : <It this column is a vector column?> },
        ...
      ],
      "records"     : [
        { "<Name of the column 1>" : <Value of the column 1 of the record 1>,
          "<Name of the column 2>" : <Value of the column 2 of the record 1>,
          ...                                                                },
        { "<Name of the column 1>" : <Value of the column 1 of the record 1>,
          "<Name of the column 2>" : <Value of the column 2 of the record 2>,
          ...                                                                },
        ...
      ]
    }

This format is designed to keep human readability, instead of less traffic.
Recommended for small traffic cases like development, debugging, features only for administrators, and so on.

##### `attributes` {#response-query-complex-attributes}

*Note: This is not implemented on the version {{ site.droonga_version }}. This information is never exported.

A hash of column informations for each exported search result. Keys of the hash are column names defined by [the `output` parameter](#query-output)'s `attributes`, values are informations of each column.

Each column information is returned as a hash with following keys:

`type`
: A string meaning the value type of the column.
  The type is indicated as one of [Groonga's primitive data formats](http://groonga.org/docs/reference/types.html), or a name for an existing table for referring columns.

`vector`
: A boolean value meaning it is a [vector column](http://groonga.org/docs/tutorial/data.html#vector-types) or not.
  Possible values:
  
   * `true`  : It is a vector column.
   * `false` : It is not a vector column, but a scalar column.

##### `records` {#response-query-complex-records}


An array of exported search result records.

Each record is exported as a hash. Keys of the hash are column names defined by [`output` parameter](#query-output)'s `attributes`, values are column values.

A value of [date time type](http://groonga.org/docs/tutorial/data.html#date-and-time-type) column will be returned as a string formatted in the [W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats"), with the time zone.


## Error types {#errors}

This command reports errors not only [general errors](/reference/message/#error) but also followings.

### `MissingSourceParameter`

Means you've forgotten to specify the `source` parameter. The status code is `400`.

### `UnknownSource`

Means there is no existing table and no other query with the name, for a `source` of a query. The status code is `404`.

### `CyclicSource`

Means there is any circular reference of sources. The status code is `400`.

### `SearchTimeout`

Means the engine couldn't finish to process the request in the time specified as `timeout`. The status code is `500`.
