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

Generally, data processing tasks in the real world need custom treatments of the data, in various stages of the data stream.
This is not easy to be done in one-size-fits-all approach.

 * One may want to modify incoming requests to work well with other systems, one may want to modify outgoing responses to help other systems understand the result.
 * One may want to do more complex data processing than that provided by Droonga as built-in, to have direct storage access for efficiency.
 * One may need to control data distribution and collection logic of Droonga to profit from the distributed nature of Droonga.

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

However, the point of view of these descriptions is based on the design of the system itself, so you're maybe confused.
Then, let's shift our perspective on pluggable operations - what you want to do by a plugin.

Adding a new command based on another existing command.
: For example, you possibly want to define a shorthand command wrapping the complex `search` command.
  *Adaption* of request and response messages makes it come true.

Adding a new command working around the storage.
: For example, you possibly want to modify data stored in the storage as you like.
  *Handling* of requests makes it come true.

Adding a new command for a complex task
: For example, you possibly want to implement a powerful command like the built-in `search` command.
  *Planning and collection* of requests make it come true.

In this tutorial, we focus on the adaption at first.
This is the most "basic" usecase of plugins, so it will help you to understand the overview of Droonga plugin development.
Then, we focus on other cases in this order.
Following this tutorial, you will learn how to write plugins.
This will be the first step to create plugins fit with your own requirements.

## How to develop plugins?

For more details, let's read these sub tutorials:

 1. [Adapt requests and responses, to add a new command based on other existing commands][adapter].
 2. [Handle requests on all partitions, to add a new command working around the storage][handler].
 3. Handle requests only on a specific partition, to add a new command around the storage more smartly. (under construction)
 4. Distribute requests and collect responses, to add a new complex command based on sub tasks. (under construction)


  [basic tutorial]: ../basic/
  [overview]: ../../overview/
  [adapter]: ./adapter/
  [handler]: ./handler/
  [distribute-collect]: ./distribute-collect/
