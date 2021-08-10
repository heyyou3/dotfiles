#!/bin/sh
cat /etc/os-release | grep VERSION=  | awk -F= '{print $2}' | sed -e 's/\"//g'