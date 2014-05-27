---
title: "Droonga tutorial: How to add a new replica to an existing cluster?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to add a new replica node, and replace a dead replica with new one, for your existing [Droonga][] cluster.

## Precondition

* You must have an existing Droonga cluster with some data.
  Please complete the ["getting started" tutorial](../groonga/) before this.
* You must know how to replicate data between multiple clusters.
  Please complete the ["How to backup and restore the database?" tutorial](../dump-restore/) before this.

## What's "replica"?

There are two axes, "replica" and "slice", for Droonga nodes.

All "replica" nodes have completely equal data, so they can process your requests (ex. "search") parallelly.
You can increase the capacity of your cluster to process increasing requests, by adding new replicas.

On the other hand, "slice" nodes have different data, for example, one node contains data of the year 2013, another has data of 2014.
You can increase the capacity of your cluster to store increasing data, by adding new slices.

Currently, for a Droonga cluster which is configured as a Groonga compatible system, only replicas can be added, but slices cannot be done.
We'll improve extensibility for slices in the future.

Anyway, this tutorial explains how to add a new replica node to an existing Droogna cluster.
Here we go!

## Add a new replica node to an existing cluster

### Setup a new node

TBD

### Stop inpouring of "write" requests

TBD

### Replicate data from the cluster to the new replica

TBD

### Join the new replica to the cluster

TBD

### Restart inpouring of "write" requests

TBD

## Replace a broken replica node in a cluster with a new node

### Unjoin the broken replica from the cluster

TBD

### Add a new replica

TBD

## Conclusion

In this tutorial, you did add a new replica node to an existing [Droonga][] cluster.
Moreover, you did replace a dead replica with a new one.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
