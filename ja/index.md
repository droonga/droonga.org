---
layout: default_ja
---

<div class="jumbotron">
<h1>Droonga</h1>
<p>スケーラブルなデータ処理エンジン</p>
<p><a class="btn btn-primary btn-lg" role="button" href="overview/">詳しく »</a></p>
</div>

## Droongaについて

Droongaは、ストリーム指向の処理モデルを採用したスケーラブルなデータ処理エンジンです。検索、更新、集約などの多くの操作がパイプラインを通じて行われるこのモデルにより、Droongaは高い柔軟性と拡張性を備えています。また、Droongaは既存操作の組み合わせによる複雑な操作にも対応しています。ユーザーはRubyでプラグインを開発して、独自の操作をDroongaに加える事ができます。

詳細は[概要](overview/)をご覧ください。

将来のDroongaについては[ロードマップ](roadmap/)をご覧ください。

## 使ってみよう

Droongaについて知った後は、さらに理解を深めるために[チュートリアル](tutorial/)を試してみて下さい。もしまだ[概要](overview/)を読んでいないようであれば、チュートリアルを始める前にそちらに目を通しておく事をお薦めします。

## ドキュメント

Droongaをより効果的に使うために、以下のドキュメントが役立つでしょう。

 * [インストール手順](install/)：Droongaのインストール手順の説明です。
 * [リファレンスマニュアル](reference/)：詳細な仕様についての説明です。
 * [コミュニティー](community/)：Droonga開発者や他のユーザーとやりとりする方法の説明です。
 * [関連プロジェクト](related-projects/)：Droongaの関連プロジェクトの紹介です。

## 最新情報

<ul class="posts">
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <span class="date">({{ post.date | date: "%Y-%m-%d" }})</span>
    </li>
  {% endfor %}
</ul>
