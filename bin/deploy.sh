set -e

REPO_NAME=combinator
APP_NAME=combinator
LIGHTSAIL_INSTANCE=LS1

VERSION=$1
if [[ -z $VERSION ]]; then
    echo "usage: $0 <version>"
    exit 1
fi

git clone git@github.com:tjbrockmeyer/$REPO_NAME /tmp/$APP_NAME
cd /tmp/$APP_NAME
if ! git checkout "tags/$VERSION"; then
    echo "could not check out a tag with the version $VERSION"
    exit 1
fi

echo 'Building image...'
docker build -t $APP_NAME .
echo 'Sending image to lightsail instance...'
docker save $APP_NAME | bzip2 | lightsail-ssh.sh "$LIGHTSAIL_INSTANCE" 'docker load'

echo 'Deploying application...'
lightsail-ssh.sh "$LIGHTSAIL_INSTANCE" \
"docker stop \$(cat ~/$APP_NAME) &>/dev/null;
docker rm \$(cat ~/$APP_NAME) &>/dev/null;
docker run -d $APP_NAME > ~/$APP_NAME;"

rm -rf /tmp/$APP_NAME
echo 'Done.'
