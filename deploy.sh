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

echo 'Getting application credentials...'
aws ssm get-parameter --with-decryption --name=" /$APP_NAME/access-key" --output text --query 'Parameter.Value' > /tmp/creds
lightsail-scp.sh "$LIGHTSAIL_INSTANCE" /tmp/creds " /tmp/$APP_NAME-creds"
rm -rf /tmp/creds

echo 'Deploying application...'
lightsail-ssh.sh "$LIGHTSAIL_INSTANCE" \
"docker stop \$(cat ~/$APP_NAME) &>/dev/null;
docker rm \$(cat ~/$APP_NAME) &>/dev/null;
mv /tmp/$APP_NAME-creds ~/$APP_NAME-access-key;

docker run -d \
    -e APP_NAME=$APP_NAME \
    -e ENV=prod \
    -e TIMEZONE_OFFSET=-6 \
    -e NODE_ENV=production \
    -e AWS_ACCESS_KEY_ID=\$(jq -r .id < ~/$APP_NAME-access-key) \
    -e AWS_SECRET_ACCESS_KEY=\$(jq -r .secret < ~/$APP_NAME-access-key) \
    -e AWS_REGION=us-east-1 \
    $APP_NAME > ~/$APP_NAME;
rm -rf ~/$APP_NAME-access-key;"

rm -rf /tmp/$APP_NAME
echo 'Done.'
