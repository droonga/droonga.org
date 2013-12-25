---
title: メッセージ形式
layout: documents_ja
---

* TOC
{:toc}


## リクエスト {#request}

リクエストのメッセージの基本的な形式は以下の通りです。

    {
      "id"      : "<ID of the message>",
      "type"    : "<Type of the message>",
      "replyTo" : "<Route to the receiver>",
      "dataset" : "<Name of the target dataset>",
      "body"    : <Body of the message>
    }

### `id` {#request-id}

### `type` {#request-type}

### `replyTo` {#request-replyTo}

### `dataset` {#request-dataset}

### `body` {#request-body}


## レスポンス {#response}

レスポンスのメッセージの基本的な形式は以下の通りです。

    {
      "type"       : "<Type of the message>",
      "inReplyTo"  : "<Route to the receiver>",
      "statusCode" : <Status code>,
      "body"       : <Body of the message>
    }

### `type` {#response-type}

### `inReplyTo` {#response-inReplyTo}

### `statusCode` {#response-statusCode}

レスポンスのステータスコードはHTTPのステータスコードに似ています。

`200` およびその他の `2xx` のステータス
: コマンドが正常に処理されたことを示します。

### `body` {#response-body}


## エラーレスポンス {#error}

コマンドの中にはエラーを返す物があります。

エラーレスポンスは通常のレスポンスと同じ `type` を伴って返されますが、通常のレスポンスとは異なる `statusCode` と `body` を持ちます。大まかなエラーの種類は `statusCode` で示され、詳細な情報は `body` の内容として返されます。

### エラーレスポンスのステータスコード {#error-status}

エラーレスポンスのステータスコードはHTTPのステータスコードに似ています。

`400` およびその他の `4xx` のステータス
: リクエストのメッセージが原因でのエラーであることを示します。

`500` およびその他の `5xx` のステータス
: Droonga Engine内部のエラーであることを示します。

### エラーレスポンスの `body` {#error-body}

エラーレスポンスの `body` の基本的な形式は以下の通りです。

    {
      "name"    : "<Name of the error>",
      "message" : "<Human readable details of the error>",
      "detail"  : <Other extra information for the error, in various formats>
    }
