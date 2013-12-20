---
title: Droonga tutorial
layout: documents
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to setup a Droonga based search system by yourself.

## Precondition

* You must have basic knowledges and experiences how setup and operate an [Ubuntu][] Server.
* You must have basic knowledges and experiences to develop applications based on the [Ruby][] and the [Node.js][].

## Abstract

### What is the Droonga?

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".

The Droonga is built on some components which are made as separated packages. You can develop various data processing systems (for example, a fulltext search engine) with high scalability from a distributed architecture, with those packages.

### Components of the Droonga

#### Droonga Engine

The component "Droonga Engine" is the main part to process data with a distributed architecture. It is triggered by requests and processes various data.

This component is developed as a [Fluentd] plugin, and released as the [fluent-plugin-droonga][] package.
It internally uses [Groonga][] as its search engine. Groonga is an open source, fulltext search engine, including a column-store feature.

#### Protocol Adapter

The component "Protocol Adapter" provides ability for clients to communicate with a Droonga engine, using various protocols.

This component is developed as a module for the [Node.js][], and released as the [express-droonga][] package.

The only one available protocol of a Droonga engine is the fluentd protocol. Instead, a protocol adapter provides various interfaces, HTTP, Socket.IO, and so on, for applications, between them and a Droonga engine.

## Abstract of the system described in this tutorial

This tutorial describes steps to build a system like following:

    +-------------+              +------------------+             +----------------+
    | Web Browser |  <-------->  | Protocol Adapter |  <------->  | Droonga Engine |
    +-------------+   HTTP /     +------------------+   Fluent    +----------------+
                      Socket.IO   w/express-droonga     protocol   w/fluent-plugin
                                                                           -droonga


                                 \--------------------------------------------------/
                                       This tutorial describes about this part.

User agents (ex. an Web browser) sends search requests to a protocol adapter. The adapter receives them, and sends internal (translated) search requests to a Droonga engine. The engine processes them actually. Search results are sent from the engine to the protocol adapter, and finally delivered to the user agent.

For example lets's try to build a database system to find [taiyaki](http://en.wikipedia.org/wiki/Taiyaki) shops, based on location data used in [another tutorial of Groonga](http://www.clear-code.com/blog/2011/9/13.html).


## Prepare an environment for experiments

