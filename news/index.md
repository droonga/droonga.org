---
title: News
layout: default
use_social_widgets: true
---

{% for post in site.posts %}
  {% include news_item.html %}
{% endfor %}
