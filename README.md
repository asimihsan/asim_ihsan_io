# asim_ihsan_io
Content for https://asim.ihsan.io website.

## TODO

-   CDK S3 BucketDeployment doesn't support setting `font/otf` content-type for OTF files. Will need a second-pass
    script that takes the bucket name of a stack and finds files like these and sets the right content-type.

## Usage

### First time setup

Install pyenv, then

```
pyenv install miniconda3-latest
pyenv virtualenv miniconda3-latest asim_ihsan_io
pip install -r requirements.txt
```

Also need critical for above-fold CSS inlining, and need moreutils for sponge:

```
brew install moreutils
npm install -g critical
```

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
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://preprod-asim.ihsan.io' hugo --buildDrafts --destination build)
find hugo/build -name '*.html' | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'preprod*')
```

### Building to production environment

```
rm -rf hugo/build
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://asim.ihsan.io' hugo --buildDrafts --destination build)
find hugo/build -name '*.html' | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'prod*')
```

#### Deploy both pre-prod and prod

```
rm -rf hugo/build
(cd hugo && HUGO_BASEURL='https://preprod-asim.ihsan.io' hugo --buildDrafts --destination build)
find hugo/build -name '*.html' | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'preprod*')

rm -rf hugo/build
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://asim.ihsan.io' hugo --buildDrafts --destination build)
find hugo/build -name '*.html' | xargs -P 4 -I{} bash -c 'echo {} && cat {} | critical --base text/fixture --inline | sponge {}'
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'prod*')
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
