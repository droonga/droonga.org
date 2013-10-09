---
title: push機能の実装方式を検討するための単体プログラム
layout: default
---

# 単体プログラムの目的

droongaのpub/sub機能については、
分散方式とのすり合わせなど検討すべき項目がいくつも残っていますが、
それ以前に、droongaの仕組みに乗っかって実際に動作する
イベントのスキャン機能(更新イベントの中からユーザが購読するクエリを検出する機能)
がどの程度の性能で動作するのか見当をつけておく必要があります。

そこでまずはdroongaに依存せず単体で動作するスキャン機能を作りました。
購読するクエリの数や種類によって、スキャン性能がどのように変化するのか調べておけば、
あとからdroongaと結合したときに、性能を予測したり最適化するのに役立ちます。

# 単体プログラム(scantest.rb)の使い方

DBを準備します。

    mkdir testdb
    groonga -n testdb/db < ddl.grn

実行します。

    ./scantest.rb testdb/db subscriptions.jsons events.jsons

# scantest.rbの説明

* 第一引数には、使用するデータベースのパスを指定します。
* 第二引数には、subscribeイベントが格納されたjsonsファイルを指定します。
* 第三引数には、scan対象となるイベントが格納されたjsonsファイルを指定します。

# イベントの形式の説明

ここで使用しているイベントの形式は、実際にdroongaで採用されるpub/subコマンドの
形式と必ずしも一致しないかも知れません。
ここでは単独で実行するテストのための都合しか考慮されていません。

## subscribeイベント

subscribeイベントは以下の要素を含むObjectです。

    user: 購読するユーザの識別子です
    route: ユーザに検出したイベントを配送するときの接続先を示す文字列です
    condition: 購読する検索条件です。以下の形式で条件を与えます。

    OR条件: ["||", 条件1, 条件2,..]
    AND条件: ["&&", 条件1, 条件2,..]
    NOT条件: ["-", 条件1, 条件2,..]

    配列の2番目以降の要素は文字列か条件のnestが指定できます。
    文字列は、更新イベントのThread.nameかComment.bodyのいずれかにマッチすれば真となります。

## 実際の動作

### subscriptions.jsonsの内容

   {"user":"user1", "route":"localhost:23003/output", "condition":["||", "aaa", "bbb"]}
   {"user":"user2", "route":"localhost:23003/output", "condition":["&&", "aaa", "bbb"]}
   {"user":"user3", "route":"localhost:23003/output", "condition":["-", "aaa", "bbb"]}

ここでは、3人のユーザがそれぞれ異なる条件を購読しています。

### events.jsonsの内容

   {"table":"Comment", "values":{"thread":"fuga/000", "body" : "abc aaa bb"}}
   {"table":"Thread", "key":"hoge/000", "values":{"name" : "abc aaa bb"}}
   {"table":"Comment", "values":{"thread":"fuga/000", "body" : "ddd eee"}}
   {"table":"Comment", "values":{"thread":"hoge/000", "body" : "fff ggg"}}

1行目は既存のスレッドへの新たな発言です。user1とuser3の購読する条件にヒットします。
2行目は新規のスレッドが立てられたイベントです。1行目と同じ条件にヒットします。
3行目は既存のスレッドへの新たな発言ですが、いずれの条件にもヒットしません。
4行目については発言内容は条件にヒットしませんが、スレッド名がヒットします。

### 期待される出力

    ["localhost:23003/output", ["user1", "user3"], {"table"=>"Comment", "values"=>{"thread"=>"fuga/000", "body"=>"abc aaa bb"}}]
    ["localhost:23003/output", ["user1", "user3"], {"table"=>"Thread", "key"=>"hoge/000","values"=>{"name"=>"abc aaa bb"}}]
    ["localhost:23003/output", ["user1", "user3"], {"table"=>"Comment", "values"=>{"thread"=>"hoge/000", "body"=>"fff ggg"}}]

route毎にまとめて出力しています。実際にpublish機能がdroongaで実装されたときに、route単位でまとめて通知するのが効率が良いのかなぁと思ってそうしています。

