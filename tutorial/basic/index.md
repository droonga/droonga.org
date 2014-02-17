---
title: "Droonga tutorial: basic usage"
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

### Install a fluent-plugin-droonga and droonga-client

    # gem install fluent-plugin-droonga droonga-client

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
          "workers": 4,
          "plugins": ["groonga", "crud", "search"],
          "number_of_replicas": 2,
          "number_of_partitions": 3,
          "partition_key": "_key",
          "date_range": "infinity",
          "ring": {
            "localhost:24224:0": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.000",
                  "localhost:24224/starbucks.001"
                ]
              }
            },
            "localhost:24224:1": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.010",
                  "localhost:24224/starbucks.011"
                ]
              }
            },
            "localhost:24224:2": {
              "weight": 50,
              "partitions": {
                "2013-09-01": [
                  "localhost:24224/starbucks.020",
                  "localhost:24224/starbucks.021"
                ]
              }
            }
          }
        }
      }
    }

This `catalog.json` defines a dataset `Starbucks` with two replicas and three partitions.
All of replicas and partitions are stored locally (in other words, they are managed by a `fluent-plugin-droonga` instance).

For more details of the configuration file `catalog.json`, see [the reference manual of catalog.json](/reference/catalog).

### Start an instance of fluent-plugin-droonga

Start a Droonga engine, it is a fluentd server with fluentd-plugin-droonga started like:

    # fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid
    # tail -F fluentd.log
      </match>
      <match output.message>
        type stdout
      </match>
    </ROOT>
    2014-02-09 14:37:08 +0900 [info]: adding source type="forward"
    2014-02-09 14:37:08 +0900 [info]: adding match pattern="starbucks.message" type="droonga"
    2014-02-09 14:37:08 +0900 [info]: adding match pattern="output.message" type="stdout"
    2014-02-09 14:37:08 +0900 [info]: catalog loaded path="/tmp/engine/catalog.json" mtime=2014-02-09 14:29:22 +0900
    2014-02-09 14:37:08 +0900 [info]: listening fluent socket on 0.0.0.0:24224

### Stop an instance of fluent-plugin-droonga

First, you need to know how to stop fluent-plugin-droonga.

Send SIGTERM to fluentd:

    # kill $(cat fluentd.pid)

You will see the following message at `tail -F fluentd.log` terminal:

    # tail -F fluentd.log
    ...
    2014-02-09 14:39:27 +0900 [info]: shutting down fluentd
    2014-02-09 14:39:30 +0900 [info]: process finished code=0

This is the way to stop fluent-plugin-droonga.

Start fluent-plugin-droonga again:

    # fluentd --config fluentd.conf --log fluentd.log --daemon fluentd.pid

### Create a database

After a Droonga engine is started, let's load data.
Prepare two jsons files, `ddl.jsons` including the database schema and `stores.jsons` including location data of stores.

ddl.jsons:

~~~
{"dataset":"Starbucks","type":"table_create","body":{"name":"Store","flags":"TABLE_HASH_KEY","key_type":"ShortText"}}
{"dataset":"Starbucks","type":"column_create","body":{"table":"Store","name":"location","flags":"COLUMN_SCALAR","type":"WGS84GeoPoint"}}
{"dataset":"Starbucks","type":"table_create","body":{"name":"Location","flags":"TABLE_PAT_KEY","key_type":"WGS84GeoPoint"}}
{"dataset":"Starbucks","type":"column_create","body":{"table":"Location","name":"store","flags":"COLUMN_INDEX","type":"Store","source":"location"}}
{"dataset":"Starbucks","type":"table_create","body":{"name":"Term","flags":"TABLE_PAT_KEY","key_type":"ShortText","default_tokenizer":"TokenBigram","normalizer":"NormalizerAuto"}}
{"dataset":"Starbucks","type":"column_create","body":{"table":"Term","name":"stores__key","flags":"COLUMN_INDEX|WITH_POSITION","type":"Store","source":"_key"}}
~~~


stores.jsons:

