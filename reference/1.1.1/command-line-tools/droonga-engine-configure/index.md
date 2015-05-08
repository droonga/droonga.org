---
title: droonga-engine-configure
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

(TBD)

## Parameters {#parameters}

`--no-prompt`
: Never show any interactive prompt.
  If this options is given, all configurations not specified by following options are filled by their default value.
  Otherwise prompts are shown for options.

`--clear`
: Clears all existing data in the data directory of the `droonga-engine` service.

`--reset-config`
: Replaces existing `droonga-engine.yaml` with the new one.
  If this option is given, `droonga-engine.yaml` is overwritten without confirmation.
  Otherwise a confirmation prompt is shown, if there is existing `droonga-engine.yaml`.

`--reset-catalog`
: Replaces existing `catalog.json` with new clean one including only an orphan Engine node.
  If this option is given, `catalog.json` is overwritten without confirmation.
  Otherwise a confirmation prompt is shown, if there is existing `catalog.json`.

`--host=HOST`
: Host name of the engine node itself.
  A guessed host name of the computer you are running the command, by default.

`--port=PORT`
: Port number to wait connection from clients and other nodes.
  `10031` by default.

`--tag=TAG`
: Tag name to accept incoming messages with.
  `droonga` by default.

`--internal-connection-lifetime=SECONDS`
: The time to expire internal connections, in seconds.
  `60` by default.

`--log-level=LEVEL`
: Log level for the logger.
  Possible values are `trace`, `debug`, `info`, `warn`, `error` and `fatal`.
  `warn` by default.

`--log-file=PATH`
: Path to the file all log messages are printed into.
  If this option is not specified, logs are printed to the standard output.

`--daemon`, `--no-daemon`
: Run as a daemon or a regular process.
  However, the `droonga-engine` service always started as a daemon by the command line `service droonga-engine start`, even if these options are given.

`--pid-file=PATH`
: Path to put the process ID of the daemon process.
  However, the process ID of the `droonga-engine` service always stored at the platform specific location by the command line `service droonga-engine start`, even if this option is given.

`--base-dir=PATH`
: Path to the directory all `droonga-engine` related files are stored into.
  However, the location `/home/droonga-engine/droonga/` is always used for the `droonga-engine` service started by the command line `service droonga-engine start`, even if this option is given.

## How to install {#install}

This is installed as a part of a rubygems package `droonga-engine`.

~~~
# gem install droonga-engine
~~~

