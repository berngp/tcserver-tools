#!/bin/sh
#-------------------------------------------
# resolve links - $0 may be a softlink
DIR=`dirname "$1"`

echo "Reading the tcsgroup $DIR/env.sh"


export CATALINA_HOME="$DIR/../mock-catalinaHome"
