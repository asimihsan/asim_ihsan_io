# asim_ihsan_io

Content for https://asim.ihsan.io website.

## TODO

-   CDK S3 BucketDeployment doesn't support setting `font/otf` content-type for OTF files. Will need a second-pass
    script that takes the bucket name of a stack and finds files like these and sets the right content-type.

## Usage

### First time setup

```
make docker-build
```

### Live rebuilding during blog writing

```
make hugo-draft
```

**Old below**

### First-time CDK setup

```
(cd cdk && cdk bootstrap aws://519160639284/us-west-2)
(cd cdk && cdk bootstrap aws://519160639284/us-east-2)
(cd cdk && cdk bootstrap aws://519160639284/us-east-1)
(cd cdk && cdk bootstrap aws://519160639284/eu-west-2)
(cd cdk && cdk bootstrap aws://519160639284/eu-central-1)
(cd cdk && cdk bootstrap aws://519160639284/sa-east-1)
```

### Build to staging environment with production assets

TODO automate, but for now change directory to root then:

```
rm -rf hugo/build
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://preprod-asim.ihsan.io' hugo --destination build)
fd . -e html hugo/build | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'preprod*')

BLOG_BUCKET_REGION=us-east-2
BLOG_BUCKET_NAME=$(aws --region $BLOG_BUCKET_REGION cloudformation describe-stacks | jq -r '.Stacks | .[] | select(.StackId | contains("preprod-AsimIhsanIoCdkStack")) | .Outputs | .[] | select(.OutputKey == "BlogBucketName") | .OutputValue')
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.html.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="text/html; charset=UTF-8" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.html.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="text/html; charset=UTF-8" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.js.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="application/javascript" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.js.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="application/javascript" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.css.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="text/css" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.css.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="text/css" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.svg.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="image/svg+xml" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.svg.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="image/svg+xml" \
  --metadata-directive REPLACE --recursive

CLOUDFRONT_REGION=us-east-2
CLOUDFRONT_DISTRIBUTION=$(aws --region $CLOUDFRONT_REGION cloudformation describe-stacks | jq -r '.Stacks | .[] | select(.StackId | contains("preprod-AsimIhsanIoCdkStack")) | .Outputs | .[] | select(.OutputKey == "CloudfrontDistribution") | .OutputValue')
aws --region $CLOUDFRONT_REGION cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION" --paths "/*"
```

### Building to production environment

```
rm -rf hugo/build
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://asim.ihsan.io' hugo --destination build)
tee hugo/build/$INDEX_NOW_API_KEY.txt <<EOF >/dev/null
$INDEX_NOW_API_KEY
EOF
fd . -e html hugo/build | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'prod*')

BLOG_BUCKET_REGION=us-east-2
#BLOG_BUCKET_NAME=$(aws --region $BLOG_BUCKET_REGION cloudformation describe-stacks | jq -r '.Stacks | .[] | select(.StackId | contains("prod-AsimIhsanIoCdkStack")) | .Outputs | .[] | select(.OutputKey == "BlogBucketName") | .OutputValue')
BLOG_BUCKET_NAME=prod-asimihsaniocdkstackkstackblogbucketff0f1834c90cbe8c0085
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.html.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="text/html; charset=UTF-8" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.html.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="text/html; charset=UTF-8" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.js.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="application/javascript" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.js.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="application/javascript" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.css.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="text/css" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.css.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="text/css" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.svg.br" \
  --acl 'public-read' \
  --content-encoding br \
  --content-type="image/svg+xml" \
  --metadata-directive REPLACE --recursive
aws --region $BLOG_BUCKET_REGION s3 cp hugo/build "s3://${BLOG_BUCKET_NAME}" \
  --exclude="*" --include="*.svg.gz" \
  --acl 'public-read' \
  --content-encoding gz \
  --content-type="image/svg+xml" \
  --metadata-directive REPLACE --recursive

CLOUDFRONT_REGION=us-east-2
CLOUDFRONT_DISTRIBUTION=$(aws --region $CLOUDFRONT_REGION cloudformation describe-stacks | jq -r '.Stacks | .[] | select(.StackId | contains("prod-AsimIhsanIoCdkStack")) | .Outputs | .[] | select(.OutputKey == "CloudfrontDistribution") | .OutputValue')
aws --region $CLOUDFRONT_REGION cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION" --paths "/*"
./src/index_now.py
```

### Live rebuilding during blog writing

