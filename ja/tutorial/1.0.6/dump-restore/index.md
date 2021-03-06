---
title: "Droongaチュートリアル: データベースのバックアップと復元"
layout: ja
---

{% comment %}
##############################################
  THIS FILE IS AUTOMATICALLY GENERATED FROM
  "_po/ja/tutorial/1.0.6/dump-restore/index.po"
  DO NOT EDIT THIS FILE MANUALLY!
##############################################
{% endcomment %}


* TOC
{:toc}

## チュートリアルのゴール

データのバックアップと復元を手動で行う際の手順を学ぶこと。

## 前提条件

* 何らかのデータが格納されている状態の[Droonga][]クラスタがあること。
  このチュートリアルを始める前に、[「使ってみる」のチュートリアル](../groonga/)を完了しておいて下さい。

このチュートリアルでは、[1つ前のチュートリアル](../groonga/)で準備した2つの既存のDroongaノード：`node0` (`192.168.100.50`) 、 `node1` (`192.168.100.51`) と、作業環境として使うもう1台のコンピュータ `node2` (`192.168.100.52`) があると仮定します。
あなたの手元にあるDroongaノードがこれとは異なる名前である場合には、以下の説明の中の`node0`、`node1`、`node2`は実際の物に読み替えて下さい。

## Droongaクラスタのデータをバックアップする

### `drndump` のインストール

最初に、Rubygems経由で `drndump` と名付けられたコマンドラインツールをインストールします:

~~~
# gem install drndump
~~~

その後、`drndump` コマンドが正しくインストールできたかどうかを確認します:

~~~
$ drndump --version
drndump 1.0.0
~~~

### Droongaクラスタ内のデータをダンプする

`drndump` コマンドはすべてのスキ−マ定義とデータをJSONs形式で取り出します。既存のDroongaクラスタのすべての内容をダンプ出力してみましょう。

例えば、クラスタが `node0` (`192.168.100.50`) と `node1` (`192.168.100.51`) の2つのノードから構成されていて、別のホスト `node2` (`192.168.100.52`) にログインしている場合、コマンドラインは以下の要領です。

~~~
# drndump --host=node0 \
           --receiver-host=node2
{
  "type": "table_create",
  "dataset": "Default",
  "body": {
    "name": "Location",
    "flags": "TABLE_PAT_KEY",
    "key_type": "WGS84GeoPoint"
  }
}
...
{
  "dataset": "Default",
  "body": {
    "table": "Store",
    "key": "store9",
    "values": {
      "location": "146702531x-266363233",
      "name": "Macy's 6th Floor - Herald Square - New York NY  (W)"
    }
  },
  "type": "add"
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Location",
    "name": "store",
    "type": "Store",
    "flags": "COLUMN_INDEX",
    "source": "location"
  }
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Term",
    "name": "store_name",
    "type": "Store",
    "flags": "COLUMN_INDEX|WITH_POSITION",
    "source": "name"
  }
}
~~~

以下の点に注意して下さい:

 * `--host` オプションには、クラスタ内のいずれかのノードの正しいホスト名またはIPアドレスを指定します。
 * `--receiver-host` オプションには、今操作しているコンピュータ自身の正しいホスト名またはIPアドレスを指定します。
   この情報は、Droongaクラスタがメッセージを送り返すために使われます。
 * コマンドの実行結果は、ダンプ出力元と同じ内容のデータセットを構築するのに必要なすべての情報を含んでいます。

実行結果は標準出力に出力されます。
結果をJSONs形式のファイルに保存する場合は、リダイレクトを使って以下のようにして下さい:

~~~
$ drndump --host=node0 \
          --receiver-host=node2 \
    > dump.jsons
~~~


## Droongaクラスタのデータを復元する

### `droonga-client`のインストール

`drndump` コマンドの実行結果は、Droonga用のメッセージの一覧です。

Droongaクラスタにそれらのメッセージを送信するには、`droonga-send` コマンドを使います。
このコマンドを含んでいるGemパッケージ `droonga-client` をインストールして下さい:

~~~
# gem install droonga-client
~~~

`droonga-send` コマンドが正しくインストールされた事を確認しましょう:

~~~
$ droonga-send --version
droonga-send 0.1.9
~~~

### 空のDroongaクラスタを用意する

2つのノード `node0` (`192.168.100.50`) と `node1` (`192.168.100.51`) からなる空のクラスタがあり、今 `node2` (`192.168.100.52`) にログインして操作を行っていて、ダンプファイルが `dump.jsons` という名前で手元にあると仮定します。

もし順番にこのチュートリアルを読み進めているのであれば、クラスタとダンプファイルが既に手元にあるはずです。以下の操作でクラスタを空にしましょう:

