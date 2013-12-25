---
title: Droonga チュートリアル
layout: documents_ja
---

* TOC
{:toc}

## チュートリアルのゴール

Droonga を使った検索システムを自分で構築できるようになる。

## 前提条件

* [Ubuntu][] Server を自分でセットアップしたり、基本的な操作ができること
* [Ruby][] と [Node.js][] の基本的な知識があること

## 概要

### Droonga とは

分散データ処理エンジンです。 "distributed-groonga" に由来します。

Droonga は複数のコンポーネントから構成されています。ユーザは、これらのパッケージを組み合わせて利用することで、全文検索をはじめとするスケーラブルな分散データ処理システムを構築することができます。

### Droonga を構成するコンポーネント

#### Droonga Engine

Droonga Engine は Droonga における分散データ処理の要となるコンポーネントです。リクエストに基いて実際のデータ処理を行います。

このコンポーネントは [Fluentd] のプラグインとして実装されており、 [fluent-plugin-droonga][] パッケージとして提供されます。
[fluent-plugin-droonga][] は検索エンジンとして、オープンソースのカラムストア機能付き全文検索エンジン [Groonga][] を使用しています。

#### Protocol Adapter

Protocol Adapter は、Droonga を様々なプロトコルで利用できるようにするためのアダプタです。

このコンポーネントは [Node.js][] のパッケージとして実装されており、[express-droonga][] パッケージとして提供されます。

Droonga Engine は fluentd プロトコルで通信を行います。Protocol Adapter は、ユーザがアプリケーションを構築する際に利用しやすいよう、 Droonga Engine の機能を HTTP や Socket.IO などのインタフェースで提供します。

## チュートリアルでつくるシステムの全体像

チュートリアルでは、以下の様な構成のシステムを構築します。

    +-------------+              +------------------+             +----------------+
    | Web Browser |  <-------->  | Protocol Adapter |  <------->  | Droonga Engine |
    +-------------+   HTTP /     +------------------+   Fluent    +----------------+
                      Socket.IO   w/express-droonga     protocol   w/fluent-plugin
                                                                           -droonga


                                 \--------------------------------------------------/
                                       この部分を構築します

ユーザは Protocol Adapter に、Web ブラウザなどを用いて接続します。Protocol Adapter は Droonga Engine へリクエストを送信します。実際の検索処理は Droonga Engine が行います。検索結果は、Droonga Engine から Protocol Adapter に渡され、最終的にユーザに返ります。

例として、[ニューヨークにあるのスターバックスの店舗](http://geocommons.com/overlays/430038)を検索できるデータベースシステムを作成することにします。


## 実験用のマシンを用意する

まずコンピュータを調達しましょう。このチュートリアルでは、既存のコンピュータにDroongaによる検索システムを構築する手順を解説します。
以降の説明は基本的に、[DigitalOcean](https://www.digitalocean.com/)で `Ubuntu 13.10 x64` の仮想マシンのセットアップを完了し、コンソールにアクセスできる状態になった後を前提として進めます。

注意：Droongaが必要とするパッケージをインストールする前に、マシンが2GB以上のメモリを備えていることを確認して下さい。メモリが不足していると、ビルド時にエラーが出て、ビルドに失敗することがあります。

## セットアップに必要なパッケージをインストールする

Droonga をセットアップするために必要になるパッケージをインストールします。

    # apt-get update
    # apt-get -y upgrade
    # apt-get install -y ruby ruby-dev build-essential nodejs npm

## Droonga Engine を構築する

Droonga Engine は、データベースを保持し、実際の検索を担当する部分です。
このセクションでは、 fluent-plugin-droonga をインストールし、検索対象となるデータを準備します。

### fluent-plugin-droonga をインストールする

    # gem install fluent-plugin-droonga

Droonga Engine を構築するのに必要なパッケージがセットアップできました。引き続き設定に移ります。

### Droonga Engine を起動するための設定ファイルを用意する

まず Droonga Engine 用のディレクトリを作成します。

    # mkdir engine
    # cd engine

以下の内容で `fluentd.conf` と `catalog.json` を作成します。

fluentd.conf:

    <source>
      type forward
      port 24224
    </source>
    <match starbucks.message>
      name localhost:24224/starbucks
      type droonga
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:24224/starbucks"],
      "farms": {
        "localhost:24224/starbucks": {
          "device": ".",
          "capacity": 10
        }
      },
      "datasets": {
        "Starbucks": {
          "workers": 0,
          "plugins": ["search", "groonga", "add"],
          "number_of_replicas": 2,
          "number_of_partitions": 2,
          "partition_key": "_key",
          "date_range": "infinity",
          "ring": {
            "localhost:23041": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.000",
                  "localhost:24224/starbucks.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.002",
                  "localhost:24224/starbucks.003"
                ]
              }
            }
          }
        }
      },
      "options": {
        "plugins": ["select"]
      }
    }

