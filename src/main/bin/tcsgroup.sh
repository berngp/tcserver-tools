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
	echo "Usage: tcsgroup /path/to/group (commands ... )"
	exit 1
else
	export CATALINA_GROUP=`cd "$1" > /dev/null; pwd`
	shift
fi
#Seeing if the command shoulb be applied to a single instance.
if [ "$1" = "-i" ]; then
	if [ -z "$2"  -o  ! -d "$CATALINA_GROUP/$2"  ]; then
		echo "The -i (instance) option should be followed by the instance name "
		echo "and such name should make reference to a directory in the TC Group path."
		echo "Usage: tcsgroup /path/to/group/base -i yourInstanceName ( commands ... )"
		echo 
		exit 1
	else
		INSTANCE="$2"
		shift 2
	fi
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
applyTo() {
	echo ""
	echo "------------------------------------------------"
	echo "`date -R`"
	echo "$1 $2 ..."
	cmd="$TCSMAIN_SH $CATALINA_GROUP/$1 $2 $3"
	echo "> [$cmd]"
	eval $cmd
	echo "$1 $2 done." 
	echo "------------------------------------------------"
	echo "" 
}

removeIn() {
	if [ -f "$CATALINA_GROUP/$1/$2" ]; then
		echo ""
		echo "rm $1/$2 ..."
		eval \"rm\" \"$CATALINA_GROUP/$1/$2\" 
		echo "$1 $2 done." 
		echo ""
	fi
}

statusOf() {
	if [ -f "$CATALINA_GROUP/$1/pid" ]; then
		_pid=`cat $CATALINA_GROUP/$1/pid`
		echo ""
		echo "status of $1..."
		#eval \"ps\" \"uwww\" \"-p $_pid\"
		eval ps uwww -p $_pid
		echo ""
	fi
}

pidStatsOn() {
	if [ -f "$CATALINA_GROUP/$1/pid" ]; then
		_pid=`cat $CATALINA_GROUP/$1/pid`
		upsince=`ps -p $_pid | grep -v "TIME" | awk '{print $3}'`
		if [ "$upsince" != "" ]; then
			echo "$1 up $upsince"
		else
			echo "$1 down but pid file left."
		fi
	else
		echo "$1 down"
	fi
}

applyCmd() {
	_f="$1"
	_iinstance="$2"
	shift 2
	if [ -n "$_iinstance" ]; then
		eval \"$_f\" \"$_iinstance\" \"$@\"
	else
	for instance in $CATALINA_GROUPS
	do
			eval \"$_f\" \"$instance\" \"$@\"
	done
	fi
}
# ----- Execute The Requested Command -----------------------------------------
if	[ "$1" = "debug" ] ; then
	shift 
	applyCmd "applyTo" "$INSTANCE" "debug $@"	

elif 	[ "$1" = "run" ]; then
	shift 
	applyCmd "applyTo" "$INSTANCE" "run $@"	

elif 	[ "$1" = "start" ] ; then
	shift 
	applyCmd "applyTo" "$INSTANCE" "start $@"	

elif 	[ "$1" = "stop" ] ; then
	shift 
	export JAVA_OPTS=""
	applyCmd "applyTo" "$INSTANCE" "stop $@"	

elif 	[ "$1" = "version" ] ; then
	shift 
	applyCmd "applyTo" "$INSTANCE" "version $@"	

elif 	[ "$1" = "status" ] ; then
	shift 
	applyCmd "statusOf" "$INSTANCE"  

elif 	[ "$1" = "up" ] ; then
	shift 
	applyCmd "pidStatsOn" "$INSTANCE"  

elif 	[ "$1" = "cleanstop" ] ; then
	shift 
	export JAVA_OPTS=""
	applyCmd "applyTo" "$INSTANCE" "stop -force $@"
	applyCmd "removeIn" "$INSTANCE" "pid" 
else
	echo "Usage: tcsgroup /path/to/group/base ( commands ... )"
	echo "options:"
	echo "  -i instanceName   Apply the command to only the given instance."
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