~~~
$ endpoint="http://node0:10041"
$ curl "$endpoint/d/table_remove?name=Location" | jq "."
[
  [
    0,
    1406610703.2229023,
    0.0010793209075927734
  ],
  true
]
$ curl "$endpoint/d/table_remove?name=Store" | jq "."
[
  [
    0,
    1406610708.2757723,
    0.006396293640136719
  ],
  true
]
$ curl "$endpoint/d/table_remove?name=Term" | jq "."
[
  [
    0,
    1406610712.379644,
    6.723403930664062e-05
  ],
  true
]
~~~

これでクラスタは空になりました。確かめてみましょう:

~~~
$ curl "$endpoint/d/table_list?_=$(date +%s)" | jq "."
[
  [
    0,
    1406610804.1535122,
    0.0002875328063964844
  ],
  [
    [
      [
        "id",
        "UInt32"
      ],
      [
        "name",
        "ShortText"
      ],
      [
        "path",
        "ShortText"
      ],
      [
        "flags",
        "ShortText"
      ],
      [
        "domain",
        "ShortText"
      ],
      [
        "range",
        "ShortText"
      ],
      [
        "default_tokenizer",
        "ShortText"
      ],
      [
        "normalizer",
        "ShortText"
      ]
    ]
  ]
]
$ curl "$endpoint/d/select?table=Store&output_columns=name&limit=10&_=$(date +%s)" | jq "."
[
  [
    0,
    1401363465.610241,
    0
  ],
  [
    [
      [
        null
      ],
      []
    ]
  ]
]
~~~

注意: レスポンスキャッシュを無視するために、追加のパラメータとして `_=$(date +%s)` を加えていることに注意して下さい。
これを忘れると、古い設定に基づく異キャッシュされたレスポンス（期待に反した内容）を目にしてしまうことになるでしょう。

### ダンプ結果から空のDroongaクラスタへデータを復元する

`drndump` の実行結果はダンプ出力元と同じ内容のデータセットを作るために必要な情報をすべて含んでいます。そのため、クラスタが壊れた場合でも、ダンプファイルからクラスタを再構築する事ができます。
やり方は単純で、単にダンプファイルを `droonga-send` コマンドを使ってからのクラスタに流し込むだけです。

ダンプファイルからクラスタの内容を復元するには、以下のようなコマンドを実行します:

~~~
$ droonga-send --server=node0  \
                    dump.jsons
~~~

注意:

 * `--host` オプションには、クラスタ内のいずれかのノードの正しいホスト名またはIPアドレスを指定します。

これで、データが完全に復元されました。確かめてみましょう:

~~~
$ curl "$endpoint/d/select?table=Store&output_columns=name&limit=10&_=$(date +%s)" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
  ],
  [
    [
      [
        40
      ],
      [
        [
          "name",
          "ShortText"
        ]
      ],
      [
        "1st Avenue & 75th St. - New York NY  (W)"
      ],
      [
        "76th & Second - New York NY  (W)"
      ],
      [
        "Herald Square- Macy's - New York NY"
      ],
      [
        "Macy's 5th Floor - Herald Square - New York NY  (W)"
      ],
      [
        "80th & York - New York NY  (W)"
      ],
      [
        "Columbus @ 67th - New York NY  (W)"
      ],
      [
        "45th & Broadway - New York NY  (W)"
      ],
      [
        "Marriott Marquis - Lobby - New York NY"
      ],
      [
        "Second @ 81st - New York NY  (W)"
      ],
      [
        "52nd & Seventh - New York NY  (W)"
      ]
    ]
  ]
]
~~~

古いレスポンスキャッシュを無視するために、各リクエストに追加の一意なパラメータを加えていることに注意して下さい。

## 既存のクラスタを別の空のクラスタに直接複製する

複数のDroongaクラスタが存在する場合、片方のクラスタの内容をもう片方のクラスタに複製することができます。
`droonga-engine` パッケージは `droonga-engine-absorb-data` というユーティリティコマンドを含んでおり、これを使うと、既存のクラスタから別のクラスタへ直接データをコピーする事ができます。ローカルにダンプファイルを保存する必要がない場合には、この方法がおすすめです。

### 複数のDroongaクラスタを用意する

