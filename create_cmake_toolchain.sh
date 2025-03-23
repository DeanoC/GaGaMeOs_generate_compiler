#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <target> <version> <file>"
    exit 1
fi

TARGET=$1
VERSION=$2
FILE=$3

cp /toolchain_template.cmake "$FILE"

if [ ! -f "$FILE" ]; then
    echo "File not found!"
    exit 1
fi

sed -i "s/\${triple}/$TARGET/g" "$FILE"
sed -i "s/\${version}/$VERSION/g" "$FILE"
