#!/bin/sh
echo "In env.sh"
echo "Setting a variable in env.sh to test if catalina.sh sees it.."
echo ""
export TEST_ENV_VAR="Foobar"
echo "TEST_ENV_VAR $TEST_ENV_VAR"