Prepare an comuter at first. This tutorial describes steps to develop a search service based on the Droonga, on an existing computer.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu Server 13.10 64bit` on the service [Sakura's cloud](http://cloud.sakura.ad.jp/), with an available console.

## Install packages required for the setup process

Install packages required to setup a Droonga engine.

    $ sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## Build a Droonga engine

The part "Droonga engine" stores the database and provides the search feature actually.
In this section we install a fluent-plugin-droonga and load searchable data to the database.

### Install a fluent-plugin-droonga

    $ sudo gem install fluent-plugin-droonga

Required packages are prepared by the command above. Let's continue to the configuration step.

### Prepare a configuration file to start a Droonga engine

Create a directory for a Droonga engine:

    $ mkdir engine
    $ cd engine

Next, put configuration files `fluentd.conf` and `catalog.json` like following, into the directory:

fluentd.conf:

    <source>
      type forward
      port 24224
    </source>
    <match taiyaki.message>
      name localhost:24224/taiyaki
      type droonga
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:24224/taiyaki"],
      "farms": {
        "localhost:24224/taiyaki": {
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
                  "localhost:24224/taiyaki.000",
                  "localhost:24224/taiyaki.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/taiyaki.002",
                  "localhost:24224/taiyaki.003"
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

This `catalog.json` defines a dataset `Taiyaki` with two replicas and two partitions.
All of replicas and partitions are stored locally (in other words, they are managed by a `fluent-plugin-droonga` instance).

For more details of the configuration file `catalog.json`, see [the reference manual of catalog.json](/reference/catalog).

### Start an instance of fluent-plugin-droonga

Start a Droonga engine, it is a fluentd server with fluentd-plugin-droonga started like:

    $ fluentd --config fluentd.conf
    2013-11-12 14:14:20 +0900 [info]: starting fluentd-0.10.40
    2013-11-12 14:14:20 +0900 [info]: reading config file path="fluentd.conf"
    2013-11-12 14:14:20 +0900 [info]: gem 'fluent-plugin-droonga' version '0.0.1'
    2013-11-12 14:14:20 +0900 [info]: gem 'fluentd' version '0.10.40'
    2013-11-12 14:14:20 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 24224
      </source>
      <match taiyaki.message>
        name localhost:24224/taiyaki
        type droonga
      </match>
      <match output.message>
        type stdout
      </match>
    </ROOT>
    2013-11-12 14:14:20 +0900 [info]: adding source type="forward"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="taiyaki.message" type="droonga"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="output.message" type="stdout"
    2013-11-12 14:14:20 +0900 [info]: listening fluent socket on 0.0.0.0:24224

### Create a database

After a Dronga engine is started, let's load data.
Prepare two jsons files, `ddl.jsons` including the database schema and `shops.jsons` including location data of shops.

ddl.jsons:

    {"id":"ddl:0","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Shop","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
    {"id":"ddl:1","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Shop","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
    {"id":"ddl:2","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Location","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
    {"id":"ddl:3","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Location","name":"shop","flags":"COLUMN_INDEX","type":"Shop","source":"location"}}
    {"id":"ddl:4","dataset":"Taiyaki","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"ddl:5","dataset":"Taiyaki","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Term","name":"shops__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Shop","source":"_key"}}


shops.jsons:

    {"id":"shops:0","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"根津のたいやき","values":{"location":"35.720253,139.762573"}}}
    {"id":"shops:1","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼 カタオカ","values":{"location":"35.712521,139.715591"}}}
    {"id":"shops:2","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"そばたいやき空","values":{"location":"35.683712,139.659088"}}}
    {"id":"shops:3","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"車","values":{"location":"35.721516,139.706207"}}}
    {"id":"shops:4","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"広瀬屋","values":{"location":"35.714844,139.685608"}}}
    {"id":"shops:5","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"さざれ","values":{"location":"35.714653,139.685043"}}}
    {"id":"shops:6","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"おめで鯛焼き本舗錦糸町東急店","values":{"location":"35.700516,139.817154"}}}
    {"id":"shops:7","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"尾長屋 錦糸町店","values":{"location":"35.698254,139.81105"}}}
    {"id":"shops:8","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき工房白家 阿佐ヶ谷店","values":{"location":"35.705517,139.638611"}}}
    {"id":"shops:9","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき本舗 藤家 阿佐ヶ谷店","values":{"location":"35.703938,139.637115"}}}
    {"id":"shops:10","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"みよし","values":{"location":"35.644539,139.537323"}}}
    {"id":"shops:11","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"寿々屋 菓子","values":{"location":"35.628922,139.695755"}}}
    {"id":"shops:12","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き / たつみや","values":{"location":"35.665501,139.638657"}}}
    {"id":"shops:13","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き鉄次 大丸東京店","values":{"location":"35.680912,139.76857"}}}
    {"id":"shops:14","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"吾妻屋","values":{"location":"35.700817,139.647598"}}}
    {"id":"shops:15","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ほんま門","values":{"location":"35.722736,139.652573"}}}
    {"id":"shops:16","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"浪花家","values":{"location":"35.730061,139.796234"}}}
    {"id":"shops:17","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"代官山たい焼き黒鯛","values":{"location":"35.650345,139.704834"}}}
    {"id":"shops:18","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやき神田達磨 八重洲店","values":{"location":"35.681461,139.770599"}}}
    {"id":"shops:19","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"柳屋 たい焼き","values":{"location":"35.685341,139.783981"}}}
    {"id":"shops:20","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き写楽","values":{"location":"35.716969,139.794846"}}}
    {"id":"shops:21","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たかね 和菓子","values":{"location":"35.698601,139.560913"}}}
    {"id":"shops:22","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たい焼き ちよだ","values":{"location":"35.642601,139.652817"}}}
    {"id":"shops:23","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ダ・カーポ","values":{"location":"35.627346,139.727356"}}}
    {"id":"shops:24","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"松島屋","values":{"location":"35.640556,139.737381"}}}
    {"id":"shops:25","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"銀座 かずや","values":{"location":"35.673508,139.760895"}}}
    {"id":"shops:26","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"ふるや古賀音庵 和菓子","values":{"location":"35.680603,139.676071"}}}
    {"id":"shops:27","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"蜂の家 自由が丘本店","values":{"location":"35.608021,139.668106"}}}
    {"id":"shops:28","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"薄皮たい焼き あづきちゃん","values":{"location":"35.64151,139.673203"}}}
    {"id":"shops:29","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"横浜 くりこ庵 浅草店","values":{"location":"35.712013,139.796829"}}}
    {"id":"shops:30","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"夢ある街のたいやき屋さん戸越銀座店","values":{"location":"35.616199,139.712524"}}}
    {"id":"shops:31","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"何故屋","values":{"location":"35.609039,139.665833"}}}
    {"id":"shops:32","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"築地 さのきや","values":{"location":"35.66592,139.770721"}}}
    {"id":"shops:33","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"しげ田","values":{"location":"35.672626,139.780273"}}}
    {"id":"shops:34","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"にしみや 甘味処","values":{"location":"35.671825,139.774628"}}}
    {"id":"shops:35","replyTo":"localhost:24224/output","dataset":"Taiyaki","type":"add","body":{"table":"Shop","key":"たいやきひいらぎ","values":{"location":"35.647701,139.711517"}}}


Open another terminal to keep the fluentd server working, and send those two jsons `ddl.jsons` and `shops.jsons` to the fluentd server:

    $ fluent-cat taiyaki.message < ddl.jsons
    $ fluent-cat taiyaki.message < shops.jsons


Now a Droonga engine for searching taiyaki shops database is ready.
Next, setup a protocol adapter for clients to accept search requests using popular protocols.


## Build a protocol adapter

Let's use the `express-droonga` to build a protocol adapter. It is an npm package for the Node.js.

### Install a express-droonga

    $ cd ~
    $ mkdir protocol-adapter
    $ cd protocol-adapter

After that, put a file `package.json` like following, into the directory:

package.json:

    {
      "name": "protocol-adapter",
      "description": "Droonga Protocol Adapter",
      "version": "0.0.0",
      "author": "Droonga Project",
      "private": true,
      "dependencies": {
        "express": "*",
        "express-droonga": "*"
      }
    }

Install depending packages.

    $ npm install


### Create a protocol adaper

Put a file `application.js` like following, into the directory:

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'taiyaki',
      defaultDataset: 'Taiyaki',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

Then, run the `application.js`.

    $ node application.js
       info  - socket.io started


### Synchronous search request via HTTP

We're all set. Let's send a search request to the protocol adapter via HTTP. At first, try to get all records of the `Shops` table by a request like following. (Note: The `attributes=_key` parameter means "export the value of the column `_key` to the search result". If you don't set the parameter, each record returned in the `records` will become just a blank array. You can specify multiple column names by the delimiter `,`. For example `attributes=_key,location` will return both the primary key and the location for each record.)

    $ curl "http://localhost:3000/droonga/tables/Shop?attributes=_key&limit=-1"
    {
      "result": {
        "count": 36,
        "records": [
          [
            "たい焼 カタオカ"
          ],
          [
            "根津のたいやき"
          ],
          [
            "そばたいやき空"
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
            "たいやき本舗 藤家 阿佐ヶ谷店"
          ],
          [
            "みよし"
          ],
          [
            "たい焼き / たつみや"
          ],
          [
            "吾妻屋"
          ],
          [
            "たいやき神田達磨 八重洲店"
          ],
          [
            "車"
          ],
          [
            "広瀬屋"
          ],
          [
            "たいやき工房白家 阿佐ヶ谷店"
          ],
          [
            "寿々屋 菓子"
          ],
          [
            "たい焼き鉄次 大丸東京店"
          ],
          [
            "ほんま門"
          ],
          [
            "浪花家"
          ],
          [
            "代官山たい焼き黒鯛"
          ],
          [
            "ダ・カーポ"
          ]
        ]
      }
    }

Because the `count` says `36`, you know there are all 36 records in the table. Search result records are returned as an array `records`.

Next step, let's try more meaningful query. To search shops which contain "阿佐ヶ谷" (Asagaya, a town name in Japan) in their name, give `阿佐ヶ谷` as the parameter `query`, and give `_key` as the parameter `match_to` which means the column to be searched. Non-ASCII characters in the `query` must be URL-encoded like `%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7`. Then:

    $ curl "http://localhost:3000/droonga/tables/Shop?query=%E9%98%BF%E4%BD%90%E3%83%B6%E8%B0%B7&match_to=_key&attributes=_key&limit=-1"
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
        ]
      }
    }

As the result two shops are found by the search condition.


### Asynchronous search request via Socket.IO

A Droonga protocol adapter supports not only REST API, but also [Socket.IO][]. If you send a request to a protocol adapter via Socket.IO, then the protocol adapter sends back the response for the request after the operation is finished. So you can develop a system based on a client application and an API server communicating each other asynchronously.

Now, let's create such a system based on Socket.IO.

The sample client application is a simple Web page `index.html` loaded in a Web browser, returned by the protocol adapter itself.
Put a file `index.html` into the `protocol-adaptor` directory, like following:

index.html:

    <html>
      <head>
        <script src="/socket.io/socket.io.js"></script>
        <script>
          var socket = io.connect();
          socket.on('search.result', function (data) {
            document.body.textContent += JSON.stringify(data);
          });
          socket.emit('search', { queries: {
            result: {
              source: 'Shop',
              output: {
                 elements: [
                   'startTime',
                   'elapsedTime',
                   'count',
                   'attributes',
                   'records'
                 ],
                 attributes: ['_key'],
                 limit: -1
              }
            }
          }});
        </script>
      </head>
      <body>
      </body>
    </html>

This client sends a search query by `socket.emit()`. After the request is processed and the result is returned, the callback ginven as `socket.on('search.result', ...)` will be called with the result, and it will render the result to the page.

The first argument `'search'` for the method call `socket.emit()` means that the request is a search request.
The second argument includes parameters of the search request. See the command reference of the [`search` command](/reference/commands/search) for more details.
(By the way, we used a REST API to do search in the previous section. In the case the protocol adapter translates a HTTP request to a message in the format described in the [command reference of the `search`](/reference/commands/search) internally and sends it to the Droonga engine.)

Next, modify the `application.js` to host the `index.html` by the protocol adaper, like:

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'taiyaki',
      defaultDataset: 'Taiyaki',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

    //============== INSERTED ==============
    application.get('/', function(req, res) {
      res.sendfile(__dirname + '/index.html');
    });
    //============= /INSERTED ==============

Then, type the IP address of the server for experiments into the address bar of your Web browser. For example, if the IP address is `192.0.2.1`, then the location is `http://192.0.2.1:3000/` and you can see the contents of the `index.html`. When you see the search result like following, then the search request is successfully processed:

    "result":{"count":36,"records":[["たい焼 カタオカ"],["根津のたいやき"],["そばたいやき空"],["さざれ"],["おめで鯛焼き本舗錦糸町東急店"],["尾長屋 錦糸町店"],["たいやき本舗 藤家 阿佐ヶ谷店"],["みよし"],["たい焼き / たつみや"],["吾妻屋"],["たいやき神田達磨 八重洲店"],["車"],["広瀬屋"],["たいやき工房白家 阿佐ヶ谷店"],["寿々屋 菓子"],["たい焼き鉄次 大丸東京店"],["ほんま門"],["浪花家"],["代官山たい焼き黒鯛"],["ダ・カーポ"]]}}

