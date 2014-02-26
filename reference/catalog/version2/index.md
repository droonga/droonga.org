---
title: Catalog
layout: en
---

* TOC
{:toc}

## Abstract {#abstract}

`Catalog` is a JSON data to manage the configuration of a Droonga cluster.
A Droonga cluster consists of one or more `datasets`, and a `dataset` consists of other portions. They all must be explicitly described in a `catalog` and be shared with all the hosts in the cluster.

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
              "type"             : <"Array", "Hash", "PatriciaTrie" or "DoubleArrayTrie">
              "keyType"          : "<Type of the primary key>",
              "tokenizer"        : "<Tokenizer>",
              "normalizer"       : "<Normalizer>",
              "columns" : {
                "<Name of the column 1>": {
                  "type"         : <"Scalar", "Vector" or "Index">,
                  "valueType"    : "<Type of the value>",
                  "indexOptions" : {
                    "section"    : <Section>,
                    "weight"     : <Weight>,
                    "position"   : <Position>,
                    "sources"    : [
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
                  "volume": {
                    "address": "<Address string of the volume>"
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

#### `effectiveDate` {#parameter-effective_date}

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
: True. Overridable in `dataset` and `volume` definition.

### Dataset definition {#dataset}

Value
: An object with the following key/value pairs.

#### `plugins` {#parameter-plugins}

Abstract
: Name strings of the plugins enabled for the dataset.

Value
: An array of strings.

Default value
: None. This is a required parameter.

Inheritable
: True. Overridable in `dataset` and `volume` definition.

#### `schema` {#parameter-schema}

Abstract
: Definition of tables and their columns.

Value
: An object keyed by the name of the table with value the [`table` definition](#table).

Default value
: None. This is a required parameter.

Inheritable
: True. Overridable in `dataset` and `volume` definition.

#### `fact` {#parameter-fact}

Abstract
: The name of the fact table. When a `dataset` is stored as more than one `slice`, one [fact table](http://en.wikipedia.org/wiki/Fact_table) must be selected from tables defined in [`schema`](#parameter-schema) parameter.

Value
: A string.

Default value
: None.

Inheritable
: True. Overridable in `dataset` and `volume` definition.

#### `replicas` {#parameter-replicas}

Abstract
: A collection of volumes which are the copies of each other.

Value
: An array of [`volume` definitions](#volume).

Default value
: None. This is a required parameter.

Inheritable
: False.

### Table definition {#table}

Value
: An object with the following key/value pairs.

#### `type` {#parameter-table-type}

Abstract
: Specifies which data structure is used for managing keys of the table.

Value
: Any of the following values.

* "Array": for tables which have no keys.
* "Hash": for hash tables.
* "PatriciaTrie": for patricia trie tables.
* "DoubleArrayTrie": for double array trie tables.

Default value
: "Hash"

Inheritable
: False.

#### `keyType` {#parameter-keyType}

Abstract
: Data type of the key of the table. Mustn't be assigned when the `type` is "Array".

Value
: Any of the following data types.

* "Integer"       : 64bit signed integer.
* "Float"         : 64bit floating-point number.
* "Time"          : Time value with microseconds resolution.
* "ShortText"     : Text value up to 4095 bytes length.
* "TokyoGeoPoint" : Tokyo Datum based geometric point value.
* "WGS84GeoPoint" : [WGS84](http://en.wikipedia.org/wiki/World_Geodetic_System) based geometric point value.

Default value
: None. Mandatory for tables with keys.

Inheritable
: False.

#### `tokenizer` {#parameter-tokenizer}

Abstract
: Specifies the type of tokenizer used for splitting each text value, when the table is used as a lexicon. Only available when the `keyType` is "ShortText".

Value
: Any of the following tokenizer names.

* "TokenDelimit"
* "TokenUnigram"
* "TokenBigram"
* "TokenTrigram"
* "TokenBigramSplitSymbol"
* "TokenBigramSplitSymbolAlpha"
* "TokenBigramSplitSymbolAlphaDigit"
* "TokenBigramIgnoreBlank"
* "TokenBigramIgnoreBlankSplitSymbol"
* "TokenBigramIgnoreBlankSplitSymbolAlpha"
* "TokenBigramIgnoreBlankSplitSymbolAlphaDigit"
* "TokenDelimitNull"

Default value
: None.

Inheritable
: False.

#### `normalizer` {#parameter-normalizer}

Abstract
: Specifies the type of normalizer which normalizes and restricts the key values. Only available when the `keyType` is "ShortText".

Value
: Any of the following normalizer names.

* "NormalizerAuto"
* "NormalizerNFKC51"

Default value
: None.

Inheritable
: False.

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

: An object with the following key/value pairs.

#### `type` {#parameter-column-type}

Abstract
: Specifies the quantity of data stored as each column value.

Value
: Any of the followings.

* "Scalar": A single value.
* "Vector": A list of values.
* "Index" : A set of unique values with additional properties respectively. Properties can be specified in [`indexOptions`](#parameter-indexOptions).

Default value
: "Scalar"

Inheritable
: False.

#### `valueType` {#parameter-valueType}

Abstract
: Data type of the column value.

Value
: Any of the following data types or the name of another table defined in the same dataset. When a table name is assigned, the column acts as a foreign key references the table.

* "Bool"          : `true` or `false`.
* "Integer"       : 64bit signed integer.
* "Float"         : 64bit floating-point number.
* "Time"          : Time value with microseconds resolution.
* "ShortText"     : Text value up to 4,095 bytes length.
* "Text"          : Text value up to 2,147,483,647 bytes length.
* "TokyoGeoPoint" : Tokyo Datum based geometric point value.
* "WGS84GeoPoint" : [WGS84](http://en.wikipedia.org/wiki/World_Geodetic_System) based geometric point value.

Default value
: None. This is a required parameter.

Inheritable
: False.

#### `indexOptions` {#parameter-indexOptions}

Abstract
: Specifies the optional properties of a "Index" column.

Value
: An object which is an [`indexOption` definition](#indexOption)

Default value
: `{}` (Void object).

Inheritable
: False.

### indexOption definition {#indexOption}

Value
: An object with the following key/value pairs.

#### `section` {#parameter-section}

Abstract
: Specifies whether the index column stores the section data or not. Section data is typically used for distinguishing in which part of the sources the value appears.

Value
: A boolean value (`true` or `false`).

Default value
: `false`.

Inheritable
: False.

#### `weight` {#parameter-weight}

Abstract
: Specifies whether the index column stores the weight data or not. Weight data is used for indicating the importance of the value in the sources.

Value
: A boolean value (`true` or `false`).

Default value
: `false`.

Inheritable
: False.

#### `position` {#parameter-position}

Abstract
: Specifies whether the index column stores the position data or not. Position data is used for specifying the position where the value appears in the sources. It is indispensable for fast and accurate phrase-search.

Value
: A boolean value (`true` or `false`).

Default value
: `false`.

Inheritable
: False.

#### `sources` {#parameter-sources}

Abstract
: Makes the column an inverted index of the referencing table's columns.

Value
: An array of column names of the referencing table assigned as [`valueType`](#parameter-valueType).

Default value
: None.

Inheritable
: False.

### Volume definition {#volume}

Abstract
: A unit to compose a dataset. A dataset consists of one or more volumes. A volume consists of either a single instance of database or a collection of `slices`. When a volume consists of a single database instance, `address` parameter must be assigned and the other parameters must not be assigned. Otherwise, `dimension`, `slicer` and `slices` are required, and vice versa.

Value
: An object with the following key/value pairs.

#### `address` {#parameter-address}

Abstract
: Specifies the location of the database instance.

Value
: A string in the following format.

"[database_type:]hostname[:port_number]/localpath/to/the/database"

* database_type: Omittable. Default value is "groonga".
* port_number: Omittable. Default value is 10047.

Default value
: None.

Inheritable
: False.

#### `dimension` {#parameter-dimension}

Abstract
: Specifies the dimension to slice the records in the fact table. Either '_key" or a scalar type column can be selected from [`columns`](#parameter-columns) parameter of the fact table. See [dimension](http://en.wikipedia.org/wiki/Dimension_%28data_warehouse%29).

Value
: A string.

Default value
: "_key"

Inheritable
: True. Overridable in `dataset` and `volume` definition.

#### `slicer` {#parameter-slicer}

Abstract
: Function to slice the value of dimension column.

Value
: Name of slicer function.

Default value
: "hash"

Inheritable
: True. Overridable in `dataset` and `volume` definition.

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

Abstract
: Definition of each slice. Specifies the range of sliced data and the volume to store the data.

Value
: An object with the following key/value pairs.

#### `weight` {#parameter-slice-weight}

Abstract
: Specifies the share in the slices. Only available when the `slicer` is ratio-scaled.

Value
: A numeric value.

Default value
: `1`.

Inheritable
: False.

#### `label` {#parameter-label}

Abstract
: Specifies the concrete value that slicer may return. Only available when the slicer is nominal-scaled.

Value
: A value of the dimension column data type. When the value is not provided, this slice is regarded as `else`. Therefore, only one slice without `label` is allowed in a slices.

Default value
: None.

Inheritable
: False.

#### `boundary` {#parameter-boundary}

Abstract
: Specifies the concrete value that can compare with `slicer`'s return value. Only available when the `slicer` is ordinal-scaled.

Value
: A value of the dimension column data type. When the value is not provided, this slice is regarded as `else`. Therefore, only one slice without `boundary` is allowed in a slices.

Default value
: None.

Inheritable
: False.

#### `volume` {#parameter-volume}

Abstract
: A volume to store the data which corresponds to the slice.

Value

: An object which is a [`volume` definition](#volume)

Default value
: None.

Inheritable
: False.
