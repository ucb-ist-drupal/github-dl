#!/usr/bin/env bash
#
# Adapted from https://gist.github.com/maxim/6e15aa45ba010ab030c4
#
# github-dl.sh
# 
# This script downloads an asset from latest or specific Github release of a
# private repo. Feel free to extract more of the variables into command line
# parameters.
#
# PREREQUISITES
#
# curl, wget, jq
#
# Create a token: https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
# and grant "Full control of private repositories" scope.
#
# USAGE
#
# (chmod +x this file)
#
#     github-dl.sh $TOKEN $GITHUB_USER $GITHUB_REPO 1.1.1 $ASSET_FILENAME
#
# to download latest version:
#
#      github-dl.sh $TOKEN $GITHUB_USER $GITHUB_REPO latest $ASSET_FILENAME
#
# If your arguments don't match, the script will exit with error.

TOKEN=$1
REPO="$2/$3"
FILE=$5      # the name of your release asset file, e.g. build.tar.gz
VERSION=$4                       # tag name or the word "latest"
GITHUB="https://api.github.com"

function gh_curl() {
  curl -H "Authorization: token $TOKEN" \
       -H "Accept: application/vnd.github.v3.raw" \
       $@
}

if [ "$VERSION" = "latest" ]; then
  # Github should return the latest release first.
  parser=".[0].assets | map(select(.name == \"$FILE\"))[0].id"
else
  parser=". | map(select(.tag_name == \"$VERSION\"))[0].assets | map(select(.name == \"$FILE\"))[0].id"
fi;

asset_id=`gh_curl -s $GITHUB/repos/$REPO/releases | jq "$parser"`
if [ "$asset_id" = "null" ]; then
  >&2 echo "ERROR: Wrong argument? repo=$REPO, $VERSION, file=$FILE (Also check your token)"
  exit 1
fi;

wget -q --auth-no-challenge --header='Accept:application/octet-stream' \
  https://$TOKEN:@api.github.com/repos/$REPO/releases/assets/$asset_id \
  -O $FILE
