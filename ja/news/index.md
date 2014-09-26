---
title: 最新情報
layout: ja
use_social_widgets: true
---

{% for post in site.posts %}
  {% if post.path contains "ja/news/" %}
    {% include news-item.ja.html %}
  {% else %}
  {% endif %}
{% endfor %}
