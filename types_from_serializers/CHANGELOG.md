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



