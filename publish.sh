set -e

# ./build-book.sh
git push
jekyll build
s3_website push