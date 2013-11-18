---
title: column_create
layout: documents_ja
---

* TOC
{:toc}

## 概要 {#abstract}

`column_create` は、テーブルにカラムを作成します。

このコマンドは[Groonga の `column_create` コマンド](http://groonga.org/ja/docs/reference/commands/column_create.html)と互換性があります。

`column_create` はRequest-Response型のコマンドです。コマンドに対しては必ず対応するレスポンスが返されます。

## 構文 {#syntax}

    {
      "table"  : "テーブル名",
      "name"   : "カラム名",
      "flags"  : "カラムの属性",
      "type"   : "値の型",
      "source" : "インデックス対象のカラム名"
    }

## パラメータ {#parameters}

`table`, `name` 以外のパラメータはすべて省略可能です。

すべてのパラメータは[Groonga の `column_create` コマンドの引数](http://groonga.org/ja/docs/reference/commands/column_create.html#parameters)と共通です。詳細はGroongaのコマンドリファレンスを参照して下さい。

## レスポンス {#response}

このコマンドは、レスポンスとしてカラムの作成の成否を示す真偽値を返却します。

 * `true`：カラムの作成に成功した。
 * `false`：カラムの作成に失敗した。

