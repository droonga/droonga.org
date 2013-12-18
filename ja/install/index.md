---
title: インストール手順
layout: documents_ja
---

# 概要

Droongaは主に、[fluent-plugin-droonga][]と[express-droonga][]の2つのパッケージから構成されています。

## 依存関係

### Ruby

[fluent-plugin-droonga][]は[Ruby][]を必要とします。

### Node.js

[express-droonga][]は[Node.js][]を必要とします。


# Ubuntu 13.10

## 依存パッケージのインストール

    sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## fluent-plugin-droongaのインストール

    sudo gem install fluent-plugin-droonga

## express-droongaのインストール

    sudo npm install express-droonga

以上で、Droongaベースのデータ処理システムを構築する準備が整いました。ここから先は[チュートリアル](/ja/tutorial/)を参照して下さい。

  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
