#!/bin/bash

# Output zip file
OUTPUT_ZIP="media_convert_function.zip"

# just to ensure to rm the file even if it does not exist
rm -f $OUTPUT_ZIP

# directly in the ruby submondule project
# cd lambda-ruby


SOURCE_DIR="."

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

# go back to the root dir
# cd - > /dev/null

# print out the message
echo "***Lambda function packaged into $OUTPUT_ZIP"