#!/bin/bash -e
#
# Downloads and unpacks the app from a private repo in github
#
# $GITHUB_USER  -- Github user to login with
# $GITHUB_TOKEN -- github token
# $DEPLOY_DIR	-- dir to deploy into
# $GITHUB_URL   -- url containing tarball and branch
# $APP_NAME     -- name of the app, will be the dir name in deploy_dir
#
#
# Test for a reboot,  if this is a reboot just skip this script.
#
# Packages 	git-core
# ßInputs	APP_NAME, CLEAN, DEPLOY_DIR, GITHUB_TOKEN, GITHUB_URL, GITHUB_USER

if test "$RS_REBOOT" = "true" ; then
  echo "Skip code install on reboot."
  logger -t RightScale "Skip code install on reboot."
  exit 0 # Leave with a smile ...
fi


if [ -z "$GITHUB_URL" ]; then 
  echo "github url not defined..."
  echo "skipping the retrieval of the application"
  exit -1
fi

## Find out about the old deploy directory
if [ -e $DEPLOY_DIR/$APP_NAME ]; then
  if test "$CLEAN" = "YES" ; then
    echo "Removing existing deploy directory..."
    rm -rf $DEPLOY_DIR/$APP_NAME
  fi
fi

## Create deploy dir
echo "Creating deploy directory..."
mkdir -p $DEPLOY_DIR/$APP_NAME

## Retrieve the code from github and unpack it
echo "Downloading..."
#echo "wget --post-data=\"login=$GITHUB_USER&token=$GITHUB_TOKEN\" --no-check-certificate -O /tmp/$APP_NAME.tar.gz $GITHUB_URL"
#wget --post-data="login=$GITHUB_USER&token=$GITHUB_TOKEN" --no-check-certificate -O /tmp/$APP_NAME.tar.gz $GITHUB_URL
curl -u "$GITHUB_USER:$GITHUB_TOKEN" $GITHUB_URL -L -o /tmp/$APP_NAME.tar.gz --insecure

## Prepare dir
echo "Prepare to deploy..."
chmod 775 $DEPLOY_DIR

## Unpacking...
echo "Unpacking web application..."
echo "Extracting $APP_NAME in $DEPLOY_DIR..."
tar -xvzf /tmp/$APP_NAME.tar.gz -C $DEPLOY_DIR/$APP_NAME --strip 1
if [ ! $? ]; then
  echo "Failed to extract sources."
  exit -1
fi

## post download hook
if [ -e $DEPLOY_DIR/$APP_NAME/deploy/post.sh ] ; then
  cd $DEPLOY_DIR/$APP_NAME
  chmod +x deploy/post.sh
  deploy/post.sh $DEPLOY_DIR/$APP_NAME
  if [ ! $? ]; then
    echo "Failed in post download hook."
    exit -1
  fi
fi

exit 0