---
title: table_create
layout: documents
---

* TOC
{:toc}

## 概要 {#abstract}

`table_create` は、テーブルを作成します。

このコマンドは[Groonga の `table_create` コマンド](http://groonga.org/ja/docs/reference/commands/table_create.html)と互換性があります。

`table_create` はRequest-Response型のコマンドです。コマンドに対しては必ず対応するレスポンスが返されます。

## 構文 {#syntax}

    {
      "name"              : "テーブル名",
      "flags"             : "テーブルのフラグ",
      "key_type"          : "主キーの型",
      "value_type"        : "値の型",
      "default_tokenizer" : "デフォルトトークナイザー",
      "normalizer"        : "ノーマライザー"
    }

## パラメータ {#parameters}

`name` 以外のパラメータはすべて省略可能です。

すべてのパラメータは[Groonga の `table_create` コマンドの引数](http://groonga.org/ja/docs/reference/commands/table_create.html#parameters)と共通です。詳細はGroongaのコマンドリファレンスを参照して下さい。

## レスポンス {#response}

このコマンドは、レスポンスとしてテーブルの作成の成否を示す真偽値を返却します。

 * `true`：テーブルの作成に成功した。
 * `false`：テーブルの作成に失敗した。

