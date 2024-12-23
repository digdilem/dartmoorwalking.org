#!/bin/bash
cd /var/www/html/walks

./scripts/build_map.pl

hugo server --disableFastRender --bind 10.1.0.1 -D  -b http://10.1.0.1:1313

