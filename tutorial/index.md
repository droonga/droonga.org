---
title: droonga チュートリアル
layout: default
---

# droonga チュートリアル

## チュートリアルのゴール

droonga を使った検索システムを自分で構築できるようになる。

## 前提条件

* [Ubuntu][] Server を自分でセットアップしたり、基本的な操作ができること
* [Ruby][] と [Node.js][] の基本的な知識があること

## 概要

### droonga とは

分散データ処理エンジンです。 "distributed-groonga" に由来します。

droonga は複数のパッケージから構成されています。ユーザは、これらのパッケージを組み合わせて利用することで、全文検索をはじめとするスケーラブルな分散データ処理システムを構築することができます。

### droonga を構成するパッケージ

#### fluent-plugin-droonga

[fluent-plugin-droonga][] は droonga における分散データ処理の要となるパッケージです。リクエストに基いて実際のデータ処理を行います。[Fluentd] のプラグインとして実装されています。

#### express-droonga

[express-droonga][] は droonga フロントエンドアプリケーションを構築する際に使うフレームワークです。
express-droonga を活用することで、スケーラブルかつリアルタイム性の高い検索アプリケーションを構築することができます。
express-droonga には、 fluent-plugin-droonga に対しリクエストを送ったり、fluend-plugin-droonga から返ってくるレスポンスを処理するなど、個別のアプリケーションに依らない、fluent-plugin-droonga を使う上で一般的な処理がまとめられています。

[Node.js][] のライブラリとして提供されており、ユーザは作成するアプリケーションに組み込んで使います。

#### groonga

[groonga] はオープンソースのカラムストア機能付き全文検索エンジンです。droonga は groonga を利用して構築されています。

## チュートリアルでつくるプロダクトの全体像

チュートリアルでは、以下の様な構成のプロダクトを構築します。

    +-------------+              +------------------+             +-----------------+
    | Web Browser |  <-------->  | droonga frontend |  <------->  | droonga backend |
    +-------------+   HTTP /     +------------------+   Fluent    +-----------------+
                      Socket.IO    w/express-droonga    protocol    w/fluent-plugin
                                                                            -droonga


                                 \--------------------------------------------------/
                                                 この部分を構築します

ユーザは droonga frontend に、Web ブラウザなどを用いて接続します。droonga frontend はユーザの操作に応じて droonga backend へリクエストを送信します。実際の検索処理は droonga backend が行います。検索結果は、droonga backend から droonga frontend に渡され、最終的にユーザに返ります。

## 実験用のマシンを用意する

