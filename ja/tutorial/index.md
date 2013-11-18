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

例として、たい焼き屋を検索できるデータベースシステムを作成することにします。
[groongaで高速な位置情報検索](http://www.clear-code.com/blog/2011/9/13.html) に出てくるたいやき屋データをもとに、変更を加えたデータを利用します。


## 実験用のマシンを用意する

本チュートリアルでは、 [さくらのクラウド](http://cloud.sakura.ad.jp/) に `Ubuntu Server 13.10 64bit` をセットアップし、その上に Droonga による検索システムを構築します。
Ubuntu Server のセットアップが完了し、コンソールにアクセス出来る状態になったと仮定し、以降の手順を説明していきます。

## セットアップに必要なパッケージをインストールする

Droonga をセットアップするために必要になるパッケージをインストールします。

    $ sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## Droonga Engine を構築する

Droonga Engine は、データベースを保持し、実際の検索を担当する部分です。
このセクションでは、 fluent-plugin-droonga をインストールし、検索対象となるデータを準備します。

### fluent-plugin-droonga をインストールする

    $ sudo gem install fluent-plugin-droonga

Droonga Engine を構築するのに必要なパッケージがセットアップできました。引き続き設定に移ります。


### Droonga Engine を起動するための設定ファイルを用意する

まず Droonga Engine 用のディレクトリを作成します。

    $ mkdir engine
    $ cd engine

以下の内容で `fluentd.conf` と `catalog.json` を作成します。

fluentd.conf:

    <source>
      type forward
      port 24224
    </source>
    <match taiyaki.message>
      name localhost:24224/taiyaki
      type droonga
      proxy true
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:24224/taiyaki"],
      "farms": {
        "localhost:24224/taiyaki": {
          "device": ".",
          "capacity": 10
        }
      },
      "datasets": {
        "Taiyaki": {
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
                  "localhost:24224/taiyaki.000",
                  "localhost:24224/taiyaki.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/taiyaki.002",
                  "localhost:24224/taiyaki.003"
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

この `catalog.json` では、 `Taiyaki` データセットを定義し、2組のレプリカ×2個のパーティションで構成するよう指示しています。
この例では、全てのレプリカ及びパーティションは、ローカル(一つの `fluent-plugin-droonga` の管理下)に配置します。

`catalog.json` の詳細については [catalog.json](/reference/catalog) を参照してください。

### fluent-plugin-droonga を起動する

以下のようにして fluentd-plugin-droonga を起動します。

    $ fluentd --config fluentd.conf
    2013-11-12 14:14:20 +0900 [info]: starting fluentd-0.10.40
    2013-11-12 14:14:20 +0900 [info]: reading config file path="fluentd.conf"
    2013-11-12 14:14:20 +0900 [info]: gem 'fluent-plugin-droonga' version '0.0.1'
    2013-11-12 14:14:20 +0900 [info]: gem 'fluentd' version '0.10.40'
    2013-11-12 14:14:20 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 24224
      </source>
      <match taiyaki.message>
        name localhost:24224/taiyaki
        type droonga
        proxy true
      </match>
      <match output.message>
        type stdout
      </match>
    </ROOT>
    2013-11-12 14:14:20 +0900 [info]: adding source type="forward"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="taiyaki.message" type="droonga"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="output.message" type="stdout"
    2013-11-12 14:14:20 +0900 [info]: listening fluent socket on 0.0.0.0:24224

### データベースを作成する

Dronga Engine が起動したので、データを投入しましょう。
スキーマを定義した `ddl.jsons` と、たいやき屋のデータ `shops.jsons` を用意します。

ddl.jsons:

    {"id":"ddl:0","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Shop","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
    {"id":"ddl:1","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Shop","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
    {"id":"ddl:2","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Location","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
    {"id":"ddl:3","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Location","name":"shop","flags":"COLUMN_INDEX","type":"Shop","source":"location"}}
    {"id":"ddl:4","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"ddl:5","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Term","name":"shops__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Shop","source":"_key"}}


shops.jsons:

    {"id":"shops:0","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"根津のたいやき","values":{"location":"35.720253,139.762573"}}}
    {"id":"shops:1","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼 カタオカ","values":{"location":"35.712521,139.715591"}}}
    {"id":"shops:2","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"そばたいやき空","values":{"location":"35.683712,139.659088"}}}
    {"id":"shops:3","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"車","values":{"location":"35.721516,139.706207"}}}
    {"id":"shops:4","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"広瀬屋","values":{"location":"35.714844,139.685608"}}}
    {"id":"shops:5","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"さざれ","values":{"location":"35.714653,139.685043"}}}
    {"id":"shops:6","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"おめで鯛焼き本舗錦糸町東急店","values":{"location":"35.700516,139.817154"}}}
    {"id":"shops:7","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"尾長屋 錦糸町店","values":{"location":"35.698254,139.81105"}}}
    {"id":"shops:8","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき工房白家 阿佐ヶ谷店","values":{"location":"35.705517,139.638611"}}}
    {"id":"shops:9","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき本舗 藤家 阿佐ヶ谷店","values":{"location":"35.703938,139.637115"}}}
    {"id":"shops:10","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"みよし","values":{"location":"35.644539,139.537323"}}}
    {"id":"shops:11","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"寿々屋 菓子","values":{"location":"35.628922,139.695755"}}}
    {"id":"shops:12","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き / たつみや","values":{"location":"35.665501,139.638657"}}}
    {"id":"shops:13","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き鉄次 大丸東京店","values":{"location":"35.680912,139.76857"}}}
    {"id":"shops:14","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"吾妻屋","values":{"location":"35.700817,139.647598"}}}
    {"id":"shops:15","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ほんま門","values":{"location":"35.722736,139.652573"}}}
    {"id":"shops:16","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"浪花家","values":{"location":"35.730061,139.796234"}}}
    {"id":"shops:17","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"代官山たい焼き黒鯛","values":{"location":"35.650345,139.704834"}}}
    {"id":"shops:18","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき神田達磨 八重洲店","values":{"location":"35.681461,139.770599"}}}
    {"id":"shops:19","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"柳屋 たい焼き","values":{"location":"35.685341,139.783981"}}}
    {"id":"shops:20","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き写楽","values":{"location":"35.716969,139.794846"}}}
    {"id":"shops:21","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たかね 和菓子","values":{"location":"35.698601,139.560913"}}}
    {"id":"shops:22","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き ちよだ","values":{"location":"35.642601,139.652817"}}}
    {"id":"shops:23","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ダ・カーポ","values":{"location":"35.627346,139.727356"}}}
    {"id":"shops:24","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"松島屋","values":{"location":"35.640556,139.737381"}}}
    {"id":"shops:25","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"銀座 かずや","values":{"location":"35.673508,139.760895"}}}
    {"id":"shops:26","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ふるや古賀音庵 和菓子","values":{"location":"35.680603,139.676071"}}}
    {"id":"shops:27","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"蜂の家 自由が丘本店","values":{"location":"35.608021,139.668106"}}}
    {"id":"shops:28","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"薄皮たい焼き あづきちゃん","values":{"location":"35.64151,139.673203"}}}
    {"id":"shops:29","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"横浜 くりこ庵 浅草店","values":{"location":"35.712013,139.796829"}}}
    {"id":"shops:30","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"夢ある街のたいやき屋さん戸越銀座店","values":{"location":"35.616199,139.712524"}}}
    {"id":"shops:31","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"何故屋","values":{"location":"35.609039,139.665833"}}}
    {"id":"shops:32","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"築地 さのきや","values":{"location":"35.66592,139.770721"}}}
    {"id":"shops:33","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"しげ田","values":{"location":"35.672626,139.780273"}}}
    {"id":"shops:34","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"にしみや 甘味処","values":{"location":"35.671825,139.774628"}}}
    {"id":"shops:35","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやきひいらぎ","values":{"location":"35.647701,139.711517"}}}


fluentd を起動した状態で別の端末を開き、以下のようにして `ddl.jsons` と `shops.jsons` を投入します:

    $ fluent-cat taiyaki.message < ddl.jsons
    $ fluent-cat taiyaki.message < shops.jsons


これで、たい焼きデータベースを検索するための Droonga Engine ができました。
引き続き Protocol Adapter を構築して、検索リクエストを受け付けられるようにしましょう。


## Protocol Adapter を構築する

Protocol Adapter を構築するために、 `express-droonga` を使用します。 `express-droonga` は、Node.js のパッケージです。

### express-droonga をインストールする

    $ cd ~
    $ mkdir protocol-adapter
    $ cd protocol-adapter

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
      tag: 'taiyaki',
      defaultDataset: 'Taiyaki',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

`application.js` を実行します。

    $ nodejs application.js
       info  - socket.io started


### 動作を確認

準備が整いました。 Protocol Adapter に向けて HTTP 経由でリクエストを発行し、データベースに問い合わせを行ってみましょう。まずは `Shops` テーブルの中身を取得してみます。以下のようなリクエストを用います。(`attributes=_key` を指定しているのは「検索結果に `_key` 値を含めて返してほしい」という意味です。これがないと、`records` に何も値がないレコードが返ってきてしまいます。`attributes` パラメータには `,` 区切りで複数の属性を指定することができます。`attributes=_key,location` と指定することで、緯度経度もレスポンスとして受け取ることができます)

    $ curl "http://localhost:3000/droonga/tables/Shop?attrbutes=_key"
    {
      "result": {
        "count": 36,
        "records": [
          [
            "たい焼 カタオカ"
          ],
          [
            "根津のたいやき"
          ],
          [
            "そばたいやき空"
          ],
          [
            "さざれ"
          ],
          [
            "おめで鯛焼き本舗錦糸町東急店"
          ],
          [
            "尾長屋 錦糸町店"
          ],
          [
            "たいやき本舗 藤家 阿佐ヶ谷店"
          ],
          [
            "みよし"
          ],
          [
            "たい焼き / たつみや"
          ],
          [
            "吾妻屋"
          ],
          [
            "たいやき神田達磨 八重洲店"
          ],
          [
            "車"
          ],
          [
            "広瀬屋"
          ],
          [
            "たいやき工房白家 阿佐ヶ谷店"
          ],
          [
            "寿々屋 菓子"
          ],
          [
            "たい焼き鉄次 大丸東京店"
          ],
          [
            "ほんま門"
          ],
          [
            "浪花家"
          ],
          [
            "代官山たい焼き黒鯛"
          ],
          [
            "ダ・カーポ"
          ]
        ]
      }
    }

`count` の値からデータが全部で 36 件あることがわかります。`records` に配列として検索結果が入っています。

もう少し複雑なクエリを試してみましょう。例えば、店名に「阿佐ヶ谷」を含むたいやき屋を検索します。`query` パラメータにクエリ `阿佐ヶ谷` を URL エンコードした `%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7` を、`match_to` パラメータに検索対象として `_key` を指定し、以下のようなリクエストを発行します。


    $ curl "http://localhost:3000/droonga/tables/Shop?query=%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7&match_to=_key&attributes=_key"
    {
      "result": {
        "count": 2,
        "records": [
          [
            "たいやき工房白家 阿佐ヶ谷店"
          ],
          [
            "たいやき本舗 藤家 阿佐ヶ谷店"
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
              source: 'Shop',
              output: {
                 elements: [
                   'startTime',
                   'elapsedTime',
                   'count',
                   'attributes',
                   'records'
                 ],
                 attributes: ['_key']
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
      tag: 'taiyaki',
      defaultDataset: 'Taiyaki',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

    //========== 追加箇所ここから ==========
    application.get('/', function(req, res) {
      res.sendfile(__dirname + '/index.html');
    });
    //========== 追加箇所ここまで ==========

Web ブラウザにサーバの IP アドレスを入れて、リクエストを送信してみましょう。
以降、サーバの IP アドレスが `192.0.2.1` であったとします。
`http://192.0.2.1:3000/` をリクエストすると、先の `index.html` が返されるようになります。

Webブラウザから `http://192.0.2.1:3000` を開いてみてください。以下のように検索結果が表示されれば成功です。

    "result":{"count":36,"records":[["たい焼 カタオカ"],["根津のたいやき"],["そばたいやき空"],["さざれ"],["おめで鯛焼き本舗錦糸町東急店"],["尾長屋 錦糸町店"],["たいやき本舗 藤家 阿佐ヶ谷店"],["みよし"],["たい焼き / たつみや"],["吾妻屋"],["たいやき神田達磨 八重洲店"],["車"],["広瀬屋"],["たいやき工房白家 阿佐ヶ谷店"],["寿々屋 菓子"],["たい焼き鉄次 大丸東京店"],["ほんま門"],["浪花家"],["代官山たい焼き黒鯛"],["ダ・カーポ"]]}}

Web ブラウザから Socket.IO 経由でリクエストが Protocol Adapter に送信され、それが Engine に送られ、検索結果が Protocol Adapter に返され、さらに Web ブラウザに返されます。

今度は全文検索を行ってみましょう。先ほどと同様に「阿佐ヶ谷」を店名に含むたいやき屋を検索します。`index.html` の `socket.emit()` の呼び出しを書き換え、以下の様な `index.html` を用意します。

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
              source: 'Shop',
              condition: {
                query: '阿佐ヶ谷',
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
                 attributes: ['_key']
              }
            }
          }});
        </script>
      </head>
      <body>
      </body>
    </html>

ブラウザで再度 `http://192.0.2.1:3000` を開くと、以下のような検索結果が表示されます。

    {"result":{"count":2,"records":[["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]]}}

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
