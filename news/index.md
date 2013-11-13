---
title: News
layout: default
---

{% for post in site.posts %}
  {% include news_item.html %}
{% endfor %}
