set -e

REPO_NAME=combinator
APP_NAME=combinator
LIGHTSAIL_INSTANCE=LS1
PORT=8081

VERSION=$1
if [[ -z $VERSION ]]; then
    echo "usage: $0 <version>"
    exit 1
fi

set +e; rm -rf /tmp/$APP_NAME; set -e
git clone git@github.com:tjbrockmeyer/$REPO_NAME /tmp/$APP_NAME
cd /tmp/$APP_NAME
if ! git checkout "tags/$VERSION"; then
    echo "could not check out a tag with the version $VERSION"
    exit 1
fi

echo 'Building image...'
./bin/build.sh
echo 'Sending image to lightsail instance...'
docker save $APP_NAME | bzip2 | lightsail-ssh.sh "$LIGHTSAIL_INSTANCE" 'docker load'

echo 'Deploying application...'
lightsail-ssh.sh "$LIGHTSAIL_INSTANCE" \
"docker stop $APP_NAME &>/dev/null;
docker run -dit -p $PORT:80 --rm --name $APP_NAME $APP_NAME;"

rm -rf /tmp/$APP_NAME
echo 'Done.'
