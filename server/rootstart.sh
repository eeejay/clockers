#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NODE=$(which node)

sudo su - -c "cd ${DIR} && DEBUG=${DEBUG} ${NODE} ./bin/www"
