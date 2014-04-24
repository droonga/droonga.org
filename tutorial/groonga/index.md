---
title: "Droonga tutorial: How to migrate from Groonga?"
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to run a Droonga server by your hand, and use it as a [Groonga][groonga] compatible server.

## Precondition

* You must have basic knowledge and experiences to setup and operate an [Ubuntu][] Server.
* You must have basic knowledge and experiences to use the [Groonga][groonga] via HTTP.

## Abstract

It is a data processing engine based on a distributed architecture, named after the terms "distributed-Groonga".
As its name suggests, it can work as a Groonga compatible server with some improvements - replication and sharding.

In a certain sense, the Droonga is quite different from Groonga, about its architecture, design, API etc.
However, you don't have to understand the whole architecture of the Droonga, if you simply use it just as a Groonga compatible server.

For example, let's try to build a database system to find [Starbucks stores in New York](http://geocommons.com/overlays/430038).

## Prepare an environment for experiments

Prepare a computer at first.
This tutorial describes steps to setup a Droonga server on an existing computer.
Following instructions are basically written for a successfully prepared virtual machine of the `Ubuntu 13.10 x64` on the service [DigitalOcean](https://www.digitalocean.com/), with an available console.

NOTE: Make sure to use instances with >= 2GB memory equipped, at least during installation of required packages for Droonga.
Otherwise, you may experience a strange build error.

## How to install a Droonga server?

TBD

## How to start and stop the Droonga server?

TBD

## Create a table

TBD

## Load data to a table

TBD

## Select data from a table

TBD

## Conclusion

In this tutorial, you did setup a [Droonga][] server on a [Ubuntu Linux][Ubuntu].
Moreover, you load data to it and select data from it successfully, as a [Groonga][] compatible server.

  [Ubuntu]: http://www.ubuntu.com/
  [Droonga]: https://droonga.org/
  [Groonga]: http://groonga.org/
