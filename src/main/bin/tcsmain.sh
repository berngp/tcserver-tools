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
# Wrapps any call to the catalina.sh script specified by the CATALINA_HOME variable but
#
# Environment Variable Prequisites
#
#   CATALINA_HOME   May point at your Catalina "build" directory.
#
#   CATALINA_BASE   (Optional) Base directory for resolving dynamic portions
#                   of a Catalina installation.  If not present, resolves to
#                   the same directory that CATALINA_HOME points to.
#
#   CATALINA_OUT    (Optional) Full path to a file where stdout and stderr
#                   will be redirected.
#                   Default is $CATALINA_BASE/logs/catalina.out
#
#   CATALINA_OPTS   (Optional) Java runtime options used when the "start",
#                   or "run" command is executed.
#
#   CATALINA_TMPDIR (Optional) Directory path location of temporary directory
#                   the JVM should use (java.io.tmpdir).  Defaults to
#                   $CATALINA_BASE/temp.
#
#   JAVA_OPTS       (Optional) Java runtime options used when the "start",
#                   "stop", or "run" command is executed.
#
#   CATALINA_PID    (Optional) Path of the file which should contains the pid
#                   of catalina startup java process, when start (fork) is used
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

# Tomcat's Bugzilla 37848: When no TTY is available, don't output to console
have_tty=0
if [ "`tty`" != "not a tty" ]; then
    have_tty=1
fi

# Get standard environment variables
PRGDIR=`dirname "$PRG"`
# Only set CATALINA_INSTANCE if not already set
if [ -z "$CATALINA_INSTANCE" ] ; then
	if [ -d "$1" ] ; then 
	 	export CATALINA_INSTANCE=`cd "$1" > /dev/null; pwd`
		shift
	else
		export CATALINA_INSTANCE=`cd "$PRGDIR/.." >/dev/null; pwd`
	fi
fi

if [ -z "$CATALINA_BASE" ] ; then
  export CATALINA_BASE="$CATALINA_INSTANCE"
fi

#Setup the ENV through tcsenv.sh
TCS_ENV_EXECUTABLE="$PRGDIR/tcsenv.sh"
test ! -x "$TCS_ENV_EXECUTABLE" && (echo "Unable to find tcsenv.sh"; exit 1)
. "$TCS_ENV_EXECUTABLE"

#------------------------------------------------------------------
# When setting cygwin support add the changes of the paths bellow..
#   |
#  ---
# -----
#------------------------------------------------------------------


EXECUTABLE="$CATALINA_HOME/bin/catalina.sh"
# Check that target executable exists
if [ ! -x "$EXECUTABLE" ]; then
  echo "Cannot find $EXECUTABLE or is not executable"
  echo "This file is needed to run this program"
  exit 1
fi


# ----- Execute The Requested Command -----------------------------------------
# Bugzilla 37848: only output this if we have a TTY
if [ $have_tty -eq 1 ]; then
	echo "CATALINA INSTANCE MANAGER...."
	echo "Using CATALINA_INSTANCE:  $CATALINA_INSTANCE"
	echo "Using CATALINA_BASE:      $CATALINA_BASE"
	#echo "Using CATALINA_HOME:   	$CATALINA_HOME"
	#echo "Using CATALINA_TMPDIR: 	$CATALINA_TMPDIR"
	echo "Using CATALINA_OPTS:      $CATALINA_OPTS"
	echo "Using JAVA_OPTS:          $JAVA_OPTS"
	echo ""
	#if [ "$1" = "debug" ] ; then
	#   echo "Using JAVA_HOME:       $JAVA_HOME"
	#   echo "Using JRE_HOME:        $JRE_HOME"
	#fi
	test -n "$CLASSPATH"		 && (echo "Using CLASSPATH:		$CLASSPATH")
	if [ ! -z "$CATALINA_PID" ]; then
	    echo "Using CATALINA_PID:    $CATALINA_PID"
	fi
fi

cmd="$EXECUTABLE $@"

echo $cmd 
eval $cmd 
exit $?
