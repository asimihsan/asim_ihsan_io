# asim_ihsan_io
Content for https://asim.ihsan.io website.

## TODO

-   CDK S3 BucketDeployment doesn't support setting `font/otf` content-type for OTF files. Will need a second-pass
    script that takes the bucket name of a stack and finds files like these and sets the right content-type.

## Usage

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
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && hugo --buildDrafts --destination build)
(cd hugo && HUGO_BASEURL='https://preprod-asim.ihsan.io' hugo --buildDrafts --destination build)
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'preprod*')
```

### Building to production environment

```
rm -rf hugo/build
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://asim.ihsan.io' hugo --buildDrafts --destination build)
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'prod*')
```

#### Deploy both pre-prod and prod

```
rm -rf hugo/build
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && hugo --buildDrafts --destination build)
(cd hugo && HUGO_BASEURL='https://preprod-asim.ihsan.io' hugo --buildDrafts --destination build)
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'preprod*')

rm -rf hugo/build
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && HUGO_ENV=production HUGO_BASEURL='https://asim.ihsan.io' hugo --buildDrafts --destination build)
./src/compress_build.py
(cd cdk && cdk deploy --require-approval never 'prod*')
```

### Live rebuilding during blog writing

```
IP_ADDRESS=192.168.1.9
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && hugo --buildDrafts --destination build --watch server --disableFastRender --bind 0.0.0.0 --baseURL "http://${IP_ADDRESS}" --enableGitInfo)
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
