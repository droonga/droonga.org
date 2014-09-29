---
title: "How to benchmark Droonga with Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to benchmark a [Droonga][] cluster and compare it to a [Groonga][groonga].

## Precondition

* You must have basic knowledge and experiences to set up and operate an [Ubuntu][] or [CentOS][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.
* You must have basic knowledge to construct a [Droonga][] cluster by your hand.
  Please complete the ["getting started" tutorial](../groonga/) before this.

## Why benchmarking?

Because Droonga has compatibility to Groonga, you'll plan to migrate your application based on Groonga to Droonga.
Before that, you should benchmark Droonga and confirm that it is better alternative for your application.

For example, assume that your application has following spec:

 * The database contains all pages of [Japanese Wikipedia](http://ja.wikipedia.org/).
 * 50% accesses are a fixed query for the front page. Others have different search queries.
 * There are three [Ubuntu][] 14.04LTS servers for the new Droogna cluster: `192.168.0.10`, `192.168.0.11`, and `192.168.0.12`.

## Prepare the data source

First, download the archive of Wikipedia pages and convert it to a dump file for Groonga, on the node `192.168.0.10`.
Because the archive is very large, downloading and data conversion may take some a few hours.

    (on 192.168.0.10)
    % cd ~/
    % git clone https://github.com/droonga/wikipedia-search.git
    % cd wikipedia-search
    % bundle install
    % time rake data:convert:groonga:ja data/groonga/ja-all-pages.grn

After that, a dump file `~/wikipedia-search/data/groonga/ja-all-pages.grn` becomes available.

## Set up a Groonga server

As a criterion, let's setup the Groonga on the node `192.168.0.10`.

    (on 192.168.0.10)
    % sudo apt-get -y install software-properties-common
    % sudo add-apt-repository -y universe
    % sudo add-apt-repository -y ppa:groonga/ppa
    % sudo apt-get update
    % sudo apt-get -y install groonga

Now the Groonga is available.
Prepare the database based dump files.
This may take much time (10 or more hours).

    (on 192.168.0.10)
    % mkdir -p $HOME/groonga/db/
    % groonga -n $HOME/groonga/db/db quit
    % time (cat ~/wikipedia-search/config/groonga/schema.grn | groonga $HOME/groonga/db/db)
    % time (cat ~/wikipedia-search/config/groonga/indexes.grn | groonga $HOME/groonga/db/db)
    % time (cat ~/wikipedia-search/data/groonga/ja-all-pages.grn | groonga $HOME/groonga/db/db)

Then start the Groonga as an HTTP server.

    (on 192.168.0.10)
    % groonga -p 10041 -d --protocol http $HOME/groonga/db/db

## Set up a Droonga cluster

Install Droonga to nodes.

    (on 192.168.0.10, 192.168.0.11, 192.168.0.12)
    % sudo apt-get update
    % sudo apt-get -y upgrade
    % sudo apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm
    % sudo gem install droonga-engine grn2drn drnbench
    % sudo npm install -g droonga-http-server
    % mkdir ~/droonga
    % droonga-engine-catalog-generate \
        --hosts=192.168.0.10,192.168.0.11,192.168.0.12 \
        --n-workers=$(cat /proc/cpuinfo | grep processor | wc -l) \
        --output=~/droonga/catalog.json

After installation, start servers.
To run Groonga and Droonga parallelly, specify a new port number for the `droonga-http-server` different to Groonga's one.
Now we use `10042` for Droonga, `10041` for Groonga.

    (on 192.168.0.10)
    % export host=192.168.0.10
    % export DROONGA_BASE_DIR=$HOME/droonga
    % droonga-engine --host=$host \
        --log-file=$DROONGA_BASE_DIR/droonga-engine.log \
        --daemon \
        --pid-file=$DROONGA_BASE_DIR/droonga-engine.pid
    % droonga-http-server --port=10042 \
        --receive-host-name=$host \
        --droonga-engine-host-name=$host \
        --environment=production \
        --daemon \
        --pid-file=$DROONGA_BASE_DIR/droonga-http-server.pid

    (on 192.168.0.11)
    % export host=192.168.0.11
    ...

    (on 192.168.0.12)
    % export host=192.168.0.12
    ...

Next, prepare the database from dump files.
Note that you must send requests for schema and indexes to just one endpoint, because parallel sending of schema definition requests for multiple nodes will break the database.

    (on 192.168.0.10)
    % time (cat ~/wikipedia-search/config/groonga/schema.grn | grn2drn | \
              droonga-send --server=192.168.0.10)
    % time (cat ~/wikipedia-search/config/groonga/indexes.grn | grn2drn | \
              droonga-send --server=192.168.0.10)

Instead you can use a direct dump from the Groonga server, like:

    (on 192.168.0.10)
    % time (grndump --no-dump-tables $HOME/groonga/db/db | grn2drn | \
              droonga-send --server=192.168.0.10 \
                           --report-throughput)

After that, import data from the dump file.

    (on 192.168.0.10)
    % time (cat ~/wikipedia-search/data/groonga/ja-pages.grn | grn2drn | \
              droonga-send --server=192.168.0.10 \
                           --server=192.168.0.11 \
                           --server=192.168.0.12)

Instead you can use a direct dump from the Groonga server, like:

    (on 192.168.0.10)
    % time (grndump --no-dump-schema --no-dump-indexes $HOME/groonga/db/db | \
              grn2drn | \
              droonga-send --server=192.168.0.10 \
                           --server=192.168.0.11 \
                           --server=192.168.0.12 \
                           --report-throughput)

This may take much time (10 or more hours).



(TBD, based on https://github.com/droonga/presentation-droonga-meetup-1-introduction/blob/master/benchmark/README.md )




  [Ubuntu]: http://www.ubuntu.com/
  [CentOS]: https://www.centos.org/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
