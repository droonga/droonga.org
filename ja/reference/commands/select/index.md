---
title: select
layout: documents_ja
---

* TOC
{:toc}

## 概要 {#abstract}

`select` は、テーブルから指定された条件にマッチするレコードを検索し、見つかったレコードを返却します。

このコマンドは[Groonga の `select` コマンド](http://groonga.org/ja/docs/reference/commands/select.html)と互換性があります。

`select` はRequest-Response型のコマンドです。コマンドに対しては必ず対応するレスポンスが返されます。

## 構文 {#syntax}

    {
      "table"            : "テーブル名",
      "match_columns"    : "検索対象のカラム名のリストを'||'区切りで指定",
      "query"            : "検索条件",
      "filter"           : "複雑な検索条件",
      "scorer"           : "見つかったすべてのレコードに適用するgrn_expr",
      "sortby"           : "ソートキーにするカラム名のリストをカンマ(',')区切りで指定",
      "output_columns"   : "返却するカラム名のリストをカンマ(',')区切りで指定",
      "offset"           : ページングの起点,
      "limit"            : 返却するレコード数,
      "drilldown"        : "ドリルダウンするカラム名",
      "drilldown_sortby" : "ドリルダウン結果のソートキーにするカラム名のリストをカンマ(',')区切りで指定",
      "drilldown_output_columns" :
                           "ドリルダウン結果として返却するカラム名のリストをカンマ(',')区切りで指定",
      "drilldown_offset" : ドリルダウン結果のページングの起点,
      "drilldown_limit"  : 返却するドリルダウン結果のレコード数,
      "cache"            : "クエリキャッシュの指定",
      "match_escalation_threshold":
                           検索方法をエスカレーションする閾値,
      "query_flags"      : "queryパラメーターのカスタマイズ用フラグ",
      "query_expander"   : "クエリー展開用の引数"
    }

## パラメータ {#parameters}

`table` 以外のパラメータはすべて省略可能です。

また、バージョン {{ site.droonga_version }} の時点では以下のパラメータのみが動作します。
これら以外のパラメータは未実装のため無視されます。

 * `table`
 * `match_columns`
 * `query`
 * `output_columns`

すべてのパラメータの意味は[Groonga の `select` コマンドの引数](http://groonga.org/ja/docs/reference/commands/select.html#parameters)と共通です。詳細はGroongaのコマンドリファレンスを参照して下さい。


## レスポンス {#response}

このコマンドは、レスポンスとして検索結果の配列を返却します。

検索結果の配列の構造は[Groonga の `select` コマンドの返り値](http://groonga.org/ja/docs/reference/commands/select.html#id6)と共通です。詳細はGroongaのコマンドリファレンスを参照して下さい。

