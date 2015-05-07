---
title: drndump
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`drndump` extracts all schema, records, and index definitions of a dataset in a Droonga cluster.

For example, if there is a Droonga Engine node `192.168.100.50` and you are logged in to a computer `192.168.100.10` in the same network segment, the command line to extract all data in the cluster is:

~~~
(on 192.168.100.10)
$ drndump --host 192.168.100.50 --receiver-host 192.168.100.10
{
  "type": "table_create",
  "dataset": "Default",
  "body": {
    "name": "Location",
    "flags": "TABLE_PAT_KEY",
    "key_type": "WGS84GeoPoint"
  }
}
{
  "type": "table_create",
  "dataset": "Default",
  "body": {
    "name": "Store",
    "flags": "TABLE_PAT_KEY",
    "key_type": "ShortText"
  }
}
...
{
  "type": "column_create",
  "dataset": "Default",
  "body": {
    "table": "Term",
    "name": "store_name",
    "type": "Store",
    "flags": "COLUMN_INDEX|WITH_POSITION",
    "source": "name"
  }
}
~~~

The output of this command is valid messages to restore same data to another Droonga cluster.
In other words, this command can create a complete backup of a Droonga cluster.

You can save the output as a file by redirection like:

~~~
(on 192.168.100.10)
$ drndump --host 192.168.100.50 --receiver-host 192.168.100.10 \
    > dump.jsons
~~~

You can restore the dataset from a dump output, using [`droonga-request` command](../droonga-request/) or [`droonga-send` command](../droonga-send/).
See also both descriptions.


## Parameters {#parameters}

`--host=NAME`
: Host name of the engine node.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to communicate with the engine.
  `10031` by default.

`--tag=TAG`
: Tag name to communicate with the engine.
  `droonga` by default.

`--dataset=NAME`
: Dataset name to be dumped.
  `Default` by default.

`--receiver-host=NAME`
: Host name of the computer you are running this command.
  A guessed host name of the computer, by default.

`--help`
: Shows the usage of the command.


## How to install {#install}

This is installed as a part of a rubygems package `drndump`.

~~~
# gem install drndump
~~~

