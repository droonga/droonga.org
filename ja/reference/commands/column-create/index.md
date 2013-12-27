---
title: column_create
layout: documents_ja
---

* TOC
{:toc}

## 概要 {#abstract}

`column_create` は、指定したテーブルに新しいカラムを作成します。

このコマンドは[Groonga の `column_create` コマンド](http://groonga.org/ja/docs/reference/commands/column_create.html)と互換性があります。

形式
: Request-Response型。コマンドに対しては必ず対応するレスポンスが返されます。

リクエストの `type`
: `column_create`

リクエストの `body`
: パラメータのハッシュ。

レスポンスの `type`
: `column_create.result`

## パラメータの構文 {#syntax}

    {
      "table"  : "<テーブル名>",
      "name"   : "<カラム名>",
      "flags"  : "<カラムの属性>",
      "type"   : "<値の型>",
      "source" : "<インデックス対象のカラム名>"
    }

## パラメータの詳細 {#parameters}

`table`, `name` 以外のパラメータはすべて省略可能です。

すべてのパラメータは[Groonga の `column_create` コマンドの引数](http://groonga.org/ja/docs/reference/commands/column_create.html#parameters)と共通です。詳細はGroongaのコマンドリファレンスを参照して下さい。

## レスポンス {#response}

このコマンドは、レスポンスとしてコマンドの実行結果に関する情報を格納した配列を返却します。

    [
      [
        <Groongaのステータスコード>,
        <開始時刻>,
        <処理に要した時間>
      ],
      <カラムが作成されたかどうか>
    ]

このコマンドはレスポンスの `statusCode` として常に `200` を返します。これは、Groonga互換コマンドのエラー情報はGroongaのそれと同じ形で処理される必要があるためです。

レスポンスの `body` の詳細：

ステータスコード
: コマンドが正常に受け付けられたかどうかを示す整数値です。以下のいずれかの値をとります。
  
   * `0` (`Droonga::GroongaHandler::Status::SUCCESS`) : 正常に処理された。.
   * `-22` (`Droonga::GroongaHandler::Status::INVALID_ARGUMENT`) : 引数が不正である。

開始時刻
: 処理を開始した時刻を示す数値（UNIX秒）。

処理に要した時間
: 処理を開始してから完了までの間にかかった時間を示す数値。

カラムが作成されたかどうか
: カラムが作成されたかどうかを示す真偽値です。以下のいずれかの値をとります。
  
   * `true`：カラムを作成した。
   * `false`：カラムを作成しなかった。
