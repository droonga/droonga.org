---
title: Install
layout: en
---

# Overview

The main part of Droonga consists of two packages: [fluent-plugin-droonga][] and [droonga-http-server][].

## Dependencies

### Ruby

[fluent-plugin-droonga][] requires [Ruby][].

### Node.js

[droonga-http-server][] requires [Node.js][].


# Ubuntu 13.10

## Install dependencies

    sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## Install fluent-plugin-droonga

    sudo gem install fluent-plugin-droonga

## Install droonga-http-server

    sudo npm install -g droonga-http-server

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
