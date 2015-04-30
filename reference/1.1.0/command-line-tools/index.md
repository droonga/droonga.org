---
title: Command line tools
layout: en
---

Droonga provides some command line tools.
This section describes usage of them.

## Communicating with Droonga cluster

 * [droonga-add](droonga-add/): Adds a new record to a cluster.
 * [droonga-groonga](droonga-groonga/): Sends Groonga commands to a cluster.
 * [droonga-system-status](droonga-system-status/): Reports status of members in a cluster.
 * [droonga-request](droonga-request/): Sends any message to a cluster and reports the response.
 * [droonga-send](droonga-send/): Sends any message to a cluster.
 * [drndump](drndump/): Extracts all schema definitions and records from a cluster.

## Cluster management

 * [droonga-engine-join](droonga-engine-join/): Adds a new replica node to a cluster.
 * [droonga-engine-unjoin](droonga-engine-unjoin/): Removes an existing replica node from a cluster.
 * [droonga-engine-absorb-data](droonga-engine-absorb-data/): Copy all schema definitions and records from a cluster to another.
 * [droonga-engine-set-role](droonga-engine-set-role/): Sets the role of a node in a cluster.

## Low level system administration

 * [droonga-engine-configure](droonga-engine-configure/): Configures the `droonga-engine` service on a computer.
 * [droonga-engine-catalog-generate](droonga-engine-catalog-generate/): Generates a new cluster definition file.
 * [droonga-engine-catalog-modify](droonga-engine-catalog-modify/): Modifies an existing cluster definition file.
 * [droonga-http-server-configure](droonga-http-server-configure/): Configures the `droonga-http-server` service on a computer.

