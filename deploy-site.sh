#!/bin/sh

# prepare build dir
mkdir -p build/

# copy files to build dir
cp index.html build/
cp -r css/ build/
cp -r thanks/ build/
cp -r icons/ build/
cp robots.txt build/
cp sitemap.xml build/
cp favicon.ico build/

# sync build dir to S3 bucket
cd build || exit 1
aws s3 sync . "s3://$APPI_BUCKET"

# call CF invalidation
aws cloudfront create-invalidation --distribution-id "$APPI_DISTRO" --paths "/*"

