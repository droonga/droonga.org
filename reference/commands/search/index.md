---
title: search
layout: documents
---

* TOC
{:toc}

## Abstract {#abstract}

The `search` command finds records from the specified table based on given conditions, and returns found records and/or related information.

This is designed as the most basic (low layer) command on Droonga, to search information from the database. When you want to add a new plugin including "search" feature, you should develop it as just a wrapper of this command, instead of developing something based on more low level technologies.

This is a request-response style command. One response message is always returned per one request.

## Syntax {#syntax}

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

This section describes how to use the `search` command, via a typical usage with following table:

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

This is the most simple example to output all records of the Person table:

    search
    {
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
    
    => search.result
       {
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

The name `people` is a temporary name for the search query and its result.
A response of a `search` command will be returned as a hash, and the keys are same to keys of the given `queries`.
So, this means: "name the search result of the query as `people`".

Why the command above returns all informations of the table? Because:

 * There is no search condition. This command matches to all records in the specified table, if no condition is specified.
 * [`output`](#query-output)'s `elements` contains `records` (and `count`) column(s). The parameter `elements` controls the returned information. Matched records are returned as `records`, the total number of matched records are returned as `count`.
 * [`output`](#query-output)'s `limit` is `-1`. The parameter `limit` controls the number of returned records, and `-1` means "return all records".
 * [`output`](#query-output)'s `attributes` contails all columns of the Person table. The parameter `attributes` controls which columns' value are returned.


#### Search conditions {#usage-condition}

Search conditions are specified via the `condition` parameter. There are two styles of search conditions: "scrypt syntax" and "query syntax". See [`condition` parameter](#query-condition) for more details.

##### Search conditions in Script syntax {#usage-condition-script-syntax}

Search conditions in script syntax are similar to ECMAScript. For example, following query means "find records that `name` contains `Alice` and `age` is larger than `25`":

    search
    {
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

    => search.result
       {
         "people" : {
           "count" : 2,
           "records" : [
             ["Alice Arnold", 20],
             ["Alice Cooper", 30],
             ["Alice Miller", 25]
           ]
         }
       }

[Script syntax is compatible to Groonga's one](http://groonga.org/docs/reference/grn_expr/script_syntax.html). See the linked document for more details.

##### Search conditions in Query syntax {#usage-condition-query-syntax}

The query syntax is mainly designed for search boxes in webpages. For example, following query means "find records that `name` or `note` contain the given word, and the word is `Alice`":

    search
    {
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
    
    => search.result
       {
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

[Query syntax is compatible to Groonga's one](http://groonga.org/docs/reference/grn_expr/query_syntax.html). See the linked document for more details.


#### Sorting of search results {#usage-sort}

Returned records can be sorted by conditions specified as the `sortBy` parameter. For example, following query means "sort results by their `age`, in ascending order":

    search
    {
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
    
    => search.result
       {
         "people" : {
           "count" : 8,
           "records" : [
             ["Alice Arnold", 20],
             ["Alice Miller", 25],
             ["Alice Cooper", 30]
           ]
         }
       }

If you add `-` before name of columns, then search results are returned in descending order. For example:

    search
    {
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
    
    => search.result
       {
         "people" : {
           "count" : 8,
           "records" : [
             ["Alice Cooper", 30],
             ["Alice Miller", 25],
             ["Alice Arnold", 20]
           ]
         }
       }

See [`sortBy` parameter](#query-sortBy) for more details.

#### Paging of search results {#usage-paging}

Search results can be retuned partially via `offset` and `limit` under the [`output`](#query-output) parameter. For example, following queries will return 20 or more search results by 10's.

    search
    {
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
    => returns 10 results from the 1st to the 10th.
    
    search
    {
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
    => returns 10 results from the 11th to the 20th.
    
    search
    {
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
    => returns 10 results from the 21th to the 30th.

The value `-1` is not recommended  for the `limit` parameter, in regular use. It will return too much results and increase traffic loads. Instead `100` or less value is recommended for the `limit` parameter. Then you should do paging by the `offset` parameter.

See [`output` parameter](#query-output) for more details.

Moreover, you can do paging via [the `sortBy` parameter](#query-sortBy-hash) and it will work faster than the paging by the `output` parameter. You should do paging via the `sortBy` parameter instead of `output` as much as possible.


#### Output format {#usage-format}

Search result records in examples above are shown as arrays of arrays, but they can be returned as arrays of hashes by the [`output`](#query-output)'s `format` parameter. If you specify `complex` for the `format`, then results are returned like:

    search
    {
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
    
    => search.result
       {
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

Search result records will be returned as an array of hashes, when you specify `complex` as the value of the `format` parameter.
Otherwise - `simple` or nothing is specified -, records are returned as an array of arrays.

See [`output` parameters](#query-output) and [responses](#response) for more details.


### Advanced usage {#usage-advanced}

#### Grouping {#usage-group}

You can group search results by a column, via the [`groupBy`](#query-groupBy) parameters. For example, following query returns a result grouped by the `sex` column, with the count of original search results:

    search
    {
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
    
    => search.result
       {
         "sexuality" : {
           "count" : 2,
           "records" : 
             ["female", 2],
             ["male", 7]
           ]
         }
       }

The result means: "There are two `female` records and seven `male` records, moreover there are two types for the column `sex`.

You can also extract the ungrouped record by the `maxNSubRecords` parameter and the `_subrecs` virtual column. For example, following query returns the result grouped by `sex` and extract two ungrouped records:

    search
    {
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
    
    => search.result
       {
         "sexuality" : {
           "count" : 2,
           "records" : 
             ["female", 2, [["Alice Arnold"], ["Alice Miller"]]],
             ["male",   7, [["Alice Cooper"], ["Bob Dole"]]]
           ]
         }
       }


See [`groupBy` parameters](#query-groupBy) for more details.

*Note: The version {{ site.droonga_version }} doesn't support grouping of search results from partitioned datasets. You should use this feature only on single partition datasets, while you are using the version {{ site.droonga_version }}.


#### Multiple search queries in one request {#usage-multiple-queries}

Multiple queries can be appear in one `search` command. For example, following query searches people yanger than 25 or older than 40:

    search
    {
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
    
    => search.result
       {
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

Each search result can be identified by the temporary name given for each query.

#### Chained search queries {#usage-chain}

You can specify not only an existing table, but search result of another query also, as the value of the "source" parameter. Chained search queries can do flexible search in just one request.

For example, the following query returns two results: records that their `name` contains `Alice`, and results grouped by their `sex` column:

    search
    {
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
    
    => search.result
       {
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

You can use search queries just internally, without output. For example, the following query does: 1) group records of the Person table by their `job` column, and 2) extract grouped results which have the text `player` in their `job`. (*Note: The second query will be done without indexes, so it can be slow.)

    search
    {
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
    
    => search.result
       {
         "playerJob" : {
           "count" : 2,
           "records" : [
             ["basketball player", 1],
             ["baseball player", 1]
           ]
         }
       }


## Parameters {#parameters}

### Container parameters {#container-parameters}

#### `timeout` {#parameter-timeout}

*Note: This parameter is not implemented yet on the version {{ site.droonga_version }}.

Abstract
: Threshold to time out for the request.

Value
: An integer in milliseconds.

Required
: No. This is optional.

Default value
: `10000` (10 seconds)

Droonga Engine will return an error response instead of a search result, if the search operation take too much time, longer than the given `timeout`.
Clients may free resources for the search operation after the timeout.

#### `queries` {#parameter-queries}

Abstract
: Search queries.

Value
: A hash. Keys of the hash are query names, values of the hash are [queries (hashes of query parameters)](#query-parameters).

Required
: Yes.

You can put multiple search queries in a `search` request.

On the {{ site.droonga_version }}, all search results for a request are returned in one time. In the future, as an optional behaviour, each result can be returned as separated messages progressively.

### Parameters of each query {#query-parameters}

#### `source` {#query-source}

Abstract
: The source of the search operation.

Value
: A name string of an existing table, or a name of another query.

Default value
: Nothing. This is a required parameter.

You can do a facet search, specifying a name of another search query as the source.

The order of operations is automatically resolved by Droonga itself.
You don't have to write queries in the order they should be operated in.

#### `condition` {#query-condition}

Abstract
: Conditions to search records from the source.

Value
: Possible pattenrs:
  
  1. A [script syntax](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html) string.
  2. A hash including [script syntax](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html) string.
  3. A hash including [query syntax](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html) string.
  4. An array of conditions from 1 to 3 and an operator.

Default value
: Nothing.

If no condition is given, then all records in the source will appear as the search result, for following operations and the output.

##### Search condition in a Script syntax string {#query-condition-script-syntax-string}

This is a sample condition in the script syntax:

    "name == 'Alice' && age >= 20"

It means "the value of the `name` column equals to `"Alice"`, and the value of the `age` column is `20` or more".

See [the reference document of the script syntax on Groonga](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html) for more details.

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
  See [the document of the query syntax in Groonga](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html) for more details.
  This parameter is always required.

`matchTo`
: An array of strings, meaning the list of column names to be searched by default. If you specify no column name in the `query`, it will work as a search query for columns specified by this parameter.
  You can apply weighting for each column, like `name * 2`.
  This parameter is optional.

`defaultOperator`
: A string to specify the default logical operator for multiple queries listed in the `query`. Possible values:
  
   * `"&&"` : means "AND" condition.
   * `"||"` : means "OR" condition.
   * `"-"`  : means ["NOT" condition](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html#logical-not).
  
  This parameter is optional, the default value is `"&&"`.

`allowPragma`
: A boolean value to allow (`true`) or disallow (`false`) to use "pragma" like `*E-1`, on the head of the `query`.
  This parameter is optional, the default value is `true`.

`allowColumn`
: A boolean value to allow (`true`) or disallog (`false`) to specify column name for each query in the `query`, like `name:Alice`.
  This parameter is optional, the default value is `true`.

`matchEscalationThreshold`
: An integer to specify the threshold to escalate search methods.
  When the number of search results by indexes is smaller than this value, then Droonga does the search based on partial matching, etc.
  See also [the specification of the search behavior of Groonga](http://groonga.org/ja/docs/spec/search.html) for more details.
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
 * `"-"`  : means ["NOT" condition](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html#logical-not).

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
: The sort and paging conditions.

Value
: Possible patterns:
  
  1. An array of column name strings.
  2. A hash including an array of sort column name strings and paging conditions.

Default value
: Nothing.

If paging conditions are not specified, then all sorted results will appear as the sort result, for following operations and the output.

##### Basic sort condition {#query-sortBy-array}

Sort condition is given as an array of column name strings.

At first Droonga tries to sort records by the value of the first given sort column. After that, if there are multiple records which have same value for the column, then Drooga tries to sort them by the secondary given sort column. These processes are repeated for all given sort columns.

You must specify sort columns as an array, even if there is only one column.

Records are sorted by the value of the column value, in an ascending order. Results can be sorted in descending order if sort column name has a prefix `-`.

For example, this condition means "sort records by the `name` at first in an ascending order, and sort them by their `age~ column in the descending order":

    ["name", "-age"]

##### Paging of sorted results {#query-sortBy-hash}

Paging conditions can be specified as a part of the hash of the sort condition, like:

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
: An integer meaning the number of sorted results to be extracted. Possible values are `-1`, `0`, or larger integers.
  
  This parameter is optional and the default value is `-1`.

For example, this condition extracts 10 sorted results from 11th to 20th:

    {
      "keys"   : ["name", "-age"],
      "offset" : 10,
      "limit"  : 10
    }

In most cases, paging in the sort condition is faster than paging by `output`'s `limit` and `output`, because this operation reduces the number of records.


#### `groupBy` {#query-groupBy}

Abstract
: 処理対象のレコード群を集約する条件を指定します。

Value
: 以下のパターンのいずれかをとります。
  
  1. 基本的な集約条件（カラム名または式）の文字列。
  2. 複雑な集約条件を指定するハッシュ。 

Default value
: なし（集約しない）。

集約条件を指定した場合、指定に基づいてレコードを集約した結果のレコードがその後の処理の対象となります。

※註：バージョン {{ site.droonga_version }} では、複数パーティションに別れたデータセットでの検索結果を集約した場合、集約結果に同一キーのレコードが複数登場することがあります（パーティションごとの集約結果のマージ処理が未実装であるため）。バージョン {{ site.droonga_version }} では、この機能はパーティション分けを伴わないデータセットでのみの利用を推奨します。

##### 基本的な集約条件の指定 {#query-groupBy-string}

基本的な集約条件では、処理対象のレコード群が持つカラムの名前を文字列として指定します。

DroongaはそのカラムのValueが同じであるレコードを集約し、カラムのValueをキーとした新しいレコード群を結果として出力します。
集約結果のレコードは以下のカラムを持ちます。

`_key`
: 集約前のレコード群における、集約対象のカラムのValueです。

`_nsubrecs`
: 集約前のレコード群における、集約対象のカラムのValueが一致するレコードの総数を示す数Valueです。

例えば以下は、`job` カラムのValueでレコードを集約し、`job` カラムのValueとしてどれだけの種類が存在しているのか、および、各 `job` のValueを持つレコードが何件存在しているのかを集約結果として取り出すという意味になります。

    "job"

##### 複雑な集約条件の指定 {#query-groupBy-hash}

集約の指定において、集約結果の一部として出力する集約前のレコードの数を、以下の形式で指定する事ができます。

    {
      "key"            : "基本的な集約条件",
      "maxNSubRecords" : 集約結果の一部として出力する集約前のレコードの数
    }

`key`
: [基本的な集約条件の指定](#query-groupBy-string)の形式による、集約条件を指定する文字列。
  このパラメータは省略できません。

`maxNSubRecords`
: 集約結果の一部として出力する集約前のレコードの最大数を示す `0` または正の整数。
  `-1` は指定できません。
  
  このパラメータは省略可能で、Default valueは `0` です。

例えば以下は、`job` カラムのValueでレコードを集約した結果について、各 `job` カラムのValueを含んでいるレコードを代表として1件ずつ取り出すという意味になります。

    {
      "key"            : "job",
      "maxNSubRecords" : 1
    }

集約結果のレコードは、[基本的な集約条件の指定](#query-groupBy-string)の集約結果のレコード群が持つすべてのカラムに加えて、以下のカラムを持ちます。

`_subrecs`
: 集約前のレコード群における、集約対象のカラムのValueが一致するレコードの配列。


#### `output` {#query-output}

Abstract
: 処理結果の出力形式を指定します。

Value
: 出力形式を指定するハッシュ。 

Default value
: なし（結果を出力しない）。

指定を省略した場合、その検索クエリの検索結果はレスポンスには出力されません。
集約操作などのために必要な中間テーブルにあたる検索結果を求めるだけの検索クエリにおいては、 `output` を省略して処理時間や転送するデータ量を減らすことができます。

出力形式は、以下の形式のハッシュで指定します。

    {
      "elements"   : [出力する情報の配列],
      "format"     : "検索結果のレコードの出力スタイル",
      "offset"     : ページングの起点,
      "limit"      : 出力するレコード数,
      "attributes" : [レコードのカラムの出力指定の配列]
    }

`elements`
: その検索クエリの結果として[レスポンス](#response)に出力する情報を、プロパティ名の文字列の配列で指定します。
  以下の項目を指定できます。項目は1つだけ指定する場合であっても必ず配列で指定します。
  
   * `"startTime"` ※バージョン {{ site.droonga_version }} では未実装です。指定しても機能しません。
   * `"elapsedTime"` ※バージョン {{ site.droonga_version }} では未実装です。指定しても機能しません。
   * `"count"`
   * `"attributes"` ※バージョン {{ site.droonga_version }} では未実装です。指定しても機能しません。
   * `"records"`
  
  このパラメータは省略可能で、省略時の初期Valueはありません（結果を何も出力しません）。

`format`
: 検索結果のレコードの出力スタイルを指定します。
  以下のいずれかのValue（文字列）を取ります。
  
   * `"simple"`  : 個々のレコードを配列として出力します。
   * `"complex"` : 個々のレコードをハッシュとして出力します。
  
  このパラメータは省略可能で、省略時の初期Valueは `"simple"` です。

`offset`
: 出力するレコードのページングの起点を示す `0` または正の整数。
  
  このパラメータは省略可能で、Default valueは `0` です。

`limit`
: 出力するレコード数を示す `-1` 、 `0` 、または正の整数。
  `-1`を指定すると、すべてのレコードを出力します。
  
  このパラメータは省略可能で、Default valueは `0` です。

`attributes`
: レコードのカラムのValueについて、出力形式を配列で指定します。
  個々のカラムのValueの出力形式は以下のいずれかで指定します。
  
   * カラム名の文字列。例は以下の通りです。
     * `"name"` : `name` カラムのValueをそのまま `name` カラムとして出力します。
     * `"age"`  : `age` カラムのValueをそのまま `age` カラムとして出力します。
   * 詳細な出力形式指定のハッシュ。例は以下の通りです。
     * 以下の例は、 `name` カラムのValueを `realName` カラムとして出力します。
       
           { "label" : "realName", "source" : "name" }
       
     * 以下の例は、 `name` カラムのValueについて、全文検索にヒットした位置を強調したHTMLコード片の文字列を `html` カラムとして出力します。
       
           { "label" : "html", "source": "snippet_html(name)" }
       
     * 以下の例は、`country` カラムについて、すべてのレコードの当該カラムのValueが文字列 `"Japan"` であるものとして出力します。
       （存在しないカラムを実際に作成する前にクライアント側の挙動を確認したい場合などに、この機能が利用できます。）
       
           { "label" : "country", "source" : "'Japan'" }
       
     * 以下の例は、集約前の元のレコードの総数を、集約後のレコードの `"itemsCount"` カラムのValueとして出力します。
       
           { "label" : "itemsCount", "source" : "_nsubrecs", }
       
     * 以下の例は、集約前の元のレコードの配列を、集約後のレコードの `"items"` カラムのValueとして出力します。
       `"attributes"` は、この項の説明と同じ形式で指定します。
       
           { "label" : "items", "source" : "_subrecs",
             "attributes": ["name", "price"] }
  
  このパラメータは省略可能で、Default valueはありません（カラムを何も出力しません）。


## レスポンス {#response}

このコマンドは、個々の検索クエリの名前をキー、[個々の検索クエリ](#query-parameters)の処理結果をValueとした、以下のようなハッシュを返却します。

    {
      "検索クエリ1の名前" : {
        "startTime"   : "検索を開始した時刻",
        "elapsedTime" : 検索にかかった時間（単位：ミリ秒）,
        "count"       : 検索条件にヒットしたレコードの総数,
        "attributes"  : [出力されたレコードのカラムの情報],
        "records"     : [出力されたレコードの配列]
      },
      "検索クエリ2の名前" : 検索クエリの検索結果,
      ...
    }

検索クエリの処理結果のハッシュは以下の項目を持つことができ、[検索クエリの `output`](#query-output) の `elements` で明示的に指定された項目のみが出力されます。

### `startTime` {#response-query-startTime}

検索を開始した時刻（ローカル時刻）の文字列です。

形式は、[W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats")のタイムゾーンを含む形式となります。
例えば以下の要領です。

    2013-11-29T08:15:30+09:00

### `elapsedTime` {#response-query-elapsedTime}

検索にかかった時間の数Value（単位：ミリ秒）です。

### `count` {#response-query-count}

検索条件に該当するレコードの総数の数Valueです。
このValueは、検索クエリの [`sortBy`](#query-sortBy) や [`output`](#query-output) における `offset` および `limit` の指定の影響を受けません。

### `attributes` および `records` {#response-query-attributes-and-records}

 * `attributes` は出力されたレコードのカラムの情報を示す配列またはハッシュです。
 * `records` は出力されたレコードの配列です。

`attributes` および `records` の出力形式は[検索クエリの `output`](#query-output) の `format` の指定に従って以下の2通りに別れます。

#### 単純な形式のレスポンス {#response-query-simple-attributes-and-records}

`format` が　`"simple"` の場合、個々の検索クエリの結果は以下の形を取ります。

    {
      "startTime"   : "検索を開始した時刻",
      "elapsedTime" : 検索にかかった時間,
      "count"       : レコードの総数,
      "attributes"  : [
        { "name"   : "カラム1の名前",
          "type"   : "カラム1の型",
          "vector" : カラム1がベクターカラムかどうか },
        { "name"   : "カラム2の名前",
          "type"   : "カラム2の型",
          "vector" : カラム2がベクターカラムかどうか },
        ...
      ],
      "records"     : [
        [レコード1のカラム1のValue, レコード1のカラム2のValue, ...],
        [レコード2のカラム1のValue, レコード2のカラム2のValue, ...],
        ...
      ]
    }

これは、受け取ったデータの扱いやすさよりも、データの転送量を小さく抑える事を優先する出力形式です。
大量のレコードを検索結果として受け取る場合や、多量のアクセスが想定される場合などに適しています。

##### `attributes` {#response-query-simple-attributes}

※註：バージョン {{ site.droonga_version }} では未実装です。この情報は実際には出力されません。
  
出力されたレコードのカラムについての情報の配列で、[検索クエリの `output`](#query-output) における `attributes` で指定された順番で個々のカラムの情報を含みます。

個々のカラムの情報はハッシュの形をとり、以下の情報を持ちます。

`name`
: カラムの出力名の文字列です。[検索クエリの `output`](#query-output) における `attributes` の指定内容に基づきます。

`type`
: カラムのValueの型を示す文字列です。
  Valueは[Groonga のプリミティブなデータ型](http://groonga.org/ja/docs/reference/types.html)の名前か、もしくはテーブル名です。

`vector`
: カラムが[ベクター型](http://groonga.org/ja/docs/tutorial/data.html#vector-types)かどうかを示す真偽Valueです。
  以下のいずれかのValueをとります。
  
   * `true`  : カラムはベクター型である。
   * `false` : カラムはベクター型ではない（スカラー型である）。

##### `records` {#response-query-simple-records}

出力されたレコードの配列です。

個々のレコードは配列の形をとり、[検索クエリの `output`](#query-output) における `attributes` で指定された各カラムのValueを同じ順番で含みます。

[日時型](http://groonga.org/ja/docs/tutorial/data.html#date-and-time-type)のカラムのValueは、[W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats")のタイムゾーンを含む形式の文字列として出力されます。


#### 複雑な形式のレスポンス {#response-query-complex-attributes-and-records}

`format` が　`"complex"` の場合、個々の検索クエリの結果は以下の形を取ります。

    {
      "startTime"   : "検索を開始した時刻",
      "elapsedTime" : 検索にかかった時間,
      "count"       : レコードの総数,
      "attributes"  : {
        "カラム1の名前" : { "type"   : "カラム1の型",
                            "vector" : カラム1がベクターカラムかどうか },
        "カラム2の名前" : { "type"   : "カラム2の型",
                            "vector" : カラム2がベクターカラムかどうか },
        ...
      ],
      "records"     : [
        { "カラム1" : "レコード1のカラム1のValue",
          "カラム2" : "レコード1のカラム2のValue",
          ...                                   },
        { "カラム1" : "レコード2のカラム1のValue",
          "カラム2" : "レコード2のカラム2のValue",
          ...                                   },
        ...
      ]
    }

これは、データの転送量を小さく抑える事よりも、受け取ったデータの扱いやすさを優先する出力形式です。
検索結果の件数が小さい事があらかじめ分かっている場合や、管理機能などのそれほど多量のアクセスが見込まれない場合などに適しています。

##### `attributes` {#response-query-complex-attributes}

※註：バージョン {{ site.droonga_version }} では未実装です。この情報は実際には出力されません。

出力されたレコードのカラムについての情報を含むハッシュで、[検索クエリの `output`](#query-output) における `attributes` で指定された出力カラム名がキー、カラムの情報がValueとなります。

個々のカラムの情報はハッシュの形をとり、以下の情報を持ちます。

`type`
: カラムのValueの型を示す文字列です。
  Valueは[Groonga のプリミティブなデータ型](http://groonga.org/ja/docs/reference/types.html)の名前か、もしくはテーブル名です。

`vector`
: カラムが[ベクター型](http://groonga.org/ja/docs/tutorial/data.html#vector-types)かどうかを示す真偽Valueです。
  以下のいずれかのValueをとります。
  
   * `true`  : カラムはベクター型である。
   * `false` : カラムはベクター型ではない（スカラー型である）。

##### `records` {#response-query-complex-records}

出力されたレコードの配列です。

個々のレコードは、[検索クエリの `output`](#query-output) における `attributes` で指定された出力カラム名をキー、カラムのValueをValueとしたハッシュとなります。

[日時型](http://groonga.org/ja/docs/tutorial/data.html#date-and-time-type)のカラムのValueは、[W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats")のタイムゾーンを含む形式の文字列として出力されます。

