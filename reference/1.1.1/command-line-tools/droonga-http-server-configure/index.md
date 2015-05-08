---
title: droonga-http-server-configure
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

`--reset-config`
: Replaces existing `droonga-http-server.yaml` with the new one.
  If this option is given, `droonga-http-server.yaml` is overwritten without confirmation.
  Otherwise a confirmation prompt is shown, if there is existing `droonga-http-server.yaml`.

`--host=HOST`
: Host name to listen.
  In other words, this is the bind address.
  `0.0.0.0` (accepts all connections for host name and IP address of this computer) by default.

`--port=PORT`
: Port number to wait connection from clients.
  `10041` by default.

`--receiver-host-name=NAME`
: Host name of the HTTP server node itself.
  It must be resolvable by all Droonga Engine nodes.
  Engine nodes send any message including responses for requests proxied by the HTTP server with the host name specified by this option.
  A guessed host name of the computer you are running the command, by default.

`--droonga-engine-host-names=NAME1,NAME2,...`
: List of Droonga Engine nodes' host name to try to connect on the startup.
  A guessed host name of the computer you are running the command, by default.

`--tag=TAG`
: Tag name to communicate with Droonga Engine nodes.
  `droonga` by default.

`--port=PORT`
: Port number to communicate with Droonga Engine nodes.
  `10031` by default.

`--default-dataset=NAME`
: Default dataset name for sending messages.

`--default-timeout=SECONDS`
: Time to terminate unresponsive connections, in seconds.
  `3` by default.

`--access-log-file=PATH`
: Path to the file which access logs are printed into.
  `-` means the standard output.
  `-` by default.

`--system-log-file=PATH`
: Path to the file which system logs are printed into.
  `-` means the standard output.
  `-` by default.

`--system-log-level=LEVEL`
: Log level for the logger.
  Possible values are `silly`/`trace`, `debug`, `verbose`, `info`, `warn` and `error`.
  `warn` by default.

`--cache-size=N`
: The maximum number of cached responses.
  This is applied only for some endpoints like `/d/select`.
  `100` by default.

`--cache-ttl-in-seconds=SECONDS`
: The time to live of cached responses, in seconds.
  This is applied only for some endpoints like `/d/select`.
  `60` by default.

`--enable-trust-proxy`, `--disable-trust-proxy`
: Enable "trust proxy" configuration or not.
  You have to enable it when you run the `droonga-http-server` service behind a reverse proxy.
  `--disable-trust-proxy` is by default.

`--document-root=PATH`
: Path to the document root.
  `(droonga-http-server's installation directory)/public/groonga-admin` by default.

`--plugins=PLUGIN1,PLUGIN2,...`
: List of activated plugins.
  Possible values:
  
  * `./api/rest`: Provides REST endpoints for the `search` command.
  * `./api/groonga`: Provides Groonga compatible endpoints.
  * `./api/droonga`: Provides generic endpoint for Droonga's native commands.
  
  All plugins are activated by default.

`--daemon`
: Run as a daemon.
  However, the `droonga-http-server` service always started as a daemon by the command line `service droonga-http-server start`, even if this option is given.

`--pid-file=PATH`
: Path to put the process ID of the daemon process.
  However, the process ID of the `droonga-http-server` service always stored at the platform specific location by the command line `service droonga-http-server start`, even if this option is given.

`--environment=ENVIRONMENT`
: Running environment of the server.
  Possible values:
  
  * `development` (default)
  * `production`
  * `testing`

`-h`, `--help`
: Shows the usage of the command.

## How to install {#install}

This is installed as a part of an npm package `droonga-http-server`.

~~~
# npm install -g droonga-http-server
~~~

