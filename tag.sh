set -e

VERSION=$1
if [[ -z $VERSION ]]; then
    echo "usage: $0 <version>"
    exit 1
fi

if [[ -n "$(git status --porcelain=v1 2>/dev/null)" ]]; then
    echo "there are uncommitted changes - resolve your changes before tagging"
    exit 1
fi

elm make src/Main.elm

git tag -a "$VERSION" -m "Release version $VERSION"
git push --tags

echo "Tag finished!"
