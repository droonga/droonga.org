---
title: search
layout: documents
---

## 概要

`search` は、1つ以上のテーブルから指定された条件にマッチするレコードを検索し、見つかったレコードに関する情報を返却します。

これは、Droonga において検索機能を提供する最も低レベルのコマンドです。
検索用のコマンドをプラグインとして実装する際は、内部的にこのコマンドを使用して検索を行うという用途が想定されます。

## 構文

    {
      "timeout" : タイムアウトするまでの時間,
      "queries" : {
        "検索クエリの名前1" : {
          "source"    : "検索対象のテーブル名、または結果を参照する別の検索クエリの名前",
          "condition" : 検索条件,
          "sortBy"    : ソートの指定,
          "groupBy"   : 集約の指定,
          "output"    : {
            "elements"   : [検索結果として出力する情報の配列],
            "format"     : "検索結果のフォーマット形式",
            "offset"     : ページングの起点,
            "limit"      : 返却するレコード数,
            "attributes" : [レコードのカラムの出力指定の配列]
          }
        },
        "検索クエリの名前2" : { ... },
        ...
      }
    }

## パラメータ

### 全体のパラメータ

#### `timeout`

※註：このパラメータはバージョン 1.0 では未実装です。指定しても機能しません。

概要
: 検索処理がタイムアウトするまでの時間を指定します。

値
: タイムアウトするまでの時間の数値（単位：ミリ秒）。

指定の省略
: 可能。

省略時の初期値
: 10000（10秒）

指定した時間以内に Droonga Engine が検索の処理を完了できなかった場合、Droonga はその時点で検索処理を打ち切り、エラーを返却します。
クライアントは、この時間を過ぎた後は検索処理に関するリソースを解放して問題ありません。

#### `queries`

概要
: 検索クエリとして、検索の条件と出力の形式を指定します。

