<h1 align="center">
Types From Serializers
<p align="center">
<a href="https://github.com/ElMassimo/types_from_serializers/actions"><img alt="Build Status" src="https://github.com/ElMassimo/types_from_serializers/workflows/build/badge.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/types_from_serializers"><img alt="Maintainability" src="https://codeclimate.com/github/ElMassimo/types_from_serializers/badges/gpa.svg"/></a>
<!-- <a href="https://codeclimate.com/github/ElMassimo/types_from_serializers"><img alt="Test Coverage" src="https://codeclimate.com/github/ElMassimo/types_from_serializers/badges/coverage.svg"/></a> -->
<a href="https://rubygems.org/gems/types_from_serializers"><img alt="Gem Version" src="https://img.shields.io/gem/v/types_from_serializers.svg?colorB=e9573f"/></a>
<a href="https://github.com/ElMassimo/types_from_serializers/blob/master/LICENSE.txt"><img alt="License" src="https://img.shields.io/badge/license-MIT-428F7E.svg"/></a>
</p>
</h1>

[oj]: https://github.com/ohler55/oj
[oj_serializers]: https://github.com/ElMassimo/oj_serializers
[ams]: https://github.com/rails-api/active_model_serializers
[Rails]: https://github.com/rails/rails
[Issues]: https://github.com/ElMassimo/types_from_serializers/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc
[Discussions]: https://github.com/ElMassimo/types_from_serializers/discussions
[TypeScript]: https://www.typescriptlang.org/
[Vite Ruby]: https://github.com/ElMassimo/vite_ruby
[vite-plugin-full-reload]: https://github.com/ElMassimo/vite-plugin-full-reload
[base_serializers]: https://github.com/ElMassimo/types_from_serializers#base_serializers
[config]: https://github.com/ElMassimo/types_from_serializers#configuration-%EF%B8%8F

Automatically generate TypeScript interfaces from your [JSON serializers][oj_serializers].

_Currently, this library targets [`oj_serializers`][oj_serializers] and `ActiveRecord` in [Rails] applications_.

## Demo 🎬

