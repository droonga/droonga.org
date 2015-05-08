---
title: droonga-engine-catalog-generate
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-catalog-generate` generates new [`catalog.json` file](../../catalog/version2/) for a Droonga Engine node.

For most usecase you don't need to use this command.
Instead, use [the `droonga-engine-configure` command](../droonga-engine-configure/) to initialize an Engine node and change cluster's structure via management commands like [`droonga-engine-join`](../droonga-engine-join/) or [`droonga-engine-unjoin`](../droonga-engine-unjoin/).

This command is designed to generate a new `catalog.json` from scratch.
When you hope to modify only the list of replica nodes, [the `droonga-engine-catalog-modify` command](../droonga-engine-catalog-modify/) is better choice.

## Examples {#examples}

### Orphan cluster with single volume

Most popular usage is generating `catalog.json` for an orphan Engine node as a new replica node managed by [the `droonga-engine-join` command](../droonga-engine-join/). For example, if you are logged in to an unprepared node `192.168.100.50`, the command line is:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate --hosts 192.168.100.50
~~~

Full version with omitted options is:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --output  /home/droonga-engine/droonga/catalog.json \
    --dataset Default             \
      --n-workers 4               \
      --hosts     192.168.100.50  \
      --port      10031           \
      --tag       droonga         \
      --n-slices  1               \
      --plugins   groonga,search,crud,dump,system,catalog
~~~

These options `--n-workers`, `--hosts`, `--port`, `--tag`, `--n-slices` and `--plugins` are associated to the nearest preceding `--dataset` option.
All these options preceding to any user defined `--dataset` option are automatically associated to the default dataset named `Default`.

Generated `catalog.json` is:

~~~
{
  "version": 2,
  "effectiveDate": "2015-05-08T09:02:12+00:00",
  "datasets": {
    "Default": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": [
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            {
              "weight": 100,
              "volume": { "address": "192.168.100.50:10031/droonga.000" }
            }
          ]
        }
      ]
    }
  }
}
~~~


### Cluster with multiple replica nodes

To define a dataset with multiple replica nodes, you have to give all host names used as replica nodes separated with `,` (comma) via the `--hosts` option, like:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --hosts 192.168.100.50,192.168.100.51
~~~

Full version with omitted options is:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --output  /home/droonga-engine/droonga/catalog.json \
    --dataset Default             \
      --n-workers 4               \
      --hosts     192.168.100.50,192.168.100.51 \
      --port      10031           \
      --tag       droonga         \
      --n-slices  1               \
      --plugins   groonga,search,crud,dump,system,catalog
~~~

Generated `catalog.json` is:

~~~
{
  "version": 2,
  "effectiveDate": "2015-05-08T09:02:12+00:00",
  "datasets": {
    "Default": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": [
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.50:10031/droonga.000" } }
          ]
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.51:10031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~


### Cluster with multiple replica nodes and multiple slices for each replica

To define a dataset with sliced replicas, you have to add one more option `--n-slices` for the dataset, like:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --hosts    192.168.100.50,192.168.100.51 \
    --n-slices 2
~~~

Full version with omitted options is:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --output  /home/droonga-engine/droonga/catalog.json \
    --dataset Default             \
      --n-workers 4               \
      --hosts     192.168.100.50,192.168.100.51 \
      --port      10031           \
      --tag       droonga         \
      --n-slices  2               \
      --plugins   groonga,search,crud,dump,system,catalog
~~~

Generated `catalog.json` is:

~~~
{
  "version": 2,
  "effectiveDate": "2015-05-08T09:02:12+00:00",
  "datasets": {
    "Default": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": [
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 50,
              "volume": { "address": "192.168.100.50:10031/droonga.000" } },
            { "weight": 50,
              "volume": { "address": "192.168.100.50:10031/droonga.001" } }
          ]
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 50,
              "volume": { "address": "192.168.100.51:10031/droonga.000" } },
            { "weight": 50,
              "volume": { "address": "192.168.100.51:10031/droonga.001" } }
          ]
        }
      ]
    }
  }
}
~~~

`2` or larger number for the `--n-slices` option produces multiple slices on each replica node itself.
For effective slicing we should use one node per one slice, but currently it is not supported by this command.
Moreover, we still don't support replicas under a slice yet.
These limitations will be solved on future versions.

### Cluster including two or more datasets

To define multiple datasets in a cluster you have to use the `--dataset` option, like:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --hosts   192.168.100.50,192.168.100.51 \
    --port    20031 \
    --dataset Testing \
    --hosts   192.168.100.60,192.168.100.61 \
    --port    20032
~~~

Full version with omitted options is:

~~~
(on 192.168.100.50)
# droonga-engine-catalog-generate \
    --output  /home/droonga-engine/droonga/catalog.json \
    --dataset Default             \
      --n-workers 4               \
      --hosts     192.168.100.50,192.168.100.51 \
      --port      20031           \
      --tag       droonga         \
      --n-slices  1               \
      --plugins   groonga,search,crud,dump,system,catalog \
    --dataset Testing             \
      --n-workers 4               \
      --hosts     192.168.100.60,192.168.100.61 \
      --port      20032           \
      --tag       droonga         \
      --n-slices  1               \
      --plugins   groonga,search,crud,dump,system,catalog
~~~

As above, dataset-associated options affect to the dataset defined by their nearest preceding `--dataset` option.

Generated `catalog.json` is:

~~~
{
  "version": 2,
  "effectiveDate": "2015-05-08T09:02:12+00:00",
  "datasets": {
    "Default": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": [
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.50:20031/droonga.000" } }
          ]
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.51:20031/droonga.000" } }
          ]
        }
      ]
    },
    "Testing": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": [
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.60:20032/droonga.000" } }
          ]
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.61:20032/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~


## Parameters {#parameters}

`--output=PATH`
: The output path of generated `catalog.json` to be saved as.
  `-` means the standard output.
  Any existing file at the specified path will be overwritten without confirmation.
  It is the path to the `catalog.json` for the `droonga-engine` service on the computer (`/home/droonga-engine/droonga/catalog.json`), by default.

`--dataset=NAME`
: The name of a new dataset.
  This can be specified multiple times to define multiple datasets.
  `Default` by default.

`--n-workers=N`
: Number of workers for each volume in the dataset specified by the preceding `--dataset` option.
  `4` by default.

`--hosts=NAME1,NAME2,...`
: Host names of engine nodes to be used as replicas in the dataset specified by the preceding `--dataset` option.
  A single guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with engine nodes in the dataset specified by the preceding `--dataset` option.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with engine nodes in the dataset specified by the preceding `--dataset` option.
  `droonga` by default.

`--n-slices=N`
: Number of slices for each replica in the dataset specified by the preceding `--dataset` option.
  `1` by default.

`--plugins=PLUGIN1,PLUGIN2,...`
: Plugin names activated for the dataset specified by the preceding `--dataset` option.
  `groonga,search,crud,dump,system,catalog` (the list of all buit-in plugins) by default.

`--schema=PATH`
: The path to a JSON file including schema definition for the dataset specified by the preceding `--dataset` option.

`--fact=TABLE`
: Name of the fact table in the dataset specified by the preceding `--dataset` option.

`--replicas=PATH`
: The path to a JSON file including replicas definition for the dataset specified by the preceding `--dataset` option.
  If this option is used, other options to define replicas in the dataset (`--hosts`, `--port`, `--tag` and `--n-slices`) are ignored.

## How to install {#install}

This is installed as a part of a rubygems package `droonga-engine`.


~~~
# gem install droonga-engine
~~~

