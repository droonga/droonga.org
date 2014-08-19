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
* Your `catalog.json` must have the dataset `Default`.
  Otherwise, you must change the name of the dataset, like:

        "datasets": {
      -   "Starbucks": {
      +   "Default": {
  
* Your `catalog.json` must have `dump` and `system` plugins in the list of plugins.
  Otherwise, you must add them to the list of `plugins`, like:
  
      - "plugins": ["groonga", "crud", "search"],
      + "plugins": ["groonga", "crud", "search", "dump", "system"],
  
* Your `catalog.json` must not have any information in its `schema` section.
  Otherwise, you must make the `schema` section empty, like:
  
      "schema": {},
  

## Backup data in a Droonga cluster

### Install `drndump`

First, install a command line tool named `drndump` via rubygems:

    # gem install drndump

After that, establish that the `drndump` command has been installed successfully:

    # drndump --version
    drndump 1.0.0

### Dump all data in a Droonga cluster

The `drndump` command extracts all schema and data as JSONs.
Let's dump contents of existing your Droonga cluster.

For example, if your cluster is constructed from two nodes `192.168.100.50` and `192.168.100.51`, and now you are logged in to the host `192.168.100.52` then the command line is:

~~~
# drndump --host=192.168.100.50 \
           --receiver-host=192.168.100.52
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

 * You must specify valid host name or IP address of one of nodes in the cluster, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send messages.
 * The result includes complete commands to construct a dataset, same to the source.

The result is printed to the standard output.
To save it as a JSONs file, you'll use a redirection like:

    # drndump --host=192.168.100.50 \
              --receiver-host=192.168.100.52 \
        > dump.jsons


## Restore data to a Droonga cluster

### Install `droonga-client`

The result of `drndump` command is a list of Droonga messages.

You need to use `droonga-send` command to send it to your Droogna cluster.
Install the command included in the package `droonga-client`, via rubygems:

    # gem install droonga-client

After that, establish that the `droonga-send` command has been installed successfully:

    # droonga-send --version
    droonga-send 0.1.9

### Prepare an empty Droonga cluster

Assume that there is an empty Droonga cluster constructed from two nodes `192.168.100.50` and `192.168.100.51`, now you are logged in to the host `192.168.100.52`, and there is a dump file `dump.jsons`.

If you are reading this tutorial sequentially, you'll have an existing cluster and the dump file.
Make it empty with these commands:

~~~
# endpoint="http://192.168.100.50:10041"
# curl "$endpoint/d/table_remove?name=Location" | jq "."
[
  [
    0,
    1406610703.2229023,
    0.0010793209075927734
  ],
  true
]
# curl "$endpoint/d/table_remove?name=Store" | jq "."
[
  [
    0,
    1406610708.2757723,
    0.006396293640136719
  ],
  true
]
# curl "$endpoint/d/table_remove?name=Term" | jq "."
[
  [
    0,
    1406610712.379644,
    6.723403930664062e-05
  ],
  true
]
~~~

After that the cluster becomes empty. Confirm it:

~~~
# endpoint="http://192.168.100.50:10041"
# curl "$endpoint/d/table_list" | jq "."
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
# curl "$endpoint/d/select?table=Store&output_columns=name&limit=10" | jq "."
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

### Restore data from a dump result, to an empty Droonga cluster

Because the result of the `drndump` command includes complete information to construct a dataset same to the source, you can re-construct your cluster from a dump file, even if the cluster is broken.
You just have to pour the contents of the dump file to an empty cluster, by the `droonga-send` command.

To restore the cluster from the dump file, run a command line like:

~~~
# droonga-send --server=192.168.100.50  \
                    dump.jsons
~~~

Note to these things:

 * You must specify valid host name or IP address of one of nodes in the cluster, via the option `--host`.
 * You must specify valid host name or IP address of the computer you are logged in, via the option `--receiver-host`.
   It is used by the Droonga cluster, to send response messages.

Then the data is completely restored. Confirm it:

~~~
# curl $endpoint/select?table=Store&output_columns=name&limit=10" | jq "."
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

Assume that there are two clusters: the source has a node `192.168.100.50`, and the destination has a node `192.168.100.51`.

If you are reading this tutorial sequentially, you'll have an existing cluster with two nodes.
Construct two clusters by `droonga-engine-catalog-modify` and make one cluster empty, with these commands:

    (on 192.168.100.50)
    # host=192.168.100.50
    # droonga-engine-catalog-modify --source=~/droonga/catalog.json \
                                    --update \
                                    --replica-hosts=$host

    (on 192.168.100.51)
    # host=192.168.100.51
    # droonga-engine-catalog-modify --source=~/droonga/catalog.json \
                                    --update \
                                    --replica-hosts=$host
    # endpoint="http://$host:10041"
    # curl "$endpoint/d/table_remove?name=Location"
    # curl "$endpoint/d/table_remove?name=Store"
    # curl "$endpoint/d/table_remove?name=Term"

After that there are two clusters: one contains `192.168.100.50` with data, another contains `192.168.100.51` with no data. Confirm it:


~~~
# curl "http://192.168.100.50:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.50:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.50:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
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
# curl "http://192.168.100.51:10041/droonga/system/status" | jq "."
{
  "nodes": {
    "192.168.100.51:10031/droonga": {
      "live": true
    }
  }
}
# curl "http://192.168.100.51:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
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

Note: `/droonga/system/status` may not return the result like above. It can cache the result of old status. We have to update these codes to confirm cluster changes.


### Duplicate data between two Droonga clusters

To copy data between two clusters, run the `droonga-engine-absorb-data` command on a node, like:

~~~
(on 192.168.100.50 or 192.168.100.51)
# droonga-engine-absorb-data --source-host=192.168.100.50 \
                             --destination-host=192.168.100.51
Start to absorb data from 192.168.100.50
                       to 192.168.100.51
  dataset = Default
  port    = 10031
  tag     = droonga

Absorbing...
...
Done.
~~~

After that contents of these two clusters are completely synchronized. Confirm it:

~~~
# curl "http://192.168.100.50:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
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
# curl "http://192.168.100.51:10041/d/select?table=Store&output_columns=name&limit=10" | jq "."
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

    (on 192.168.100.50)
    # droonga-engine-catalog-modify --source=~/droonga/catalog.json \
                                    --update \
                                    --add-replica-hosts=192.168.100.51

    (on 192.168.100.51)
    # droonga-engine-catalog-modify --source=~/droonga/catalog.json \
                                    --update \
                                    --add-replica-hosts=192.168.100.50

After that there is just one cluster - yes, it's the initial state.

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

## Conclusion

In this tutorial, you did backup a [Droonga][] cluster and restore the data.
Moreover, you did duplicate contents of an existing Droogna cluster to another empty cluster.

Next, let's learn [how to add a new replica to an existing Droonga cluster](../add-replica/).

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
