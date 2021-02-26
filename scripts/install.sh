#!/usr/bin/sh

set -e
yarn install --pure-lockfile
shippable_retry bower install --allow-root --force-latest

cd diff_worker
shippable_retry bower install --allow-root --force-latest
cd ..

cd truss_worker
shippable_retry bower install --allow-root --force-latest
cd ..
