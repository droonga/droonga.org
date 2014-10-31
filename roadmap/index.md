---
title: Roadmap
layout: en
---

* TOC
{:toc}

# `droonga-engine`

## 1.0.8

 * Make drop-in replacement of log search system based on Groonga.

## 1.x.x

 * Optimize performance of `search` for unsharded replicas.
   (Currently, mechanisms of hash-based sharding always affect for replicas.
   They should be skipped for unsharded replicas.)
 * Support hash-based sharding of replicas, by `droonga-enigine-join` and `droonga-engine-unjoin` commands.
 * Support non-stop modification of cluster structure.
   (Currently, we have to stop updating data while modifying cluster structure.
   Joining of new replica should be done completely silently.
   To do it, we have to do:
   1) half-unjoin a source replica from the cluster,
   2) synchronize data from the source replica to the new destination replica,
   3) join those replicas to the cluster,
   and 3) wait to dispatch search requests to newly joined replicas until buffered updating requests are completely processed.)
 * Restart workers after schema change.
   (Currently, old schema information cached by workers can break indexes for newly added records.)
 * Support various type system notifications.
   (Currently, munin or something can be available to monitor status of nodes.
   However it should be integrated.)
 * Better compatibility to Groonga: Support `suggest` and related commands.
 * Support various type shardings (e.g. time-range based).

## 2.0.0

  * Auto catalog generation or catalog generation support
  * Auto catalog synchronism
  * Dynamic partition reconstruction
  * Fault recovery
  * Schema estimation
  * Schema evolution
  * Target date: unknown

# `droonga-http-server`

## 1.x.x

 * Detect available `droonga-engine` nodes automatically.
   (Nodes should fetch `catalog.json` from initially connected `droonga-engine` node via the `catalog.fetch` command and refresh connections based on the cluster definition.
 * Prevent to send request messages to dead `droonga-engine` nodes.
   (Nodes should join to the orchestration based on Serf.)
 * Better dashboard.
   (For example, search columns should be listed and filtered based on the schema information.
   This better dashboard will be developed in a separate repository to be shared by Groonga and Droogna...)

# `express-droonga`

## 1.x.x

 * Make connections to `droonga-engine` nodes redundant.

