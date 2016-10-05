#!/bin/bash

set -ex

nmap 127.0.0.1 -PN -p 5000 | grep open
nmap 127.0.0.1 -PN -p 5044 | grep open

