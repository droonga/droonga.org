---
title: droonga-engine-catalog-modify
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-catalog-modify` modifies an existing `catalog.json` to change the structure of the Droonga clsuter.

For most usecase you don't need to use this command.
Instead, use management commands like [`droonga-engine-join`](../droonga-engine-join/) or [`droonga-engine-unjoin`](../droonga-engine-unjoin/).

## Examples {#examples}

For example, if there is an existing `catalog.json` at `/tmp/catalog.json` with the content:

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
              "volume": { "address": "192.168.100.60:20031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~

### Adding new replicas

A command line to add a new replica node `192.168.100.52` to the cluster's dataset `Default` is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --no-update \
    --add-replica-hosts 192.168.100.52
~~~

Full version with omitted options is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --output - \
    --no-update \
    --dataset Default \
      --add-replica-hosts 192.168.100.52
~~~

This command automatically applies the port number and the tag name same to existing other replicas.
You don't have to specify such information.

Modified `catalog.json` is:

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
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.52:10031/droonga.000" } }
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
              "volume": { "address": "192.168.100.60:20031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~

### Removing existing replicas

A command line to remove an existing replica node `192.168.100.51` from the cluster's dataset `Default` is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --no-update \
    --remove-replica-hosts 192.168.100.51
~~~

Full version with omitted options is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --output - \
    --no-update \
    --dataset Default \
      --remove-replica-hosts 192.168.100.51
~~~

Modified `catalog.json` is:

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
              "volume": { "address": "192.168.100.60:20031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~

All replica nodes can be removed from the cluster:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --no-update \
    --remove-replica-hosts 192.168.100.52,192.168.100.51
{
  "version": 2,
  "effectiveDate": "2015-05-08T09:02:12+00:00",
  "datasets": {
    "Default": {
      "nWorkers": 4,
      "plugins": ["groonga", "search", "crud", "dump", "system", "catalog"],
      "schema": {},
      "replicas": []
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
              "volume": { "address": "192.168.100.60:20031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~

However, it is an invalid `catalog.json`.
You never can add replicas to the blank dataset again by this command itself.
To fix such a broken `catalog.json`, you need to regenerate it again by [the `droonga-engine-catalog-generate` command](../droonga-engine-catalog-generate/).


### Updating list of replica nodes for multiple datasets at once

A command line to produce two changes: adding a new replica node `192.168.100.52` to the dataset `Default` and adding another new replica node `192.168.100.61` to the dataset `Testing`, is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --no-update \
    --add-replica-hosts 192.168.100.52 \
    --dataset Testing \
    --add-replica-hosts 192.168.100.61
~~~

Full version with omitted options is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --output - \
    --no-update \
    --dataset Default \
      --add-replica-hosts 192.168.100.52 \
    --dataset Testing \
      --add-replica-hosts 192.168.100.61
~~~

Modified `catalog.json` is:

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
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.52:10031/droonga.000" } }
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
              "volume": { "address": "192.168.100.60:20031/droonga.000" } }
          ]
        },
        {
          "dimension": "_key",
          "slicer": "hash",
          "slices": [
            { "weight": 100,
              "volume": { "address": "192.168.100.61:20031/droonga.000" } }
          ]
        }
      ]
    }
  }
}
~~~

Because this command recognizes the port number and the tag name as dataset-specific configurations, `10031` is used for new replica node under the `Default` dataset and `20031` is used for the one under the `Testing` dataset.

Another case, a command line to swap replica nodes of two datasets `Default` and `Testing` is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --no-update \
    --replica-hosts 192.168.100.60 \
    --dataset Testing \
    --replica-hosts 192.168.100.50,192.168.100.51
~~~

Full version with omitted options is:

~~~
$ droonga-engine-catalog-modify \
    --source /tmp/catalog.json \
    --output - \
    --no-update \
    --dataset Default \
      --replica-hosts 192.168.100.60 \
    --dataset Testing \
      --replica-hosts 192.168.100.50,192.168.100.51
~~~

Modified `catalog.json` is:

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
              "volume": { "address": "192.168.100.60:10031/droonga.000" } }
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
    }
  }
}
~~~

Note that each volume's port number is changed.
Because port numbers are associated to their owner dataset, port numbers are also swapped.

## Parameters {#parameters}

`--source=PATH`
: The path to the `catalog.json` to be modified.
  `-` means the standard input.
  It is the path to the `catalog.json` for the `droonga-engine` service on the computer (`/home/droonga-engine/droonga/catalog.json`), by default.

`--output=PATH`
: The output path of modified `catalog.json` to be saved as.
  `-` means the standard output.
  Any existing file at the specified path will be overwritten without confirmation.
  `-` by default.

`--[no-]update`
: Update the source file itself, or not.
  
  * `--update` overwrites the source file itself given by the `--source` option.
  * `--no-update` prints the modified `catalog.json` to the output given by the `--output` option.
  
  `--update` by default.

`--dataset=NAME`
: The name of an existing dataset to be modified.
  This can be specified multiple times to modify multiple datasets.
  `Default` by default.

`--replica-hosts=NAME1,NAME2,...`
: Host names of engine nodes to be used as replicas in the dataset specified by the preceding `--dataset` option.
  If you specify this option, all existing replica nodes defined in the dataset are replaced.

`--add-replica-hosts=NAME1,NAME2,...`
: Host names of engine nodes to be added to the cluster as replicas, in the dataset specified by the preceding `--dataset` option.

`--remove-replica-hosts=NAME1,NAME2,...`
: Host names of engine nodes to be removed from the cluster, in the dataset specified by the preceding `--dataset` option.

## How to install {#install}

This is installed as a part of a rubygems package `droonga-engine`.

~~~
# gem install droonga-engine
~~~

