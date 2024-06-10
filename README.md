# Getting Started

## Setting up with Bundle

Install gem using bundler

```sh
bundle install --path vendor/bundle
```

or manually create the following config .bundle/config

```yaml
---
BUNDLE_PATH: "vendor/bundle"
BUNDLE_WITHOUT: "development:test"
```

## Run on docker with a specific ruby version

```sh
docker build -t media_convert .
docker run -it media_convert bash

ruby ./media_convert_create_job.rb
```
