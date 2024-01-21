#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

find $1 -exec rename -v 's/ü/ue/g; s/Ü/Ue/g; s/ä/ae/g; s/Ä/Ae/g; s/ö/oe/g; s/Ö/Oe/g; s/ß/ss/g' {} \;
