## [2.0.2](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@2.0.1...types_from_serializers@2.0.2) (2023-04-05)


### Features

* map citext from PostgreSQL to string ([#7](https://github.com/ElMassimo/types_from_serializers/issues/7)) ([d8c6848](https://github.com/ElMassimo/types_from_serializers/commit/d8c6848b99b0f4ba3770871f491755c229a2c4b0))



## [2.0.1](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@2.0.0...types_from_serializers@2.0.1) (2023-04-03)


### Bug Fixes

* `add_attribute` now expects keyword arguments ([154b49e](https://github.com/ElMassimo/types_from_serializers/commit/154b49e463e3e6533b21520b7f0d699e6f0f47ba))



## [2.0.0](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@0.1.2...types_from_serializers@2.0.0) (2023-04-02)

This version adds support for `oj_serializers-2.0.2`, supporting all changes in:

- https://github.com/ElMassimo/oj_serializers/pull/9

### Features ✨

- Now keys will match the [`transform_keys`](https://github.com/ElMassimo/oj_serializers#transforming-attribute-keys-) configuration instead of always being camelized
- Support for [`flat_one`](https://github.com/ElMassimo/oj_serializers#composing-serializers-)
- Use relative paths for imports to make the output configuration more flexible
- Define the order of properties in the interface with `sort_properties_by`

## [0.1.3](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@0.1.2...types_from_serializers@0.1.3) (2022-07-12)


### Features

* apply the sql mapping fallback as the default ([64898c4](https://github.com/ElMassimo/types_from_serializers/commit/64898c4e3a3f83ea67294f2200f253cd2a64aea9))



## [0.1.2](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@0.1.1...types_from_serializers@0.1.2) (2022-07-12)


### Bug Fixes

* avoid having the full file path in the cache key ([556f8f6](https://github.com/ElMassimo/types_from_serializers/commit/556f8f667608fa950a3ad0647540055b1b5f1dc8))



## [0.1.1](https://github.com/ElMassimo/types_from_serializers/compare/types_from_serializers@0.1.0...types_from_serializers@0.1.1) (2022-07-12)



# 0.1.0 (2022-07-12)


### Features

- Start simple, no additional syntax required
- Infers types from a related `ActiveRecord` model, using the SQL schema
- Understands JS native types and how to map SQL columns: `string`, `boolean`, etc
- Automatically types [associations](https://github.com/ElMassimo/oj_serializers#associations-dsl-), importing the generated types for the referenced serializers
- Detects [conditional attributes](https://github.com/ElMassimo/oj_serializers#rendering-an-attribute-conditionally) and marks them as optional: `name?: string`
- Fallback to a custom interface using `type_from`
- Supports custom types and automatically adds the necessary imports
- handle non-ActiveRecord models and extract types from unions ([ea9b2a7](https://github.com/ElMassimo/types_from_serializers/commit/ea9b2a71cb85503ff691e5ef115ab73f89b005af))
- support specifying base serializers and additional dirs to scan ([164cfe1](https://github.com/ElMassimo/types_from_serializers/commit/164cfe17bb0527c59cf95441381aef7bf797a568))