~~~
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1st Avenue & 75th St. - New York NY  (W)","values":{"location":"40.770262,-73.954798"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"76th & Second - New York NY  (W)","values":{"location":"40.771056,-73.956757"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2nd Ave. & 9th Street - New York NY","values":{"location":"40.729445,-73.987471"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"15th & Third - New York NY  (W)","values":{"location":"40.733946,-73.9867"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"41st and Broadway - New York NY  (W)","values":{"location":"40.755111,-73.986225"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"84th & Third Ave - New York NY  (W)","values":{"location":"40.777485,-73.954979"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"150 E. 42nd Street - New York NY  (W)","values":{"location":"40.750784,-73.975582"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"West 43rd and Broadway - New York NY  (W)","values":{"location":"40.756197,-73.985624"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 35th Street Balcony - New York NY","values":{"location":"40.750703,-73.989787"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 6th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Herald Square- Macy's - New York NY","values":{"location":"40.750703,-73.989787"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Macy's 5th Floor - Herald Square - New York NY  (W)","values":{"location":"40.750703,-73.989787"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"80th & York - New York NY  (W)","values":{"location":"40.772204,-73.949862"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Columbus @ 67th - New York NY  (W)","values":{"location":"40.774009,-73.981472"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"45th & Broadway - New York NY  (W)","values":{"location":"40.75766,-73.985719"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Marriott Marquis - Lobby - New York NY","values":{"location":"40.759123,-73.984927"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Second @ 81st - New York NY  (W)","values":{"location":"40.77466,-73.954447"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"52nd & Seventh - New York NY  (W)","values":{"location":"40.761829,-73.981141"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1585 Broadway (47th) - New York NY  (W)","values":{"location":"40.759806,-73.985066"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"85th & First - New York NY  (W)","values":{"location":"40.776101,-73.949971"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"92nd & 3rd - New York NY  (W)","values":{"location":"40.782606,-73.951235"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"165 Broadway - 1 Liberty - New York NY  (W)","values":{"location":"40.709727,-74.011395"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"1656 Broadway - New York NY  (W)","values":{"location":"40.762434,-73.983364"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"54th & Broadway - New York NY  (W)","values":{"location":"40.764275,-73.982361"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"Limited Brands-NYC - New York NY","values":{"location":"40.765219,-73.982025"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"19th & 8th - New York NY  (W)","values":{"location":"40.743218,-74.000605"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"60th & Broadway-II - New York NY  (W)","values":{"location":"40.769196,-73.982576"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"63rd & Broadway - New York NY  (W)","values":{"location":"40.771376,-73.982709"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"195 Broadway - New York NY  (W)","values":{"location":"40.710703,-74.009485"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Broadway - New York NY  (W)","values":{"location":"40.704538,-74.01324"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"2 Columbus Ave. - New York NY  (W)","values":{"location":"40.769262,-73.984764"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"NY Plaza - New York NY  (W)","values":{"location":"40.702802,-74.012784"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"36th and Madison - New York NY  (W)","values":{"location":"40.748917,-73.982683"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"125th St. btwn Adam Clayton & FDB - New York NY","values":{"location":"40.808952,-73.948229"}}}
{"dataset":"Starbucks","type":"add","body":{"table":"Store","key":"70th & Broadway - New York NY  (W)","values":{"location":"40.777463,-73.982237"}}}
~~~

Open another terminal and send those two jsons to the fluentd server.

Send `ddl.jsons` as follows:

~~~
# droonga-request --tag starbucks ddl.jsons
Elapsed time: 0.060984
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.207507",
    "statusCode": 200,
    "type": "table_create.result",
    "body": [
      [
        0,
        1392611486.2097359,
        0.026822328567504883
      ],
      true
    ]
  }
]
Elapsed time: 0.007164
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.268766",
    "statusCode": 200,
    "type": "column_create.result",
    "body": [
      [
        0,
        1392611486.269676,
        0.0010280609130859375
      ],
      true
    ]
  }
]
Elapsed time: 0.008584
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.2760692",
    "statusCode": 200,
    "type": "table_create.result",
    "body": [
      [
        0,
        1392611486.276955,
        0.002329111099243164
      ],
      true
    ]
  }
]
Elapsed time: 0.109383
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.284704",
    "statusCode": 200,
    "type": "column_create.result",
    "body": [
      [
        0,
        1392611486.2854872,
        0.00432896614074707
      ],
      true
    ]
  }
]
Elapsed time: 0.008829
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.394273",
    "statusCode": 200,
    "type": "table_create.result",
    "body": [
      [
        0,
        1392611486.395301,
        0.0017240047454833984
      ],
      true
    ]
  }
]
Elapsed time: 0.11633
[
  "droonga.message",
  1392611486,
  {
    "inReplyTo": "1392611486.4032152",
    "statusCode": 200,
    "type": "column_create.result",
    "body": [
      [
        0,
        1392611486.404574,
        0.018894195556640625
      ],
      true
    ]
  }
]
~~~