Your Web browser sends a request to the protocol adapter via Socket.IO, the protocol adapter sends it to the Droonga engine via fluent protocol, the engine returns the search result to the protocol adapter, and the protocol adapter sends back the search result to the client.

Next, try a fulltext search request like the previous section, to find shops with the town name "阿佐ヶ谷".
Modify the parameter given to the `socket.emit()` method in the `index.html`, like following:

    <html>
      <head>
        <script src="/socket.io/socket.io.js"></script>
        <script>
          var socket = io.connect();
          socket.on('search.result', function (data) {
            document.body.textContent += JSON.stringify(data);
          });
          socket.emit('search', { queries: {
            result: {
              source: 'Shop',
              condition: {
                query: '阿佐ヶ谷',
                matchTo: '_key'
              },
              output: {
                 elements: [
                   'startTime',
                   'elapsedTime',
                   'count',
                   'attributes',
                   'records'
                 ],
                 attributes: ['_key'],
                 limit: -1
              }
            }
          }});
        </script>
      </head>
      <body>
      </body>
    </html>

Reload the current page `http://192.0.2.1:3000` in your Web browser, then you'll see a search result like following:

    {"result":{"count":2,"records":[["たいやき工房白家 阿佐ヶ谷店"],["たいやき本舗 藤家 阿佐ヶ谷店"]]}}

OK, you've successfully created a client application which can send search requests and receive responses asynchronously via Socket.IO.


## Conclusion

In this tutorial, you did setup both packages [fluent-plugin-droonga][] and [express-droonga][] which construct [Droonga][] service on a [Ubuntu Linux][Ubuntu].
Moreover, you built a search system based on a protocol adapter with a Droonga engine, and successfully searched.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
  [Groonga]: http://groonga.org/
  [Ruby]: http://www.ruby-lang.org/
  [nvm]: https://github.com/creationix/nvm
  [Socket.IO]: http://socket.io/
  [Fluentd]: http://fluentd.org/
  [Node.js]: http://nodejs.org/
