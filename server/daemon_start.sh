#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=/opt/node/bin:$PATH

cd $DIR

npm start &> /var/log/clockers.log
