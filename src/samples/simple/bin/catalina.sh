#!/bin/sh
echo ""
echo "In catalina.sh $@"
echo "Using CATALINA_INSTANCE:	$CATALINA_INSTANCE"
echo "Using CATALINA_BASE:   	$CATALINA_BASE"
echo "Using CATALINA_HOME:   	$CATALINA_HOME"
echo "Using CATALINA_OPTS:   	$CATALINA_OPTS"
echo "Using CATALINA_PID:   	$CATALINA_PID"
echo "Using JAVA_OPTS:   	$JAVA_OPTS"

echo "Testing for TEST_ENV_VAR [$TEST_ENV_VAR]..."

test -z "$TEST_ENV_VAR" && (echo "Unable to find expected variable TEST_ENV_VAR $TEST_ENV_VAR"; exit 1)

echo "If you read this we are all good :)"

