---
title: Droonga チュートリアル
layout: default
---

# Droonga チュートリアル

## チュートリアルのゴール

Droonga を使った検索システムを自分で構築できるようになる。

## 前提条件

* [Ubuntu][] Server を自分でセットアップしたり、基本的な操作ができること
* [Ruby][] と [Node.js][] の基本的な知識があること

## 概要

### Droonga とは

分散データ処理エンジンです。 "distributed-groonga" に由来します。

Droonga は複数のパッケージから構成されています。ユーザは、これらのパッケージを組み合わせて利用することで、全文検索をはじめとするスケーラブルな分散データ処理システムを構築することができます。

### Droonga を構成するパッケージ

#### fluent-plugin-droonga

[fluent-plugin-droonga][] は Droonga における分散データ処理の要となるパッケージです。リクエストに基いて実際のデータ処理を行います。[Fluentd] のプラグインとして実装されています。

#### express-droonga

[express-droonga][] は Droonga フロントエンドアプリケーションを構築する際に使うフレームワークです。
express-droonga を活用することで、スケーラブルかつリアルタイム性の高い検索アプリケーションを構築することができます。
express-droonga には、 fluent-plugin-droonga に対しリクエストを送ったり、fluent-plugin-droonga から返ってくるレスポンスを処理するなど、個別のアプリケーションに依らない、fluent-plugin-droonga を使う上で一般的な処理がまとめられています。

[Node.js][] のライブラリとして提供されており、ユーザは作成するアプリケーションに組み込んで使います。

#### Groonga

[Groonga] はオープンソースのカラムストア機能付き全文検索エンジンです。Droonga は Groonga を利用して構築されています。

## チュートリアルでつくるプロダクトの全体像

チュートリアルでは、以下の様な構成のプロダクトを構築します。

    +-------------+              +------------------+             +-----------------+
    | Web Browser |  <-------->  | Droonga frontend |  <------->  | Droonga backend |
    +-------------+   HTTP /     +------------------+   Fluent    +-----------------+
                      Socket.IO    w/express-droonga    protocol    w/fluent-plugin
                                                                            -droonga


                                 \--------------------------------------------------/
                                                 この部分を構築します

ユーザは Droonga frontend に、Web ブラウザなどを用いて接続します。Droonga frontend はユーザの操作に応じて Droonga backend へリクエストを送信します。実際の検索処理は Droonga backend が行います。検索結果は、Droonga backend から Droonga frontend に渡され、最終的にユーザに返ります。

