---
title: "Droonga tutorial: Basic usage of low-layer commands"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to setup a Droonga based search system by yourself, with low-layer commands of Droonga.

## Precondition

* You must have basic knowledge and experiences to setup and operate an [Ubuntu][] or [CentOS][] Server.
* You must have basic knowledge and experiences to develop applications based on the [Ruby][] and the [Node.js][].

## Abstract

### What is the Droonga?

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".

The Droonga is built on some components which are made as separated packages. You can develop various data processing systems (for example, a fulltext search engine) with high scalability from a distributed architecture, with those packages.

### Components of the Droonga

#### Droonga Engine

The component "Droonga Engine" is the main part to process data with a distributed architecture. It is triggered by requests and processes various data.

This component is developed and released as the [droonga-engine][].
The protocol is compatible to [Fluentd].

It internally uses [Groonga][] as its search engine.
Groonga is an open source, fulltext search engine, including a column-store feature.

#### Protocol Adapter

The component "Protocol Adapter" provides ability for clients to communicate with a Droonga engine, using various protocols.

The only one available protocol of a Droonga engine is the fluentd protocol.
Instead, protocol adapters translate it to other common protocols (like HTTP, Socket.OP, etc.) between the Droonga Engine and clients.

Currently, there is an implementation for the HTTP: [droonga-http-server][], a [Node.js][] module package.
In other words, the droonga-http-server is one of Droonga Progocol Adapters, and it's a "Droonga HTTP Protocol Adapter".

## Abstract of the system described in this tutorial

This tutorial describes steps to build a system like following:

    +-------------+              +------------------+             +----------------+
    | Web Browser |  <-------->  | Protocol Adapter |  <------->  | Droonga Engine |
    +-------------+   HTTP       +------------------+   Fluent    +----------------+
                                 w/droonga-http        protocol   w/droonga-engine
                                           -server


                                 \--------------------------------------------------/
                                       This tutorial describes about this part.

User agents (ex. a Web browser) send search requests to a protocol adapter. The adapter receives them, and sends internal (translated) search requests to a Droonga engine. The engine processes them actually. Search results are sent from the engine to the protocol adapter, and finally delivered to the user agents.

For example, let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).


## Prepare an environment for experiments

Prepare a computer at first. This tutorial describes steps to develop a search service based on the Droonga, on an existing computer.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 13.10 x64` or `CentOS 6.5 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE: Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga. Otherwise, you may experience a strange build error.

Assume that the host is `192.168.100.50`.

## Install packages required for the setup process

Install packages required to setup a Droonga engine.

Ubuntu:

    # apt-get update
    # apt-get -y upgrade
    # apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm

CentOS:

    # yum -y groupinstall development
    # curl -L get.rvm.io | bash -s stable
    # source /etc/profile.d/rvm.sh
    # rvm reload
    # rvm install 2.1.2
    # yum -y install npm

Yes, in short, you have to activate `gem` and `npm` commands, and install some packages to build native extensions.

## Build a Droonga engine

The part "Droonga engine" stores the database and provides the search feature actually.
In this section we install a droonga-engine and load searchable data to the database.

### Install a droonga-engine and droonga-client

    # gem install droonga-engine droonga-client

Required packages are prepared by the command above. Let's continue to the configuration step.

### Prepare configuration files to start a Droonga engine

Create a directory for a Droonga engine:

    # mkdir engine
    # cd engine

Then put a configuration file `droonga-engine.yaml` like following, into the directory:

droonga-engine.yaml:

    host: 192.168.100.50
    port: 10031
    tag:  droonga

You must put correct host name or IP address of the computer itself.

Next, put another configuration file `catalog.json` like following, into the directory:

