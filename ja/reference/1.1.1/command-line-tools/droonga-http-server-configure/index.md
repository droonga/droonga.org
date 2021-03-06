---
title: droonga-http-server-configure
layout: ja
---

{% comment %}
##############################################
  THIS FILE IS AUTOMATICALLY GENERATED FROM
  "_po/ja/reference/1.1.1/command-line-tools/droonga-http-server-configure/index.po"
  DO NOT EDIT THIS FILE MANUALLY!
##############################################
{% endcomment %}


* TOC
{:toc}

## 概要 {#abstract}

`droonga-http-server-configure`は、そのコンピュータ自身を`droonga-http-server`のノードとして設定します。

このコマンドの最も代表的な用途は、コンピュータをクリーンな状態のHTTPサーバー用ノードとしてリセットする事です。
このコマンドはコンピュータをどのように設定するかを対話的に尋ねてきます：

~~~
# droonga-http-server-configure 
Do you want the configuration file "droonga-http-server.yaml" to be regenerated? (y/N): y
IP address to accept requests from clients (0.0.0.0 means "any IP address") [0.0.0.0]: 
port [10041]: 
hostname of this node [nodeX]: 
hostnames of droonga-engine nodes (comma, vertical bar, or white-space separated) [nodeX]: 
port number of the droonga-engine node [10031]: 
tag of the droonga-engine node [droonga]: 
default dataset [Default]: 
timeout for unresponsive connections (in seconds) [3]: 
path to the access log file [droonga-http-server.access.log]: 
path to the system log file [droonga-http-server.system.log]: 
log level for the system log (silly,debug,verbose,info,warn,error) [warn]: 
maximum size of the response cache [100]: 
time to live of cached responses, in seconds [60]: 
enable "trust proxy" configuration (y/N): 
path to the document root [/usr/local/lib/node_modules/droonga-http-server/public/groonga-admin]: 
environment [production]: 
~~~

プランが既に固まっているのであれば、コマンドラインオプションを使ってサイレントに実行する事もできます：

~~~
# droonga-http-server-configure \
    --no-prompt \
    --reset-config \
    --host 0.0.0.0 \
    --port 10041 \
    --droonga-engine-host-names node0,node1,node2 \
    --droonga-engine-port 10031 \
    --tag droonga \
    --system-log-level info
~~~

`droonga-http-server`サービスがサービスとして正しく設定されている場合、このコマンドはインストール済みのサービスを設定するためだけに動作し、（サービスの利用においては使われない）いくつかのオプションは無視されます。


## パラメータ {#parameters}

`--no-prompt`
: 対話的な入力プロンプトを表示しない。
  このオプションが指定された場合、以下のオプションで指定されなかった設定項目は全て既定の値で埋められます。
  オプションが指定されない場合、以下の各項目に対応する設問が表示されます。

`--reset-config`
: 既存の`droonga-http-server.yaml`を新しい物に置き換えます。
  このオプションが指定された場合、`droonga-http-server.yaml`は確認無しに上書きされます。
  オプションが指定されず、既存の`droonga-http-server.yaml`が存在する場合、上書きして良いかどうかが尋ねられます。

`--host=HOST`
: リッスンするホスト名。
  言い換えると、これはバインドアドレスを示します。
  既定値は`0.0.0.0`（そのコンピュータに割り当てられた全てのIPアドレスとホスト名で接続を受け付ける）です。

`--port=PORT`
: クライアントからの接続を待ち受けるポートの番号。
  既定値は`10041`です。

`--receiver-host-name=NAME`
: HTTPサーバ用ノード自身のホスト名。
  ここで指定する名前は、全てのDroonga Engineノードから名前解決できる物でなくてはなりません。
  EngineノードはHTTPサーバによって仲介されたリクエストに対するレスポンスを含むすべてのメッセージを、ここで指定されたホスト名宛に送信します。
  既定値は、コマンドを実行しているコンピュータ自身の推測されたホスト名です。

`--droonga-engine-host-names=NAME1,NAME2,...`
: 起動時に接続を試みるDroonga Engineノードのホスト名のリスト。
  既定値は、コマンドを実行しているコンピュータ自身の推測されたホスト名です。

`--droonga-engine-port=PORT`
: Droonga Engineノードとの通信に使うポート番号。
  既定値は`10031`です。

`--tag=TAG`
: Droonga Engineノードとの通信に使うタグ名。
  既定値は`droonga`です。

`--default-dataset=NAME`
: メッセージの既定の送信先データセット名。
  既定値は`Default`です。

`--default-timeout=SECONDS`
: 応答がない接続を打ち切るまでの待ち時間（単位：秒）。
  既定値は`3`です。

`--access-log-file=PATH`
: アクセスログの出力先ファイルのパス。
  `-`を指定した場合、ログは標準出力に出力されます。
  既定値は`-`です。

`--system-log-file=PATH`
: システムログの出力先ファイルのパス。
  `-`を指定した場合、ログは標準出力に出力されます。
  既定値は`-`です。

`--system-log-level=LEVEL`
: システムログ用ロガーのログレベル。
  取り得る値は`silly`/`trace`、`debug`、`verbose`、`info`、`warn`、`error`のうちのいずれかです。
  既定値は`warn`です。

`--cache-size=N`
: レスポンスキャッシュの最大件数。
  この設定は、`/d/select`などのいくつかのエンドポイントについてのみ反映されます。
  既定値は`100`です。

`--cache-ttl-in-seconds=SECONDS`
: レスポンスキャッシュの寿命（単位：秒）。
  この設定は、`/d/select`などのいくつかのエンドポイントについてのみ反映されます。
  既定値は`60`です。

`--enable-trust-proxy`, `--disable-trust-proxy`
: 「プロキシを信用する」設定を有効化するかどうか。
  `droonga-http-server`のサービスをリバースプロキシの背後で動作させる場合、この設定を有効化する必要があります。
  既定値は`--disable-trust-proxy`です。

`--document-root=PATH`
: ドキュメントルートへのパス。
  既定値は`(droonga-http-serverのインストール先ディレクトリ)/public/groonga-admin`です。

`--plugins=PLUGIN1,PLUGIN2,...`
: 有効化するプラグインのリスト。
  取り得る値；
  
  * `./api/rest`: `search`コマンドのためのREST形式のエンドポイントを提供します。
  * `./api/groonga`: Groonga互換のエンドポイントを提供します。
  * `./api/droonga`: Droongaネイティブコマンド用の一般的なエンドポイントを提供します。
  
  既定の状態では、全てのプラグインが有効化されます。

`--daemon`
: デーモンとして実行する
  ただし、`service droonga-http-server start`コマンドで開始されるサービスについては常にデーモンとして実行されます。

`--pid-file=PATH`
: デーモンとして実行されたプロセスのプロセスIDの出力先ファイルのパス。
  ただし、`service droonga-http-server start`コマンドで開始されるサービスについては、プロセスIDは常にプラットフォームごとの適切な位置に出力されます。

`--environment=ENVIRONMENT`
: サーバの実行時の環境。
  取り得る値：
  
  * `development`
  * `production` （既定値）
  * `testing`

`-h`, `--help`
: コマンドの使い方の説明を表示します。

## インストール方法 {#install}

このコマンドは、npmのパッケージ`droonga-http-server`の一部としてインストールされます。

~~~
# npm install -g droonga-http-server
~~~

