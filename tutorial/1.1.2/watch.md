---
title: Droonga tutorial
layout: en
---

* TOC
{:toc}

## Real-time search

Droonga supports streaming-style real-time search.

### Update configurations of the Droonga engine

Update your fluentd.conf and catalog.jsons, like:

fluentd.conf:

      <source>
        type forward
        port 24224
      </source>
      <match starbucks.message>
        name localhost:24224/starbucks
        type droonga
      </match>
    + <match droonga.message>
    +   name localhost:24224/droonga
    +   type droonga
    + </match>
      <match output.message>
        type stdout
      </match>

catalog.json:

      {
        "effective_date": "2013-09-01T00:00:00Z",
        "zones": [
    +     "localhost:24224/droonga",
          "localhost:24224/starbucks"
        ],
        "farms": {
    +     "localhost:24224/droonga": {
    +       "device": ".",
    +       "capacity": 10
    +     },
          "localhost:24224/starbucks": {
            "device": ".",
            "capacity": 10
          }
        },
        "datasets": {
    +     "Watch": {
    +       "workers": 2,
    +       "plugins": ["search", "groonga", "add", "watch"],
    +       "number_of_replicas": 1,
    +       "number_of_partitions": 1,
    +       "partition_key": "_key",
    +       "date_range": "infinity",
    +       "ring": {
    +         "localhost:23041": {
    +           "weight": 50,
    +           "partitions": {
    +             "2013-09-01": [
    +               "localhost:24224/droonga.watch"
    +             ]
    +           }
    +         }
    +       }
    +     },
          "Starbucks": {
            "workers": 0,
            "plugins": ["search", "groonga", "add"],
            "number_of_replicas": 2,
            "number_of_partitions": 2,
            "partition_key": "_key",
            "date_range": "infinity",
            "ring": {
              "localhost:23041": {
                "weight": 50,
                "partitions": {
                  "2013-09-01": [
                    "localhost:24224/starbucks.000",
                    "localhost:24224/starbucks.001"
                  ]
                }
              },
              "localhost:23042": {
                "weight": 50,
                "partitions": {
                  "2013-09-01": [
                    "localhost:24224/starbucks.002",
                    "localhost:24224/starbucks.003"
                  ]
                }
              }
            }
          }
        },
        "options": {
          "plugins": []
        }
      }

### Add a streaming API to the protocol adapter


Add a streaming API to the protocol adapter, like;

application.js:

    var express = require('express'),
        droonga = require('express-droonga');
    
    var application = express();
    var server = require('http').createServer(application);
    server.listen(3000); // the port to communicate with clients
    
    //============== INSERTED ==============
    var streaming = {
      'streaming': new droonga.command.HTTPStreaming({
        dataset: 'Watch',
        path: '/watch',
        method: 'GET',
        subscription: 'watch.subscribe',
        unsubscription: 'watch.unsubscribe',
        notification: 'watch.notification',
        createSubscription: function(request) {
          return {
            condition: request.query.query
          };
        }
      })
    };
    //============= /INSERTED ==============
    
    application.droonga({
      prefix: '/droonga',
      tag: 'starbucks',
      defaultDataset: 'Starbucks',
      server: server, // this is required to initialize Socket.IO API!
      plugins: [
        droonga.API_REST,
        droonga.API_SOCKET_IO,
        droonga.API_GROONGA,
        droonga.API_DROONGA
    //============== INSERTED ==============
        ,streaming
    //============= /INSERTED ==============
      ]
    });

    application.get('/', function(req, res) {
      res.sendfile(__dirname + '/index.html');
    });

### Prepare feeds

Prepare "feed"s like:

feeds.jsons:

    {"id":"feed:0","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"old place 0"}}}
    {"id":"feed:1","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"new place 0"}}}
    {"id":"feed:2","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"old place 1"}}}
    {"id":"feed:3","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"new place 1"}}}
    {"id":"feed:4","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"old place 2"}}}
    {"id":"feed:5","dataset":"Watch","type":"watch.feed","body":{"targets":{"key":"new place 2"}}}

### Try it!

At first, restart servers in each console.

The engine:

    # fluentd --config fluentd.conf

The protocol adapter:

    # nodejs application.js

Next, connect to the streaming API via curl:

    # curl "http://localhost:3000/droonga/watch?query=new"

Then the client starts to receive streamed results.

Next, open a new console and send "feed"s to the engine like:

    # fluent-cat droonga.message < feeds.jsons

Then the client receives three results "new place 0", "new place 1", and "new place 2" like:

    {"targets":{"key":"new place 0"}}
    {"targets":{"key":"new place 1"}}
    {"targets":{"key":"new place 2"}}

They are search results for the query "new", given as a query parameter of the streaming API.

Results can be appear in different order, like:

    {"targets":{"key":"new place 1"}}
    {"targets":{"key":"new place 0"}}
    {"targets":{"key":"new place 2"}}

because "feed"s are processed in multiple workers asynchronously.

