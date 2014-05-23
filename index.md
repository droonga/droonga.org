---
layout: en
---

<div class="jumbotron">
<h1>Droonga</h1>
<p>A distributed full-text search engine</p>
<p><a class="btn btn-primary btn-lg" role="button" href="getting-started/">Learn more »</a></p>
</div>

## About Droonga

Droonga is a distributed full-text search engine, based on a stream oriented processing model.
In many operations (searching, updating, grouping, and so on), Droonga processes various data by pipeline.
As the result, Droonga has large potential around its flexibility and extensibility.
Moreover, those features provide high availability for people who develop any data processing engine based on Droonga.
You can process complex operations by mixing operations, and you can add custom operations to Droonga via plugins written as Ruby-scripts.

See [overview](overview/) for more details.

See [roadmap](roadmap/) for the future Droonga.

## Documentations

The following documentations will help you to use Droonga more effectively:

 * [Install](install/) describes how to install Droonga.
 * [Tutorial](tutorial/) describes how to use Droonga.
 * [Reference manual](reference/) describes about specifications for users and developers.
 * [Community](community/) describes how to communicate with developers and other users.
 * [Related projects](related-projects/) introduces related projects.

## The latest news

<ul class="posts">
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <span class="date">({{ post.date | date: "%Y-%m-%d" }})</span>
    </li>
  {% endfor %}
</ul>