本チュートリアルでは、 [さくらのクラウド](http://cloud.sakura.ad.jp/) に `Ubuntu Server 13.04 64bit` をセットアップし、その上に droonga による検索システムを構築します。
Ubuntu Server のセットアップが完了し、コンソールにアクセス出来る状態になったと仮定し、以降の手順を説明していきます。

## セットアップに必要なパッケージをインストールする

droonga をセットアップするために必要になるパッケージをインストールします。

    $ sudo apt-get install -y ruby ruby-dev build-essential

## droonga backend を構築する

droonga backend は、デーベースを保持し、実際の検索を担当する部分です。
このセクションでは、 fluent-plugin-droonga をインストールし、検索対象となるデータを準備します。

### fluent-plugin-droonga をインストールする

(fluent-plugin-droonga がリリースされるまで:)

    $ sudo apt-get install git-core

    $ git clone https://github.com/droonga/fluent-plugin-droonga.git
    $ cd fluent-plugin-droonga
    $ gem build fluent-plugin-droonga.gemspec
    $ sudo gem install fluent-plugin-droonga

(fluent-plugin-droonga がリリースされた後:)

    $ sudo gem install fluent-plugin-droonga

droonga backend を構築するのに必要なパッケージがすべてセットアップできました。引き続き backend の設定に移ります。


### groonga データベースを用意する

現在 droonga は活発に開発が進められていますが、データベースのスキーマを操作したり、データをデータベースに読み込む機能はまだ実装されていません。
ここでは、 groonga コマンドを使用して、検索対象のデータベースを直接作成します。

まず droonga backend 用のディレクトリを作成します。

    $ mkdir backend
    $ cd backend

例として、たい焼き屋を検索できるデータベースを作成しましょう。
[groongaで高速な位置情報検索](http://www.clear-code.com/blog/2011/9/13.html) に出てくるたいやき屋データをもとに、店名で全文検索ができるように変更を加えた以下のデータを利用します。

ddl.grn:

    table_create Shops TABLE_HASH_KEY ShortText
    column_create Shops location COLUMN_SCALAR WGS84GeoPoint

    table_create Locations TABLE_PAT_KEY WGS84GeoPoint
    column_create Locations shop COLUMN_INDEX Shops location

    table_create Term TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto
    column_create Term shops__key COLUMN_INDEX|WITH_POSITION Shops _key

shops.grn:

    load --table Shops
    [
    ["_key", "location"],
    ["根津のたいやき", "35.720253,139.762573"],
    ["たい焼 カタオカ", "35.712521,139.715591"],
    ["そばたいやき空", "35.683712,139.659088"],
    ["車", "35.721516,139.706207"],
    ["広瀬屋", "35.714844,139.685608"],
    ["さざれ", "35.714653,139.685043"],
    ["おめで鯛焼き本舗錦糸町東急店", "35.700516,139.817154"],
    ["尾長屋 錦糸町店", "35.698254,139.81105"],
    ["たいやき工房白家 阿佐ヶ谷店", "35.705517,139.638611"],
    ["たいやき本舗 藤家 阿佐ヶ谷店", "35.703938,139.637115"],
    ["みよし", "35.644539,139.537323"],
    ["寿々屋 菓子", "35.628922,139.695755"],
    ["たい焼き / たつみや", "35.665501,139.638657"],
    ["たい焼き鉄次 大丸東京店", "35.680912,139.76857"],
    ["吾妻屋", "35.700817,139.647598"],
    ["ほんま門", "35.722736,139.652573"],
    ["浪花家", "35.730061,139.796234"],
    ["代官山たい焼き黒鯛", "35.650345,139.704834"],
    ["たいやき神田達磨 八重洲店", "35.681461,139.770599"],
    ["柳屋 たい焼き", "35.685341,139.783981"],
    ["たい焼き写楽", "35.716969,139.794846"],
    ["たかね 和菓子", "35.698601,139.560913"],
    ["たい焼き ちよだ", "35.642601,139.652817"],
    ["ダ・カーポ", "35.627346,139.727356"],
    ["松島屋", "35.640556,139.737381"],
    ["銀座 かずや", "35.673508,139.760895"],
    ["ふるや古賀音庵 和菓子", "35.680603,139.676071"],
    ["蜂の家 自由が丘本店", "35.608021,139.668106"],
    ["薄皮たい焼き あづきちゃん", "35.64151,139.673203"],
    ["横浜 くりこ庵 浅草店", "35.712013,139.796829"],
    ["夢ある街のたいやき屋さん戸越銀座店", "35.616199,139.712524"],
    ["何故屋", "35.609039,139.665833"],
    ["築地 さのきや", "35.66592,139.770721"],
    ["しげ田", "35.672626,139.780273"],
    ["にしみや 甘味処", "35.671825,139.774628"],
    ["たいやきひいらぎ", "35.647701,139.711517"]
    ]

groonga コマンドを実行するため、groonga のあるディレクトリに PATH を設定します。
先ほど fluent-plugin-droonga をインストールした際に、rroonga(Ruby 用groonga ラッパーライブラリ)が自動的にインストールされており、
その過程で groonga がビルドされているはずです。今回はそのディレクトリに PATH を設定することにします。
`gem contents` コマンドを使って、 rroonga パッケージに含まれているファイルの中から groonga のバイナリを探します。

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

以上のように、groonga のバージョンや configure option が表示されれば成功です。


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

以下の内容で `taiyaki.conf` を作成します。

taiyaki.conf:

    <source>
      type forward
      port 24224
    </source>
    <match droonga.message>
      type droonga
      n_workers 2
      database taiyaki/db
      queue_name jobqueue24224
      handlers search
    </match>

### fluent-plugin-droonga を起動してみる

    $ fluentd --config taiyaki.conf
    2013-08-29 12:25:12 +0900 [info]: starting fluentd-0.10.36
    2013-08-29 12:25:12 +0900 [info]: reading config file path="taiyaki.conf"
    2013-08-29 12:25:12 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 23003
      </source>
      <match droonga.message>
        type droonga
        n_workers 2
        database taiyaki/db
        queue_name jobqueue23003
      </match>
    </ROOT>
    2013-08-29 12:25:12 +0900 [info]: adding source type="forward"
    2013-08-29 12:25:12 +0900 [info]: adding match pattern="droonga.message" type="droonga"
    2013-08-29 12:25:12 +0900 [info]: listening fluent socket on 0.0.0.0:24224

これで、たい焼きデータベースを検索できる droonga backend の準備ができました。
引き続き droonga frontend を構築して、検索リクエストを受け付けられるようにしましょう。


## droonga frontend を構築する

droonga frontend を構築するために、 `express-droonga` を使用します。 `express-droonga` は、Node.js のライブラリです。ユーザは、ユースケースに応じた droonga frontend を Node.js アプリケーション作成し、そのアプリケーションに `express-droonga` を組み込む形で利用します。

### nvm をインストールする

Ubuntu 13.04 標準の Node.js は、バージョンが `0.6.19` と古いため、express-droonga に必要なパッケージを利用することができません。
ここでは [nvm][] (Node Version Manager) を利用して、新しい Node.js をセットアップします。

    $ wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh
    $ source ~/.profile

### Node.js をインストールする

    $ nvm install v0.10.17
    $ nvm alias default 0.10

Node.js のバージョンを表示して、先ほどインストールした `0.10.17` であることを確認してみましょう。

    $ node --version
    v0.10.17

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
      server: server // this is required to initialize Socket.IO API!
    });

