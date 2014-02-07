---
title: Catalog
layout: en
---

A Droonga network consists of several resources. You need to describe
them in **catalog**. All the nodes in the network shares the same
catalog.

This documentation describes about catalog.

 * TOC
{:toc}

## How to manage

So far, you need to write catalog and share it to all the nodes
manually.

Some utility programs will generate catalog in near feature.
Furthermore Droonga network will maintain and share catalog
automatically.

## Glossary

This section describes terms in catalog.

### Catalog

Catalog is a series of data which represents the resources in the
network.

### Zone

Zone is a set of farms. Farms in a zone are expected to close to each
other, like in the same host, in the same switch, in the same network.

### Farm

A farm is a Droonga Engine instance. Droonga Engine is implemented as
a [Fluentd][] plugin, fluent-plugin-droonga.

A `fluentd` process can have multiple Droonga Engines. If you add one
or more `match` entries with type `droonga` into `fluentd.conf`, a
`fluentd` process instantiates one or more Droonga Engines.

A farm has its own workers and a job queue. A farm push request to its
job queue and workers pull a request from the job queue.

### Dataset

Dataset is a set of logical tables. A logical table must belong to
only one dataset.

Each dataset must have an unique name in the same Droonga network.

### Logical table

Logical table consists of one or more partitioned physical tables.
Logical table doesn't have physical records. It returns physical
records from physical tables.

You can custom how to partition a logical table into one or more
physical tables. For example, you can custom partition key, the
number of partitions and so on.

### Physical table

Physical table is a table in Groonga database. It stores physical
records to the table.

### Ring

Ring is a series of partition sets. Dataset must have one
ring. Dataset creates logical tables on the ring.

Droonga Engine replicates each record in a logical table into one or
more partition sets.

### Partition set

Partition set is a set of partitions. A partition set stores all
records in all logical tables in the same Droonga network. In other
words, dataset is partitioned in a partition set.

A partition set is a replication of other partition set.

Droonga Engine may support partitioning in one or more partition
sets in the future. It will be useful to use different partition
size for old data and new data. Normally, old data are smaller and
new data are bigger. It is reasonable that you use larger partition
size for bigger data.

### Partition

Partition is a Groonga database. It has zero or more physical
tables.

### Plugin

Droonga Engine can be extended by writing plugin scripts.
In most cases, a series of plugins work cooperatively to
achieve required behaviors.
So, plugins are organized by behaviors.
Each behavior can be attached to datasets and/or tables by
adding "plugins" section to the corresponding entry in the catalog.

More than one plugin can be assigned in a "plugins" section as an array.
The order in the array controls the execution order of plugins
when adapting messages.
When adapting an incoming message, plugins are applied in forward order
whereas those are applied in reverse order when adapting an outgoing message.

## Example

Consider the following case:

 * There are two farms.
 * All farms (Droonga Engine instances) works on the same fluentd.
 * Each farm has two partitions.
 * There are two replicas.
 * There are two partitions for each table.

Catalog is written as a JSON file. Its file name is `catalog.json`.

Here is a `catalog.json` for the above case:

~~~json
{
  "version": 1,
  "effective_date": "2013-06-05T00:05:51Z",
  "zones": ["localhost:23003/farm0", "localhost:23003/farm1"],
  "farms": {
    "localhost:23003/farm0": {
      "device": "disk0",
      "capacity": 1024
    },
    "localhost:23003/farm1": {
      "device": "disk1",
      "capacity": 1024
    }
  },
  "datasets": {
    "Wiki": {
      "workers": 4,
      "plugins": ["groonga", "crud", "search"],
      "number_of_replicas": 2,
      "number_of_partitions": 2,
      "partition_key": "_key",
      "date_range": "infinity",
      "ring": {
        "localhost:23004": {
          "weight": 10,
          "partitions": {
            "2013-07-24": [
              "localhost:23003/farm0.000",
              "localhost:23003/farm1.000"
            ]
          }
        },
        "localhost:23005": {
          "weight": 10,
          "partitions": {
            "2013-07-24": [
              "localhost:23003/farm1.001",
              "localhost:23003/farm0.001"
            ]
          }
        }
      }
    }
  }
}
~~~

## Parameters

Here are descriptions about parameters in `catalog.json`.

### `version` {#version}

It is a format version of the catalog file.

Droonga Engine will change `catalog.json` format in the
future. Droonga Engine can provide auto format update feature with the
information.

The value must be `1`.

This is a required parameter.

Example:

~~~json
{
  "version": 1
}
~~~

### `effective_date`

It is a date string representing the day the catalog becomes
effective.

The date string format must be [W3C-DTF][].

This is a required parameter.

Note: fluent-plugin-droonga 0.8.0 doesn't use this value yet.

Example:

~~~json
{
  "effective_date": "2013-11-29T11:29:29Z"
}
~~~

### `zones`

It is an array of farms.

You should make elements in a `zones` close to each other, like in the
same host, in the same switch, in the same network.

This is a required parameter.

Note: fluent-plugin-droonga 0.8.0 doesn't use this value yet.

Example:

~~~json
{
  "zones": [
    "localhost:23003/farm0",
    "localhost:23003/farm1",
    "localhost:23004/farm0"
  ]
}
~~~

### `farms`

It is an array of Droonga Engine instances.

TODO: IMPROVE ME.

**Farms** correspond with fluent-plugin-droonga instances. A fluentd process may have multiple **farms** if more than one **match** entry with type **droonga** appear in the "fluentd.conf".
Each **farm** has its own job queue.
Each **farm** can attach to a data partition which is a part of a **dataset**.

This is a required parameter.

Example:

~~~json
{
  "farms": {
    "localhost:23003/farm0": {
      "device": "/disk0",
      "capacity": 1024
    },
    "localhost:23003/farm1": {
      "device": "/disk1",
      "capacity": 1024
    }
  }
}
~~~

### `datasets`

A **dataset** is a set of **tables** which comprise a single logical **table** virtually.
Each **dataset** must have a unique name in the network.

### `ring`

`ring` is a series of partitions which comprise a dataset. `replica_count`, `number_of_partitons` and **time-slice** factors affect the number of partitions in a `ring`.

### `workers`

`workers` is an integer number which specifies the number of worker processes to deal with the dataset.
If `0` is specified, no worker is forked and all operations are done in the master process.

### `number_of_partitions`

`number_of_partition` is an integer number which represents the number of partitions divided by the hash function. The hash function which determines where each record resides the partition in a dataset is compatible with memcached.

### `date_range`

`date_range` determines when to split the dataset. If a string "infinity" is assigned, dataset is never split by time factor.

### `number_of_replicas`

`number_of_replicas` represents the number of replicas of dataset maintained in the network.

  [Fluentd]: http://fluentd.org/
  [W3C-DTF]: http://www.w3.org/TR/NOTE-datetime "Date and Time Formats"
