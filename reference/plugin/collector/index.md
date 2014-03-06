---
title: Collector
layout: en
---

* TOC
{:toc}


## Abstract {#abstract}

A collector merges two input values to single value.
The Droonga Engine tries to collect three or more values by applying the specified collector for two of them again and again.

## Built-in collector classes {#builtin-collectors}

There are some pre-defined collector classes used by built-in plugins.
Of course they are available for your custom plugins.

### `Droonga::Collectors::And`

Returns a result from comparison of two values by the `and` logical operator.
If both values are logically equal to `true`, then one of them (it is indeterminate) becomes the result.

Values `null` (`nil`) and `false` are treated as `false`.
Otherwise `true`.

### `Droonga::Collectors::Or`

Returns a result from comparison of two values by the `or` logical operator.
If only one of them is logically equal to `true`, then the value becomes the result.
Otherwise, if values are logically same, one of them (it is indeterminate) becomes the result.

Values `null` (`nil`) and `false` are treated as `false`.
Otherwise `true`.

### `Droonga::Collectors::Sum`

Returns a summarized value of two input values.

This collector works a little complicatedly.

 * If one of values is equal to `null` (`nil`), then the other value becomes the result.
 * If both values are hash, then a merged hash becomes the result.
   * The result hash has all keys of two hashes.
     If both have same keys, then one of their values appears as the value of the key in the reuslt hash.
   * It is indeterminate which value becomes the base.
 * Otherwise the result of `a + b` becomes the result.
   * If they are arrays or strings, a concatenated value becomes the result.
     It is indeterminate which value becomes the lefthand.

