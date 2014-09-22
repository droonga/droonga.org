---
title: "Droonga tutorial: Getting started/How to migrate from Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to run a Droonga cluster by your hand, and use it as a [Groonga][groonga] compatible server.

## Precondition

* You must have basic knowledge and experiences to set up and operate an [Ubuntu][] or [CentOS][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.

## What's Droonga?

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".
As its name suggests, it can work as a Groonga compatible server with some improvements - replication and sharding.

In a certain sense, the Droonga is quite different from Groonga, about its architecture, design, API etc.
However, you don't have to understand the whole architecture of the Droonga, if you simply use it just as a Groonga compatible server.

For example, let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).

## Set up a Droonga cluster

A database system based on the Droonga is called *Droonga cluster*.
This section describes how to set up a Droonga cluster from scratch.

### Prepare computers for Droonga nodes

A Droonga cluster is constructed from one or more computers, called *Droonga node*(s).
Prepare computers for Droonga nodes at first.

This tutorial describes steps to set up Droonga cluster based on existing computers.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 14.04 x64` or `CentOS 7 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE:

 * Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga.
Otherwise, you may experience a strange build error.
 * Make sure the hostname reported by `hostname -f` or the IP address reported by `hostname -i` is correctly accessible from each other computer in your cluster.

You need to prepare two or more nodes for effective replication.
So this tutorial assumes that you have two computers:

 * has an IP address `192.168.100.50`, with a hostname `node0`.
 * has an IP address `192.168.100.51`, with a hostname `node1`.

### Set up computers as Droonga nodes