```
IFS='' read -r -d '' PROGRAM <<"EOF"
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
print(s.getsockname()[0])
s.close()
EOF
IP_ADDRESS=$(python -c "${PROGRAM}")

rm -rf hugo/build
(cd hugo && hugo --buildDrafts --destination build --watch server --disableFastRender --bind 0.0.0.0 --baseURL "http://${IP_ADDRESS}" --enableGitInfo --port 5000)
```

### Live watching readability stats

Prerequisites

```
brew install fswatch
```

Then:

```
fswatch hugo/content | xargs -n1 -I{} bash -c '(cd hugo && hugo --buildDrafts --destination build-readability) && ./src/analyze_post.py ./hugo/build/healthy-breathing-with-a-smart-bulb/index.json'
```

## Setup

-   Install and setup nvm: https://github.com/nvm-sh/nvm
-   Install the latest LTS version of node and npm:

```
cd hugo/themes/anake/src
nvm use
nvm install-latest-npm
```

-  Set up node dependencies

```
cd hugo/themse/ananke/src
npm install
```

-   Build for debug

```
cd hugo/themse/ananke/src
npm start
```

-   Build for production

```
cd hugo/themse/ananke/src
npm run build:production
```

## How to build Iosevka font

```
git clone https://github.com/be5invis/Iosevka.git --branch v11.2.6 --single-branch
cd Iosevka
tee private-build-plans.toml <<EOF >/dev/null EOF
[buildPlans.iosevka-custom]
family = "Iosevka Custom"
spacing = "normal"
#spacing = "quasi-proportional"
serifs = "sans"
no-cv-ss = true
no-ligation = true

[buildPlans.iosevka-custom.weights.regular]
shape = 400
menu = 400
css = 400

[buildPlans.iosevka-custom.weights.bold]
shape = 700
menu = 700
css = 700

[buildPlans.iosevka-custom.slopes.upright]
angle = 0
shape = "upright"
menu = "upright"
css = "normal"

[buildPlans.iosevka-custom.slopes.italic]
angle = 9.4
shape = "italic"
menu = "italic"
css = "italic"
EOF
brew install ttfautohint
npm install
npm run build -- contents::iosevka-custom
```

Now follow https://markoskon.com/creating-font-subsets/ to subset:

```
destination=/Users/asimi/asim_ihsan_io/hugo/static/font
pyenv local asim_ihsan_io
unicode_range="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,\
    U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,\
    U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"
declare -a arr
arr=(
    "ttf/iosevka-custom-regular.ttf"
    "ttf/iosevka-custom-bold.ttf"
    "ttf/iosevka-custom-italic.ttf"
    "ttf/iosevka-custom-bolditalic.ttf"
)
for val in "${arr[@]}"; do
    dir_name="$(dirname "${val}")"
    new_name="${dir_name}"/"$(basename "${val}" | cut -f 1 -d '.')"-subset."${dir_name}"
    echo "new name: ${new_name}"
    pyftsubset \
    dist/iosevka-custom/"${val}" \
    --output-file=dist/iosevka-custom/"${new_name}" \
    --layout-features='*' \
    --unicodes="${unicode_range}"
    rsync -av dist/iosevka-custom/"${new_name}" "${destination}"
done
declare -a arr
arr=(
    "woff2/iosevka-custom-regular.woff2"
    "woff2/iosevka-custom-bold.woff2"
    "woff2/iosevka-custom-italic.woff2"
    "woff2/iosevka-custom-bolditalic.woff2"
)
for val in "${arr[@]}"; do
    dir_name="$(dirname "${val}")"
    new_name="${dir_name}"/"$(basename "${val}" | cut -f 1 -d '.')"-subset."${dir_name}"
    echo "new name: ${new_name}"
    pyftsubset \
    dist/iosevka-custom/"${val}" \
    --output-file=dist/iosevka-custom/"${new_name}" \
    --flavor="${dir_name}" \
    --layout-features='*' \
    --unicodes="${unicode_range}"
    rsync -av dist/iosevka-custom/"${new_name}" "${destination}"
done
```

Same for Fira Sans Condensed:

