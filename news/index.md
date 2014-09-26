---
title: News
layout: en
use_social_widgets: true
---

{% for post in site.posts %}
  {% if post.path contains "ja/news/" %}
  {% else %}
    {% include news-item.html %}
  {% endif %}
{% endfor %}