値
: 個々の検索クエリの名前をキー、[個々の検索クエリ](#query-parameters)の内容を値としたハッシュ。

指定の省略
: 不可能。

`search` は、複数の検索クエリを一度に受け取る事ができます。

バージョン 1.0 ではすべての検索クエリの結果を一度にレスポンスとして返却する動作のみ対応していますが、将来的には、それぞれの検索クエリの結果を分割して受け取る（結果が出た物からバラバラに受け取る）動作にも対応する予定です。

### 個々の検索クエリのパラメータ {#query-parameters}

#### `source`

概要
: 検索対象とするデータソースを指定します。

値
: テーブル名の文字列、または結果を参照する別の検索クエリの名前の文字列。

指定の省略
: 不可能。

別の検索クエリの処理結果をデータソースとして指定する事により、ファセット検索などを行う事ができます。

なお、その場合の各検索クエリの実行順（依存関係）は Droonga が自動的に解決します。
依存関係の順番通りに各検索クエリを並べて記述する必要はありません。

#### `condition`

概要
: 検索の条件を指定します。

値
: 以下のパターンのいずれかをとります。
  
  1. [スクリプト構文](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html)形式の文字列。
  2. [スクリプト構文](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html)形式の文字列を含むハッシュ。
  3. 詳細な検索条件のハッシュ。
  4. 1〜3および演算子の文字列の配列。 

指定の省略
: 可能。

省略時の既定値
: なし（検索しない）。

検索条件を指定した場合、検索条件に該当したすべてのレコードがその後の処理の対象となります。
検索条件を指定しなかった場合、データソースに含まれるすべてのレコードがその後の処理の対象となります。

##### スクリプト構文形式の文字列による検索条件 {#query-condition-script-syntax-string}

以下のような形式の文字列で検索条件を指定します。

    "name == 'Alice' && age >= 20"

上記の例は「 `name` カラムの値が `"Alice"` と等しく、且つ `age` カラムの値が20以上である」という意味になります。

詳細は[Groonga のスクリプト構文のリファレンス](http://groonga.org/ja/docs/reference/grn_expr/script_syntax.html)を参照して下さい。

##### スクリプト構文形式の文字列を含むハッシュによる検索条件 {#query-condition-script-syntax-hash}

[スクリプト構文形式の文字列による検索条件](#query-condition-script-syntax-string)をベースとした、以下のような形式のハッシュで検索条件を指定します。

    {
      "script"      : "name == 'Alice' && age >= 20",
      "allowUpdate" : true
    }

（詳細未稿：仕様が未確定、動作が不明、未実装のため）

##### 詳細な検索条件のハッシュによる検索条件 {#query-condition-hash}

以下のような形式のハッシュで検索条件を指定します。

    {
      "query"                    : "Alice",
      "matchTo"                  : ["name * 2", "job * 1"],
      "defaultOperator"          : "&&",
      "allowPragma"              : true,
      "allowColumn"              : true,
      "matchEscalationThreshold" : 10
    }

`query`
: クエリを文字列で指定します。
  詳細は[Groonga のクエリー構文の仕様](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html)を参照して下さい。
  このパラメータは省略できません。

`matchTo`
: 検索対象のカラムを、カラム名の文字列またはその配列で指定します。
  カラム名の後に `name * 2` のような指定を加える事で、重み付けができます。
  このパラメータは省略可能で、省略時の初期値は `"_key"` です。
  <!-- ↑要検証！ -->

`defaultOperator`
: `query` に複数のクエリが列挙されている場合の既定の論理演算の条件を指定します。
  以下のいずれかの文字列を指定します。
  
   * `"&&"` : AND条件と見なす。
   * `"||"` : OR条件と見なす。
   * `"-"`  : [論理否定](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html#logical-not)条件と見なす。
  
  このパラメータは省略可能で、省略時の初期値は `"&&"` です。

`allowPragma`
: `query` の先頭において、`*E-1` のようなプラグマの指定を許容するかどうかを真偽値で指定します。
  このパラメータは省略可能で、省略時の初期値は `true` （プラグマの指定を許容する）です。

`allowColumn`
: `query` において、カラム名を指定した `name:Alice` のような書き方を許容するかどうかを真偽値で指定します。
  このパラメータは省略可能で、省略時の初期値は `true` （カラム名の指定を許容する）です。

`matchEscalationThreshold`
: 検索方法をエスカレーションするかどうかを決定するための閾値を指定します。
  インデックスを用いた全文検索のヒット件数がこの閾値以下であった場合は、非分かち書き検索、部分一致検索へエスカレーションします。
  詳細は [Groonga の検索の仕様の説明](http://groonga.org/ja/docs/spec/search.html)を参照して下さい。
  このパラメータは省略可能で、省略時の初期値は `0` です。


##### 配列による検索条件 {#query-condition-array}

以下のような形式の配列で検索条件を指定します。

    [
      "&&",
      検索条件1,
      検索条件2,
      ...
    ]

配列の最初の要素は、論理演算子を以下のいずれかの文字列で指定します。

 * `"&&"` : AND条件と見なす。
 * `"||"` : OR条件と見なす。
 * `"-"`  : [論理否定](http://groonga.org/ja/docs/reference/grn_expr/query_syntax.html#logical-not)条件と見なす。

配列の2番目以降の要素で示された検索条件について、1番目の要素で指定した論理演算子による論理演算を行います。
例えば以下は、スクリプト構文形式の文字列による検索条件2つによるAND条件であると見なされ、「 `name` カラムの値が `"Alice"` と等しく、且つ `age` カラムの値が20以上である」という意味になります。

    ["&&", "name == 'Alice'", "age >= 20"]

配列を入れ子にする事により、より複雑な検索条件を指定する事もできます。
例えば以下は、「 `name` カラムの値が `"Alice"` と等しく、且つ `age` カラムの値が20以上であるが、 `job` カラムの値が `"engineer"` ではない」という意味になります。

    [
      "-",
      ["&&", "name == 'Alice'", "age >= 20"],
      "job == 'engineer'"
    ]

#### `sortBy`

概要
: ソートの条件および取り出すレコードの範囲を指定します。

値
: 以下のパターンのいずれかをとります。
  
  1. カラム名の文字列の配列。
  2. ソート条件と取り出すレコードの範囲を指定するハッシュ。 

指定の省略
: 可能。

省略時の既定値
: なし（ソートしない）。

レコードの範囲を指定した場合、指定に基づいてソートした結果から、さらに指定の範囲のレコードを取り出した結果がその後の処理の対象となります。

##### 基本的なソート条件の指定 {#query-sortBy-array}

ソート条件はカラム名の文字列の配列として指定します。
まず最初に指定したカラムの値でレコードをソートし、カラムの値が同じレコードが複数あった場合は2番目に指定したカラムの値でさらにソートする、という形で、すべての指定カラムの値に基づいてソートを行います。

ソート対象のカラムを1つだけ指定する場合であっても、必ず配列として指定する必要があります。

ソート順序は指定したカラムの値での昇順となります。カラム名の前に `-` を加えると降順となります。

例えば以下は、「 `name` の値で昇順にソートし、同じ値のレコードはさらに `age` の値で降順にソートする」という意味になります。

    ["name", "-age"]

##### ソート結果から取り出すレコードの範囲の指定 {#query-sortBy-hash}

ソートの指定において、以下の形式でソート結果から取り出すレコードの範囲を指定する事ができます。

    {
      "keys"   : [基本的なソート条件の指定],
      "offset" : ページングの起点,
      "limit"  : 取り出すレコード数
    }

`keys`
: ソート条件を[基本的なソート条件の指定](#query-sortBy-array)の形式で指定します。
  このパラメータは省略できません。

`offset`
: 取り出すレコードのページングの起点を示す `0` または正の整数。
  
  このパラメータは省略可能で、省略時の既定値は `0` です。

`limit`
: 取り出すレコード数を示す `-1` 、 `0` 、または正の整数。
  `-1`を指定すると、すべてのレコードを取り出します。
  
  このパラメータは省略可能で、省略時の既定値は `-1` です。

例えば以下は、ソート結果の10番目から20番目までのレコードを取り出すという意味になります。

    {
      "keys"   : ["name", "-age"],
      "offset" : 10,
      "limit"  : 10
    }

これらの指定を行った場合、取り出されたレコードのみがその後の処理の対象となります。
そのため、 `output` における `offset` および `limit` の指定よりも高速に動作します。


#### `groupBy`

概要
: 処理対象のレコードを集約する条件を指定します。

値
: 以下のパターンのいずれかをとります。
  
  1. 単純な集約条件（カラム名または式）の文字列。
  2. 複雑な集約条件を指定するハッシュ。 

指定の省略
: 可能。

省略時の既定値
: なし（集約しない）。

集約条件を指定した場合、指定に基づいてレコードを集約した結果のレコードがその後の処理の対象となります。

##### 基本的な集約条件の指定 {#query-groupBy-string}

（未稿）

##### 複雑な集約条件の指定 {#query-groupBy-hash}

（未稿）

<!--
          "groupBy": {"key": "name", "maxNSubRecords": 2},
          // a String or an Object.
          //
          // A String: column name or expression used a the group key.
          //
          // An Object: "key" value is the group key. "maxNSubRecords"
          //            value is an integer number to control the maximum number
          //            of sub-records to be stored in each grouped record.
-->

#### `output`

概要
: 処理結果の出力形式を指定します。

値
: 出力形式を指定するハッシュ。 

指定の省略
: 可能。

省略時の既定値
: なし（結果を出力しない）。

指定を省略した場合、その検索クエリの検索結果はレスポンスには出力されません。
集約操作などのために必要な中間テーブルにあたる検索結果を求めるだけの検索クエリにおいては、 `output` を省略して処理時間や転送するデータ量を減らすことができます。

`elements`
: （未稿）

<!--
            "elements": [
              "startTime",
              "elapsedTime",
              "count",
              "attributes",
              "records"
            ],
            // only the elements assigned in this array will be output.
-->

`format`
: 以下のいずれかの値（文字列）を取ります。
  
   * `"simple"`  : 単純なレコードの形式で検索結果を返却する。
   * `"complex"` : 複雑なレコードの形式で検索結果を返却する

`offset`
: 返却するレコードのページングの起点を示す `0` または正の整数。
  
  このパラメータは省略可能で、省略時の既定値は `0` です。

`limit`
: 返却するレコード数を示す `-1` 、 `0` 、または正の整数。
  `-1`を指定すると、すべてのレコードを返却します。
  
  このパラメータは省略可能で、省略時の既定値は `0` です。

`attributes`
: レコードのカラムの値についての、出力形式の指定の配列。
  （未稿）

<!--
            // The result can be sliced here
            // besides that in "sortBy" section.
            "attributes": [
              // basic
              { "label": "realName", "source": "name" },
              // shorthand
              "age", // equals to { label: "age", source: "age" }
              // function call. "source" can include groonga's built-in functions.
              { "label": "html", "source": "snippet_html(name)" },
              // literal
              { "label": "count", "source": "0" },
              { "label": "country", "source": "'Japan'" },
              // sub-record
              { "label": "specimen", "source": "_subrecs",
                "attributes": [
                  { "label": "comment", "source": "comment"}
                ]
              }
-->


## レスポンス

このコマンドは、個々の検索クエリの名前をキー、[個々の検索クエリ](#query-parameters)の処理結果を値とした、以下のようなハッシュを返却します。

    {
      "検索クエリの名前1" : {
        "startTime"   : "検索を開始した時刻",
        "elapsedTime" : 検索にかかった時間（単位：ミリ秒）,
        "count"       : 検索条件にヒットしたレコードの総数,
        "attributes"  : [返却されたレコードのカラムの情報],
        "records"     : [返却されたレコードの配列]
      },
      "検索クエリの名前2" : 検索クエリの検索結果,
      ...
    }

`attributes` および `records` の出力形式は `output` の `type` の指定に従って2通りに別れます。

### 単純な形式のレスポンス

`type` が　`"simple"` の場合のレスポンスは以下の形を取ります。

    {
      "people" : {
        "startTime"   : "2001-08-02T10:45:23.5+09:00",
        "elapsedTime" : 123.456,
        "count"       : 123,
        "attributes"  : [
          { "name" : "name", "type": "ShortText", "vector": false },
          { "name" : "age",  "type": "UInt32",    "vector": false }
        ],
        "records"     : [
          ["Alice", 10],
          ["Bob",   20]
        ]
      },
      ...
    }

（未稿）


### 複雑な形式のレスポンス

`type` が　`"complex"` の場合のレスポンスは以下の形を取ります。

    {
      "people" : {
        "startTime"   : "2001-08-02T10:45:23.5+09:00",
        "elapsedTime" : 123.456,
        "count"       : 123,
        "attributes"  : {
          "name" : { "type": "ShortText", "vector": false },
          "age"  : { "type": "UInt32",    "vector": false }
        ],
        "records"     : [
          { "name" : "Alice", "age" : 10 },
          { "name" : "Bob",   "age" : 20 }
        ]
      },
      ...
    }

（未稿）