ノード `node0` (`192.168.100.50`) を含む複製元クラスタと、ノード `node1' (`192.168.100.51`) を含む複製先クラスタの2つのクラスタがあると仮定します。

もし順番にこのチュートリアルを読み進めているのであれば、2つのノードを含むクラスタが手元にあるはずです。`droonga-engine-catalog-modify` を使って2つのクラスタを作り、1つを空にしましょう。手順は以下の通りです:

~~~
(on node0)
# droonga-engine-catalog-modify --replica-hosts=node0
~~~

~~~
(on node1)
# droonga-engine-catalog-modify --replica-hosts=node1
$ endpoint="http://node1:10041"
$ curl "$endpoint/d/table_remove?name=Location&_=$(date +%s)"
$ curl "$endpoint/d/table_remove?name=Store&_=$(date +%s)"
$ curl "$endpoint/d/table_remove?name=Term&_=$(date +%s)"
~~~

これで、ノード `node0` を含む複製元クラスタと、ノード `node1` を含む複製先の空のクラスタの、2つのクラスタができました。確かめてみましょう:


~~~
$ curl "http://node0:10041/droonga/system/status?_=$(date +%s)" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    }
  }
}
$ curl "http://node0:10041/d/select?table=Store&output_columns=name&limit=10&_=$(date +%s)" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
  ],
  [
    [
      [
        40
      ],
      [
        [
          "name",
          "ShortText"
        ]
      ],
      [
        "1st Avenue & 75th St. - New York NY  (W)"
      ],
      [
        "76th & Second - New York NY  (W)"
      ],
      [
        "Herald Square- Macy's - New York NY"
      ],
      [
        "Macy's 5th Floor - Herald Square - New York NY  (W)"
      ],
      [
        "80th & York - New York NY  (W)"
      ],
      [
        "Columbus @ 67th - New York NY  (W)"
      ],
      [
        "45th & Broadway - New York NY  (W)"
      ],
      [
        "Marriott Marquis - Lobby - New York NY"
      ],
      [
        "Second @ 81st - New York NY  (W)"
      ],
      [
        "52nd & Seventh - New York NY  (W)"
      ]
    ]
  ]
]
$ curl "http://node1:10041/droonga/system/status?_=$(date +%s)" | jq "."
{
  "nodes": {
    "node1:10031/droonga": {
      "live": true
    }
  }
}
$ curl "http://node1:10041/d/select?table=Store&output_columns=name&limit=10&_=$(date +%s)" | jq "."
[
  [
    0,
    1401363465.610241,
    0
  ],
  [
    [
      [
        null
      ],
      []
    ]
  ]
]
~~~

古いレスポンスキャッシュを無視するために、各リクエストに追加の一意なパラメータを加えていることに注意して下さい。


### 2つのDroongaクラスタの間でデータを複製する

2つのクラスタの間でデータをコピーするには、いずれかのノード上で以下のように `droonga-engine-absorb-data` コマンドを実行します:

~~~
(on node0 or node1)
$ droonga-engine-absorb-data --source-host=node0 \
                             --destination-host=node1
Start to absorb data from node0
                       to node1
  dataset = Default
  port    = 10031
  tag     = droonga

Absorbing...
...
Done.
~~~

以上の操作で、2つのクラスタの内容が完全に同期されました。確かめてみましょう:

~~~
$ curl "http://node1:10041/d/select?table=Store&output_columns=name&limit=10&_=$(date +%s)" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
  ],
  [
    [
      [
        40
      ],
      [
        [
          "name",
          "ShortText"
        ]
      ],
      [
        "1st Avenue & 75th St. - New York NY  (W)"
      ],
      [
        "76th & Second - New York NY  (W)"
      ],
      [
        "Herald Square- Macy's - New York NY"
      ],
      [
        "Macy's 5th Floor - Herald Square - New York NY  (W)"
      ],
      [
        "80th & York - New York NY  (W)"
      ],
      [
        "Columbus @ 67th - New York NY  (W)"
      ],
      [
        "45th & Broadway - New York NY  (W)"
      ],
      [
        "Marriott Marquis - Lobby - New York NY"
      ],
      [
        "Second @ 81st - New York NY  (W)"
      ],
      [
        "52nd & Seventh - New York NY  (W)"
      ]
    ]
  ]
]
~~~

古いレスポンスキャッシュを無視するために、各リクエストに追加の一意なパラメータを加えていることに注意して下さい。

### 2つのDroongaクラスタを結合する

これらの2つのクラスタを結合するために、以下のコマンド列を実行しましょう:

~~~
(on node0)
# droonga-engine-catalog-modify --add-replica-hosts=node1
~~~

~~~
(on node1)
# droonga-engine-catalog-modify --add-replica-hosts=node0
~~~

これで、1つだけクラスタがある状態になりました。最初の状態に戻ったという事になります。

~~~
$ curl "http://node0:10041/droonga/system/status?_=$(date +%s)" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
~~~

古いレスポンスキャッシュを無視するために、各リクエストに追加の一意なパラメータを加えていることに注意して下さい。

## まとめ

このチュートリアルでは、[Droonga][]クラスタのバックアップとデータの復元の方法を実践しました。
また、既存のDroongaクラスタの内容を別の空のクラスタへ複製する方法も実践しました。

続いて、[既存のDroongaクラスタに新しいreplicaを追加する手順](../add-replica/)を学びましょう。

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
