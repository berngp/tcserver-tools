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
# Get standard environment variables
PRGDIR=`dirname "$PRG"`
# See if we have debug flag
if [ "$1" = "-v" ]; then
	vf=1
	shift
fi

# Get CATALINA_GROUP
if [ ! -d "$1" ]; then
	echo "Argument $1 must be a directory that points to the TC Group path."
	exit 1
else
	export CATALINA_GROUP=`cd "$1" > /dev/null; pwd`
fi

# Load Group's Env if available 
if   [ -f "$CATALINA_GROUP/env.sh" ] ; then
	TCS_GROUP_ENV_SH="$CATALINA_GROUP/env.sh"
	. "$TCS_GROUP_ENV_SH"
else 
	echo "Info: No env.sh found or can't execute."
fi

# Fetch group's tc base
if   [ -z "$CATALINA_BASE" ] ; then
	_CBASE=`ls -d * | grep -e '\.*\(-base\)$'`
	export CATALINA_BASE="$CATALINA_GROUP/$_CBASE"
else 
	echo "Info: No env.sh found or can't execute."
fi

# Fetch group's tc instances
if   [ ! $CATALINA_GROUPS ] ; then
	_CGROUPS=`ls -d * | grep -e '\.*\([[:digit:]+]\|-inst\|-instance\)$'`
	CATALINA_GROUPS=$( echo $_CGROUPS | tr " " "\n" )
else 
	echo "Info: No env.sh found or can't execute."
fi

TCSMAIN_SH="$PRGDIR/tcsmain.sh"
# Check that target executable exists
if [ ! -x "$TCSMAIN_SH" ]; then
  echo "Cannot find $TCSMAIN_SH is not executable"
  echo "This file is needed to run this program"
  exit 1
fi

# ----- Execute The Requested Command -----------------------------------------
applyToGroup() {
	for instance in $CATALINA_GROUPS
	do
		echo ""
		echo "------------------------------------------------"
		echo "`date -R`"
		echo "$instance $1 ..."
		cmd="$TCSMAIN_SH $CATALINA_GROUP/$instance $1 $2"
		echo "> [$cmd]"
		eval $cmd
		echo "$instance $1 done." 
		echo "------------------------------------------------"
		echo "" 
	done
}

removeInGroup() {
	for instance in $CATALINA_GROUPS
	do
		if [ -f "$CATALINA_GROUP/$instance/$1" ]; then
			echo ""
			echo "rm $instance/$1 ..."
			eval \"rm\" \"$CATALINA_GROUP/$instance/$1\" 
			echo "$instance $1 done." 
			echo ""
		fi
	done
}

statusOfGroup() {
	for instance in $CATALINA_GROUPS
	do
		if [ -f "$CATALINA_GROUP/$instance/pid" ]; then
			_pid=`cat $CATALINA_GROUP/$instance/pid`
			echo ""
			echo "status of $instance ..."
			#eval \"ps\" \"uwww\" \"-p $_pid\"
			eval ps uwww -p $_pid
			echo ""
		fi
	done
}

pidStasOnGroup() {
	for instance in $CATALINA_GROUPS
	do
		if [ -f "$CATALINA_GROUP/$instance/pid" ]; then
			_pid=`cat $CATALINA_GROUP/$instance/pid`
			upsince=`ps -p $_pid | grep -v "TIME" | awk '{print $3}'`
			if [ "$upsince" != "" ]; then
				echo "$instance up $upsince"
			else
				echo "$instance down but pid file left."
			fi
		else
			echo "$instance down"
		fi
	done
}
# ----- Execute The Requested Command -----------------------------------------
if	[ "$2" = "debug" ] ; then
	shift 2
	applyToGroup debug $@	

elif 	[ "$2" = "run" ]; then
	shift 2
	applyToGroup run $@	

elif 	[ "$2" = "start" ] ; then
	shift 2
	applyToGroup start $@	

elif 	[ "$2" = "stop" ] ; then
	echo "$@"
	shift 2
	applyToGroup stop $@	

elif 	[ "$2" = "version" ] ; then
	shift 2
	applyToGroup version $@	

elif 	[ "$2" = "status" ] ; then
	shift 2
	statusOfGroup

elif 	[ "$2" = "up" ] ; then
	shift 2
	pidStasOnGroup 

elif 	[ "$2" = "cleanstop" ] ; then
	shift 2
	applyToGroup stop "-force $@"
	removeInGroup pid 
else
	echo "Usage: tcsgroup /path/to/group/base ( commands ... )"
	echo "commands:"
	echo "  run               Start Catalina in the current window"
	echo "  run -security     Start in the current window with security manager"
	echo "  start             Start Catalina in a separate window"
	echo "  start -security   Start in a separate window with security manager"
	echo "  stop              Stop Catalina, waiting up to 5 seconds for the process to end"
	echo "  stop n            Stop Catalina, waiting up to n seconds for the process to end"
	echo "  stop -force       Stop Catalina, wait up to 5 seconds and then use kill -KILL if still running"
	echo "  stop n -force     Stop Catalina, wait up to n seconds and then use kill -KILL if still running"
	echo "  version           What version of tomcat are you running?"
	echo "  status            Status of all instances of the group."
	echo "  up                PID up status on all instances of the group."
	echo "  cleanstop         Stops instances and removes pid files."
	exit 1

fi
