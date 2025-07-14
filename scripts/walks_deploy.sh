#!/bin/bash

cd /var/www/html/walks

# Build the site
hugo

# Build the map
/var/www/html/walks/scripts/build_map.pl

# Zip up all the GPX files into one file after replacing any GME strings
cd /var/www/html/walks/static/gpx

sed -i 's/Geocaching Map Enhancements v0.8.2/dartmoorwalking.org/g' *.gpx
sed -i 's/GME Export/dartmoorwalking.org/g' *.gpx
sed -i 's/Route file exported from Geocaching.com using Geocaching Map Enhancements./Route file exported from dartmoorwalking.org - please see the corresponding web page for this walk/g' *.gpx
sed -i 's/Geocaching.com user/Simon Avery/g' *.gpx

rm /var/www/html/walks/static/dartmoorwalking.org-gpxfiles.zip
zip -j /var/www/html/walks/static/dartmoorwalking.org-gpxfiles.zip /var/www/html/walks/static/gpx/*.gpx /var/www/html/walks/static/README.txt


# Simon - if this expires again, then read https://developers.cloudflare.com/pub-sub/learning/command-line-wrangler/

#export CLOUDFLARE_API_TOKEN="j0xwuphpqYWSuU7ylpvhpF3M15tl8YUcwx_OVE_x"  - Broken 241213
export CLOUDFLARE_API_TOKEN="tvXm8ysXzgmx6i4nBHPST0l4B2mqrN7HPz8p4N_E"
    
npx wrangler pages deploy /var/www/html/walks/public --project-name=dartmoorwalking
    


