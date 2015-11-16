---
title: Reference manuals
layout: en
---

You can refer to reference manuals for all releases including the next
release.

## The current release

* [{{ site.version.current }}]({{ site.version.current }}/)

## The next release

* [{{ site.version.next }}]({{ site.version.next }}/)

## Old releases

{% for old_version in site.version.olds %}
* [{{ old_version }}]({{ old_version }}/)
{% endfor %}
