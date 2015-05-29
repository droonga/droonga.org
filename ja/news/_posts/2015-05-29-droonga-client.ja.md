---
title: droonga-client-ruby 0.2.2をリリースしました！
layout: news-item.ja
---

Droonga Engine用のRuby用クライアントライブラリとコマンドラインツールを提供する[droonga-client-ruby][]の、バージョン0.2.2をリリースしました！

このバージョンでは、Droongaクラスタをコマンドライン操作で[Groonga][groonga]感覚で利用できるツールの[`droonga-groonga`コマンド][droonga-groonga]において、標準入力を使った複数コマンドの流し込みに対応しました。
これにより、以下の要領でGroonga用のスキーマ定義ファイルなどの内容を簡単にDroongaクラスタに反映することができます。

~~~
$ cat /path/to/schema.grn | droonga-groonga --host node0 --port 10031
~~~

元々、似たようなことは[grn2drn][]と[`droonga-request`コマンド][droonga-request]の組み合わせでできていましたが、2つのコマンドの使い方を覚えなくてはならないため若干面倒でした。
`groonga`コマンドとほとんど同じ感覚で使える、という点が特徴の[`droonga-groonga`コマンド][droonga-groonga]単体で標準入力からの流し込みを行えるようになったことで、Groongaからの移行がより容易になったと言えるでしょう。
Groongaを使い慣れているという方は、ぜひ試してみて下さい。

また、[`droonga-add`][droonga-add], [`droonga-system-status`][droonga-system-status], [`droonga-groonga`][droonga-groonga]の各コマンドについて、`--dry-run`オプションを指定することで、実際に送信される予定のメッセージの確認のみを行えるようにしました。
コマンドの実行前に影響を予想したい場合にお使い下さい。

Droongaプロジェクトはユーザや開発者としての皆さんのご協力をお待ちしています！
詳しくは[コミュニティ][community]のページをご覧下さい。

  [community]: /ja/community/
  [groonga]: http://groonga.org/ja/
  [droonga-client-ruby]: https://github.com/droonga/droonga-client-ruby
  [grn2drn]: https://github.com/droonga/grn2drn
  [droonga-groonga]: /ja/reference/command-line-tools/droonga-groonga/
  [droonga-request]: /ja/reference/command-line-tools/droonga-request/
  [droonga-add]: /ja/reference/command-line-tools/droonga-add/
  [droonga-system-status]: /ja/reference/command-line-tools/droonga-system-status/
