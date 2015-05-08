---
title: droonga-engine-catalog-generate
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-catalog-generate` generates new [`catalog.json` file](../../catalog/version2/) for a Droonga Engine node.

For most usecase you don't need to use this command.
Instead, use [the `droonga-engine-configure` command](../droonga-engine-configure/) to initialize an Engine node and change cluster's structure via management commands like [`droonga-engine-join`](../droonga-engine-join/) or ['droonga-engine-unjoin`](../droonga-engine-unjoin/).

(TBD)

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