Send `stores.jsons` as follows:

~~~

$ droonga-request --tag starbucks stores.jsons
Elapsed time: 0.251712
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.414268",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.007161
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.666198",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.006794
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.6735082",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.070859
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.680408",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.064862
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.7514088",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.009247
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.816423",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.012615
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.825906",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.01329
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.838811",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.016937
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.852271",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.009726
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.8693151",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.009445
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.879232",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003686
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.888693",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.00309
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.892619",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.007988
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.895704",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003158
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.903796",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.006433
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.907073",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.006858
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.913633",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003178
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.920607",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002921
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.923857",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002627
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.926882",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002955
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.92959",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003133
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.932686",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002871
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.9359381",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.00274
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.938964",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002905
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.941767",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002512
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.94483",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002553
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.947414",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002482
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.950102",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.00294
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.952671",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003141
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.955711",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002479
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.958953",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002375
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.9615061",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002571
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.963968",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.003212
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.966677",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
Elapsed time: 0.002769
[
  "droonga.message",
  1392611703,
  {
    "inReplyTo": "1392611703.970025",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
~~~

Now a Droonga engine for searching Starbucks stores database is ready.

### Send request with droonga-request

Check if it is working. Create a query as a JSON file as follows.

search-all-stores.json:

~~~
{
  "dataset": "Starbucks"
  "queries": {
    "stores": {
      "source": "Store",
      "output": {
        "elements": [
          "startTime",
        "elapsedTime",
        "count",
        "attributes",
        "records"
          ],
        "attributes": ["_key"],
        "limit": -1
      }
    }
  }
}
~~~

Send the request to Droonga Engine:

~~~
# droonga-request --tag starbucks search-all-stores.json
Elapsed time: 0.202101
[
  "droonga.message",
  1392614906,
  {
    "inReplyTo": "1392614905.993328",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 35,
        "records": [
          [
            "1st Avenue & 75th St. - New York NY  (W)"
          ],
          [
            "76th & Second - New York NY  (W)"
          ],
          [
            "2nd Ave. & 9th Street - New York NY"
          ],
          [
            "84th & Third Ave - New York NY  (W)"
          ],
          [
            "Macy's 35th Street Balcony - New York NY"
          ],
          [
            "80th & York - New York NY  (W)"
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
            "1656 Broadway - New York NY  (W)"
          ],
          [
            "2 Broadway - New York NY  (W)"
          ],
          [
            "NY Plaza - New York NY  (W)"
          ],
          [
            "70th & Broadway - New York NY  (W)"
          ],
          [
            "15th & Third - New York NY  (W)"
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
            "Macy's 5th Floor - Herald Square - New York NY  (W)"
          ],
          [
            "52nd & Seventh - New York NY  (W)"
          ],
          [
            "92nd & 3rd - New York NY  (W)"
          ],
          [
            "Limited Brands-NYC - New York NY"
          ],
          [
            "19th & 8th - New York NY  (W)"
          ],
          [
            "60th & Broadway-II - New York NY  (W)"
          ],
          [
            "36th and Madison - New York NY  (W)"
          ],
          [
            "125th St. btwn Adam Clayton & FDB - New York NY"
          ],
          [
            "41st and Broadway - New York NY  (W)"
          ],
          [
            "150 E. 42nd Street - New York NY  (W)"
          ],
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "Marriott Marquis - Lobby - New York NY"
          ],
          [
            "Second @ 81st - New York NY  (W)"
          ],
          [
            "165 Broadway - 1 Liberty - New York NY  (W)"
          ],
          [
            "54th & Broadway - New York NY  (W)"
          ],
          [
            "63rd & Broadway - New York NY  (W)"
          ],
          [
            "195 Broadway - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

Now the store names are retrieved. The engine looks working correctly.
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
