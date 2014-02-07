---
title: \"Droonga tutorial: basic usage\"
layout: en
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

User agents (ex. a Web browser) sends search requests to a protocol adapter. The adapter receives them, and sends internal (translated) search requests to a Droonga engine. The engine processes them actually. Search results are sent from the engine to the protocol adapter, and finally delivered to the user agent.

For example let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).


## Prepare an environment for experiments

Prepare a computer at first. This tutorial describes steps to develop a search service based on the Droonga, on an existing computer.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 13.10 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE: Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga. Otherwise, you may experience a strange build error.

## Install packages required for the setup process

Install packages required to setup a Droonga engine.

    # apt-get update
    # apt-get -y upgrade
    # apt-get install -y ruby ruby-dev build-essential nodejs npm

## Build a Droonga engine

The part "Droonga engine" stores the database and provides the search feature actually.
In this section we install a fluent-plugin-droonga and load searchable data to the database.

### Install a fluent-plugin-droonga

    # gem install fluent-plugin-droonga

Required packages are prepared by the command above. Let's continue to the configuration step.

### Prepare a configuration file to start a Droonga engine

Create a directory for a Droonga engine:

    # mkdir engine
    # cd engine

Next, put configuration files `fluentd.conf` and `catalog.json` like following, into the directory:

fluentd.conf:

    <source>
      type forward
      port 24224
    </source>
    <match starbucks.message>
      name localhost:24224/starbucks
      type droonga
    </match>
    <match output.message>
      type stdout
    </match>

catalog.json:

    {
      "effective_date": "2013-09-01T00:00:00Z",
      "zones": ["localhost:24224/starbucks"],
      "farms": {
        "localhost:24224/starbucks": {
          "device": ".",
          "capacity": 10
        }
      },
      "datasets": {
        "Starbucks": {
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
                  "localhost:24224/starbucks.000",
                  "localhost:24224/starbucks.001"
                ]
              }
            },
            "localhost:23042": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.002",
                  "localhost:24224/starbucks.003"
                ]
              }
            }
          }
        }
      },
      "options": {
        "plugins": ["crud"]
      }
    }

This `catalog.json` defines a dataset `Starbucks` with two replicas and two partitions.
All of replicas and partitions are stored locally (in other words, they are managed by a `fluent-plugin-droonga` instance).

For more details of the configuration file `catalog.json`, see [the reference manual of catalog.json](/reference/catalog).

### Start an instance of fluent-plugin-droonga

Start a Droonga engine, it is a fluentd server with fluentd-plugin-droonga started like:

    # fluentd --config fluentd.conf
    2013-11-12 14:14:20 +0900 [info]: starting fluentd-0.10.40
    2013-11-12 14:14:20 +0900 [info]: reading config file path="fluentd.conf"
    2013-11-12 14:14:20 +0900 [info]: gem 'fluent-plugin-droonga' version '0.0.1'
    2013-11-12 14:14:20 +0900 [info]: gem 'fluentd' version '0.10.40'
    2013-11-12 14:14:20 +0900 [info]: using configuration file: <ROOT>
      <source>
        type forward
        port 24224
      </source>
      <match starbucks.message>
        name localhost:24224/starbucks
        type droonga
      </match>
      <match output.message>
        type stdout
      </match>
    </ROOT>
    2013-11-12 14:14:20 +0900 [info]: adding source type="forward"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="starbucks.message" type="droonga"
    2013-11-12 14:14:20 +0900 [info]: adding match pattern="output.message" type="stdout"
    2013-11-12 14:14:20 +0900 [info]: listening fluent socket on 0.0.0.0:24224

### Create a database

After a Droonga engine is started, let's load data.
Prepare two jsons files, `ddl.jsons` including the database schema and `stores.jsons` including location data of stores.

