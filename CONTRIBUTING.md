## Setting Up a Development Environment

1. Install [mise](https://mise.jdx.dev/), then run `mise trust && mise install` to install Ruby 4.0.7, Node.js 24, and pnpm.

2. Run the following commands to set up the development environment.

```
bundle install
```

```
pnpm install
```

```
pnpm migrate
```

## Making sure your changes pass all tests

There are a number of automated checks which run on GitHub Actions when a pull request is created.
You can run those checks on your own locally to make sure that your changes would not break the CI build.

### 1. Check the code for JavaScript style violations

```
pnpm lint
```

### 2. Check the code for Ruby style violations

```
bin/rubocop
```

### 3. Run the test suite

```
bin/rspec
```
