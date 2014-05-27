---
title: "Droonga tutorial: How to add a new replica to an existing cluster?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to add a new node to your existing [Droonga][] cluster, as a replica.

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

## Setup a new node

TBD

## Stop inpouring of "write" requests

TBD

## Replicate data from the cluster to the new replica

TBD

## Join the new replica to the cluster

TBD

## Restart inpouring of "write" requests

TBD

## Conclusion

In this tutorial, you did add a new replica node to an existing [Droonga][] cluster.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
  [command reference]: ../../reference/commands/
