#!/bin/sh

if [ $# != 1 ]; then 
  echo "Usage $0 <tag-name>"
  exit -1
fi

git tag $1
git push origin $1
commit_hash=$(git rev-parse --short HEAD)

docker-buildx build --build-arg VERSION=$1 --build-arg GIT_COMMIT=$commit_hash --platform linux/arm64 -t registry.gitlab.com/dracks/swift-language-study:$1 .
docker push registry.gitlab.com/dracks/swift-language-study:$1
