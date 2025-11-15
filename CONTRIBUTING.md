## Setting Up a Development Environment

1. Install [pnpm](https://pnpm.io/installation)

2. Run the following commands to set up the development environment.

```sh
bundle install
```

```sh
pnpm install
```

```sh
pnpm migrate
```

## Making sure your changes pass all tests

There are a number of automated checks which run on GitHub Actions when a pull request is created.
You can run those checks on your own locally to make sure that your changes would not break the CI build.

### 1. Rebuild the generated files

```sh
pnpm gen
```

### 2. Check the code for JavaScript style violations

```sh
pnpm lint
```

### 3. Check the code for Ruby style violations

```sh
bin/rubocop
```

### 4. Run the test suite

```sh
bin/rspec
```
