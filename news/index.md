---
title: News
layout: en
use_social_widgets: true
---

{% for post in site.posts %}
  {% if post.language == "en" %}
    {% include news-item.html %}
  {% endif %}
{% endfor %}
