---
title: "Droonga tutorial: How to backup and restore the database?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to backup and restore data by your hand.

## Precondition

* You must have an existing [Droonga][] cluster with some data.
  Please complete the ["getting started" tutorial](../groonga/) before this.

This tutorial assumes that there are two existing Droonga nodes prepared by the [previous tutorial](../groonga/): `node0` (`192.168.100.50`) and `node1` (`192.168.100.51`), and there is another computer `node2` (`192.168.100.52`) as a working environment.
If you have Droonga nodes with other names, read `node0`, `node1` and `node2` in following descriptions as yours.

## Backup data in a Droonga cluster

### Install `drndump`

First, install a command line tool named `drndump` via rubygems, to your working machine:

~~~
# gem install drndump
~~~

After that, establish that the `drndump` command has been installed successfully:

~~~
$ drndump --version
drndump 1.0.0
~~~

### Dump all data in a Droonga cluster

The `drndump` command extracts all schema and data as JSONs.
Let's dump contents of existing your Droonga cluster.

For example, if your cluster is constructed from two nodes `node0` (`192.168.100.50`) and `node1` (`192.168.100.51`), and now you are logged in to new another computer `node2` (`192.168.100.52`). then the command line is:

~~~
# drndump --host=node0 \
           --receiver-host=node2
{
  "type": "table_create",
  "dataset": "Default",
  "body": {
    "name": "Location",
    "flags": "TABLE_PAT_KEY",
    "key_type": "WGS84GeoPoint"
  }
}
...
{
  "dataset": "Default",
  "body": {
    "table": "Store",
    "key": "store9",
    "values": {
      "location": "146702531x-266363233",
      "name": "Macy's 6th Floor - Herald Square - New York NY  (W)"
    }
  },
  "type": "add"
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Location",
    "name": "store",
    "type": "Store",
    "flags": "COLUMN_INDEX",
    "source": "location"
  }
}
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Term",
    "name": "store_name",
    "type": "Store",
    "flags": "COLUMN_INDEX|WITH_POSITION",
    "source": "name"
  }
}
~~~

Note to these things:

 * You must specify valid host name of one of nodes in the cluster, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send response messages.
 * The result includes complete commands to construct a dataset, same to the source.

The result is printed to the standard output.
To save it as a JSONs file, you'll use a redirection like:

~~~
$ drndump --host=node0 \
          --receiver-host=node2 \
    > dump.jsons
~~~


## Restore data to a Droonga cluster

### Install `droonga-client`

The result of `drndump` command is a list of Droonga messages.

You need to use `droonga-send` command to send it to your Droogna cluster.
Install the command included in the package `droonga-client`, via rubygems:

~~~
# gem install droonga-client
~~~

After that, establish that the `droonga-send` command has been installed successfully:

~~~
$ droonga-send --version
droonga-send 0.1.9
~~~

### Prepare an empty Droonga cluster

Assume that there is an empty Droonga cluster constructed from two nodes `node0` (`192.168.100.50`) and `node1` (`192.168.100.51`), now you are logged in to the host `node2` (`192.168.100.52`), and there is a dump file `dump.jsons`.

If you are reading this tutorial sequentially, you'll have an existing cluster and the dump file.
Make it empty with these commands:

~~~
$ endpoint="http://node0:10041"
$ curl "$endpoint/d/table_remove?name=Location" | jq "."
[
  [
    0,
    1406610703.2229023,
    0.0010793209075927734
  ],
  true
]
$ curl "$endpoint/d/table_remove?name=Store" | jq "."
[
  [
    0,
    1406610708.2757723,
    0.006396293640136719
  ],
  true
]
$ curl "$endpoint/d/table_remove?name=Term" | jq "."
[
  [
    0,
    1406610712.379644,
    6.723403930664062e-05
  ],
  true
]
~~~

After that the cluster becomes empty.
Let's confirm it.
You'll see empty result by `select` and `table_list` commands, like:

~~~
$ curl "$endpoint/d/table_list" | jq "."
[
  [
    0,
    1406610804.1535122,
    0.0002875328063964844
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
    ]
  ]
]
$ curl -X DELETE "$endpoint/cache" | jq "."
true
$ curl "$endpoint/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401363465.610241,
    0
  ],
  [
    [
      [
        null
      ],
      []
    ]
  ]
]
~~~

