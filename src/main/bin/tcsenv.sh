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
#   2) $CATALINA_INSTANCE/bin/env.sh
#   3) $PRGDIR/env.sh where PGRDIR is the home dir of this shell
# -----------------------------------------------------------------------------

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

# Only set CATALINA_INSTANCE if not already set
if   [ -x "$CATALINA_BASE/bin/env.sh" ] ; then
	TCS_TOOLS_ENV_SH="$CATALINA_BASE/bin/env.sh"
elif [ -f "$CATALINA_INSTANCE/bin/env.sh" ] ; then
	TCS_TOOLS_ENV_SH="$CATALINA_INSTANCE/bin/env.sh"
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
  export CATALINA_OUT="$CATALINA_INSTANCE"/logs/catalina.out
fi

if [ -z "$CATALINA_TMPDIR" ] ; then
  # Define the java.io.tmpdir to use for Catalina
  export CATALINA_TMPDIR="$CATALINA_INSTANCE"/temp
fi

#Extract information from the tcs-instance conf. properties file.
if [ -r "$CATALINA_INSTANCE/tcsi.properties" ]; then
	_OPTS=`grep -v '^[\s*#]' $CATALINA_INSTANCE/tcsi.properties | awk '{printf "-D%s ", $1}'` 
	JAVA_OPTS="$JAVA_OPTS $_OPTS"
	#---------------------------
	JVM_ROUTE=`grep -e '^[\s*jvmRoute\s*=]' $CATALINA_INSTANCE/tcsi.properties | sed 's/\s*jvmRoute\s*=\s*//g'` 
	if [ -z "$JVM_ROUTE" ]; then
		JVM_ROUTE=`echo "$CATALINA_INSTANCE" | sed 's/.*\/\(.*\)$/\1/'`
		JAVA_OPTS="-DjvmRoute=$JVM_ROUTE $JAVA_OPTS"
	fi
	export JAVA_OPTS
fi

#Override PID
export CATALINA_PID="$CATALINA_INSTANCE/pid"



