# asim_ihsan_io
Content for https://asim.ihsan.io website.

## Usage

### Build to staging environment with production assets

TODO automate, but for now change directory to root then:

```
(cd hugo/themes/ananke/src && npm run build:production)
(cd hugo && hugo --buildDrafts --destination build)
(cd cdk && cdk deploy)
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