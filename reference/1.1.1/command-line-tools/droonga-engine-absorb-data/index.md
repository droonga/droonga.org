---
title: droonga-engine-absorb-data
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`droonga-engine-absorb-data` copies all data of the specified source dataset to the destination dataset.

For example, if there is a Droonga Engine node `192.168.100.50` which is a node in the source cluster and you are logged in to a computer `192.168.200.10` which is another Droonga Engine node in the destination cluster, the command line to copy all data from `192.168.100.50` to `192.168.200.10` is:

~~~
(on 192.168.100.10)
$ droonga-engine-absorb-data --host 192.168.200.10 \
                             --receiver-host 192.168.200.10 \
                             --source-host 192.168.100.50
Start to absorb data from Default at 192.168.100.50:10031/droonga
                       to Default at 192.168.200.10:10031/droonga
                      via 192.168.200.10 (this host)

Absorbing...
Getting the timestamp of the last processed message in the source node...
The timestamp of the last processed message in the source node: 2015-04-29T10:07:08.230158Z
Setting the destination node to ignore messages older than the timestamp...
100% done (maybe 00:00:00 remaining)
Done.
~~~

See also [the tutorial about copying data between multiple Droonga clusters](/tutorial/dump-restore/).


## Parameters {#parameters}

`--host=NAME`
: Host name of the destination engine node to copy data.
  This is a required parameter.

`--port=PORT`
: Port number to communicate with the destination engine node.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with the destination engine node.
  `droonga` by default.

`--dataset=NAME`
: Name of the destination dataset for copying data.
  `Default` by default.

`--source-host=NAME`
: Host name of the soruce engine node to copy data.
  This is a required parameter.

`--source-port=PORT`
: Port number to communicate with the soruce engine node.
  `10031` by default.

`--source-tag=TAG`
: Tag name to communicate with the soruce engine node.
  `droonga` by default.

`--source-dataset=NAME`
: Name of the soruce dataset for copying data.
  `Default` by default.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--records-per-second=N`
: Maximum number of records to be copied per one second.
  `-1` means "no limit".
  `100` by default.

`--progress-interval-seconds=SECONDS`
: Interval seconds to report progress of data copying.
  `3` by default.

`--[no-]verbose`
: Output details for internal operations or not.
  This is mainly for debugging.

`--help`
: Shows the usage of the command.

## How to install {#install}

This is installed as a part of a rubygems package `droonga-engine`.

~~~
# gem install droonga-engine
~~~

