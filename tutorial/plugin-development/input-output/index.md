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


## Create a plugin

Put a plugin code into `input_adapter` directory.

lib/droonga/plugin/input_adapter/example.rb:

```ruby
module Droonga
  class ExampleInputAdapterPlugin < Droonga::InputAdapterPlugin
    repository.register("example", self)
  end
end
```

This plugin does nothing except registering itself to Droonga.

## Activate plugin with `catalog.json`

You need to update `catalog.json` to activate your plugin.
Insert following at the last part of `catalog.json` in order to make `"input_adapter"` become a key of the top level hash:

catalog.json:
```
(snip)
  },
  "input_adapter": {
    "plugins": ["example"]
  }
}
```

## Run

Let's Droonga get started. Note that you need to specify `./lib` directory in `RUBYLIB` environment variable in order to make ruby possible to find your plugin.

```
RUBYLIB=./lib fluentd --config fluentd.conf
```



  [tutorial]: ../../
  [overview]: ../../../overview/