For a schema such as [this one](https://github.com/ElMassimo/types_from_serializers/blob/main/playground/vanilla/db/schema.rb):

<details>
  <summary>DB Schema</summary>

```ruby
  create_table "composers", force: :cascade do |t|
    t.text "first_name"
    t.text "last_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "songs", force: :cascade do |t|
    t.text "title"
    t.integer "composer_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "video_clips", force: :cascade do |t|
    t.text "title"
    t.text "youtube_id"
    t.integer "song_id"
    t.integer "composer_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end
```
</details>

and a serializer like the following:

```ruby
class VideoSerializer < BaseSerializer
  object_as :video, model: :VideoClip

  attributes :id, :created_at, :title, :youtube_id

  type :string, optional: true
  def youtube_url
    "https://www.youtube.com/watch?v=#{video.youtube_id}" if video.youtube_id
  end

  has_one :song, serializer: SongSerializer
end
```

it would generate a TypeScript interface like:

```ts
import type Song from '~/types/serializers/Song'

export default interface Video {
  id: number
  createdAt: string | Date
  title?: string
  youtubeId?: string
  youtubeUrl?: string
  song: Song
}
```

> **Note**
>
> This is the default configuration, but you have [full control][config] over generation.


## Why? 🤔

It's easy for the backend and the frontend to become out of sync.
Traditionally, preventing bugs requires writing extensive integration tests.

[TypeScript] is a great tool to catch this kind of bugs and mistakes, as it can
detect incorrect usages and missing fields, but writing types manually is
cumbersome, and they can become stale over time, giving a false sense of confidence.

This library takes advantage of the declarative nature of serializer libraries
such as [`active_model_serializers`][ams] and [`oj_serializers`][oj_serializers],
extending them to allow embedding type information, as well as inferring types
from the SQL schema when available.

As a result, it's posible to easily detect mismatches between the backend and
the frontend, as well as make the fields more discoverable and provide great
autocompletion in the frontend, without having to manually write the types.

## Features ⚡️

- Start simple, no additional syntax required
- Infers types from a related `ActiveRecord` model, using the SQL schema
- Understands JS native types and how to map SQL columns: `string`, `boolean`, etc
- Automatically types [associations](https://github.com/ElMassimo/oj_serializers#associations-dsl-), importing the generated types for the referenced serializers
- Detects [conditional attributes](https://github.com/ElMassimo/oj_serializers#rendering-an-attribute-conditionally) and marks them as optional: `name?: string`
- Fallback to a custom interface using `type_from`
- Supports custom types and automatically adds the necessary imports


## Installation 💿

Add this line to your application's Gemfile:

```ruby
gem 'types_from_serializers'
```

And then run:

    $ bundle install

## Usage 🚀

To get started, [create a `BaseSerializer`](https://github.com/ElMassimo/types_from_serializers/blob/main/playground/vanilla/app/serializers/base_serializer.rb) that extends [`Oj::Serializer`][oj_serializers], and include the `TypesFromSerializers::DSL` module.

```ruby
# app/serializers/base_serializer.rb

class BaseSerializer < Oj::Serializer
  include TypesFromSerializer::DSL
end
```

> **Note**
>
> You can customize this behavior using [`base_serializers`][base_serializers].

> **Warning**
>
> All serializers should extend one of the [`base_serializers`][base_serializers], or they won't be
detected.


### SQL Attributes

In most cases, you'll want to let `TypesFromSerializer` infer the types from the [SQL schema](https://github.com/ElMassimo/types_from_serializers/blob/main/playground/vanilla/db/schema.rb).

If you are using `ActiveRecord`, the model related to the serializer will be inferred can be inferred from the serializer name:

```ruby
UserSerializer => User
```

It can also be inferred from an [object alias](https://github.com/ElMassimo/oj_serializers#using-a-different-alias-for-the-internal-object) if provided:

```ruby
class PersonSerializer < BaseSerializer
  object_as :user
```

In cases where we want to use a different alias, you can provide the model name explicitly:

```ruby
class PersonSerializer < BaseSerializer
  object_as :person, model: :User
```

### Model Attributes

When you want to be more strict than the SQL schema, or for attributes that are methods in the model, you can use:

```ruby
  typed_attributes(
    name: :string,
    status: :Status, # a custom type in ~/types/Status.ts
  )
```

### Serializer Attributes

For attributes defined in the serializer, use the `type` helper:

```ruby
  type :boolean
  def suspended
    user.status.suspended?
  end
```

> **Note**
>
> When specifying a type, [`serializer_attribute`](https://github.com/ElMassimo/oj_serializers#serializer_attributes) will be called automatically.

### Fallback Attributes

You can also specify `types_from` to provide a TypeScript interface that should
be used to obtain the field types:

```ruby
class LocationSerializer < BaseSerializer
  object_as :location, types_from: :GoogleMapsLocation

  attributes(
    :lat,
    :lng,
  )
end
```

```ts
import GoogleMapsLocation from '~/types/GoogleMapsLocation'

export default interface Location {
  lat: GoogleMapsLocation['lat']
  lng: GoogleMapsLocation['lng']
}
```

## Generation 📜

To get started, run `bin/rails s` to start the `Rails` development server.

`TypesFromSerializers` will automatically register a `Rails` reloader, which
detects changes to serializer files, and will generate code on-demand only for
the modified files.

It can also detect when new serializer files are added, or removed, and update
the generated code accordingly.

### Manually

To generate types manually, use the rake task:

```
bundle exec rake types_from_serializers:generate
```

or if you prefer to do it manually from the console:

```ruby
require "types_from_serializers/generator"

TypesFromSerializer.generate(force: true)
```

### With [`vite-plugin-full-reload`][vite-plugin-full-reload] ⚡️

When using _[Vite Ruby]_, you can add [`vite-plugin-full-reload`][vite-plugin-full-reload]
to automatically reload the page when modifying serializers, causing the Rails
reload process to be triggered, which is when generation occurs.

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import ruby from 'vite-plugin-ruby'
import reloadOnChange from 'vite-plugin-full-reload'

defineConfig({
  plugins: [
    ruby(),
    reloadOnChange(['app/serializers/**/*.rb'], { delay: 200 }),
  ],
})
```

As a result, when modifying a serializer and hitting save, the type for that
serializer will be updated instantly!

## Configuration ⚙️

You can configure generation in a Rails initializer:

```ruby
# config/initializers/types_from_serializers.rb

if Rails.env.development?
  TypesFromSerializers.config do |config|
    config.name_from_serializer = ->(name) { name }
  end
end
```

### `base_serializers`

_Default:_ `["BaseSerializer"]`

Allows you to specify the base serializers, that are used to detect other
serializers in the app that you would like to generate interfaces for.

### `serializers_dirs`

_Default:_ `["app/serializers"]`

The dirs where the serializer files are located.

### `output_dir`

_Default:_ `"app/frontend/types"`

The dir where the generated TypeScript interface files are placed.

### `name_from_serializer`

_Default:_ `->(name) { name.delete_suffix("Serializer") }`

A `Proc` that specifies how to convert the name of the serializer into the name
of the generated TypeScript interface.

### `native_types`

_Default:_ `["Array", "Record", "Date"]`

Types that don't need to be imported in TypeScript.

You can extend this list as needed if you are using global definitions.

### `sql_to_typescript_type_mapping`

Specifies [how to map](https://github.com/ElMassimo/types_from_serializers/blob/main/types_from_serializers/lib/types_from_serializers/generator.rb#L297-L308) SQL column types to TypeScript native and custom types.

```ruby
# Example: You have response middleware that automatically converts date strings
# into Date objects, and you want TypeScript to treat those fields as `Date`.
config.sql_to_typescript_type_mapping.update(
  date: :Date,
  datetime: :Date,
)

# Example: You won't transform fields when receiving data in the frontend
# (date fields are serialized to JSON as strings).
config.sql_to_typescript_type_mapping.update(
  date: :string,
  datetime: :string,
)

# Example: You plan to introduce types slowly, and don't want to be strict with
# untyped fields, so treat them as `any` instead of `unknown`.
config.sql_to_typescript_type_mapping.default = :any
```

## Contact ✉️

Please use [Issues] to report bugs you find, and [Discussions] to make feature requests or get help.

Don't hesitate to _⭐️ star the project_ if you find it useful!

Using it in production? Always love to hear about it! 😃

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
