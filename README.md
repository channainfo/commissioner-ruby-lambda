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

## Run test

```sh
bundle exec rspec spec
```

## Create a lambda-layer

Zip the lambda-ruby folder and rename the zip output to lambda-layer.zip

```sh
zip -r  lambda-layer.zip -x "lambda-ruby/vendor/*"
```

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
