---
title: droongaの分散機能を試す手順
layout: default
---

# droongaの分散機能を試す手順

## droongaのセットアップ

最新版のf-p-dその他をインストールします。

## 設定ファイルの準備

以下の二つの設定ファイルを準備する必要があります

* catalog.json
* fluentd.conf

### catalog.json

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:23003/taiyaki"],
      "farms": {
        "localhost:23003/taiyaki": {
          "device": ".",
          "capacity": 10
        }
      },
      "datasets": {
        "Taiyaki": {
          "workers": 0,
          "plugins": ["search", "groonga", "add"],
          "number_of_replicas": 2,
          "number_of_partitions": 2,
          "partition_key": "_key",
          "date_range": "infinity",
          "ring": {
            "localhost:23041": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:23003/taiyaki.000",
                  "localhost:23003/taiyaki.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:23003/taiyaki.002",
                  "localhost:23003/taiyaki.003"
                ]
              }
            }
          }
        }
      },
      "options": {
        "plugins": ["select"]
      }
    }


### fluentd.conf

    <source>
      type forward
      port 23003
    </source>
    <match taiyaki.**>
      name localhost:23003/taiyaki
      type droonga
      proxy true
      n_workers 0
      handlers proxy
    </match>
    <match output.message>
      type stdout
    </match>

## 起動

上記の設定ファイルが存在するディレクトリでfluentdを起動します。

    fluentd -c fluentd.conf &

## スキーマ定義

以下のようなjsonsファイルを準備します。

ddl.jsons

    {"id":"0","dataset":"Taiyaki","type":"table_create", "replyTo":"localhost:23003/output", "body":{ "name":"Shops", "flags":"TABLE_HASH_KEY", "key_type":"ShortText"}}
    {"id":"1","dataset":"Taiyaki","type":"column_create", "replyTo":"localhost:23003/output", "body":{ "table":"Shops", "name":"location", "flags":"COLUMN_SCALAR", "type":"WGS84GeoPoint"}}
    {"id":"2","dataset":"Taiyaki","type":"table_create", "replyTo":"localhost:23003/output", "body":{ "name":"Locations", "flags":"TABLE_PAT_KEY", "key_type":"WGS84GeoPoint"}}
    {"id":"3","dataset":"Taiyaki","type":"column_create", "replyTo":"localhost:23003/output", "body":{ "table":"Locations", "name":"shop", "flags":"COLUMN_INDEX", "type":"Shops", "source":"location"}}
    {"id":"4","dataset":"Taiyaki","type":"table_create", "replyTo":"localhost:23003/output", "body":{ "name":"Term", "flags":"TABLE_PAT_KEY", "key_type":"ShortText", "default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"5","dataset":"Taiyaki","type":"column_create", "replyTo":"localhost:23003/output", "body":{ "table":"Term", "name":"shops__key", "flags":"COLUMN_INDEX|WITH_POSITION", "type":"Shops", "source":"_key"}}

fluent-catで流し込みます。

    fluent-cat -p 23003 taiyaki < ddl.jsons

## データのロード

以下のようなjsonsファイルを準備します。

shop.jsons

    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"根津のたいやき", "values":{"location":"35.720253,139.762573"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼 カタオカ", "values":{"location":"35.712521,139.715591"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"そばたいやき空", "values":{"location":"35.683712,139.659088"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"車", "values":{"location":"35.721516,139.706207"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"広瀬屋", "values":{"location":"35.714844,139.685608"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"さざれ", "values":{"location":"35.714653,139.685043"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"おめで鯛焼き本舗錦糸町東急店", "values":{"location":"35.700516,139.817154"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"尾長屋 錦糸町店", "values":{"location":"35.698254,139.81105"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき工房白家 阿佐ヶ谷店", "values":{"location":"35.705517,139.638611"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき本舗 藤家 阿佐ヶ谷店", "values":{"location":"35.703938,139.637115"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"みよし", "values":{"location":"35.644539,139.537323"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"寿々屋 菓子", "values":{"location":"35.628922,139.695755"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き / たつみや", "values":{"location":"35.665501,139.638657"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き鉄次 大丸東京店", "values":{"location":"35.680912,139.76857"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"吾妻屋", "values":{"location":"35.700817,139.647598"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ほんま門", "values":{"location":"35.722736,139.652573"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"浪花家", "values":{"location":"35.730061,139.796234"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"代官山たい焼き黒鯛", "values":{"location":"35.650345,139.704834"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやき神田達磨 八重洲店", "values":{"location":"35.681461,139.770599"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"柳屋 たい焼き", "values":{"location":"35.685341,139.783981"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き写楽", "values":{"location":"35.716969,139.794846"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たかね 和菓子", "values":{"location":"35.698601,139.560913"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たい焼き ちよだ", "values":{"location":"35.642601,139.652817"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ダ・カーポ", "values":{"location":"35.627346,139.727356"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"松島屋", "values":{"location":"35.640556,139.737381"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"銀座 かずや", "values":{"location":"35.673508,139.760895"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"ふるや古賀音庵 和菓子", "values":{"location":"35.680603,139.676071"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"蜂の家 自由が丘本店", "values":{"location":"35.608021,139.668106"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"薄皮たい焼き あづきちゃん", "values":{"location":"35.64151,139.673203"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"横浜 くりこ庵 浅草店", "values":{"location":"35.712013,139.796829"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"夢ある街のたいやき屋さん戸越銀座店", "values":{"location":"35.616199,139.712524"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"何故屋", "values":{"location":"35.609039,139.665833"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"築地 さのきや", "values":{"location":"35.66592,139.770721"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"しげ田", "values":{"location":"35.672626,139.780273"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"にしみや 甘味処", "values":{"location":"35.671825,139.774628"}}}
    {"replyTo":"localhost:23003/output","dataset":"Taiyaki","type":"add","body":{"table":"Shops","key":"たいやきひいらぎ", "values":{"location":"35.647701,139.711517"}}}

fluent-catで流し込みます。

    fluent-cat -p 23003 taiyaki < shop.jsons

## 検索

以下のようなjsonsファイルを準備します。

select.jsons

    {"id":"000000001:0", "type":"select", "replyTo":"localhost:23003/output", "dataset":"Taiyaki", "body":{ "table":"Shops", "match_columns":"_key", "query":"阿佐ヶ谷", "output_columns":"_key"}}

fluent-catで流し込みます。

    fluent-cat -p 23003 taiyaki < select.jsons

するとfluentdの標準出力に結果が出てきます。
