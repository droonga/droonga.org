# droonga チュートリアル

!! WORK IN PROGRESS !!

## チュートリアルのゴール

droonga を使った検索システムを自分で構築できるようになる。

## 前提条件

* Ubuntu Linux 上で基本的な操作ができること
* [Vagrant][vagrant] がマシンにインストールされており、基本的な操作ができること
* Ruby と Node.js の基本的な知識があること

## 概要

### droonga とは

### droonga を構成するコンポーネント

#### fluent-plugin-droonga

#### express-droonga

#### groonga

## チュートリアルでつくるプロダクトの概要

TODO: ブロック図があるとよいとおもう

## 実験用のVMを用意する

    $ vagrant init precise64 http://files.vagrantup.com/precise64.box

TODO: config.vm.customize ["modifyvm", :id, "--memory", 2048] を指定する

    $ vagrant up

    $ vagrant ssh

## droonga backend を構築する

TODO: backendって何

TODO: fluent-plugin-droonga は Ruby を利用しているので、Ruby を準備します。なるべく新しい Ruby を維持できるように rbenv と ruby-build を使います。的なこと。


### 必要なパッケージをインストール


Ruby をビルドするにあたって、 git-core と build-essential のパッケージが必要になりますので、インストールしておきます。

    $ sudo apt-get install -y git-core build-essential

### rbenv と ruby-build をセットアップする

rbenv を [ドキュメント][rbenv] にしたがってセットアップします。

    $ git clone https://github.com/sstephenson/rbenv.git .rbenv
    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    $ exec $SHELL -l

ruby-build も [ドキュメント][ruby-build] にしたがってインストールします。

    $ git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

### Ruby をビルドする

rbenv と ruby-build がセットアップできたので、これらを使って [Ruby][ruby] を build します。

    vagrant@precise64:~$ rbenv install 2.0.0-p247

このバージョンの Ruby をデフォルトで使用するように設定しましょう。

    vagrant@precise64:~$ rbenv global 2.0.0-p247

Ruby のバージョンを表示して、先ほどインストールした `2.0.0p247` であることを確認してみましょう。

    vagrant@precise64:~$ ruby --version
    ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]

確かに、先ほどインストールしたバージョンの Ruby が使われていることがわかりました。


### fluent-plugin-droonga をインストールする

    $ git clone https://github.com/droonga/fluent-plugin-droonga.git
    $ cd fluent-plugin-droonga
    $ gem build fluent-plugin-droonga.gemspec
    $ gem install fluent-plugin-droonga
    $ rbenv rehash

(fluent-plugin-droonga がリリースされた後:)

    $ gem install fluent-plugin-droonga
    $ rbenv rehash

droonga backend を構築するのに必要なパッケージがセットアップできたので、引き続き backend の設定に移ります。


### groonga データベースを用意する

TODO: なぜこの手順が必要なの？

    $ mkdir backend
    $ cd backend
    $ mkdir taiyaki

例として、たい焼き屋を検索できるデータベースを作成しましょう。
[groongaで高速な位置情報検索](http://www.clear-code.com/blog/2011/9/13.html) に出てくるたいやき屋データをもとに、店名で全文検索ができるように変更を加えた以下のデータを利用します。

ddl.grn:

    table_create Shops TABLE_HASH_KEY ShortText
    column_create Shops location COLUMN_SCALAR WGS84GeoPoint

    table_create Locations TABLE_PAT_KEY WGS84GeoPoint
    column_create Locations shop COLUMN_INDEX Shops location

    table_create Term TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto
    column_create Term shops__key COLUMN_INDEX|WITH_POSITION Shops _key

shop.ddl:

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

TODO: groonga の実行形式にパスを通すなどする (apt で groonga 入れた方がいいかも)

ddl.grn と shops.grn をデータベースに読み込みます。

    $ groonga -n taiyaki/db < ddl.grn
    $ groonga taiyaki/db < shops.grn


### fluent-plugin-droonga を起動するための設定ファイルを用意する

以下の内容で `taiyaki.conf` を作成します。

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


### fluent-plugin-droonga を起動してみる

    vagrant@precise64:~/backend$ fluentd --config taiyaki.conf
    2013-08-21 05:33:14 +0000 [info]: starting fluentd-0.10.36
    2013-08-21 05:33:14 +0000 [info]: reading config file path="taiyaki.conf"
    2013-08-21 05:33:14 +0000 [info]: using configuration file: <ROOT>
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
    2013-08-21 05:33:14 +0000 [info]: adding source type="forward"
    2013-08-21 05:33:14 +0000 [info]: adding match pattern="droonga.message" type="droonga"

これで、たい焼きデータベースを検索できる droonga backend の準備ができました。
引き続き droonga frontend を構築して、検索リクエストを受け付けられるようにしましょう。


## droonga frontend を構築する


### nvm をインストールする

    $ wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh
    $ source ~/.bash_profile

### Node.js をインストールする

    $ nvm install 0.10.16
    $ nvm alias default 0.10

Node.js のバージョンを表示して、先ほどインストールした `0.10.16` であることを確認してみましょう。

    vagrant@precise64:~$ node --version
    v0.10.16

### express-droonga をインストールする

    $ cd ~
    $ mkdir frontend
    $ cd frontend

以下のような `package.json` を用意します。

    {
      "name": "frontend",
      "description": "frontend",
      "version": "0.0.0",
      "author": "Droonga project",
      "dependencies": {
        "express": "*",
        "express-droonga": "git+https://github.com/droonga/express-droonga.git"
      }
    }

(express-droonga がリリースされたあと:)

    {
      "name": "frontend",
      "description": "frontend",
      "version": "0.0.0",
      "author": "Droonga project",
      "dependencies": {
        "express": "*",
        "express-droonga": "*"
      }
    }

パッケージをインストールします。

    $ npm install


### frontend を作成する

以下のような内容で frontend.js を作成します。

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

frontend.js を実行します。

    vagrant@precise64:~/frontend$ node frontend.js
       info  - socket.io started


### 動作を確認

準備が整いました。 frontend に向けて HTTP 経由でリクエストを発行し、データベースに問い合わせを行ってみましょう。まずは `Shops` テーブルの中身を取得してみます。以下のようなリクエストを用います。(`attributes=_key` を指定しているのは「検索結果に `_key` 値を含めて返してほしい」という意味です。これが無いと、`records` に何も値がないレコードが返ってきてしまいます。`attributes=_key,location` と指定することで、緯度経度もレスポンスとして受け取ることができます)

    vagrant@precise64:~$ curl "http://localhost:3000/droonga/tables/Shops?attributes=_key"
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

もう少し複雑なクエリを試してみましょう。例えば、店名に「阿佐ヶ谷」を含むたいやき屋を検索します。`query` パラメータにクエリ `阿佐ヶ谷` を、`match_to` パラメータに検索対象として `_key` を指定し、以下のようなリクエストを発行します。

    vagrant@precise64:~$ curl "http://localhost:3000/droonga/tables/Shops?query=%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7&match_to=_key&attributes=_key"
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


  [droonga]: https://droonga.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
  [groonga]: http://groonga.org/
  [vagrant]: http://www.vagrantup.com/
  [ruby]: http://www.ruby-lang.org/
