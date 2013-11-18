set -e

# ./build-book.sh
jekyll build
s3_website push