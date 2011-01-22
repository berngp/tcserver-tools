#!/bin/sh
#-------------------------------------------
# resolve links - $0 may be a softlink
DIR=`dirname "$1"`

echo "Reading the tcsgroup $DIR/env.sh"

export JVM_ROUTE_GROUP="jvmRoute.group"
export CATALINA_HOME="$DIR/../mock-catalinaHome"
#export RUN_AS tomcat
