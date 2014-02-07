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
This makes droonga flexible.

Generally, data processing tasks in the real world need custom treatments of the data, in various stages of the data stream. This is not easy to be done in one-size-fits-all approach.

 * One may want to modify incoming requests to work well with other systems, one may want to modify outgoing responses to help other systems understand the result.
 * One may want to do more complex data processing than that provided by Droonga as built-in, to have direct storage access for efficiency.
 * One may need to control data distribution and collection logic of Droonga to profit from distributed nature of Droonga.

You can use plugins in those situations.

## Types of plugins

Droonga has 4 types of plugins corresponding to the purpose of plugin.
In other words, from the point of view of Droonga internal, the type of a plugin is distinguished by the component which the plugin is plugged in. See the [overview][] to grasp the big picture.

AdapterPlugin
: used to modify incoming requests and outgoing responses.

HandlerPlugin
: used for low-level data handling.

PlannerPlugin
: used to control internal message distribution.

CollectorPlugin
: used to control internal message collection.

In this tutorial, we focus on AdapterPlugin at first. This is the most "basic" plugin, so it will help you to understand the overview of Droonga plugin development.
Then, we focus on HandlerPlugin, PlannerPlugin and CollectorPlugin in this order.
Following this tutorial, you will learn how to write these plugins. This will be the first step to create plugins fit with your own requirements.

## How to develop plugins? How to operate requests and responses?

 1. [Modify requests and responses][adapter]
 2. Process requests (under construction)
 3. [Distribute requests and collect responses][distribute-collect]

  [basic tutorial]: ../
  [overview]: ../../overview/
  [adapter]: ./adapter/
  [distribute-collect]: ./distribute-collect/