Note, clear the response cache before sending a request for the `select` command.
Otherwise you'll see unexpected cached result based on old configurations.

Response caches are stored for recent 100 requests, and their lifetime is 1 minute, by default.
You can clear all response caches manually by sending an HTTP `DELETE` request to the path `/cache`, like above.

### Restore data from a dump result, to an empty Droonga cluster

Because the result of the `drndump` command includes complete information to construct a dataset same to the source, you can re-construct your cluster from a dump file, even if the cluster is broken.
You just have to pour the contents of the dump file to an empty cluster, by the `droonga-send` command.

To restore the cluster from the dump file, run a command line like:

~~~
$ droonga-send --server=node0  \
                    dump.jsons
~~~

Note:

 * You must specify valid host name or IP address of one of nodes in the cluster, via the option `--host`.

Then the data is completely restored. Confirm it:

~~~
$ curl -X DELETE "$endpoint/cache" | jq "."
true
$ curl "$endpoint/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
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

## Duplicate an existing Droonga cluster to another empty cluster directly

If you have multiple Droonga clusters, then you can duplicate one to another.
For this purpose, the package `droonga-engine` includes a utility command `droonga-engine-absorb-data`.
It copies all data from an existing cluster to another one directly, so it is recommended if you don't need to save dump file locally.

### Prepare multiple Droonga clusters

Assume that there are two clusters: the source has a node `node0` (`192.168.100.50`), and the destination has a node `node1' (`192.168.100.51`).

If you are reading this tutorial sequentially, you'll have an existing cluster with two nodes.
Construct two clusters by `droonga-engine-catalog-modify` and make one cluster empty, with these commands:

~~~
(on node0)
# droonga-engine-catalog-modify --replica-hosts=node0
~~~

~~~
(on node1)
# droonga-engine-catalog-modify --replica-hosts=node1
$ endpoint="http://node1:10041"
$ curl "$endpoint/d/table_remove?name=Location"
$ curl "$endpoint/d/table_remove?name=Store"
$ curl "$endpoint/d/table_remove?name=Term"
~~~

After that there are two clusters: one contains `node0` with data, another contains `node1` with no data. Confirm it:


~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    }
  }
}
$ curl -X DELETE "http://node0:10041/cache" | jq "."
true
$ curl "http://node0:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
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
$ curl "http://node1:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node1:10031/droonga": {
      "live": true
    }
  }
}
$ curl -X DELETE "http://node1:10041/cache" | jq "."
true
$ curl "http://node1:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401363465.610241,
    0
  ],
  [
    [
      [
        null
      ],
      []
    ]
  ]
]
~~~


### Duplicate data between two Droonga clusters

To copy data between two clusters, run the `droonga-engine-absorb-data` command on a node, like:

~~~
(on node0 or node1)
$ droonga-engine-absorb-data --source-host=node0 \
                             --destination-host=node1
Start to absorb data from node0
                       to node1
  dataset = Default
  port    = 10031
  tag     = droonga

Absorbing...
...
Done.
~~~

After that contents of these two clusters are completely synchronized. Confirm it:

~~~
$ curl -X DELETE "http://node1:10041/cache" | jq "."
true
$ curl "http://node1:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
[
  [
    0,
    1401363556.0294158,
    7.62939453125e-05
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

### Unite two Droonga clusters

Run following command lines to unite these two clusters:

~~~
(on node0)
# droonga-engine-catalog-modify --add-replica-hosts=node1
~~~

~~~
(on node1)
# droonga-engine-catalog-modify --add-replica-hosts=node0
~~~

After that there is just one cluster - yes, it's the initial state.

~~~
$ curl "http://node0:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "node0:10031/droonga": {
      "live": true
    },
    "node1:10031/droonga": {
      "live": true
    }
  }
}
~~~

## Conclusion

In this tutorial, you did backup a [Droonga][] cluster and restore the data.
Moreover, you did duplicate contents of an existing Droogna cluster to another empty cluster.

Next, let's learn [how to add a new replica to an existing Droonga cluster](../add-replica/).

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
