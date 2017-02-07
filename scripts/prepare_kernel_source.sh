#! /usr/bin/env bash

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <working dir>"
    exit 1
fi

# Prepare kernel source
WORKING_DIR=$1
WORKING_DIR=${WORKING_DIR%%/}

mkdir -p $WORKING_DIR
cd $WORKING_DIR
if [ -d $WORKING_DIR/linux -a -d $WORKING_DIR/linux/.git ] ; then
    cd $WORKING_DIR/linux
    git pull
else
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux-2.6.git linux
fi

# Get version list
cd $WORKING_DIR/linux
# Solve warning for git log v2.6.26..v2.6.27
# 'warning: inexact rename detection was skipped due to too many files'
git config diff.renameLimit 1000
TAGS=`git tag | grep -E '^v[0-9]*\.[0-9]*(\.[0-9]*)?$' | sort -t. -k1.2,1n -k2,2n -k3,3n`
VERSION_COUNT=0
VERSIONS=''
for i in $TAGS ; do
    VERSIONS=$VERSIONS" "$i
    VERSION_COUNT=`expr $VERSION_COUNT + 1`
done
# echo $VERSIONS
# echo $VERSION_COUNT

# Generate ChangeLogs
mkdir -p $WORKING_DIR/ChangeLogs
LOOP=""
PRE=""
COUNT=0
for LOOP in $VERSIONS
do
    COUNT=`expr $COUNT + 1`
	if [ "$PRE" = "" ]
	then
		PRE=$LOOP
		continue
	fi
	echo "Creating ChangeLog-$LOOP"
	if [ $COUNT -lt `expr $VERSION_COUNT` -a -e $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP ] ; then
	    echo "Skip: $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP"
	else
	    git log -M --date=short --pretty=format:"Author: %aN <%ae>; Date: %ad" --shortstat --dirstat --no-merges $PRE..$LOOP > $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP
	fi
	echo "Creating ChangeLog-$LOOP-other"
	if [ $COUNT -lt `expr $VERSION_COUNT` -a -e $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP-other ] ; then
	    echo "Skip: $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP-other"
	else
	    git log $PRE..$LOOP --date=short --pretty=format:"%ad%n%b"  --no-merges > $WORKING_DIR/ChangeLogs/ChangeLog-$LOOP-other
	fi
	PRE=$LOOP
done
#echo $LOOP

echo "Creating ChangeLog-HEAD"
git log -M --date=short --pretty=format:"Author: %aN <%ae>; Date: %ad" --shortstat --dirstat --no-merges $LOOP.. > $WORKING_DIR/ChangeLogs/ChangeLog-HEAD
echo "Creating ChangeLog-HEAD-other"
git log $LOOP.. --date=short --pretty=format:"%ad%n%b"  --no-merges > $WORKING_DIR/ChangeLogs/ChangeLog-HEAD-other

