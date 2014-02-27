---
title: Droonga plugin development tutorial
layout: en
---

* TOC
{:toc}

## The goal of this tutorial

Learning steps to develop a Droonga plugin by yourself.
You must complete the [basic tutorial][] before this.


## What's "plugin"?

Plugin is one of the most important concept of Droonga.
This makes Droonga flexible.

Generally, data processing tasks in the real world need custom treatments of the data, in various stages of the data stream. This is not easy to be done in one-size-fits-all approach.

 * One may want to modify incoming requests to work well with other systems, one may want to modify outgoing responses to help other systems understand the result.
 * One may want to do more complex data processing than that provided by Droonga as built-in, to have direct storage access for efficiency.
 * One may need to control data distribution and collection logic of Droonga to profit from distributed nature of Droonga.

You can use plugins in those situations.

## Pluggable operations in Droonga Engine

In Droonga Engine, there are 2 large pluggable phases and 3 sub phases for plugins.
In other words, from the point of view of plugins, each plugin can do from 1 to 4 operations.
See the [overview][] to grasp the big picture.

Adaption phase
: At this phase, a plugin can modify incoming requests and outgoing responses.

Processing phase
: At this phase, a plugin can process incoming requests on each partition, step by step.

The processing phase includes 3 sub pluggable phases:

Handling phase
: At this phase, a plugin can do low-level data handling, for example, database operations and so on.

Planning phase
: At this phase, a plugin can split an incoming request to multiple steps.

Collection phase
: At this phase, a plugin can merge results from steps to a unified result.

In this tutorial, we focus at the adaption phase at first.
This is the most "basic" usecase of plugins, so it will help you to understand the overview of Droonga plugin development.
Then, we focus an other phases in this order.
Following this tutorial, you will learn how to write plugins. This will be the first step to create plugins fit with your own requirements.

## How to develop plugins?

For more details, let's read these sub tutorials:

 1. [Modify requests and responses][adapter]
 2. [Handle requests on all partitions][handler]
 3. Handle requests only on a specific partition (under construction)
 4. Distribute requests and collect responses (under construction)


  [basic tutorial]: ../basic/
  [overview]: ../../overview/
  [adapter]: ./adapter/
  [handler]: ./handler/
  [distribute-collect]: ./distribute-collect/
