---
title: "How to benchmark Droonga with Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to benchmark a [Droonga][] cluster and compare it to a [Groonga][groonga] server.

## Precondition

* You must have basic knowledge and experiences to set up and operate an [Ubuntu][] or [CentOS][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.
* You must have basic knowledge to construct a [Droonga][] cluster.
  Please complete the ["getting started" tutorial](../groonga/) before this.

And, assume that there are three [Ubuntu][] 14.04LTS servers for the new Droogna cluster:

 * `192.168.100.50`
 * `192.168.100.51`
 * `192.168.100.52`

## Why benchmarking?

Because Droonga has compatibility to Groonga, you'll plan to migrate your application based on Groonga to Droonga.
Before that, you should benchmark Droonga and confirm that it is better alternative for your application.

Of course you may simply hope to know the difference in performance between Groonga and Droonga.
Benchmarking will make it clear.

### Ensure an existing reference database (and the data source)

If you have any existing service based on Groonga, it becomes the reference.
Then you just have to dump all data in your Groonga database and load them to a new Droonga cluster.

Otherwise - if you have no existing service, prepare a new reference database with much data for effective benchmark.
The repository [wikipedia-search][] includes some helper scripts to construct your Groonga server (and Droonga cluster), with [Japanese Wikipedia](http://ja.wikipedia.org/) pages.

So let's prepare a new Groonga database including Wikipedia pages, on a node `192.168.100.50`.

 1. Determine the size of the database.
    You have to use good enough size database for benchmarking.
    
    * If it is too small, you'll see "too bad" benchmark result for Droonga, because the percentage of the Droonga's overhead becomes relatively too large.
    * If it is too large, you'll see "too unstable" result because swapping of RAM will slow the performance down randomly.
    * If RAM size of all nodes are different, you should determine the size of the database for the minimum size RAM.

    For example, if there are three nodes `192.168.100.50` (8GB RAM), `192.168.100.51` (8GB RAM), and `192.168.100.52` (6GB RAM), then the database should be smaller than 6GB.
 2. Set up the Groonga server, as instructed on [the installation guide](http://groonga.org/docs/install.html).
    
    ~~~
    (on 192.168.100.50)
    % sudo apt-get -y install software-properties-common
    % sudo add-apt-repository -y universe
    % sudo add-apt-repository -y ppa:groonga/ppa
    % sudo apt-get update
    % sudo apt-get -y install groonga
    ~~~
    
    Then the Groonga becomes available.
 3. Download the archive of Wikipedia pages and convert it to a dump file for Groonga, with the rake task `data:convert:groonga:ja`.
    You can specify the number of records (pages) to be converted via the environment variable `MAX_N_RECORDS` (default=5000).
    
    ~~~
    (on 192.168.100.50)
    % cd ~/
    % git clone https://github.com/droonga/wikipedia-search.git
    % cd wikipedia-search
    % bundle install
    % time (MAX_N_RECORDS=100000 bundle exec rake data:convert:groonga:ja \
                                   data/groonga/ja-pages.grn)
    ~~~
    
    Because the archive is very large, downloading and data conversion may take time.
    
    After that, a dump file `~/wikipedia-search/data/groonga/ja-pages.grn` is there.
    Create a new database and load the dump file to it.
    This also may take more time:
    
    ~~~
    (on 192.168.100.50)
    % mkdir -p $HOME/groonga/db/
    % groonga -n $HOME/groonga/db/db quit
    % time (cat ~/wikipedia-search/config/groonga/schema.grn | groonga $HOME/groonga/db/db)
    % time (cat ~/wikipedia-search/config/groonga/indexes.grn | groonga $HOME/groonga/db/db)
    % time (cat ~/wikipedia-search/data/groonga/ja-pages.grn | groonga $HOME/groonga/db/db)
    ~~~
    
    Note: number of records affects to the database size.
    Just for information, my results are here:
    
     * 1.1GB database was constructed from 300000 records.
       Data conversion took 17 min, data loading took 6 min.
     * 4.3GB database was constructed from 1500000 records.
       Data conversion took 53 min, data loading took 64 min.
    
 4. Start the Groonga as an HTTP server.
    
    ~~~
    (on 192.168.100.50)
    % groonga -p 10041 -d --protocol http $HOME/groonga/db/db
    ~~~

OK, now we can use this node as the reference for benchmarking.


## Set up a Droonga cluster

Install Droonga to all nodes.
Because we are benchmarking it via HTTP, you have to install both services `droonga-engine` and `droonga-http-server` for each node.

~~~
(on 192.168.100.50)
% host=192.168.100.50
% curl https://raw.githubusercontent.com/droonga/droonga-engine/master/install.sh | \
    sudo HOST=$host bash
% curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | \
    sudo ENGINE_HOST=$host HOST=$host PORT=10042 bash
% sudo droonga-engine-catalog-generate \
    --hosts=192.168.100.50,192.168.100.51,192.168.100.52
% sudo service droonga-engine start
% sudo service droonga-http-server start
~~~

~~~
(on 192.168.100.51)
% host=192.168.100.51
...
~~~

~~~
(on 192.168.100.52)
% host=192.168.100.52
...
~~~

Note: to start `droonga-http-server` with a port number different from Groonga, we should specify another port `10042` via the `PORT` environment variable, like above.


## Synchronize data from Groonga to Droonga

Next, prepare the Droonga database.
Send Droonga messages from dump files, like:

~~~
(on 192.168.100.50)
% sudo gem install grn2drn
% time (cat ~/wikipedia-search/config/groonga/schema.grn | \
          grn2drn | \
          droonga-send --server=192.168.100.50 \
                       --report-throughput)
% time (cat ~/wikipedia-search/config/groonga/indexes.grn | \
          grn2drn | \
          droonga-send --server=192.168.100.50 \
                       --report-throughput)
% time (cat ~/wikipedia-search/data/groonga/ja-pages.grn | \
          grn2drn | \
          droonga-send --server=192.168.100.50 \
                       --server=192.168.100.51 \
                       --server=192.168.100.52 \
                       --report-throughput)
~~~

Note that you must send requests for schema and indexes to just one endpoint.
Parallel sending of schema definition requests for multiple nodes will break the database.

This may take much time.
After all, now you have two HTTP servers: Groonga HTTP server with the port `10041`, and Droonga HTTP Servers with the port `10042`.


(TBD, based on https://github.com/droonga/presentation-droonga-meetup-1-introduction/blob/master/benchmark/README.md )

 * The cache hit rate for requests is 50%.



  [Ubuntu]: http://www.ubuntu.com/
  [CentOS]: https://www.centos.org/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [wikipedia-search]: https://github.com/droonga/wikipedia-search.git
  [command reference]: ../../reference/commands/