ddl.jsons:

    {"id":"ddl:0","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Store","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
    {"id":"ddl:1","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Store","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
    {"id":"ddl:2","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Location","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
    {"id":"ddl:3","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Location","name":"store","flags":"COLUMN_INDEX","type":"Store","source":"location"}}
    {"id":"ddl:4","dataset":"Starbucks","type":"table_create","replyTo":"localhost:24224/output","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
    {"id":"ddl:5","dataset":"Starbucks","type":"column_create","replyTo":"localhost:24224/output","body":{"table":"Term","name":"stores__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Store","source":"_key"}}


stores.jsons:

    {"id":"stores:0","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1st Avenue & 75th St. - New York NY  (W)","values":{"location":"40.770262,-73.954798"}}}
    {"id":"stores:1","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"76th & Second - New York NY  (W)","values":{"location":"40.771056,-73.956757"}}}
    {"id":"stores:2","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2nd Ave. & 9th Street - New York NY","values":{"location":"40.729445,-73.987471"}}}
    {"id":"stores:3","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"15th & Third - New York NY  (W)","values":{"location":"40.733946,-73.9867"}}}
    {"id":"stores:4","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"41st and Broadway - New York NY  (W)","values":{"location":"40.755111,-73.986225"}}}
    {"id":"stores:5","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"84th & Third Ave - New York NY  (W)","values":{"location":"40.777485,-73.954979"}}}
    {"id":"stores:6","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"150 E. 42nd Street - New York NY  (W)","values":{"location":"40.750784,-73.975582"}}}
    {"id":"stores:7","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"West 43rd and Broadway - New York NY  (W)","values":{"location":"40.756197,-73.985624"}}}
    {"id":"stores:8","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 35th Street Balcony - New York NY","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:9","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 6th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:10","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Herald Square- Macy's - New York NY","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:11","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 5th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
    {"id":"stores:12","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"80th & York - New York NY  (W)","values":{"location":"40.772204,-73.949862"}}}
    {"id":"stores:13","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Columbus @ 67th - New York NY  (W)","values":{"location":"40.774009,-73.981472"}}}
    {"id":"stores:14","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"45th & Broadway - New York NY  (W)","values":{"location":"40.75766,-73.985719"}}}
    {"id":"stores:15","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Marriott Marquis - Lobby - New York NY","values":{"location":"40.759123,-73.984927"}}}
    {"id":"stores:16","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Second @ 81st - New York NY  (W)","values":{"location":"40.77466,-73.954447"}}}
    {"id":"stores:17","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"52nd & Seventh - New York NY  (W)","values":{"location":"40.761829,-73.981141"}}}
    {"id":"stores:18","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1585 Broadway (47th) - New York NY  (W)","values":{"location":"40.759806,-73.985066"}}}
    {"id":"stores:19","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"85th & First - New York NY  (W)","values":{"location":"40.776101,-73.949971"}}}
    {"id":"stores:20","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"92nd & 3rd - New York NY  (W)","values":{"location":"40.782606,-73.951235"}}}
    {"id":"stores:21","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"165 Broadway - 1 Liberty - New York NY  (W)","values":{"location":"40.709727,-74.011395"}}}
    {"id":"stores:22","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1656 Broadway - New York NY  (W)","values":{"location":"40.762434,-73.983364"}}}
    {"id":"stores:23","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"54th & Broadway - New York NY  (W)","values":{"location":"40.764275,-73.982361"}}}
    {"id":"stores:24","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Limited Brands-NYC - New York NY","values":{"location":"40.765219,-73.982025"}}}
    {"id":"stores:25","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"19th & 8th - New York NY  (W)","values":{"location":"40.743218,-74.000605"}}}
    {"id":"stores:26","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"60th & Broadway-II - New York NY  (W)","values":{"location":"40.769196,-73.982576"}}}
    {"id":"stores:27","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"63rd & Broadway - New York NY  (W)","values":{"location":"40.771376,-73.982709"}}}
    {"id":"stores:28","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"195 Broadway - New York NY  (W)","values":{"location":"40.710703,-74.009485"}}}
    {"id":"stores:29","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Broadway - New York NY  (W)","values":{"location":"40.704538,-74.01324"}}}
    {"id":"stores:30","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Columbus Ave. - New York NY  (W)","values":{"location":"40.769262,-73.984764"}}}
    {"id":"stores:31","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"NY Plaza - New York NY  (W)","values":{"location":"40.702802,-74.012784"}}}
    {"id":"stores:32","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"36th and Madison - New York NY  (W)","values":{"location":"40.748917,-73.982683"}}}
    {"id":"stores:33","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"125th St. btwn Adam Clayton & FDB - New York NY","values":{"location":"40.808952,-73.948229"}}}
    {"id":"stores:34","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"70th & Broadway - New York NY  (W)","values":{"location":"40.777463,-73.982237"}}}
    {"id":"stores:35","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2138 Broadway - New York NY  (W)","values":{"location":"40.781078,-73.981167"}}}
    {"id":"stores:36","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"118th & Frederick Douglas Blvd. - New York NY  (W)","values":{"location":"40.806176,-73.954109"}}}
    {"id":"stores:37","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"42nd & Second - New York NY  (W)","values":{"location":"40.750069,-73.973393"}}}
    {"id":"stores:38","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Broadway @ 81st - New York NY  (W)","values":{"location":"40.784972,-73.978987"}}}
    {"id":"stores:39","replyTo":"localhost:24224/output","dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Fashion Inst of Technology - New York NY","values":{"location":"40.746948,-73.994557"}}}


Open another terminal to keep the fluentd server working, and send those two jsons `ddl.jsons` and `stores.jsons` to the fluentd server:

    # fluent-cat starbucks.message < ddl.jsons
    # fluent-cat starbucks.message < stores.jsons


Now a Droonga engine for searching Starbucks stores database is ready.
Next, setup a protocol adapter for clients to accept search requests using popular protocols.


## Build a protocol adapter

Let's use the `express-droonga` to build a protocol adapter. It is an npm package for the Node.js.

### Install a express-droonga

    # cd ~
    # mkdir protocol-adapter
    # cd protocol-adapter

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


### Create a protocol adapter

Put a file `application.js` like following, into the directory:

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'starbucks',
      defaultDataset: 'Starbucks',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
      ]
    });

Then, run the `application.js`.

    # nodejs application.js
       info  - socket.io started


### Synchronous search request via HTTP

We're all set. Let's send a search request to the protocol adapter via HTTP. At first, try to get all records of the `Stores` table by a request like following. (Note: The `attributes=_key` parameter means "export the value of the column `_key` to the search result". If you don't set the parameter, each record returned in the `records` will become just a blank array. You can specify multiple column names by the delimiter `,`. For example `attributes=_key,location` will return both the primary key and the location for each record.)

    # curl "http://localhost:3000/droonga/tables/Store?attributes=_key&limit=-1"
    {
      "stores": {
        "count": 40,
        "records": [
          [
            "76th & Second - New York NY  (W)"
          ],
          [
            "15th & Third - New York NY  (W)"
          ],
          [
            "41st and Broadway - New York NY  (W)"
          ],
          [
            "West 43rd and Broadway - New York NY  (W)"
          ],
          [
            "Macy's 6th Floor - Herald Square - New York NY  (W)"
          ],
          [
            "Herald Square- Macy's - New York NY"
          ],
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "45th & Broadway - New York NY  (W)"
          ],
          [
            "1585 Broadway (47th) - New York NY  (W)"
          ],
          [
            "85th & First - New York NY  (W)"
          ],
          [
            "92nd & 3rd - New York NY  (W)"
          ],
          [
            "1656 Broadway - New York NY  (W)"
          ],
          [
            "19th & 8th - New York NY  (W)"
          ],
          [
            "60th & Broadway-II - New York NY  (W)"
          ],
          [
            "195 Broadway - New York NY  (W)"
          ],
          [
            "2 Broadway - New York NY  (W)"
          ],
          [
            "NY Plaza - New York NY  (W)"
          ],
          [
            "36th and Madison - New York NY  (W)"
          ],
          [
            "125th St. btwn Adam Clayton & FDB - New York NY"
          ],
          [
            "2138 Broadway - New York NY  (W)"
          ],
          [
            "118th & Frederick Douglas Blvd. - New York NY  (W)"
          ],
          [
            "42nd & Second - New York NY  (W)"
          ],
          [
            "1st Avenue & 75th St. - New York NY  (W)"
          ],
          [
            "2nd Ave. & 9th Street - New York NY"
          ],
          [
            "84th & Third Ave - New York NY  (W)"
          ],
          [
            "150 E. 42nd Street - New York NY  (W)"
          ],
          [
            "Macy's 35th Street Balcony - New York NY"
          ],
          [
            "Macy's 5th Floor - Herald Square - New York NY  (W)"
          ],
          [
            "80th & York - New York NY  (W)"
          ],
          [
            "Marriott Marquis - Lobby - New York NY"
          ],
          [
            "Second @ 81st - New York NY  (W)"
          ],
          [
            "52nd & Seventh - New York NY  (W)"
          ],
          [
            "165 Broadway - 1 Liberty - New York NY  (W)"
          ],
          [
            "54th & Broadway - New York NY  (W)"
          ],
          [
            "Limited Brands-NYC - New York NY"
          ],
          [
            "63rd & Broadway - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ],
          [
            "70th & Broadway - New York NY  (W)"
          ],
          [
            "Broadway @ 81st - New York NY  (W)"
          ],
          [
            "Fashion Inst of Technology - New York NY"
          ]
        ]
      }
    }

Because the `count` says `40`, you know there are all 40 records in the table. Search result records are returned as an array `records`.

Next step, let's try more meaningful query. To search stores which contain "Columbus" in their name, give `Columbus` as the parameter `query`, and give `_key` as the parameter `match_to` which means the column to be searched. Then:

    # curl "http://localhost:3000/droonga/tables/Store?query=Columbus&match_to=_key&attributes=_key&limit=-1"
    {
      "stores": {
        "count": 2,
        "records": [
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }

As the result two stores are found by the search condition.


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
            stores: {
              source: 'Store',
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

This client sends a search query by `socket.emit()`. After the request is processed and the result is returned, the callback given as `socket.on('search.result', ...)` will be called with the result, and it will render the result to the page.

The first argument `'search'` for the method call `socket.emit()` means that the request is a search request.
The second argument includes parameters of the search request. See the command reference of the [`search` command](/reference/commands/search) for more details.
(By the way, we used a REST API to do search in the previous section. In the case the protocol adapter translates a HTTP request to a message in the format described in the [command reference of the `search`](/reference/commands/search) internally and sends it to the Droonga engine.)

Next, modify the `application.js` to host the `index.html` by the protocol adapter, like:

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    application.droonga({
      prefix: '/droonga',
      tag: 'starbucks',
      defaultDataset: 'Starbucks',
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

    {"stores":{"count":40,"records":[["76th & Second - New York NY (W)"],["15th & Third - New York NY (W)"],["41st and Broadway - New York NY (W)"],["West 43rd and Broadway - New York NY (W)"],["Macy's 6th Floor - Herald Square - New York NY (W)"],["Herald Square- Macy's - New York NY"],["Columbus @ 67th - New York NY (W)"],["45th & Broadway - New York NY (W)"],["1585 Broadway (47th) - New York NY (W)"],["85th & First - New York NY (W)"],["92nd & 3rd - New York NY (W)"],["1656 Broadway - New York NY (W)"],["19th & 8th - New York NY (W)"],["60th & Broadway-II - New York NY (W)"],["195 Broadway - New York NY (W)"],["2 Broadway - New York NY (W)"],["NY Plaza - New York NY (W)"],["36th and Madison - New York NY (W)"],["125th St. btwn Adam Clayton & FDB - New York NY"],["2138 Broadway - New York NY (W)"],["118th & Frederick Douglas Blvd. - New York NY (W)"],["42nd & Second - New York NY (W)"],["1st Avenue & 75th St. - New York NY (W)"],["2nd Ave. & 9th Street - New York NY"],["84th & Third Ave - New York NY (W)"],["150 E. 42nd Street - New York NY (W)"],["Macy's 35th Street Balcony - New York NY"],["Macy's 5th Floor - Herald Square - New York NY (W)"],["80th & York - New York NY (W)"],["Marriott Marquis - Lobby - New York NY"],["Second @ 81st - New York NY (W)"],["52nd & Seventh - New York NY (W)"],["165 Broadway - 1 Liberty - New York NY (W)"],["54th & Broadway - New York NY (W)"],["Limited Brands-NYC - New York NY"],["63rd & Broadway - New York NY (W)"],["2 Columbus Ave. - New York NY (W)"],["70th & Broadway - New York NY (W)"],["Broadway @ 81st - New York NY (W)"],["Fashion Inst of Technology - New York NY"]]}}

Your Web browser sends a request to the protocol adapter via Socket.IO, the protocol adapter sends it to the Droonga engine via fluent protocol, the engine returns the search result to the protocol adapter, and the protocol adapter sends back the search result to the client.

Next, try a fulltext search request like the previous section, to find stores with the town name "Columbus".
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
            stores: {
              source: 'Store',
              condition: {
                query: 'Columbus',
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

    {"stores":{"count":2,"records":[["Columbus @ 67th - New York NY (W)"],["2 Columbus Ave. - New York NY (W)"]]}}

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