`frontend.js` を実行します。

    $ node frontend.js
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
            alert(JSON.stringify(data));
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

`socket.emit()` でクエリを送信します。クエリの処理が完了し、結果が戻ってくると、 `socket.on('search.result', ...)` のコールバックが呼ばれ、alert にその結果が表示されます。

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

    application.get('/', function(req, res) {
      res.sendfile(__dirname + '/index.html');
    });

Web ブラウザにサーバの IP アドレスを入れて、リクエストを送信してみましょう。
以降、サーバの IP アドレスが `192.0.2.1` であったとします。
`http://192.0.2.1:3000/` をリクエストすると、先の `index.html` が返されるようになります。

Webブラウザから `http://192.0.2.1:3000` を開いてみてください。以下のように検索結果が alert で表示されれば成功です。

    {"result":{"count":36,"records":[["根津のたいやき"],["たい焼 カタオカ"],["そばたいやき空"],["車"],["広瀬屋"],["さざれ"],["おめで鯛焼き本舗錦糸町東急店"],["尾長屋 錦糸町店"],["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]],"startTime":"2013-08-28T08:42:25+00:00","elapsedTime":0.0002415180206298828}}

Web ブラウザから Socket.IO 経由でリクエストが frontend に送信され、それが backend に送られ、検索結果が frontend に返され、さらに Web ブラウザに返されます。

今度は全文検索を行ってみましょう。先ほどと同様に「阿佐ヶ谷」を店名に含むたいやき屋を検索します。`index.html` の `socket.emit()` の呼び出しを書き換え、以下の様な `index.html` を用意します。

    <html>
      <head>
        <script src="/socket.io/socket.io.js"></script>
        <script>
          var socket = io.connect();
          socket.on('search.result', function (data) {
            alert(JSON.stringify(data));
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

ブラウザで再度 `http://192.0.2.1:3000` を開くと、以下のような検索結果が alert で表示されます。

    {"result":{"count":2,"records":[["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]],"startTime":"2013-08-28T09:23:14+00:00","elapsedTime":0.0030717849731445312}}

このように、Socket.IO を利用して、リクエストとレスポンスを非同期に送受信する検索クライアントを作成することができました。


## まとめ

[Ubuntu Linux][Ubuntu] 上に [droonga][] を構成するパッケージである [fluent-plugin-droonga][] と [express-droonga][] をセットアップしました。
これらのパッケージを利用して構築した frontend / backend からなるアプリケーションを用いて、実際に検索を行いました。


  [Ubuntu]: http://www.ubuntu.com/
  [droonga]: https://droonga.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
  [groonga]: http://groonga.org/
  [Ruby]: http://www.ruby-lang.org/
  [nvm]: https://github.com/creationix/nvm
  [Socket.IO]: http://socket.io/
  [Fluentd]: http://fluentd.org/
  [Node.js]: http://nodejs.org/
