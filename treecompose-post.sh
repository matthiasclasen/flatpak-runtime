#!/usr/bin/env bash

# Non writable directories are a pain in the ass since xdg-app rm -rf
# can't remove files in them
find /usr -type d -exec chmod u+w {} \;
