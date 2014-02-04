---
title: 国際化
layout: ja
---

このドキュメントは英語で書かれたドキュメントを他の言語に翻訳する方法を説明します。

## ワークフロー

英語で書かれたドキュメントを1つ翻訳するワークフローは次の通りです。

  1. `rake` を実行。
  2. `_po/${翻訳対象のロケール}/${対象ファイルへのパス}.edit.po` を翻訳。
  3. `rake` を実行。
  4. `jekyll server --watch` を実行。
  5. `http://localhost:4000/${翻訳対象のロケール}/${対象ファイルへのパス}.html` を確認
  6. `_po/${翻訳対象のロケール}/${対象ファイルへのパス}.po` （ `.edit.po` ではないことに注意） と `${翻訳対象のロケール}/${対象ファイルへのパス}.md` をコミット。

## 例

`overview/index.md` を日本語に翻訳する例です。

`rake` を実行する。

~~~
% rake
~~~

`_po/ja/overview/index.edit.po` を翻訳する。

~~~
% gedit _po/ja/overview/index.edit.po
~~~

注：テキストエディターでなく、POエディターを使うこともできます。POエディターには、たとえば、Emacsのpo-mode、Vim、[Gtranslator](https://wiki.gnome.org/Apps/Gtranslator)、[Lokalize](http://userbase.kde.org/Lokalize)などがあります。

`rake` を実行する。

~~~
% rake
~~~

`jekyll server --watch`を実行する。

~~~
% jekyll server --watch &
~~~

`http://localhost:4000/ja/overview/index.html` を確認する。

~~~
% firefox http://localhost:4000/ja/overview/index.html
~~~

`_po/ja/overview/index.po` と `ja/overview/index.md` をコミットする。

~~~
% git add _po/ja/overview/index.po
% git add ja/overview/index.md
% git commit
% git push
~~~