この `catalog.json` では、 `Starbucks` データセットを定義し、2組のレプリカ×2個のパーティションで構成するよう指示しています。
この例では、全てのレプリカ及びパーティションは、ローカル(一つの `fluent-plugin-droonga` の管理下)に配置します。

`catalog.json` の詳細については [catalog.json](/ja/reference/catalog) を参照してください。

### fluent-plugin-droonga を起動する

以下のようにして fluentd-plugin-droonga を起動します。

    # fluentd --config fluentd.conf
    2013-11-12 14:14:20 +0900 [info]: starting fluentd-0.10.40
    2013-11-12 14:14:20 +0900 [info]: reading config file path="fluentd.conf"
    2013-11-12 14:14:20 +0900 [info]: gem 'fluent-plugin-droonga' version '0.0.1'
    2013-11-12 14:14:20 +0900 [info]: gem 'fluentd' version '0.10.40'
    2013-11-12 14:14:20 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 24224
      </source>
      <match starbucks.message>
        name localhost:24224/starbucks
        type droonga
      </match>
      <match output.message>
        type stdout
      </match>
    </ROOT>
    2013-11-12 14:14:20 +0900 [info]: adding source type="forward"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="starbucks.message" type="droonga"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="output.message" type="stdout"
    2013-11-12 14:14:20 +0900 [info]: listening fluent socket on 0.0.0.0:24224

### データベースを作成する

Dronga Engine が起動したので、データを投入しましょう。
スキーマを定義した `ddl.jsons` と、店舗のデータ `stores.jsons` を用意します。

