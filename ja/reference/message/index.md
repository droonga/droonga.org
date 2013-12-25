---
title: メッセージ形式
layout: documents_ja
---

* TOC
{:toc}


## リクエスト {#request}

リクエストのメッセージの基本的な形式は以下の通りです。

    {
      "id"      : "<メッセージの識別子>",
      "type"    : "<メッセージの種類>",
      "replyTo" : "<レスポンスの受信者へのパス>",
      "dataset" : "<対象データセット名>",
      "body"    : <メッセージ本文>
    }

### `id` {#request-id}

概要
: そのメッセージの一意な識別子。

値
: 識別子となる文字列。一意でさえあれば、どんな形式のどんな文字列でも指定できます。値は対応するレスポンスの['inReplyTo`](#response-inReplyTo)に使われます。

省略時の既定値


### `type` {#request-type}

概要
: そのメッセージの種類。

値
: [コマンド](/ja/reference/commands/)の名前の文字列

省略時の既定値


### `replyTo` {#request-replyTo}

概要
: レスポンスの受信者へのパス。

Value
: An path string in the format: `<hostname>:<port>/<tag>`, for example: `loalhost:24224/output`.

省略時の既定値
: なし。この情報は省略可能で、省略した場合はレスポンスのメッセージは単に捨てられます。

### `dataset` {#request-dataset}

概要
: 対象となるデータセット。

値
: データセット名の文字列。

省略時の既定値


### `body` {#request-body}

概要
: メッセージの本文。

値
: オブジェクト、文字列、数値、真偽値、または `null`。

Default value
: Nothing. This is optional.

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
