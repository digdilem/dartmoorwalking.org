rem deploy.bat for dartmoorwalking

c:
cd \code\dartmoorwalking

hugo build --cleanDestinationDir --minify 

git add .
git commit -am "Updating to reflect development"
git push -f origin master

npx wrangler pages deploy c:\code\dartmoorwalking\public --project-name=dartmoorwalking  --commit-dirty=true



