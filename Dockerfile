# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
#   Base Ubuntu
# -----------------------------------------------------------------------------
FROM ubuntu:jammy-20230308 as base

# See: https://pipenv.pypa.io/en/latest/basics/
# See: https://docs.docker.com/build/building/cache/

ENV AWSCLI_VERSION='2.11.5'
ENV CDK_VERSION='2.70.0'
ENV DEBIAN_FRONTEND "noninteractive"
ENV HUGO_VERSION='0.111.3'
ENV LANG en_US.utf8
ENV NETLIFY_VERSION='12.10.0'
ENV PYENV_GIT_TAG=v2.3.16
ENV PYENV_PYTHON='3.10.10'
ENV VERSION_NODE=v18.15.0
ENV VERSION_NVM=0.39.3

RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        # Python dependencies
        build-essential \
        curl \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libxcursor1 \
        libxdamage-dev \
        libxml2-dev \
        libxmlsec1-dev \
        llvm \
        make \
        tk-dev \
        wget \
        xz-utils \
        zlib1g-dev \
        # Chromium \
        # ca-certificates \
        # fonts-liberation \
        # libappindicator3-1 \
        # libasound2 \
        # libatk-bridge2.0-0 \
        # libatk1.0-0 \
        # libc6 \
        # libcairo2 \
        # libcups2 \
        # libdbus-1-3 \
        # libexpat1 \
        # libfontconfig1 \
        # libgbm1 \
        # libgcc1 \
        # libglib2.0-0 \
        # libgtk-3-0 \
        # libnspr4 \
        # libnss3 \
        # libpango-1.0-0 \
        # libpangocairo-1.0-0 \
        # libstdc++6 \
        # libx11-6 \
        # libx11-xcb1 \
        # libxcb1 \
        # libxcomposite1 \
        # libxcursor1 \
        # libxdamage1 \
        # libxext6 \
        # libxfixes3 \
        # libxi6 \
        # libxrandr2 \
        # libxrender1 \
        # libxss1 \
        # libxtst6 \
        # lsb-release \
        # wget \
        # xdg-utils \
        # Other
        ca-certificates \
        default-jre \
        fd-find \
        git \
        jq \
        locales \
        moreutils \
        ripgrep \
        unzip \
        vim && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    # AWS CLI
    cd /var/cache && \
    rm -rf aws && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64-$AWSCLI_VERSION.zip" -o "awscliv2.zip" && \
    # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$AWSCLI_VERSION.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -f awscliv2.zip
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Node
# -----------------------------------------------------------------------------
FROM base as node

# Install Node
RUN --mount=type=cache,target=/root/.cache,sharing=locked \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v${VERSION_NVM}/install.sh | bash && \
    /bin/bash -c ". ~/.nvm/nvm.sh && \
        nvm install $VERSION_NODE && nvm use $VERSION_NODE && \
        nvm alias default node" && \
    # Install Node dependencies
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install netlify-cli@"${NETLIFY_VERSION}" -g --unsafe-perm=true' && \
    # /bin/bash -c '. ~/.nvm/nvm.sh && npm install critical -g --unsafe-perm=true' && \
    # /bin/bash -c '. ~/.nvm/nvm.sh && npm install puppeteer -g --unsafe-perm=true' && \
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install aws-cdk@"${CDK_VERSION}" -g --unsafe-perm=true' && \
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install @mermaid-js/mermaid-cli -g --unsafe-perm=true'
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Python
# -----------------------------------------------------------------------------
FROM base as python

ADD Pipfile Pipfile.lock /root/

# Setup pyenv and install extra python versions
RUN curl https://pyenv.run | bash && \
    echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc  && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
RUN --mount=type=cache,target=/root/.pyenv/cache,sharing=locked \
    bash -i -c "/root/.pyenv/bin/pyenv install $PYENV_PYTHON" && \
    bash -i -c "/root/.pyenv/bin/pyenv global $PYENV_PYTHON" && \
    bash -i -c 'pip install --upgrade pip' && \
    bash -i -c 'pip install pipenv' && \
    bash -i -c 'cd /root/ && pipenv install --system --deploy'

# -----------------------------------------------------------------------------
#   Caching CDK dependencies.
# -----------------------------------------------------------------------------
FROM node as cdk

ENV PATH="$HOME/.nvm/versions/node/${VERSION_NODE}/bin:${PATH}"

COPY cdk /root/cdk

RUN --mount=type=cache,target=/root/.gradle,sharing=locked \
    bash -i -c 'cd /root/cdk && mkdir -p /root/hugo/build && ./gradlew run'

# -----------------------------------------------------------------------------
#   Hugo
# -----------------------------------------------------------------------------
FROM base as hugo

# RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz | tar -xz && \
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-arm64.tar.gz | tar -xz && \
    mv hugo /usr/local/bin/hugo
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Final
# -----------------------------------------------------------------------------
FROM base as final

COPY --from=node /root/.npm /root/.npm
COPY --from=node /root/.nvm /root/.nvm
COPY --from=python /root/.pyenv /root/.pyenv
COPY --from=hugo /usr/local/bin/hugo /usr/local/bin/hugo
COPY --from=cdk /root/.gradle /root/.gradle

RUN apt-get clean && \
    echo 'export PATH="$HOME/.pyenv/bin:/usr/local/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc  && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc && \
    echo '. ~/.nvm/nvm.sh' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.nvm/versions/node/${VERSION_NODE}/bin:${PATH}"' >> ~/.bashrc && \
    echo 'export LANG=en_US.utf8' >> ~/.bashrc
# -----------------------------------------------------------------------------
