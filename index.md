---
layout: en
---

<div class="jumbotron">
<h1>Droonga</h1>
<p>A scalable data processing engine</p>
<p><a class="btn btn-primary btn-lg" role="button" href="overview/">Learn more »</a></p>
</div>

## About Droonga

Droonga is a scalable data processing engine. Droonga uses stream oriented processing model. Droonga processes data by pipeline. Many operations such as search, update, group are done in pipeline. The processing model provides flexibility and extensibility. Droonga can also process complex operations by mixing operations. Users can add custom operations to Droonga as Ruby plugins.

See [overview](overview/) for more details.

See [roadmap](roadmap/) for the future Droonga.

## Getting started

Try [tutorial](tutorial/) to know about Droonga after you understand about Droonga. If you don't read [overview](overview/) yet, read it before trying the tutorial.

## Documentations

The following documentations will help you to use Droonga more effectively:

 * [Install](install/) describes how to install Droonga.
 * [Reference manual](reference/) describes about specifications.
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
