---
title: Catalog
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

## Usage {#usage}

This [`version`](#parameter-version) of `catalog` will be available from Droonga 1.0.0.

## Syntax {#syntax}

    {
      "version": <Version number>,
      "effectiveDate": "<Effective date>",
      "datasets": {
        "<Name of the dataset 1>": {
          "nWorkers": <Number of workers>,
          "plugins": [
            "Name of the plugin 1",
            ...
          ],
          "schema": {
            "<Name of the table 1>": {
              "type"              : <"Array", "Hash", "PatriciaTrie" or "DoubleArrayTrie">
              "keyType"          : "<Type of the primary key>",
              "tokenizer"         : "<Tokenizer>",
              "normalizer"        : "<Normalizer>",
              "columns" : {
                "<Name of the column 1>": {
                  "type"          : <"Scalar", "Vector" or "Index">,
                  "valueType"   : "<Type of the value>",
                  "indexOptions"  : {
                    "withSection"   : <WithSection>,
                    "withWeight"    : <WithWeight>,
                    "withPosition"  : <WithPosition>,
                    "sources" : [
                      "<Name of a column to be indexed>",
                      ...
                    ]
                  }
                },
                "<Name of the column 2>": { ... },
                ...
              }
            },
            "<Name of the table 2>": { ... },
            ...
          },
          "fact": "<Name of the fact table>",
          "replicas": [
            {
              "dimension": "<Name of the dimension column>",
              "slicer": "<Name of the slicer function>",
              "slices": [
                {
                  "label": "<Label of the slice>",
                  "partition": {
                    "address": "<Address string of the partition>"
                  }
                },
                ...
              }
            },
            ...
          ]
        },
        "<Name of the dataset 2>": { ... },
        ...
      }
    }

## Details {#details}

### Catalog definition {#catalog}

Value
: An object with the following key/value pairs.

#### `version` {#parameter-version}

Abstract
: Version number of the catalog file.

Value
: `2`. (Specification written in this page is valid only when this value is `2`)

Default value
: None. This is a required parameter.

Inheritable
: False.

#### `effectiveDate` {#paramter-effective_date}

Abstract
: The time when this catalog becomes effective.

Value
: A local time string formatted in the [W3C-DTF](http://www.w3.org/TR/NOTE-datetime "Date and Time Formats"), with the time zone.

Default value
: None. This is a required parameter.

Inheritable
: False.

#### `datasets` {#parameter-datasets}

Abstract
: Definition of datasets.

Value
: An object keyed by the name of the dataset with value the [`dataset` definition](#dataset).

Default value
: None. This is a required parameter.

Inheritable
: False.

#### `nWorkers` {#parameter-n_workers}

Abstract
: The number of worker processes spawned for each database instance.

Value
: An integer value.

Default value
: 0 (No worker. All operations are done in the master process)

Inheritable
: True. Overridable in `dataset` and `partition` definition.

### Dataset definition {#dataset}

Value
: An object with the following key/value pairs.

#### `plugins` {#parameter-plugins}

Abstract
: plugin names.

Value
: An array of strings.

Default value
: None. This is a required parameter.

Inheritable
: True. Overridable in `dataset` and `partition` definition.

#### `schema` {#parameter-schema}

Abstract
: Definition of tables and their columns.

Value
: An object keyed by the name of the table with value the [`table` definition](#table).

Default value
: None. This is a required parameter.

Inheritable
: True. Overridable in `dataset` and `partition` definition.

#### `fact` {#parameter-fact}

Abstract
: Name of the fact table. When a `dataset` is stored as more than one `slice`, one [fact table](http://en.wikipedia.org/wiki/Fact_table) must be selected from tables defined in [`schema`](#parameter-schema) parameter.

Value
: A string.

Default value
: None.

Inheritable
: True. Overridable in `dataset` and `partition` definition.

#### `replicas` {#parameter-replicas}

Abstract
: Definition of replicas which store the contents of the dataset.

Value
: An array of [`partition` definitions](#partition).

Default value
: None. This is a required parameter.

Inheritable
: False.

### Table definition {#table}

Value
: An object with the following keys.

#### `type` {#parameter-table-type}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `keyType` {#parameter-keyType}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `tokenizer` {#parameter-tokenizer}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `normalizer` {#parameter-normalizer}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `columns` {#parameter-columns}

Abstract

: Column definition for the table.

Value
: An object keyed by the name of the column with value the [`column` definition](#column).

Default value
: None.

Inheritable
: False.

### Column definition {#column}

Value

: An object with the following keys.

#### `type` {#parameter-column-type}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `valueType` {#parameter-valueType}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `indexOptions` {#parameter-indexOptions}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

### indexOption definition {#indexOption}

Value

: (TBD)

#### `withSection` {#parameter-withSection}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `withWeight` {#parameter-withWeight}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `withPosition` {#parameter-withPosition}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

#### `sources` {#parameter-sources}

Abstract

: (TBD)

Value
: (TBD)

Default value
: (TBD)

Inheritable
: (TBD)

### Partition definition {#partition}

Value
: An object with the following key/value pairs.

#### `address` {#parameter-address}

Abstract
: (TBD)

Value
: (TBD)

Default value
: None.

Inheritable
: False.

#### `dimension` {#parameter-dimension}

Abstract
: When a `dataset` is stored as more than one `slice`, either '_key" or a scalar type column must be selected from [`columns`](#parameter-columns) parameter of the fact table. When the selected column is a foreign key, the refered table is called [dimension table](http://en.wikipedia.org/wiki/Dimension_table).

Value
: A string.

Default value
: "_key"

Inheritable
: True. Overridable in `dataset` and `partition` definition.

#### `slicer` {#parameter-slicer}

Abstract
: Function to slice the value of dimension column.

Value
: Name of slicer function.

Default value
: "hash"

Inheritable
: True. Overridable in `dataset` and `partition` definition.

#### `slices` {#parameter-slices}

Abstract
: Definition of slices which store the contents of the data.

Value
: An array of [`slice` definitions](#slice).

Default value
: None.

Inheritable
: False.

### Slice definition {#slice}

A slice has one of `weight`, `label` or `boundary` parameters..

Value
: An object with the following key/value pairs.

#### `weight` {#parameter-weight}

Abstract
: Avaible when the slicer is ratio-scaled.

Value
: (TBD)

Default value
: 1.

Inheritable
: False.

#### `label` {#parameter-label}

Abstract
: Avaible when the slicer is nominal-scaled.

Value
: (TBD)

Default value
: None.

Inheritable
: False.

#### `boundary` {#parameter-boundary}

Abstract
: Avaible when the slicer is ordinal-scaled.

Value
: (TBD)

Default value
: None.

Inheritable
: False.

#### `partition` {#parameter-partition}

Abstract
: (TBD)

Value

: An object which is a [`partition` definition](#partition)

Default value
: None.

Inheritable
: False.