例として、たい焼き屋を検索できるデータベースを作成することにします。
[groongaで高速な位置情報検索](http://www.clear-code.com/blog/2011/9/13.html) に出てくるたいやき屋データをもとに、変更を加えたデータを利用します。


## 実験用のマシンを用意する

本チュートリアルでは、 [さくらのクラウド](http://cloud.sakura.ad.jp/) に `Ubuntu Server 13.10 64bit` をセットアップし、その上に Droonga による検索システムを構築します。
Ubuntu Server のセットアップが完了し、コンソールにアクセス出来る状態になったと仮定し、以降の手順を説明していきます。

## セットアップに必要なパッケージをインストールする

Droonga をセットアップするために必要になるパッケージをインストールします。

    $ sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## Droonga backend を構築する

Droonga backend は、データベースを保持し、実際の検索を担当する部分です。
このセクションでは、 fluent-plugin-droonga をインストールし、検索対象となるデータを準備します。

### fluent-plugin-droonga をインストールする

(fluent-plugin-droonga がリリースされるまで:)

    $ sudo apt-get install git

    $ git clone https://github.com/droonga/fluent-plugin-droonga.git
    $ cd fluent-plugin-droonga
    $ gem build fluent-plugin-droonga.gemspec
    $ sudo gem install fluent-plugin-droonga

(fluent-plugin-droonga がリリースされた後:)

    $ sudo gem install fluent-plugin-droonga

Droonga backend を構築するのに必要なパッケージがすべてセットアップできました。引き続き backend の設定に移ります。


### fluent-plugin-droonga を起動するための設定ファイルを用意する

まず Droonga backend 用のディレクトリを作成します。

    $ mkdir backend
    $ cd backend

以下の内容で `fluentd.conf` と `catalog.json` を作成します。

fluentd.conf:

    <source>
      type forward
      port 23003
    </source>
    <match taiyaki.message>
      name localhost:23003/taiyaki
      type droonga
      proxy true
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:23003/taiyaki"],
      "farms": {
        "localhost:23003/taiyaki": {
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
                  "localhost:23003/taiyaki.000",
                  "localhost:23003/taiyaki.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:23003/taiyaki.002",
                  "localhost:23003/taiyaki.003"
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

- TODO: catalog.json の説明へのリンク

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
        port 23003
      </source>
      <match taiyaki.message>
        name localhost:23003/taiyaki
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
    2013-11-12 14:14:20 +0900 [info]: listening fluent socket on 0.0.0.0:23003

### データベースを作成する

- TODO: grnコマンドからの変換のやり方があったほうがいいかも

ddl.jsons:

    {"id":"ddl:0","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:23003/output","body":{"name":"Shops","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
    {"id":"ddl:1","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:23003/output","body":{"table":"Shops","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
    {"id":"ddl:2","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:23003/output","body":{"name":"Locations","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
    {"id":"ddl:3","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:23003/output","body":{"table":"Locations","name":"shop","flags":"COLUMN_INDEX","type":"Shops","source":"location"}}
    {"id":"ddl:4","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:23003/output","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"ddl:5","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:23003/output","body":{"table":"Term","name":"shops__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Shops","source":"_key"}}


shops.jsons:
    {"id":"shops:0","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"根津のたいやき","values":{"location":"35.720253,139.762573"}}}
    {"id":"shops:1","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼 カタオカ","values":{"location":"35.712521,139.715591"}}}
    {"id":"shops:2","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"そばたいやき空","values":{"location":"35.683712,139.659088"}}}
    {"id":"shops:3","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"車","values":{"location":"35.721516,139.706207"}}}
    {"id":"shops:4","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"広瀬屋","values":{"location":"35.714844,139.685608"}}}
    {"id":"shops:5","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"さざれ","values":{"location":"35.714653,139.685043"}}}
    {"id":"shops:6","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"おめで鯛焼き本舗錦糸町東急店","values":{"location":"35.700516,139.817154"}}}
    {"id":"shops:7","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"尾長屋 錦糸町店","values":{"location":"35.698254,139.81105"}}}
    {"id":"shops:8","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき工房白家 阿佐ヶ谷店","values":{"location":"35.705517,139.638611"}}}
    {"id":"shops:9","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき本舗 藤家 阿佐ヶ谷店","values":{"location":"35.703938,139.637115"}}}
    {"id":"shops:10","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"みよし","values":{"location":"35.644539,139.537323"}}}
    {"id":"shops:11","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"寿々屋 菓子","values":{"location":"35.628922,139.695755"}}}
    {"id":"shops:12","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き / たつみや","values":{"location":"35.665501,139.638657"}}}
    {"id":"shops:13","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き鉄次 大丸東京店","values":{"location":"35.680912,139.76857"}}}
    {"id":"shops:14","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"吾妻屋","values":{"location":"35.700817,139.647598"}}}
    {"id":"shops:15","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ほんま門","values":{"location":"35.722736,139.652573"}}}
    {"id":"shops:16","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"浪花家","values":{"location":"35.730061,139.796234"}}}
    {"id":"shops:17","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"代官山たい焼き黒鯛","values":{"location":"35.650345,139.704834"}}}
    {"id":"shops:18","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき神田達磨 八重洲店","values":{"location":"35.681461,139.770599"}}}
    {"id":"shops:19","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"柳屋 たい焼き","values":{"location":"35.685341,139.783981"}}}
    {"id":"shops:20","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き写楽","values":{"location":"35.716969,139.794846"}}}
    {"id":"shops:21","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たかね 和菓子","values":{"location":"35.698601,139.560913"}}}
    {"id":"shops:22","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き ちよだ","values":{"location":"35.642601,139.652817"}}}
    {"id":"shops:23","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ダ・カーポ","values":{"location":"35.627346,139.727356"}}}
    {"id":"shops:24","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"松島屋","values":{"location":"35.640556,139.737381"}}}
    {"id":"shops:25","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"銀座 かずや","values":{"location":"35.673508,139.760895"}}}
    {"id":"shops:26","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ふるや古賀音庵 和菓子","values":{"location":"35.680603,139.676071"}}}
    {"id":"shops:27","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"蜂の家 自由が丘本店","values":{"location":"35.608021,139.668106"}}}
    {"id":"shops:28","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"薄皮たい焼き あづきちゃん","values":{"location":"35.64151,139.673203"}}}
    {"id":"shops:29","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"横浜 くりこ庵 浅草店","values":{"location":"35.712013,139.796829"}}}
    {"id":"shops:30","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"夢ある街のたいやき屋さん戸越銀座店","values":{"location":"35.616199,139.712524"}}}
    {"id":"shops:31","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"何故屋","values":{"location":"35.609039,139.665833"}}}
    {"id":"shops:32","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"築地 さのきや","values":{"location":"35.66592,139.770721"}}}
    {"id":"shops:33","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"しげ田","values":{"location":"35.672626,139.780273"}}}
    {"id":"shops:34","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"にしみや 甘味処","values":{"location":"35.671825,139.774628"}}}
    {"id":"shops:35","replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやきひいらぎ","values":{"location":"35.647701,139.711517"}}}


- TODO: groonga コマンドは使わないので削除してよい

groonga コマンドを実行するため、groonga のあるディレクトリに PATH を設定します。
先ほど fluent-plugin-droonga をインストールした際に、rroonga(Ruby 用Groonga ラッパーライブラリ)が自動的にインストールされており、
その過程で `groonga` がビルドされているはずです。今回はそのディレクトリに PATH を設定することにします。
`gem contents` コマンドを使って、 rroonga パッケージに含まれているファイルの中から `groonga` のバイナリを探します。

    $ gem contents rroonga | grep /vendor/local/bin/groonga$
    /var/lib/gems/1.9.1/gems/rroonga-3.0.5/vendor/local/bin/groonga

rroonga のバージョンなどによって表示される内容が異なるかもしれません。
今回は `/var/lib/gems/1.9.1/gems/rroonga-3.0.5/vendor/local/bin` に PATH を設定します。

    $ export PATH=/var/lib/gems/1.9.1/gems/rroonga-3.0.5/vendor/local/bin:$PATH

(必要に応じて `.profile` に追記してください)


では、PATH が正しく設定されたか確認してみます。

    $ groonga --version
    groonga 3.0.5 [linux-gnu,x86_64,utf8,match-escalation-threshold=0,nfkc,zlib,lzo,epoll]

    configure options: < '--prefix=/var/lib/gems/1.9.1/gems/rroonga-3.0.5/vendor/local' '--disable-static' '--disable-document'>

以上のように、`groonga` のバージョンや configure option が表示されれば成功です。

- TODO fluent-cat で投入する

`ddl.grn` と `shops.grn` をデータベースに読み込みます。

    $ mkdir taiyaki

    $ groonga -n taiyaki/db < ddl.grn
    [[0,1377746344.07873,0.00172567367553711],true]
    [[0,1377746344.08076,0.00132012367248535],true]
    [[0,1377746344.0823,0.00146889686584473],true]
    [[0,1377746344.08399,0.00826168060302734],true]
    [[0,1377746344.09256,0.0015711784362793],true]
    [[0,1377746344.09426,0.00776529312133789],true]

    $ groonga taiyaki/db < shops.grn
    [[0,1377746350.64192,0.00465011596679688],36]


### fluent-plugin-droonga を起動するための設定ファイルを用意する

- TODO: DB作成よりも先に起動するようにするのでここは削除

以下の内容で `taiyaki.conf` を作成します。

taiyaki.conf:

    <source>
      type forward
      port 24224
    </source>
    <match droonga.message>
      type droonga
      n_workers 0
      database taiyaki/db
      queue_name jobqueue24224
      handlers search
    </match>

### fluent-plugin-droonga を起動してみる

    2013-08-29 12:25:12 +0900 [info]: starting fluentd-0.10.36
    2013-08-29 12:25:12 +0900 [info]: reading config file path="taiyaki.conf"
    2013-08-29 12:25:12 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 24224
      </source>
      <match droonga.message>
        type droonga
        n_workers 0
        database taiyaki/db
        queue_name jobqueue24224
      </match>
    </ROOT>
    2013-08-29 12:25:12 +0900 [info]: adding source type="forward"
    2013-08-29 12:25:12 +0900 [info]: adding match pattern="droonga.message" type="droonga"
    2013-08-29 12:25:12 +0900 [info]: listening fluent socket on 0.0.0.0:24224

これで、たい焼きデータベースを検索できる Droonga backend の準備ができました。
引き続き Droonga frontend を構築して、検索リクエストを受け付けられるようにしましょう。


## Droonga frontend を構築する

Droonga frontend を構築するために、 `express-droonga` を使用します。 `express-droonga` は、Node.js のライブラリです。ユーザは、ユースケースに応じた Droonga frontend を Node.js アプリケーション作成し、そのアプリケーションに `express-droonga` を組み込む形で利用します。

### express-droonga をインストールする

    $ cd ~
    $ mkdir frontend
    $ cd frontend

以下のような `package.json` を用意します。

package.json (express-droonga がリリースされるまで):

    {
      "name": "frontend",
      "description": "frontend",
      "version": "0.0.0",
      "author": "Droonga project",
      "private": true,
      "dependencies": {
        "express": "*",
        "express-droonga": "git+https://github.com/droonga/express-droonga.git"
      }
    }

package.json (express-droonga がリリースされたあと):

    {
      "name": "frontend",
      "description": "frontend",
      "version": "0.0.0",
      "author": "Droonga project",
      "private": true,
      "dependencies": {
        "express": "*",
        "express-droonga": "*"
      }
    }

必要なパッケージをインストールします。

    $ npm install


### frontend を作成する

以下のような内容で `frontend.js` を作成します。

frontend.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag:    'droonga',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

`frontend.js` を実行します。

    $ nodejs frontend.js
       info  - socket.io started


### 動作を確認

準備が整いました。 frontend に向けて HTTP 経由でリクエストを発行し、データベースに問い合わせを行ってみましょう。まずは `Shops` テーブルの中身を取得してみます。以下のようなリクエストを用います。(`attributes=_key` を指定しているのは「検索結果に `_key` 値を含めて返してほしい」という意味です。これがないと、`records` に何も値がないレコードが返ってきてしまいます。`attributes` パラメータには `,` 区切りで複数の属性を指定することができます。`attributes=_key,location` と指定することで、緯度経度もレスポンスとして受け取ることができます)

    $ curl "http://localhost:3000/droonga/tables/Shops?attributes=_key"
    {
      "result": {
        "count": 36,
        "records": [
          [
            "根津のたいやき"
          ],
          [
            "たい焼 カタオカ"
          ],
          [
            "そばたいやき空"
          ],
          [
            "車"
          ],
          [
            "広瀬屋"
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
            "たいやき工房白家 阿佐ヶ谷店"
          ],
          [
            "たいやき本舗 藤家 阿佐ヶ谷店"
          ]
        ],
        "startTime": "2013-08-28T06:00:13+00:00",
        "elapsedTime": 0.0002779960632324219
      }
    }

`count` の値からデータが全部で 36 件あることがわかります。そのうちの 10 件が取得できました。

もう少し複雑なクエリを試してみましょう。例えば、店名に「阿佐ヶ谷」を含むたいやき屋を検索します。`query` パラメータにクエリ `阿佐ヶ谷` を URL エンコードした `%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7` を、`match_to` パラメータに検索対象として `_key` を指定し、以下のようなリクエストを発行します。

    $ curl "http://localhost:3000/droonga/tables/Shops?query=%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7&match_to=_key&attributes=_key"
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
        ],
        "startTime": "2013-08-28T06:18:08+00:00",
        "elapsedTime": 0.0005409717559814453
      }

以上 2 件が検索結果として該当することがわかりました。


### Socket.IO を用いた非同期処理

先ほど作った `frontend.js` は、実は REST API だけでなく、 [Socket.IO][] にも対応しています (`express-droonga` のおかげです)。Socket.IO 経由で frontend へリクエストを送ると、処理が完了した時点で frontend から結果を送り返してもらえます。この仕組を利用すると、クライアントアプリケーションと frontend の間でリクエストとレスポンスを別々に送り合う、非同期な通信を行うことができます。

ここでは、Webブラウザを「クライアントアプリケーション」とし、frontend との間で Socket.IO を利用して通信するアプリケーションを作成してみましょう。


`frontend` ディレクトリの下に以下の内容の `index.html` を配置します。

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
              source: 'Shops',
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
詳しくは [Message format: search feature](https://github.com/droonga/express-droonga/wiki/Message-format:-search-feature) を参照してください。
ところで、前のセクションでは、REST API を利用して検索を行いました。
REST API を利用した場合は、 `express-droonga` が内部で REST リクエストから上記の形式のメッセージへと変換し、`fluent-plugin-droonga` に送信するようになっています。

では、この `index.html` を frontend でホストできるようにするため、`frontend.js` を以下のように書き換えます。

frontend.js:

    var express = require('express'),
        droonga = require('express-droonga');

    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients

    application.droonga({
      prefix: '/droonga',
      tag:    'droonga',
      server: server // this is required to initialize Socket.IO API!
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

    {"result":{"count":36,"records":[["根津のたいやき"],["たい焼 カタオカ"],["そばたいやき空"],["車"],["広瀬屋"],["さざれ"],["おめで鯛焼き本舗錦糸町東急店"],["尾長屋 錦糸町店"],["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]],"startTime":"2013-08-28T08:42:25+00:00","elapsedTime":0.0002415180206298828}}

Web ブラウザから Socket.IO 経由でリクエストが frontend に送信され、それが backend に送られ、検索結果が frontend に返され、さらに Web ブラウザに返されます。

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
              source: 'Shops',
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

    {"result":{"count":2,"records":[["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]],"startTime":"2013-08-28T09:23:14+00:00","elapsedTime":0.0030717849731445312}}

このように、Socket.IO を利用して、リクエストとレスポンスを非同期に送受信する検索クライアントを作成することができました。


## まとめ

[Ubuntu Linux][Ubuntu] 上に [Droonga][] を構成するパッケージである [fluent-plugin-droonga][] と [express-droonga][] をセットアップしました。
これらのパッケージを利用して構築した frontend / backend からなるアプリケーションを用いて、実際に検索を行いました。


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