Groonga provides binary packages and you can install Groonga easily, for some environments.
(See: [how to install Groonga](http://groonga.org/docs/install.html))

On the other hand, there is installation scripts to set up a computer as a Droonga node.
Let's log in to the computer `192.168.100.50`, download two scripts, and run them by `bash` as the root user, like:

~~~
$ curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    sudo bash
$ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    sudo bash
~~~

If you are using a CentOS server, switch to the root before running, instead of using `sudo`, like:

~~~
$ su
# curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    bash
# curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    bash
~~~

If your computers cannot resolve IP addresse of each other by its host name, specify accessible IP address via environment variables, like:

~~~
$ host=192.168.100.50
$ curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    sudo HOST=$host bash
$ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    sudo ENGINE_HOST=$host HOST=$host bash
~~~

Then the computer `node0` (`192.168.100.50`) is successfully set up as a Droonga node.

Next, run the installation scripts on another node `node1` (`192.168.100.51`).
If the host name `node1` is not resolvable by others, don't forget to specify correct accessible IP address for the computer, like:

~~~
$ host=192.168.100.51
$ curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    sudo HOST=$host bash
$ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    sudo ENGINE_HOST=$host HOST=$host bash
~~~

OK, now two computers successfully start to work as Droonga nodes.

If the installation script doesn't work as expected, see [the tutorial to install services without installation script](../manual-install/).


### Configure nodes to work together as a cluster

Currently, these nodes are working just individually.
Let's configure them to work together as a cluster.

Run this command line on each node:

~~~
$ sudo -u droonga-engine -H \
    droonga-engine-catalog-generate --hosts=192.168.100.50,192.168.100.51 \
                                    --output=~droonga-engine/droonga/catalog.json
~~~

If you are using a CentOS server, switch to the root before running, instead of using `sudo`, like:

~~~
$ su
# droonga-engine-catalog-generate --hosts=192.168.100.50,192.168.100.51 \
                                  --output=~droonga-engine/droonga/catalog.json
# chown droogna-engine:droonga-engine ~droonga-engine/droonga/catalog.json
~~~

OK, now your Droonga cluster is correctly prepared.
Two nodes are working together as a Droonga cluster.

Let's continue to [the next step, "how to use the cluster"](#use).


## Use the Droonga cluster, via HTTP {#use}

### Start and stop services on each Droonga node

You can run Groonga as an HTTP server with the option `-d`, like:

    # groonga -p 10041 -d --protocol http /tmp/databases/db

On the other hand, you have to run multiple servers for each Droonga node to use your Droonga cluster via HTTP.

If services are installed by the installation script, they are already been configured as system services managed via the `service` command.
To start them, run commands like following on each Droonga node:

    # service droonga-engine start
    # service droonga-http-server start

If you installed services manually, see [the manual installation tutorial](../manual-install/#start-services).

By the command two nodes construct a cluster and they monitor each other.
If one of nodes dies and there is any still alive node, survivor(s) will work as the Droonga cluster.
Then you can recover the dead node and re-join it to the cluster secretly.

Let's make sure that the cluster works, by the `system.status` command.
You can see the result via HTTP, like:

~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
~~~

The result says that two nodes are working correctly.
Because it is a cluster, another endpoint returns same result.

~~~
# curl "http://192.168.100.51:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    },
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
~~~

To stop services, run commands like following on each Droonga node:

    # service droonga-engine stop
    # service droonga-http-server stop

If you installed services manually, see [the manual installation tutorial](../manual-install/#stop-services).

After verification, start services again, on each Droonga node.

### Create a table, columns, and indexes

Now your Droonga cluster actually works as a Groonga's HTTP server.

Requests are completely same to ones for a Groonga server.
To create a new table `Store`, you just have to send a GET request for the `table_create` command, like:

~~~
# endpoint="http://192.168.100.50:10041"
# curl "$endpoint/d/table_create?name=Store&flags=TABLE_PAT_KEY&key_type=ShortText" | jq "."
[
  [
    0,
    1401358896.360356,
    0.0035653114318847656
  ],
  true
]
~~~


Note that you have to specify the host, one of Droonga nodes with active droonga-http-server, in your Droonga cluster.
In other words, you can use any favorite node in the cluster as an endpoint.
All requests will be distributed to suitable nodes in the cluster.

Next, create new columns `name` and `location` to the `Store` table by the `column_create` command, like:

~~~
# curl "$endpoint/d/column_create?table=Store&name=name&flags=COLUMN_SCALAR&type=ShortText" | jq "."
[
  [
    0,
    1401358348.6541538,
    0.0004096031188964844
  ],
  true
]
# curl "$endpoint/d/column_create?table=Store&name=location&flags=COLUMN_SCALAR&type=WGS84GeoPoint" | jq "."
[
  [
    0,
    1401358359.084659,
    0.002511262893676758
  ],
  true
]
~~~

Create indexes also.

~~~
# curl "$endpoint/d/table_create?name=Term&flags=TABLE_PAT_KEY&key_type=ShortText&default_tokenizer=TokenBigram&normalizer=NormalizerAuto" | jq "."
[
  [
    0,
    1401358475.7229664,
    0.002419710159301758
  ],
  true
]
# curl "$endpoint/d/column_create?table=Term&name=store_name&flags=COLUMN_INDEX|WITH_POSITION&type=Store&source=name" | jq "."
[
  [
    0,
    1401358494.1656318,
    0.006799221038818359
  ],
  true
]
# curl "$endpoint/d/table_create?name=Location&flags=TABLE_PAT_KEY&key_type=WGS84GeoPoint" | jq "."
[
  [
    0,
    1401358505.708896,
    0.0016951560974121094
  ],
  true
]
# curl "$endpoint/d/column_create?table=Location&name=store&flags=COLUMN_INDEX&type=Store&source=location" | jq "."
[
  [
    0,
    1401358519.6187897,
    0.024788379669189453
  ],
  true
]
~~~

*IMPORTANT NOTE*: Don't run `table_list` or `column_list` before the table is completely created.
Otherwise indexes can be broken.
This is a known issue on the version {{ site.droonga_version }}, and it will be fixed in a future release.

OK, now the table has been created successfully.
Let's see it by the `table_list` command:

~~~
# curl "$endpoint/d/table_list" | jq "."
[
  [
    0,
    1401358908.9126804,
    0.001600027084350586
  ],
  [
    [
      [
        "id",
        "UInt32"
      ],
      [
        "name",
        "ShortText"
      ],
      [
        "path",
        "ShortText"
      ],
      [
        "flags",
        "ShortText"
      ],
      [
        "domain",
        "ShortText"
      ],
      [
        "range",
        "ShortText"
      ],
      [
        "default_tokenizer",
        "ShortText"
      ],
      [
        "normalizer",
        "ShortText"
      ]
    ],
    [
      256,
      "Store",
      "/home/vagrant/droonga/000/db.0000100",
      "TABLE_PAT_KEY|PERSISTENT",
      "ShortText",
      null,
      null,
      null
    ]
  ]
]
~~~

Because it is a cluster, another endpoint returns same result.

~~~
# curl "http://192.168.100.51:10041/d/table_list" | jq "."
[
  [
    0,
    1401358908.9126804,
    0.001600027084350586
  ],
  [
    [
      [
        "id",
        "UInt32"
      ],
      [
        "name",
        "ShortText"
      ],
      [
        "path",
        "ShortText"
      ],
      [
        "flags",
        "ShortText"
      ],
      [
        "domain",
        "ShortText"
      ],
      [
        "range",
        "ShortText"
      ],
      [
        "default_tokenizer",
        "ShortText"
      ],
      [
        "normalizer",
        "ShortText"
      ]
    ],
    [
      256,
      "Store",
      "/home/vagrant/droonga/000/db.0000100",
      "TABLE_PAT_KEY|PERSISTENT",
      "ShortText",
      null,
      null,
      null
    ]
  ]
]
~~~

### Load data to a table

Let's load data to the `Store` table.
First, prepare the data as a JSON file `stores.json`.

stores.json:

~~~
[
["_key","name","location"],
["store0","1st Avenue & 75th St. - New York NY  (W)","40.770262,-73.954798"],
["store1","76th & Second - New York NY  (W)","40.771056,-73.956757"],
["store2","2nd Ave. & 9th Street - New York NY","40.729445,-73.987471"],
["store3","15th & Third - New York NY  (W)","40.733946,-73.9867"],
["store4","41st and Broadway - New York NY  (W)","40.755111,-73.986225"],
["store5","84th & Third Ave - New York NY  (W)","40.777485,-73.954979"],
["store6","150 E. 42nd Street - New York NY  (W)","40.750784,-73.975582"],
["store7","West 43rd and Broadway - New York NY  (W)","40.756197,-73.985624"],
["store8","Macy's 35th Street Balcony - New York NY","40.750703,-73.989787"],
["store9","Macy's 6th Floor - Herald Square - New York NY  (W)","40.750703,-73.989787"],
["store10","Herald Square- Macy's - New York NY","40.750703,-73.989787"],
["store11","Macy's 5th Floor - Herald Square - New York NY  (W)","40.750703,-73.989787"],
["store12","80th & York - New York NY  (W)","40.772204,-73.949862"],
["store13","Columbus @ 67th - New York NY  (W)","40.774009,-73.981472"],
["store14","45th & Broadway - New York NY  (W)","40.75766,-73.985719"],
["store15","Marriott Marquis - Lobby - New York NY","40.759123,-73.984927"],
["store16","Second @ 81st - New York NY  (W)","40.77466,-73.954447"],
["store17","52nd & Seventh - New York NY  (W)","40.761829,-73.981141"],
["store18","1585 Broadway (47th) - New York NY  (W)","40.759806,-73.985066"],
["store19","85th & First - New York NY  (W)","40.776101,-73.949971"],
["store20","92nd & 3rd - New York NY  (W)","40.782606,-73.951235"],
["store21","165 Broadway - 1 Liberty - New York NY  (W)","40.709727,-74.011395"],
["store22","1656 Broadway - New York NY  (W)","40.762434,-73.983364"],
["store23","54th & Broadway - New York NY  (W)","40.764275,-73.982361"],
["store24","Limited Brands-NYC - New York NY","40.765219,-73.982025"],
["store25","19th & 8th - New York NY  (W)","40.743218,-74.000605"],
["store26","60th & Broadway-II - New York NY  (W)","40.769196,-73.982576"],
["store27","63rd & Broadway - New York NY  (W)","40.771376,-73.982709"],
["store28","195 Broadway - New York NY  (W)","40.710703,-74.009485"],
["store29","2 Broadway - New York NY  (W)","40.704538,-74.01324"],
["store30","2 Columbus Ave. - New York NY  (W)","40.769262,-73.984764"],
["store31","NY Plaza - New York NY  (W)","40.702802,-74.012784"],
["store32","36th and Madison - New York NY  (W)","40.748917,-73.982683"],
["store33","125th St. btwn Adam Clayton & FDB - New York NY","40.808952,-73.948229"],
["store34","70th & Broadway - New York NY  (W)","40.777463,-73.982237"],
["store35","2138 Broadway - New York NY  (W)","40.781078,-73.981167"],
["store36","118th & Frederick Douglas Blvd. - New York NY  (W)","40.806176,-73.954109"],
["store37","42nd & Second - New York NY  (W)","40.750069,-73.973393"],
["store38","Broadway @ 81st - New York NY  (W)","40.784972,-73.978987"],
["store39","Fashion Inst of Technology - New York NY","40.746948,-73.994557"]
]
~~~

Then, send it as a POST request of the `load` command, like:

~~~
# curl --data "@stores.json" "$endpoint/d/load?table=Store" | jq "."
[
  [
    0,
    1401358564.909,
    0.158
  ],
  [
    40
  ]
]
~~~

Now all data in the JSON file are successfully loaded.

### Select data from a table

OK, all data is now ready.

As the starter, let's select initial ten records with the `select` command:

~~~
# curl "$endpoint/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401362059.7437818,
    4.935264587402344e-05
  ],
  [
    [
      [
        40
      ],
      [
        [
          "name",
          "ShortText"
        ]
      ],
      [
        "1st Avenue & 75th St. - New York NY  (W)"
      ],
      [
        "76th & Second - New York NY  (W)"
      ],
      [
        "Herald Square- Macy's - New York NY"
      ],
      [
        "Macy's 5th Floor - Herald Square - New York NY  (W)"
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
        "Marriott Marquis - Lobby - New York NY"
      ],
      [
        "Second @ 81st - New York NY  (W)"
      ],
      [
        "52nd & Seventh - New York NY  (W)"
      ]
    ]
  ]
]
~~~

Of course you can specify conditions via the `query` option:

~~~
# curl "$endpoint/d/select?table=Store&query=Columbus&match_columns=name&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1398670157.661574,
    0.0012705326080322266
  ],
  [
    [
      [
        2
      ],
      [
        [
          "_key",
          "ShortText"
        ]
      ],
      [
        "Columbus @ 67th - New York NY  (W)"
      ],
      [
        "2 Columbus Ave. - New York NY  (W)"
      ]
    ]
  ]
]
# curl "$endpoint/d/select?table=Store&filter=name@'Ave'&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1398670586.193325,
    0.0003848075866699219
  ],
  [
    [
      [
        3
      ],
      [
        [
          "_key",
          "ShortText"
        ]
      ],
      [
        "2nd Ave. & 9th Street - New York NY"
      ],
      [
        "84th & Third Ave - New York NY  (W)"
      ],
      [
        "2 Columbus Ave. - New York NY  (W)"
      ]
    ]
  ]
]
~~~

## Conclusion

In this tutorial, you did set up a [Droonga][] cluster on [Ubuntu Linux][Ubuntu] or [CentOS][] computers.
Moreover, you load data to it and select data from it successfully, as a [Groonga][] compatible server.

Currently, Droonga supports only some limited features of Groonga compatible commands.
See the [command reference][] for more details.

Next, let's learn [how to backup and restore contents of a Droonga cluster](../dump-restore/).

  [Ubuntu]: http://www.ubuntu.com/
  [CentOS]: https://www.centos.org/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
