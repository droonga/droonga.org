---
title: "Droonga tutorial: Getting started/How to migrate from Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to run a Droonga cluster by your hand, and use it as a [Groonga][groonga] compatible server.

## Precondition

* You must have basic knowledge and experiences to set up and operate an [Ubuntu][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.

## What's Droonga?

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".
As its name suggests, it can work as a Groonga compatible server with some improvements - replication and sharding.

In a certain sense, the Droonga is quite different from Groonga, about its architecture, design, API etc.
However, you don't have to understand the whole architecture of the Droonga, if you simply use it just as a Groonga compatible server.

For example, let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).

## Set up a Droonga cluster

### Prepare an environment for experiments

Prepare a computer at first.
This tutorial describes steps to set up a Droonga cluster based on existing computers.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 13.10 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE: Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga.
Otherwise, you may experience a strange build error.

You need to prepare two or more computers for effective replication.

### Steps to install Droonga components

Groonga provides binary packages and you can install Groonga easily, for some environments.
(See: [how to install Groonga](http://groonga.org/docs/install.html))

However, currently there is no such an easy way to set up a database system based on Droonga.
We are planning to provide a better way (like a chef cookbook), but for now, you have to set up it by your hand.

A database system based on the Droonga is called *Droonga cluster*.
A Droonga cluster is constructed from multiple computers, called *Droonga node*.
So you have to set up multiple Droonga nodes for your Droonga cluster.

Assume that you have two computers: `192.168.0.10` and `192.168.0.11`.

 1. Install required platform packages, *on each computer*.
    
        # apt-get update
        # apt-get -y upgrade
        # apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm
    
 2. Install a gem package `droonga-engine`, *on each computer*.
    It is the core component provides most features of Droonga system.
    
        # gem install droonga-engine
    
 3. Install an npm package `droonga-http-server`, *on each computer*.
    It is the frontend component required to translate HTTP requests to Droonga's native one.
    
        # npm install -g droonga-http-server
    
 4. Prepare a configuration directory for a Droonga node, *on each computer*.
    All physical databases are placed under this directory.
    
        # mkdir ~/droonga
        # cd ~/droonga
    
 5. Create a `catalog.json`, *on one of Droonga nodes*.
    The file defines the structure of your Droonga cluster.
    You'll specify the name of the dataset via the `--dataset` option and the list of your Droonga node's IP addresses via the `--hosts` option, like:
    
        # droonga-engine-catalog-generate --hosts=192.168.0.10,192.168.0.11 \
                                          --output=./catalog.json
    
    If you have only one computer and trying to set up it just for testing, then you'll do:
    
        # droonga-engine-catalog-generate --hosts=127.0.0.1 \
                                          --output=./catalog.json
    
 6. Share the generated `catalog.json` *to your all Droonga nodes*.
    
        # scp ~/droonga/catalog.json 192.168.0.11:~/droonga/
    
    (Or, of course, you can generate same `catalog.json` on each computer, instead of copying.)

All Droonga nodes for your Droonga cluster are prepared by steps described above.
Let's continue to the next step.

## Use the Droonga cluster, via HTTP

### Start and stop services on each Droonga node

You can run Groonga as an HTTP server with the option `-d`, like:

    # groonga -p 10041 -d --protocol http /tmp/databases/db

On the other hand, you have to run multiple servers for each Droonga node to use your Droonga cluster via HTTP.

To start them, run commands like following on each Droonga node:

    # cd ~/droonga
    # host=192.168.0.10
    # droonga-engine --host=$host \
                     --log-file=$PWD/droonga-engine.log \
                     --daemon \
                     --pid-file=$PWD/droonga-engine.pid
    # env NODE_ENV=production \
        droonga-http-server --port=10041 \
                            --receive-host-name=$host \
                            --droonga-engine-host-name=$host \
                            --cache-size=-1 \
                            --daemon \
                            --pid-file=$PWD/droonga-http-server.pid

Note that you have to specify the host name of the Droonga node itself via some options.
It will be used to communicate with other Droonga nodes in the cluster.
So you have to specify different host name on another Droonga node, like:

    # cd ~/droonga
    # host=192.168.0.11
    # droonga-engine --host=$host \
    ...

By the command two nodes construct a cluster and they monitor each other.
If one of nodes dies and there is any still alive node, survivor(s) will work as the Droonga cluster.
Then you can recover the dead node and re-join it to the cluster secretly.

To stop services, run commands like following on each Droonga node:

    # kill $(cat ~/droonga/droonga-engine.pid)
    # kill $(cat ~/droonga/droonga-http-server.pid)

### Create a table, columns, and indexes

Now your Droonga cluster actually works as a Groonga's HTTP server.

Requests are completely same to ones for a Groonga server.
To create a new table `Store`, you just have to send a GET request for the `table_create` command, like:

    # endpoint="http://192.168.0.10:10041/d"
    # curl "${endpoint}/table_create?name=Store&flags=TABLE_PAT_KEY&key_type=ShortText"
    [[0,1401358896.360356,0.0035653114318847656],true]

Note that you have to specify the host, one of Droonga nodes with active droonga-http-server, in your Droonga cluster.
In other words, you can use any favorite node in the cluster as an endpoint.
All requests will be distributed to suitable nodes in the cluster.

Next, create new columns `name` and `location` to the `Store` table by the `column_create` command, like:

    # curl "${endpoint}/column_create?table=Store&name=name&flags=COLUMN_SCALAR&type=ShortText"
    [[0,1401358348.6541538,0.0004096031188964844],true]
    # curl "${endpoint}/column_create?table=Store&name=location&flags=COLUMN_SCALAR&type=WGS84GeoPoint"
    [[0,1401358359.084659,0.002511262893676758],true],true]

Create indexes also.

    # curl "${endpoint}/table_create?name=Term&flags=TABLE_PAT_KEY&key_type=ShortText&default_tokenizer=TokenBigram&normalizer=NormalizerAuto"
    [[0,1401358475.7229664,0.002419710159301758],true]
    # curl "${endpoint}/column_create?table=Term&name=store_name&flags=COLUMN_INDEX|WITH_POSITION&type=Store&source=name"
    [[0,1401358494.1656318,0.006799221038818359],true]
    # curl "${endpoint}/table_create?name=Location&flags=TABLE_PAT_KEY&key_type=WGS84GeoPoint"
    [[0,1401358505.708896,0.0016951560974121094],true]
    # curl "${endpoint}/column_create?table=Location&name=store&flags=COLUMN_INDEX&type=Store&source=location"
    [[0,1401358519.6187897,0.024788379669189453],true]

*IMPORTANT NOTE*: Don't run `table_list` or `column_list` before the table is completely created.
Otherwise indexes can be broken.
This is a known issue on the version 1.0.3, and it will be fixed in a future release.

OK, now the table has been created successfully.
Let's see it by the `table_list` command:

    # curl "${endpoint}/table_list"
    [[0,1401358908.9126804,0.001600027084350586],[[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],[256,"Store","/home/vagrant/droonga/000/db.0000100","TABLE_PAT_KEY|PERSISTENT","ShortText",null,null,null]]]

Because it is a cluster, another endpoint returns same result.

    # curl "http://192.168.0.11:10041/d/table_list"
    [[0,1401358908.9126804,0.001600027084350586],[[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],[256,"Store","/home/vagrant/droonga/000/db.0000100","TABLE_PAT_KEY|PERSISTENT","ShortText",null,null,null]]]

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

    # curl --data "@stores.json" "${endpoint}/load?table=Store"
    [[0,1401358564.909,0.158],[40]]

Now all data in the JSON file are successfully loaded.

### Select data from a table

OK, all data is now ready.

As the starter, let's select initial ten records with the `select` command:

    # curl "${endpoint}/select?table=Store&output_columns=name&limit=10"
    [[0,1401362059.7437818,0.00004935264587402344],[[[40],[["name","ShortText"]],["1st Avenue & 75th St. - New York NY  (W)"],["76th & Second - New York NY  (W)"],["Herald Square- Macy's - New York NY"],["Macy's 5th Floor - Herald Square - New York NY  (W)"],["80th & York - New York NY  (W)"],["Columbus @ 67th - New York NY  (W)"],["45th & Broadway - New York NY  (W)"],["Marriott Marquis - Lobby - New York NY"],["Second @ 81st - New York NY  (W)"],["52nd & Seventh - New York NY  (W)"]]]]

Of course you can specify conditions via the `query` option:

    # curl "${endpoint}/select?table=Store&query=Columbus&match_columns=name&output_columns=name&limit=10"
    [[0,1398670157.661574,0.0012705326080322266],[[[2],[["_key","ShortText"]],["Columbus @ 67th - New York NY  (W)"],["2 Columbus Ave. - New York NY  (W)"]]]]
    # curl "${endpoint}/select?table=Store&filter=name@'Ave'&output_columns=name&limit=10"
    [[0,1398670586.193325,0.0003848075866699219],[[[3],[["_key","ShortText"]],["2nd Ave. & 9th Street - New York NY"],["84th & Third Ave - New York NY  (W)"],["2 Columbus Ave. - New York NY  (W)"]]]]

## Conclusion

In this tutorial, you did set up a [Droonga][] cluster on [Ubuntu Linux][Ubuntu] computers.
Moreover, you load data to it and select data from it successfully, as a [Groonga][] compatible server.

Currently, Droonga supports only some limited features of Groonga compatible commands.
See the [command reference][] for more details.

Next, let's learn [how to backup and restore contents of a Droonga cluster](../dump-restore/).

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
