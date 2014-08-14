---
title: Install
layout: en
---

# Overview

The main part of Droonga consists of two packages: [droonga-engine][] and [droonga-http-server][].

## Dependencies

### Ruby

[droonga-engine][] requires [Ruby][].

### Node.js

[droonga-http-server][] requires [Node.js][].


# Ubuntu 14.04

## Install dependencies

    sudo apt-get install -y ruby ruby-dev build-essential nodejs nodejs-legacy npm

## Install droonga-engine

    sudo gem install droonga-engine

## Install droonga-http-server

    sudo npm install -g droonga-http-server

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [droonga-engine]: https://github.com/droonga/droonga-engine
  [droonga-http-server]: https://github.com/droonga/droonga-http-server
