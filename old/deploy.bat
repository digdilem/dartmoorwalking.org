




rem deploy.bat for dartmoorwalking

c:
cd \code\dartmoorwalking

hugo build --cleanDestinationDir --minify 


@REM "\Program Files (x86)\GnuWin32\bin\sed" -i 's/Geocaching Map Enhancements v0.8.2/dartmoorwalking.org/g' *.gpx
@REM "\Program Files (x86)\GnuWin32\bin\sed" -i 's/GME Export/dartmoorwalking.org/g' *.gpx
@REM "\Program Files (x86)\GnuWin32\bin\sed" -i 's/Route file exported from Geocaching.com using Geocaching Map Enhancements./Route file exported from dartmoorwalking.org - please see the corresponding web page for this walk/g' *.gpx
@REM "\Program Files (x86)\GnuWin32\bin\sed" -i 's/Geocaching.com user/Simon Avery/g' *.gpx

@REM rem --------
@REM echo Building GPX zipfile
@REM cd \code\dartmoorwalking\static\gpx
@REM del \code\dartmoorwalking\static\dartmoorwalking.org-gpxfiles.zip
@REM "\Program Files\7-Zip\7z.exe" a \code\dartmoorwalking\static\dartmoorwalking.org-gpxfiles.zip *.gpx *.txt


rem --------
echo Building maps
cd \code\dartmoorwalking\scripts
.\build_maps.ps1




@REM git add .
@REM git commit -am "Updating to reflect development"
@REM git push -f origin master

@REM npx wrangler pages deploy c:\code\dartmoorwalking\public --project-name=dartmoorwalking  --commit-dirty=true



