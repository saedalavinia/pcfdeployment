#!/bin/bash

args=("$@")

url=${args[0]}
access_token=${args[1]}

curl "$url" -k \
    -X POST \
    -H "Authorization: Bearer $access_token" \
    -F 'product[file]=@cf.pivotal'
