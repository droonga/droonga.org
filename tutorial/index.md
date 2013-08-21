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

TODO: ddl.grn と shops.grn をつくる http://www.clear-code.com/blog/2011/9/13.html
TODO: groonga の実行形式にパスを通すなどする (apt で groonga 入れた方がいいかも)

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

WIP


  [droonga]: https://droonga.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
  [groonga]: http://groonga.org/
  [vagrant]: http://www.vagrantup.com/
  [ruby]: http://www.ruby-lang.org/
