# Getting Started

## Setting up with Bundle

Install gem using bundler

```sh
bundle install --path vendor/bundle
```

or manually create the following config .bundle/config

```yaml
---
BUNDLE_PATH: "layer/gems"
BUNDLE_WITHOUT: "development:test"
```

## Run on docker with a specific ruby version

```sh
docker build -t media_convert .
docker run -it media_convert bash

ruby ./lib/handler/create_job.rb
```

Copy lib

```sh
docker cp <container_id>:/path/to/directory /path/on/host
```

## Run test

```sh
bundle exec rspec spec
```

## Create a lambda-layer

Layer is placed under the dir /opt in the lambda function container.

```sh
# command_layer.sh
# we install bundler under the vendor/bundle
bundle config set --local path vendor/bundle
bundle config set --local without test

bundle install > /dev/null

```

Eventually in the lambda function container, the layer will be under **/opt/vendor/bundle** thus when we create lambda function we modify the path to /opt/vendor/bundle

```sh
# command_function.sh
# we install the gem with --path to vendor/bundle
# AWS Lambda layer put the file under the /opt
# we want BUNDLE_PATH: "vendor/bundle" => BUNDLE_PATH: "/opt/vendor/bundle"
mv .bundle/config .bundle/config.backup
mv .bundle/config.lambda_layer .bundle/config


# zip the function
zip -r $OUTPUT_ZIP $SOURCE_DIR -x "vendor/*" ".ruby-lsp/*" ".git*" "spec/*" "*.zip" "ruby/*" \
  "*.DS_Store" > /dev/null

mv .bundle/config .bundle/config.lambda_layer
mv .bundle/config.backup .bundle/config

```

Every time you change the .bundle/config you will need to change the .bundle/config.lambda_layer as well to make sure the build for lambda function to work correctly

## Register lambda handler

To test locally

```sh
# cd to the root of the project
ruby lib/handler/callback.rb
```

To run in the AWS lambda with engine ruby using [Terraform](https://github.com/channainfo/commissioner-terraform-aws/tree/develop/modules/media_convert)

```tf

resource "aws_lambda_function" "media_convert_callback" {
  filename         = "lambda-ruby.zip" // Path to your Lambda deployment package
  source_code_hash = filebase64sha256("lambda-ruby.zip")

  function_name = "media_convert_callback"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda-ruby/lib/media_convert/callback.handler" # entry_file_name#method
  runtime       = "ruby3.2"
  architectures = ["arm64"]

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }
}
```

## Issue with lambda

```txt
"Could not find gems matching 'nokogiri' valid for all resolution platforms (x86_64-darwin-22, aarch64-linux) in cached gems or installed locally.\n\nThe source contains the following gems matching 'nokogiri':\n  * nokogiri-1.16.6-x86_64-darwin"
```

## Github workflow

Make sure you create secrets value for the repository. The secrets for action have 2 sections-- the environment secrets and the repository secrets. Make sure you create for the repository secrets

```sh
# repository secrets

```
