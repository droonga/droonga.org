---
title: droonga-engine-catalog-modify
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

(TBD)

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

