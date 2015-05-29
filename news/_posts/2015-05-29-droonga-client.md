---
title: droonga-client-ruby 0.2.2 has been released!
layout: news-item
---

Today, we've shipped a new version 0.2.2 of [droonga-client-ruby][]!
It provides client library for Ruby and command line tools.

Most important topic of this version is: now the [`droonga-groonga` command][droonga-groonga] supports multiple commands given via the standard input, like [Groonga][groonga]'s `groonga` command.
For example, you can apply your schema definition to a Droonga cluster like as:

~~~
$ cat /path/to/schema.grn | droonga-groonga --host node0 --port 10031
~~~

You already been able to get similar result by a combination of [grn2drn][] and the [`droonga-request` command][droonga-request], but now you can do it by only one simple command [`droonga-groonga`][droonga-groonga] easily.
Let's try Droonga via the command, if you are familiar to Groonga!

Moreover, [`droonga-add`][droonga-add], [`droonga-system-status`][droonga-system-status] and [`droonga-groonga`][droonga-groonga] now support a new command line option `--dry-run`.
You'll do it to forecast what's happen on the cluster by thoese commands.

Droonga project welcomes you to join us as a user and/or a developer! See [community][] to contact us!

  [community]: /community/
  [groonga]: http://groonga.org/
  [droonga-client-ruby]: https://github.com/droonga/droonga-client-ruby
  [grn2drn]: https://github.com/droonga/grn2drn
  [droonga-groonga]: /ja/reference/command-line-tools/droonga-groonga/
  [droonga-request]: /ja/reference/command-line-tools/droonga-request/
  [droonga-add]: /ja/reference/command-line-tools/droonga-add/
  [droonga-system-status]: /ja/reference/command-line-tools/droonga-system-status/
