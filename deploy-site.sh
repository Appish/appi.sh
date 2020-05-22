#!/bin/sh

# prepare build dir
mkdir -p build/thanks

# copy files to build dir
html-minifier --collapse-whitespace --remove-comments --remove-optional-tags --remove-redundant-attributes --remove-script-type-attributes index.html > build/index.html
html-minifier --collapse-whitespace --remove-comments --remove-optional-tags --remove-redundant-attributes --remove-script-type-attributes thanks/index.html > build/thanks/index.html
cp -r css/ build/
uglifycss css/custom.css > build/custom.css
cp -r icons/ build/
cp robots.txt build/
cp sitemap.xml build/
cp favicon.ico build/

# sync build dir to S3 bucket
cd build || exit 1
aws s3 sync . "s3://$APPI_BUCKET"

# call CF invalidation
aws cloudfront create-invalidation --distribution-id "$APPI_DISTRO" --paths "/*"