catalog.json:

    {
      "version": 2,
      "effectiveDate": "2013-09-01T00:00:00Z",
      "datasets": {
        "Default": {
          "nWorkers": 4,
          "plugins": ["groonga", "crud", "search", "dump", "status"],
          "schema": {
            "Store": {
              "type": "Hash",
              "keyType": "ShortText",
              "columns": {
                "location": {
                  "type": "Scalar",
                  "valueType": "WGS84GeoPoint"
                }
              }
            },
            "Location": {
              "type": "PatriciaTrie",
              "keyType": "WGS84GeoPoint",
              "columns": {
                "store": {
                  "type": "Index",
                  "valueType": "Store",
                  "indexOptions": {
                    "sources": ["location"]
                  }
                }
              }
            },
            "Term": {
              "type": "PatriciaTrie",
              "keyType": "ShortText",
              "normalizer": "NormalizerAuto",
              "tokenizer": "TokenBigram",
              "columns": {
                "stores__key": {
                  "type": "Index",
                  "valueType": "Store",
                  "indexOptions": {
                    "position": true,
                    "sources": ["_key"]
                  }
                }
              }
            }
          },
          "replicas": [
            {
              "dimension": "_key",
              "slicer": "hash",
              "slices": [
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.000"
                  }
                },
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.001"
                  }
                },
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.002"
                  }
                }
              ]
            },
            {
              "dimension": "_key",
              "slicer": "hash",
              "slices": [
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.010"
                  }
                },
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.011"
                  }
                },
                {
                  "volume": {
                    "address": "192.168.100.50:10031/droonga.012"
                  }
                }
              ]
            }
          ]
        }
      }
    }

This `catalog.json` defines a dataset `Default` as:

 * At the top level, there is one volume based on two sub volumes, called "replicas".
 * At the next lower level, one replica volume is based on three sub volumes, called "slices".
   They are minimum elements constructing a Droonga's dataset.

These six atomic volumes having `"address"` information are internally called as *single volume*s.
The `"address"` indicates the location of the corresponding physical storage which is a database for Groonga, they are managed by `droonga-engine` instances automatically.

For more details of the configuration file `catalog.json`, see [the reference manual of catalog.json](/reference/catalog).

### Start an instance of droonga-engine

Start a Droonga engine, you can start it with the command `droonga-engine`, like:

    # export DROONGA_BASE_DIR=$PWD
    # droonga-engine

### Stop an instance of droonga-engine

First, you need to know how to stop droonga-engine.

Run `droonga-engine-stop`, a utility command to stop droonga-engine service:

    # droonga-engine-stop

or, send SIGTERM to droonga-engine directly:

    # kill $(cat $DROONGA_BASE_DIR/droonga-engine.pid)

This is the way to stop droonga-engine.

Start droonga-engine again:

    # droonga-engine

### Create a database

After a Droonga engine is started, let's load data.
Prepare `stores.jsons` including location data of stores.

stores.jsons:

~~~
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "1st Avenue & 75th St. - New York NY  (W)",
    "values": {
      "location": "40.770262,-73.954798"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "76th & Second - New York NY  (W)",
    "values": {
      "location": "40.771056,-73.956757"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "2nd Ave. & 9th Street - New York NY",
    "values": {
      "location": "40.729445,-73.987471"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "15th & Third - New York NY  (W)",
    "values": {
      "location": "40.733946,-73.9867"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "41st and Broadway - New York NY  (W)",
    "values": {
      "location": "40.755111,-73.986225"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "84th & Third Ave - New York NY  (W)",
    "values": {
      "location": "40.777485,-73.954979"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "150 E. 42nd Street - New York NY  (W)",
    "values": {
      "location": "40.750784,-73.975582"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "West 43rd and Broadway - New York NY  (W)",
    "values": {
      "location": "40.756197,-73.985624"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Macy's 35th Street Balcony - New York NY",
    "values": {
      "location": "40.750703,-73.989787"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Macy's 6th Floor - Herald Square - New York NY  (W)",
    "values": {
      "location": "40.750703,-73.989787"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Herald Square- Macy's - New York NY",
    "values": {
      "location": "40.750703,-73.989787"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Macy's 5th Floor - Herald Square - New York NY  (W)",
    "values": {
      "location": "40.750703,-73.989787"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "80th & York - New York NY  (W)",
    "values": {
      "location": "40.772204,-73.949862"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Columbus @ 67th - New York NY  (W)",
    "values": {
      "location": "40.774009,-73.981472"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "45th & Broadway - New York NY  (W)",
    "values": {
      "location": "40.75766,-73.985719"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Marriott Marquis - Lobby - New York NY",
    "values": {
      "location": "40.759123,-73.984927"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Second @ 81st - New York NY  (W)",
    "values": {
      "location": "40.77466,-73.954447"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "52nd & Seventh - New York NY  (W)",
    "values": {
      "location": "40.761829,-73.981141"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "1585 Broadway (47th) - New York NY  (W)",
    "values": {
      "location": "40.759806,-73.985066"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "85th & First - New York NY  (W)",
    "values": {
      "location": "40.776101,-73.949971"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "92nd & 3rd - New York NY  (W)",
    "values": {
      "location": "40.782606,-73.951235"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "165 Broadway - 1 Liberty - New York NY  (W)",
    "values": {
      "location": "40.709727,-74.011395"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "1656 Broadway - New York NY  (W)",
    "values": {
      "location": "40.762434,-73.983364"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "54th & Broadway - New York NY  (W)",
    "values": {
      "location": "40.764275,-73.982361"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Limited Brands-NYC - New York NY",
    "values": {
      "location": "40.765219,-73.982025"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "19th & 8th - New York NY  (W)",
    "values": {
      "location": "40.743218,-74.000605"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "60th & Broadway-II - New York NY  (W)",
    "values": {
      "location": "40.769196,-73.982576"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "63rd & Broadway - New York NY  (W)",
    "values": {
      "location": "40.771376,-73.982709"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "195 Broadway - New York NY  (W)",
    "values": {
      "location": "40.710703,-74.009485"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "2 Broadway - New York NY  (W)",
    "values": {
      "location": "40.704538,-74.01324"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "2 Columbus Ave. - New York NY  (W)",
    "values": {
      "location": "40.769262,-73.984764"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "NY Plaza - New York NY  (W)",
    "values": {
      "location": "40.702802,-74.012784"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "36th and Madison - New York NY  (W)",
    "values": {
      "location": "40.748917,-73.982683"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "125th St. btwn Adam Clayton & FDB - New York NY",
    "values": {
      "location": "40.808952,-73.948229"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "70th & Broadway - New York NY  (W)",
    "values": {
      "location": "40.777463,-73.982237"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "2138 Broadway - New York NY  (W)",
    "values": {
      "location": "40.781078,-73.981167"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "118th & Frederick Douglas Blvd. - New York NY  (W)",
    "values": {
      "location": "40.806176,-73.954109"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "42nd & Second - New York NY  (W)",
    "values": {
      "location": "40.750069,-73.973393"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Broadway @ 81st - New York NY  (W)",
    "values": {
      "location": "40.784972,-73.978987"
    }
  }
}
{
  "dataset": "Default",
  "type": "add",
  "body": {
    "table": "Store",
    "key": "Fashion Inst of Technology - New York NY",
    "values": {
      "location": "40.746948,-73.994557"
    }
  }
}
~~~

Open another terminal and send the json to the Droonga engine.

Send `stores.jsons` as follows:

~~~
# droonga-request stores.jsons
Elapsed time: 0.01101195
[
  "droonga.message",
  1393562553,
  {
    "inReplyTo": "1393562553.8918273",
    "statusCode": 200,
    "type": "add.result",
    "body": true
  }
]
...
Elapsed time: 0.004817463
[
  "droonga.message",
  1393562554,
  {
    "inReplyTo": "1393562554.2447524",
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
  "dataset": "Default",
  "type": "search",
  "body": {
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
}
~~~

Send the request to the Droonga Engine:

~~~
# droonga-request search-all-stores.json
Elapsed time: 0.008286785
[
  "droonga.message",
  1393562604,
  {
    "inReplyTo": "1393562604.4970381",
    "statusCode": 200,
    "type": "search.result",
    "body": {
      "stores": {
        "count": 40,
        "records": [
          [
            "15th & Third - New York NY  (W)"
          ],
          [
            "41st and Broadway - New York NY  (W)"
          ],
          [
            "84th & Third Ave - New York NY  (W)"
          ],
          [
            "Macy's 35th Street Balcony - New York NY"
          ],
          [
            "Second @ 81st - New York NY  (W)"
          ],
          [
            "52nd & Seventh - New York NY  (W)"
          ],
          [
            "1585 Broadway (47th) - New York NY  (W)"
          ],
          [
            "54th & Broadway - New York NY  (W)"
          ],
          [
            "60th & Broadway-II - New York NY  (W)"
          ],
          [
            "63rd & Broadway - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ],
          [
            "NY Plaza - New York NY  (W)"
          ],
          [
            "2138 Broadway - New York NY  (W)"
          ],
          [
            "Broadway @ 81st - New York NY  (W)"
          ],
          [
            "76th & Second - New York NY  (W)"
          ],
          [
            "2nd Ave. & 9th Street - New York NY"
          ],
          [
            "150 E. 42nd Street - New York NY  (W)"
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
            "Marriott Marquis - Lobby - New York NY"
          ],
          [
            "85th & First - New York NY  (W)"
          ],
          [
            "1656 Broadway - New York NY  (W)"
          ],
          [
            "Limited Brands-NYC - New York NY"
          ],
          [
            "2 Broadway - New York NY  (W)"
          ],
          [
            "36th and Madison - New York NY  (W)"
          ],
          [
            "125th St. btwn Adam Clayton & FDB - New York NY"
          ],
          [
            "118th & Frederick Douglas Blvd. - New York NY  (W)"
          ],
          [
            "Fashion Inst of Technology - New York NY"
          ],
          [
            "1st Avenue & 75th St. - New York NY  (W)"
          ],
          [
            "West 43rd and Broadway - New York NY  (W)"
          ],
          [
            "80th & York - New York NY  (W)"
          ],
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "45th & Broadway - New York NY  (W)"
          ],
          [
            "92nd & 3rd - New York NY  (W)"
          ],
          [
            "165 Broadway - 1 Liberty - New York NY  (W)"
          ],
          [
            "19th & 8th - New York NY  (W)"
          ],
          [
            "195 Broadway - New York NY  (W)"
          ],
          [
            "70th & Broadway - New York NY  (W)"
          ],
          [
            "42nd & Second - New York NY  (W)"
          ]
        ]
      }
    }
  }
]
~~~

Now the store names are retrieved. The engine looks working correctly.
Next, setup a protocol adapter for clients to accept search requests via HTTP.

## Setup an HTTP Protocol Adapter

Let's use the `droonga-http-server` as an HTTP protocol adapter.

### Install the droonga-http-server

It is an npm package for the Node.js so you can install it by `npm` command easily:

    # npm install -g droonga-http-server

Next, put a configuration file `droonga-http-server.yaml` into the configuration directory specified by the environment variable `DROONGA_BASE_DIR`.

droonga-http-server.yaml:

    port:        10041
    environment: production

Because there is `droogna-engine.yaml` and droonga-http-server automatically loads some information from `droogna-engine.yaml`, you only have to put very few information to the `droonga-http-server.yaml`.
If no droonga-engine is working on the computer, you have to specify required information completely, to communicate with a droonga-engine server.
For example, if the computer is `192.168.100.51` and there is a droonga-engine server `192.168.100.50`, then `droonga-http-server.yaml` on `192.168.100.51` should be:

droonga-http-server.yaml:

    port:        10041
    environment: production
    engine:
      host:          192.168.100.50
      receiver_host: 192.168.100.51

OK, let's run it.

    # droonga-http-server


### Search request via HTTP

We're all set. Let's send a search request to the protocol adapter via HTTP. At first, try to get all records of the `Stores` table by a request like following. (Note: The `attributes=_key` parameter means "export the value of the column `_key` to the search result". If you don't set the parameter, each record returned in the `records` will become just a blank array. You can specify multiple column names by the delimiter `,`. For example `attributes=_key,location` will return both the primary key and the location for each record.)

    # curl "http://192.168.100.50:10041/tables/Store?attributes=_key&limit=-1"
    {
      "stores": {
        "count": 40,
        "records": [
          [
            "15th & Third - New York NY  (W)"
          ],
          [
            "41st and Broadway - New York NY  (W)"
          ],
          [
            "84th & Third Ave - New York NY  (W)"
          ],
          [
            "Macy's 35th Street Balcony - New York NY"
          ],
          [
            "Second @ 81st - New York NY  (W)"
          ],
          [
            "52nd & Seventh - New York NY  (W)"
          ],
          [
            "1585 Broadway (47th) - New York NY  (W)"
          ],
          [
            "54th & Broadway - New York NY  (W)"
          ],
          [
            "60th & Broadway-II - New York NY  (W)"
          ],
          [
            "63rd & Broadway - New York NY  (W)"
          ],
          [
            "2 Columbus Ave. - New York NY  (W)"
          ],
          [
            "NY Plaza - New York NY  (W)"
          ],
          [
            "2138 Broadway - New York NY  (W)"
          ],
          [
            "Broadway @ 81st - New York NY  (W)"
          ],
          [
            "76th & Second - New York NY  (W)"
          ],
          [
            "2nd Ave. & 9th Street - New York NY"
          ],
          [
            "150 E. 42nd Street - New York NY  (W)"
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
            "Marriott Marquis - Lobby - New York NY"
          ],
          [
            "85th & First - New York NY  (W)"
          ],
          [
            "1656 Broadway - New York NY  (W)"
          ],
          [
            "Limited Brands-NYC - New York NY"
          ],
          [
            "2 Broadway - New York NY  (W)"
          ],
          [
            "36th and Madison - New York NY  (W)"
          ],
          [
            "125th St. btwn Adam Clayton & FDB - New York NY"
          ],
          [
            "118th & Frederick Douglas Blvd. - New York NY  (W)"
          ],
          [
            "Fashion Inst of Technology - New York NY"
          ],
          [
            "1st Avenue & 75th St. - New York NY  (W)"
          ],
          [
            "West 43rd and Broadway - New York NY  (W)"
          ],
          [
            "80th & York - New York NY  (W)"
          ],
          [
            "Columbus @ 67th - New York NY  (W)"
          ],
          [
            "45th & Broadway - New York NY  (W)"
          ],
          [
            "92nd & 3rd - New York NY  (W)"
          ],
          [
            "165 Broadway - 1 Liberty - New York NY  (W)"
          ],
          [
            "19th & 8th - New York NY  (W)"
          ],
          [
            "195 Broadway - New York NY  (W)"
          ],
          [
            "70th & Broadway - New York NY  (W)"
          ],
          [
            "42nd & Second - New York NY  (W)"
          ]
        ]
      }
    }

Because the `count` says `40`, you know there are all 40 records in the table. Search result records are returned as an array `records`.

Next step, let's try more meaningful query. To search stores which contain "Columbus" in their name, give `Columbus` as the parameter `query`, and give `_key` as the parameter `match_to` which means the column to be searched. Then:

    # curl "http://192.168.100.50:10041/tables/Store?query=Columbus&match_to=_key&attributes=_key&limit=-1"
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

As the result, two stores are found by the search condition.

For more details of the Droonga HTTP Server, see the [reference manual][http-server].


## Conclusion

In this tutorial, you did setup both packages [droonga-engine][] and [droonga-http-server][] which construct [Droonga][] service on a [Ubuntu Linux][Ubuntu] or [CentOS][] computer.
Moreover, you built a search system based on an HTTP protocol adapter with a Droonga engine, and successfully searched.


  [http-server]: ../../reference/http-server/
  [Ubuntu]: http://www.ubuntu.com/
  [CentOS]: https://www.centos.org/
  [Droonga]: https://droonga.org/
  [droonga-engine]: https://github.com/droonga/droonga-engine
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
  [Groonga]: http://groonga.org/
  [Ruby]: http://www.ruby-lang.org/
  [nvm]: https://github.com/creationix/nvm
  [Socket.IO]: http://socket.io/
  [Fluentd]: http://fluentd.org/
  [Node.js]: http://nodejs.org/
