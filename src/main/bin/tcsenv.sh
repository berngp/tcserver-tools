#!/bin/sh

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------------------
#  Loads a an env.sh file that can override system variables, 
#  It will look for them in 
#   1) $CATALINA_BASE/bin/env.sh
#   2) $CATALINA_INSTANCE_HOME/bin/env.sh
#   3) $PRGDIR/env.sh where PGRDIR is the home dir of this shell
# -----------------------------------------------------------------------------
echo "tcsenv.sh running...."
# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

# Only set CATALINA_INSTANCE_HOME if not already set
if   [ -x "$CATALINA_BASE/bin/env.sh" ] ; then
	TCS_TOOLS_ENV_SH="$CATALINA_BASE/bin/env.sh"
elif [ -f "$CATALINA_INSTANCE_HOME/bin/env.sh" ] ; then
	TCS_TOOLS_ENV_SH="$CATALINA_INSTANCE_HOME/bin/env.sh"
else 
	TCS_TOOLS_ENV_SH="$PRGDIR/env.sh"
fi

if [ -x "$TCS_TOOLS_ENV_SH" ]; then
	. "$TCS_TOOLS_ENV_SH"
else
	echo "Info: No env.sh found or can't execute."
fi


if [ -z "$CATALINA_HOME" ] ; then
  export CATALINA_HOME="$CATALINA_BASE"
fi

if [ -z "$CATALINA_OUT" ] ; then
  export CATALINA_OUT="$CATALINA_INSTANCE_HOME"/logs/catalina.out
fi

if [ -z "$CATALINA_TMPDIR" ] ; then
  # Define the java.io.tmpdir to use for Catalina
  export CATALINA_TMPDIR="$CATALINA_INSTANCE_HOME"/temp
fi
#Setup the catalina.instance name for the JVM OPTS
export CATALINA_INSTANCE=`echo "$CATALINA_INSTANCE_HOME" | sed 's/.*\/\(.*\)$/\1/'`

JAVA_OPTS="-Dcatalina.instance=$CATALINA_INSTANCE $JAVA_OPTS "
#Extract information from the tcs-instance conf. properties file.
if [ -r "$CATALINA_INSTANCE_HOME/tcsi.properties" ]; then
	if [ $1 = 'stop'   ] ; then
		_OPTS=`grep -v '^[\s*#]' $CATALINA_INSTANCE_HOME/tcsi.properties | grep -v '.jmxremote.' | awk '{printf "-D%s ", $1}'` 
	else
		_OPTS=`grep -v '^[\s*#]' $CATALINA_INSTANCE_HOME/tcsi.properties | awk '{printf "-D%s ", $1}'` 
	fi
	JAVA_OPTS="$JAVA_OPTS $_OPTS"
	#---------------------------
	JVM_ROUTE=`grep -e '^[\s*jvmRoute\s*=]' $CATALINA_INSTANCE_HOME/tcsi.properties | sed 's/\s*jvmRoute\s*=\s*//g'` 
	if [ -z "$JVM_ROUTE" ]; then
		if [ -z "$JVM_ROUTE_GROUP" ]; then
			JVM_ROUTE_GROUP="`( cd $CATALINA_GROUP ; pwd ) | sed 's/\//\./g' | sed 's/\.\(.*\)$/\1/'`"
		fi
		JAVA_OPTS="-DjvmRoute=`hostname`.$JVM_ROUTE_GROUP.$CATALINA_INSTANCE $JAVA_OPTS"
	fi
	export JAVA_OPTS
fi

#Override PID
export CATALINA_PID="$CATALINA_INSTANCE_HOME/pid"



