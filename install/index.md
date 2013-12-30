---
title: Install
layout: en
---

# Overview

The main part of Droonga consists of two packages: [fluent-plugin-droonga][] and [express-droonga][].

## Dependencies

### Ruby

[fluent-plugin-droonga][] requires [Ruby][].

### Node.js

[express-droonga][] requires [Node.js][].


# Ubuntu 13.10

## Install dependencies

    sudo apt-get install -y ruby ruby-dev build-essential nodejs npm

## Install fluent-plugin-droonga

    sudo gem install fluent-plugin-droonga

## Install express-droonga

    sudo npm install express-droonga

Now you are ready for building your own data processing system with Droonga. See [tutorial](/tutorial/) to get started.

  [Ruby]: http://www.ruby-lang.org/
  [Node.js]: http://nodejs.org/
  [fluent-plugin-droonga]: https://github.com/droonga/fluent-plugin-droonga
  [express-droonga]: https://github.com/droonga/express-droonga