```
destination=/Users/asimi/asim_ihsan_io/hugo/static/font
pyenv local asim_ihsan_io
unicode_range="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,\
    U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,\
    U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"
cd /Users/asimi/Downloads/firasans/inst/fonts/fira-sans
declare -a arr
arr=(
    "FiraSansCondensed-Bold.ttf"
    "FiraSansCondensed-BoldItalic.ttf"
    "FiraSansCondensed-Italic.ttf"
    "FiraSansCondensed-Regular.ttf"
)
for val in "${arr[@]}"; do
    new_name="$(basename "${val}" | cut -f 1 -d '.')"-subset.ttf
    echo "new name: ${new_name}"
    pyftsubset \
    "${val}" \
    --output-file="${new_name}" \
    --layout-features='*' \
    --unicodes="${unicode_range}"
    rsync -av "${new_name}" "${destination}"
done
for val in "${arr[@]}"; do
    new_name="$(basename "${val}" | cut -f 1 -d '.')"-subset.woff2
    echo "new name: ${new_name}"
    pyftsubset \
    "${val}" \
    --output-file="${new_name}" \
    --flavor=woff2 \
    --layout-features='*' \
    --unicodes="${unicode_range}"
    rsync -av "${new_name}" "${destination}"
done
```

## How to subset and generate web-optimized fonts

https://github.com/ambroisemaupate/webfont-generator

## How to analyze CloudFront access logs

Prerequisites:

```
brew update && brew install rclone goaccess awscli jq
```

Set up rclone:

```
rclone config

n) New remote
name> prod-blog-cf-logs
4) s3

S3 provider: 1 "aws"
2) Get AWS credentials from the environment, "true"

Leave creds blank

Region: us-east-2

Default endpoint

No constraint

Everything else default
```

rclone config file:

```
➜  Downloads cat /Users/asimi/.config/rclone/rclone.conf
[prod-blog-cf-logs]
type = s3
provider = AWS
env_auth = true
region = us-east-2
```

Here is how to list buckets using rclone:

```
rclone lsd prod-blog-cf-logs:
```

Now let's mount our bucket somewhere:

```
AWS_REGION=us-east-2
STACK_NAME=prod-AsimIhsanIoCdkStack
CLOUDFRONT_BUCKET=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" | jq --raw-output '.["Stacks"][0]["Outputs"][] | select(.OutputKey == "CloudFrontAccessLogsBucketName") | .OutputValue')

DESTINATION=$HOME/Downloads/prod-blog-cf-logs
mkdir -p "${DESTINATION}"

# CTRL-C will stop the mount
umount "${DESTINATION}"; rclone mount prod-blog-cf-logs:"${CLOUDFRONT_BUCKET}" "${DESTINATION}" --read-only --no-modtime

# umount "${DESTINATION}"; rclone mount prod-blog-cf-logs:"${CLOUDFRONT_BUCKET}" "${DESTINATION}" --dir-cache-time 1m0s --max-read-ahead 128m --read-only --no-modtime
```

Now run goaccess:

```
DESTINATION=$HOME/Downloads/prod-blog-cf-logs
REPORT_OUTPUT=$HOME/Downloads/report.html
BROWSERS_LIST=$HOME/Downloads/browsers-list
TAB="$(printf '\t')"

cat > "${BROWSERS_LIST}" <<EOF
Pinger v0.1${TAB}Crawler
EOF

rm -f "${REPORT_OUTPUT}"
gzip -cd "${DESTINATION}"/*.gz | grep -v 'Pinger%20v0.1' | goaccess --log-format CLOUDFRONT --num-test=0 -o "${REPORT_OUTPUT}" --browsers-file "${BROWSERS_LIST}" --ignore-crawlers --agent-list --real-os --ignore-statics=panel

cd $(dirname "${REPORT_OUTPUT}")
python -m http.server 8080
```

Here is how to get the preprod bucket name then delete all access logs:

```
AWS_REGION=us-east-2
STACK_NAME=preprod-AsimIhsanIoCdkStack
CLOUDFRONT_BUCKET=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" | jq --raw-output '.["Stacks"][0]["Outputs"][] | select(.OutputKey == "CloudFrontAccessLogsBucketName") | .OutputValue')
rclone delete prod-blog-cf-logs:"${CLOUDFRONT_BUCKET}" --dry-run
rclone delete prod-blog-cf-logs:"${CLOUDFRONT_BUCKET}"
```

## Setting up reCAPTCHA v3 -> v2 fallback

-   https://www.google.com/u/2/recaptcha/admin/create
-   Sign up for v3 and v2, put their values into the following environment variables

```
export ASIM_IHSAN_IO_RECAPTCHA_V3_SITE_KEY=""
export ASIM_IHSAN_IO_RECAPTCHA_V3_SECRET_KEY=""

export ASIM_IHSAN_IO_RECAPTCHA_V2_SITE_KEY=""
export ASIM_IHSAN_IO_RECAPTCHA_V2_SECRET_KEY=""
```
