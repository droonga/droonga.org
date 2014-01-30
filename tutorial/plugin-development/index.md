---
title: Droonga plugin development tutorial
layout: en
---

!!WORK IN PROGRESS!!

* TOC
{:toc}

## The goal of this tutorial

Learning steps to develop a Droonga plugin by yourself.

## Precondition

* You must complete [tutorial][].

## Plugin

Plugin is one of the most important concept of Droonga.
This makes droonga flexible.

Generally, data processing tasks in real word need custom treatments of the data, in various stages of the data stream. This is not easy to done in one-size-fits-all approach.

One may want to modify input queries to work well with other systems, one may want to modify output to help other systems understand the result. One may want to do more complex data processing than that provided by Droonga as built-in, to have direct storage access for efficiency. One may need to control data distribution logic and collection logic of Droonga to profit from distributed nature of Droonga.

You can use plugins in those situations.

## Types of plugins

Droonga has 5 types of plugins corresponding to the purpose of plugin.
In other words, from the point of view of Droonga internal, the type of a plugin is distinguished by the component which the plugin is plugged in. See [overview][] to grasp the big picture.

InputAdapterPlugin
: used to modify requests.

OutputAdapterPlugin
: used to modify responses.

HandlerPlugin
: used for low-level data handling.

DistributorPlugin
: used to control internal message distribution.

CollectorPlugin
: used to control internal message collection.

In this tutorial, we focus on InputAdapterPlugin. This is the most "basic" plugin, so it will help you to understand the overview of Droonga plugin development.


## Directory Structure

Assume that we are going to add `InputAdapterPlugin` to the system built in [tutorial][]. In that tutorial, Groonga engine was placed under `engine` directory.

Plugins need to be placed in an appropriate directory. For example, `InputAdapterPlugin` should be placed under `lib/droonga/plugin/input_adapter/` directory. Let's create the directory:

    # cd engine
    # mkdir -p lib/droonga/plugin/input_adapter

After creating the directory, the directory structure should be like this:

```
engine
├── catalog.json
├── fluentd.conf
└── lib
    └── droonga
        └── plugin
            └── input_adapter
```

Put a plugin code into `input_adapter` plugin.

lib/droonga/plugin/input_adapter/example.rb:

```ruby
module Droonga
  class ExampleInputAdapter < Droonga::InputAdapterPlugin
    repository.register("example", self)
  end
end
```

This plugin does nothing except registering itself to Droonga.

You need to update `catalog.json` to activate your plugin:

catalog.json:
```
(snip)
  },
  "options": {
    "plugins": ["example"]
  }
}
```

Add `"example"` to `"plugins"` section.

Let's Droonga get started. Note that you need to specify `./lib` directory in `RUBYLIB` environment variable in order to make ruby possible to find your plugin.

```
RUBYLIB=./lib fluentd --config fluentd.conf
```


  [tutorial]: ../
  [overview]: ../../overview/