ddl.jsons:

    {"id":"ddl:0","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Store","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
    {"id":"ddl:1","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Store","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
    {"id":"ddl:2","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Location","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
    {"id":"ddl:3","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Location","name":"store","flags":"COLUMN_INDEX","type":"Store","source":"location"}}
    {"id":"ddl:4","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"ddl:5","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Term","name":"stores__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Store","source":"_key"}}


stores.jsons:

    {"id":"stores:0","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1st Avenue & 75th St. - New York NY  (W)","values":{"location":"40.770262,-73.954798"}}}
    {"id":"stores:1","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"76th & Second - New York NY  (W)","values":{"location":"40.771056,-73.956757"}}}
    {"id":"stores:2","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2nd Ave. & 9th Street - New York NY","values":{"location":"40.729445,-73.987471"}}}
    {"id":"stores:3","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"15th & Third - New York NY  (W)","values":{"location":"40.733946,-73.9867"}}}
    {"id":"stores:4","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"41st and Broadway - New York NY  (W)","values":{"location":"40.755111,-73.986225"}}}
    {"id":"stores:5","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"84th & Third Ave - New York NY  (W)","values":{"location":"40.777485,-73.954979"}}}
    {"id":"stores:6","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"150 E. 42nd Street - New York NY  (W)","values":{"location":"40.750784,-73.975582"}}}
    {"id":"stores:7","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"West 43rd and Broadway - New York NY  (W)","values":{"location":"40.756197,-73.985624"}}}
    {"id":"stores:8","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 35th Street Balcony - New York NY","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:9","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 6th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:10","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Herald Square- Macy's - New York NY","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:11","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 5th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:12","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"80th & York - New York NY  (W)","values":{"location":"40.772204,-73.949862"}}}
    {"id":"stores:13","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Columbus @ 67th - New York NY  (W)","values":{"location":"40.774009,-73.981472"}}}
    {"id":"stores:14","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"45th & Broadway - New York NY  (W)","values":{"location":"40.75766,-73.985719"}}}
    {"id":"stores:15","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Marriott Marquis - Lobby - New York NY","values":{"location":"40.759123,-73.984927"}}}
    {"id":"stores:16","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Second @ 81st - New York NY  (W)","values":{"location":"40.77466,-73.954447"}}}
    {"id":"stores:17","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"52nd & Seventh - New York NY  (W)","values":{"location":"40.761829,-73.981141"}}}
    {"id":"stores:18","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1585 Broadway (47th) - New York NY  (W)","values":{"location":"40.759806,-73.985066"}}}
    {"id":"stores:19","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"85th & First - New York NY  (W)","values":{"location":"40.776101,-73.949971"}}}
    {"id":"stores:20","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"92nd & 3rd - New York NY  (W)","values":{"location":"40.782606,-73.951235"}}}
    {"id":"stores:21","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"165 Broadway - 1 Liberty - New York NY  (W)","values":{"location":"40.709727,-74.011395"}}}
    {"id":"stores:22","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1656 Broadway - New York NY  (W)","values":{"location":"40.762434,-73.983364"}}}
    {"id":"stores:23","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"54th & Broadway - New York NY  (W)","values":{"location":"40.764275,-73.982361"}}}
    {"id":"stores:24","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Limited Brands-NYC - New York NY","values":{"location":"40.765219,-73.982025"}}}
    {"id":"stores:25","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"19th & 8th - New York NY  (W)","values":{"location":"40.743218,-74.000605"}}}
    {"id":"stores:26","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"60th & Broadway-II - New York NY  (W)","values":{"location":"40.769196,-73.982576"}}}
    {"id":"stores:27","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"63rd & Broadway - New York NY  (W)","values":{"location":"40.771376,-73.982709"}}}
    {"id":"stores:28","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"195 Broadway - New York NY  (W)","values":{"location":"40.710703,-74.009485"}}}
    {"id":"stores:29","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Broadway - New York NY  (W)","values":{"location":"40.704538,-74.01324"}}}
    {"id":"stores:30","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Columbus Ave. - New York NY  (W)","values":{"location":"40.769262,-73.984764"}}}
    {"id":"stores:31","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"NY Plaza - New York NY  (W)","values":{"location":"40.702802,-74.012784"}}}
    {"id":"stores:32","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"36th and Madison - New York NY  (W)","values":{"location":"40.748917,-73.982683"}}}
    {"id":"stores:33","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"125th St. btwn Adam Clayton & FDB - New York NY","values":{"location":"40.808952,-73.948229"}}}
    {"id":"stores:34","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"70th & Broadway - New York NY  (W)","values":{"location":"40.777463,-73.982237"}}}
    {"id":"stores:35","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2138 Broadway - New York NY  (W)","values":{"location":"40.781078,-73.981167"}}}
    {"id":"stores:36","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"118th & Frederick Douglas Blvd. - New York NY  (W)","values":{"location":"40.806176,-73.954109"}}}
    {"id":"stores:37","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"42nd & Second - New York NY  (W)","values":{"location":"40.750069,-73.973393"}}}
    {"id":"stores:38","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Broadway @ 81st - New York NY  (W)","values":{"location":"40.784972,-73.978987"}}}
    {"id":"stores:39","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Fashion Inst of Technology - New York NY","values":{"location":"40.746948,-73.994557"}}}


fluentd を起動した状態で別の端末を開き、以下のようにして `ddl.jsons` と `stores.jsons` を投入します:

    # fluent-cat starbucks.message < ddl.jsons
    # fluent-cat starbucks.message < stores.jsons


これで、スターバックスの店舗のデータベースを検索するための Droonga Engine ができました。
引き続き Protocol Adapter を構築して、検索リクエストを受け付けられるようにしましょう。


## Protocol Adapter を構築する

Protocol Adapter を構築するために、 `express-droonga` を使用します。 `express-droonga` は、Node.js のパッケージです。

### express-droonga をインストールする

    # cd ~
    # mkdir protocol-adapter
    # cd protocol-adapter

以下のような `package.json` を用意します。

package.json:

    {
      "name": "protocol-adapter",
      "description": "Droonga Protocol Adapter",
      "version": "0.0.0",
      "author": "Droonga Project",
      "private": true,
      "dependencies": {
        "express": "*",
        "express-droonga": "*"
      }
    }

必要なパッケージをインストールします。

    $ npm install


### Protocol Adapter を作成する

以下のような内容で `application.js` を作成します。

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'starbucks',
      defaultDataset: 'Starbucks',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

`application.js` を実行します。

    # nodejs application.js
       info  - socket.io started


### HTTPでの同期的な検索のリクエスト

準備が整いました。 Protocol Adapter に向けて HTTP 経由でリクエストを発行し、データベースに問い合わせを行ってみましょう。まずは `Shops` テーブルの中身を取得してみます。以下のようなリクエストを用います。(`attributes=_key` を指定しているのは「検索結果に `_key` 値を含めて返してほしい」という意味です。これがないと、`records` に何も値がないレコードが返ってきてしまいます。`attributes` パラメータには `,` 区切りで複数の属性を指定することができます。`attributes=_key,location` と指定することで、緯度経度もレスポンスとして受け取ることができます)

    # curl "http://localhost:3000/droonga/tables/Store?attributes=_key&limit=-1"
    {
      "result": {
        "count": 40,
        "records": [
          [
            "76th & Second - New York NY  (W)"
          ],
          [
            "15th & Third - New York NY  (W)"
          ],
          [
            "41st and Broadway - New York NY  (W)"
          ],
          [
            "West 43rd and Broadway - New York NY  (W)"
          ],
          [
            "Macy's 6th Floor - Herald Square - New York NY  (W)"
          ],
          [
            "Herald Square- Macy's - New York NY"
          ],
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "45th & Broadway - New York NY  (W)"
          ],
          [
            "1585 Broadway (47th) - New York NY  (W)"
          ],
          [
            "85th & First - New York NY  (W)"
          ],
          [
            "92nd & 3rd - New York NY  (W)"
          ],
          [
            "1656 Broadway - New York NY  (W)"
          ],
          [
            "19th & 8th - New York NY  (W)"
          ],
          [
            "60th & Broadway-II - New York NY  (W)"
          ],
          [
            "195 Broadway - New York NY  (W)"
          ],
          [
            "2 Broadway - New York NY  (W)"
          ],
          [
            "NY Plaza - New York NY  (W)"
          ],
          [
            "36th and Madison - New York NY  (W)"
          ],
          [
            "125th St. btwn Adam Clayton & FDB - New York NY"
          ],
          [
            "2138 Broadway - New York NY  (W)"
          ],
          [
            "118th & Frederick Douglas Blvd. - New York NY  (W)"
          ],
          [
            "42nd & Second - New York NY  (W)"
          ],
          [
            "1st Avenue & 75th St. - New York NY  (W)"
          ],
          [
            "2nd Ave. & 9th Street - New York NY"
          ],
          [
            "84th & Third Ave - New York NY  (W)"
          ],
          [
            "150 E. 42nd Street - New York NY  (W)"
          ],
          [
            "Macy's 35th Street Balcony - New York NY"
          ],
          [
            "Macy's 5th Floor - Herald Square - New York NY  (W)"
          ],
          [
            "80th & York - New York NY  (W)"
          ],
          [
            "Marriott Marquis - Lobby - New York NY"
          ],
          [
            "Second @ 81st - New York NY  (W)"
          ],
          [
            "52nd & Seventh - New York NY  (W)"
          ],
          [
            "165 Broadway - 1 Liberty - New York NY  (W)"
          ],
          [
            "54th & Broadway - New York NY  (W)"
          ],
          [
            "Limited Brands-NYC - New York NY"
          ],
          [
            "63rd & Broadway - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ],
          [
            "70th & Broadway - New York NY  (W)"
          ],
          [
            "Broadway @ 81st - New York NY  (W)"
          ],
          [
            "Fashion Inst of Technology - New York NY"
          ]
        ]
      }
    }

`count` の値からデータが全部で 36 件あることがわかります。`records` に配列として検索結果が入っています。

もう少し複雑なクエリを試してみましょう。例えば、店名に「Columbus」を含む店舗を検索します。`query` パラメータにクエリ `Columbus` を、`match_to` パラメータに検索対象として `_key` を指定し、以下のようなリクエストを発行します。

    # curl "http://localhost:3000/droonga/tables/Store?query=Columbus&match_to=_key&attributes=_key&limit=-1"
    {
      "result": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }

以上 2 件が検索結果として該当することがわかりました。


### Socket.IO を用いた非同期処理

Droonga の Protocol Adapter は、 REST API だけでなく、 [Socket.IO][] にも対応しています。Socket.IO 経由で Protocol Adapter へリクエストを送ると、処理が完了した時点で Protocol Adapter から結果を送り返してもらえます。この仕組を利用すると、クライアントアプリケーションと Droonga の間でリクエストとレスポンスを別々に送り合う、非同期な通信を行うことができます。

ここでは、Webブラウザを「クライアントアプリケーション」とし、Protocol Adapter との間で Socket.IO を利用して通信するアプリケーションを作成してみましょう。

Protocol Adapter から `index.html` を配信し、Webブラウザに渡すことにしましょう。
`protocol-adapter` ディレクトリの下に以下の内容の `index.html` を配置します。

index.html:

    <html>
      <head>
        <script src="/socket.io/socket.io.js"></script>
        <script>
          var socket = io.connect();
          socket.on('search.result', function (data) {
            document.body.textContent += JSON.stringify(data);
          });
          socket.emit('search', { queries: {
            result: {
              source: 'Store',
              output: {
                 elements: [
                   'startTime',
                   'elapsedTime',
                   'count',
                   'attributes',
                   'records'
                 ],
                 attributes: ['_key'],
                 limit: -1
              }
            }
          }});
        </script>
      </head>
      <body>
      </body>
    </html>

`socket.emit()` でクエリを送信します。クエリの処理が完了し、結果が戻ってくると、 `socket.on('search.result', ...)` のコールバックが呼ばれ、ページ内にその結果が表示されます。

`socket.emit()` の第1引数 `'search'` は、このリクエストが検索リクエストであることを指定しています。
第2引数でどのような検索を行うかを指定しています。
詳しくは [search](/ja/reference/commands/search) を参照してください。
ところで、前のセクションでは、REST API を利用して検索を行いました。
REST API を利用した場合は、 `express-droonga` が内部で REST リクエストから上記の形式のメッセージへと変換し、`fluent-plugin-droonga` に送信するようになっています。

では、この `index.html` を Protocol Adapter でホストできるようにするため、`application.js` を以下のように書き換えます。

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'starbucks',
      defaultDataset: 'Starbucks',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

    //============== INSERTED ==============
    application.get('/', function(req, res) {
      res.sendfile(__dirname + '/index.html');
    });
    //============= /INSERTED ==============

Web ブラウザにサーバの IP アドレスを入れて、リクエストを送信してみましょう。
以降、サーバの IP アドレスが `192.0.2.1` であったとします。
`http://192.0.2.1:3000/` をリクエストすると、先の `index.html` が返されるようになります。
Webブラウザから `http://192.0.2.1:3000` を開いてみてください。以下のように検索結果が表示されれば成功です。

    {"result":{"count":40,"records":[["76th & Second - New York NY (W)"],["15th & Third - New York NY (W)"],["41st and Broadway - New York NY (W)"],["West 43rd and Broadway - New York NY (W)"],["Macy's 6th Floor - Herald Square - New York NY (W)"],["Herald Square- Macy's - New York NY"],["Columbus @ 67th - New York NY (W)"],["45th & Broadway - New York NY (W)"],["1585 Broadway (47th) - New York NY (W)"],["85th & First - New York NY (W)"],["92nd & 3rd - New York NY (W)"],["1656 Broadway - New York NY (W)"],["19th & 8th - New York NY (W)"],["60th & Broadway-II - New York NY (W)"],["195 Broadway - New York NY (W)"],["2 Broadway - New York NY (W)"],["NY Plaza - New York NY (W)"],["36th and Madison - New York NY (W)"],["125th St. btwn Adam Clayton & FDB - New York NY"],["2138 Broadway - New York NY (W)"],["118th & Frederick Douglas Blvd. - New York NY (W)"],["42nd & Second - New York NY (W)"],["1st Avenue & 75th St. - New York NY (W)"],["2nd Ave. & 9th Street - New York NY"],["84th & Third Ave - New York NY (W)"],["150 E. 42nd Street - New York NY (W)"],["Macy's 35th Street Balcony - New York NY"],["Macy's 5th Floor - Herald Square - New York NY (W)"],["80th & York - New York NY (W)"],["Marriott Marquis - Lobby - New York NY"],["Second @ 81st - New York NY (W)"],["52nd & Seventh - New York NY (W)"],["165 Broadway - 1 Liberty - New York NY (W)"],["54th & Broadway - New York NY (W)"],["Limited Brands-NYC - New York NY"],["63rd & Broadway - New York NY (W)"],["2 Columbus Ave. - New York NY (W)"],["70th & Broadway - New York NY (W)"],["Broadway @ 81st - New York NY (W)"],["Fashion Inst of Technology - New York NY"]]}}

Web ブラウザから Socket.IO 経由でリクエストが Protocol Adapter に送信され、それが Engine に送られ、検索結果が Protocol Adapter に返され、さらに Web ブラウザに返されます。

今度は全文検索を行ってみましょう。先ほどと同様に「Columbus」を店名に含む店舗を検索します。`index.html` の `socket.emit()` の呼び出しを書き換え、以下の様な `index.html` を用意します。

    <html>
      <head>
        <script src="/socket.io/socket.io.js"></script>
        <script>
          var socket = io.connect();
          socket.on('search.result', function (data) {
            document.body.textContent += JSON.stringify(data);
          });
          socket.emit('search', { queries: {
            result: {
              source: 'Store',
              condition: {
                query: 'Columbus',
                matchTo: '_key'
              },
              output: {
                 elements: [
                   'startTime',
                   'elapsedTime',
                   'count',
                   'attributes',
                   'records'
                 ],
                 attributes: ['_key'],
                 limit: -1
              }
            }
          }});
        </script>
      </head>
      <body>
      </body>
    </html>

ブラウザで再度 `http://192.0.2.1:3000` を開くと、以下のような検索結果が表示されます。

    {"result":{"count":2,"records":[["Columbus @ 67th - New York NY (W)"],["2 Columbus Ave. - New York NY (W)"]]}}

このように、Socket.IO を利用して、リクエストとレスポンスを非同期に送受信する検索クライアントを作成することができました。


## まとめ

[Ubuntu Linux][Ubuntu] 上に [Droonga][] を構成するパッケージである [fluent-plugin-droonga][] と [express-droonga][] をセットアップしました。
これらのパッケージを利用することで、Protocol Adapter と Droonga Engine からなるシステムを構築し、実際に検索を行いました。

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
  [Groonga]: http://groonga.org/
  [Ruby]: http://www.ruby-lang.org/
  [nvm]: https://github.com/creationix/nvm
  [Socket.IO]: http://socket.io/
  [Fluentd]: http://fluentd.org/
  [Node.js]: http://nodejs.org/
