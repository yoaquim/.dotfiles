#!/bin/sh
cat brewlist.txt | xargs -L 1 brew install
