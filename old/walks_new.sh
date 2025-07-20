#!/bin/bash

cd /var/www/html/walks

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Usage: $0 2024-07-12"
    exit
fi


hugo new post/$1/index.md

chmod 777 /var/www/html/walks/* -R



