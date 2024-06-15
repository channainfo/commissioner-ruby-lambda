#!/bin/bash

OUTPUT_ZIP="media_convert_layer.zip"

# just to ensure to rm the file even if it does not exist
# rm -f $OUTPUT_ZIP

# directly in the ruby submondule project
# cd lambda-ruby

# bundle install --without test:development --path test:development
# ====================== lambda function ==========================
bundle config set --local path vendor/bundle
bundle config set --local without test:development

bundle install > /dev/null

# coz bundler put everything under the vendor
SOURCE_DIR="vendor"

# zip the package.
zip -r $OUTPUT_ZIP $SOURCE_DIR -x "*.DS_Store" > /dev/null

# go back to the root dir
# cd - > /dev/null

# print out the message
echo "***Lambda layer packaged into $OUTPUT_ZIP"

