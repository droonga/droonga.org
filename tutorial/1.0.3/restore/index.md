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
  Please complete [the "getting started" tutorial](../groonga/) before this.
* The `dump` plugin is registered to the `catalog.json` of your Droonga cluster.
  If not, you must add the plugin to the list of `plugins`, like:
  
      - "plugins": ["groonga", "crud", "search"],
      + "plugins": ["groonga", "crud", "search", "dump"],

## Backup data in a Droonga cluster

TBD

## Restore data to a Droonga cluster

TBD

## Conclusion

In this tutorial, you did backup a [Droonga][] cluster and restore the data.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
