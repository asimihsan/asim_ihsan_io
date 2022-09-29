# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
#   Base Ubuntu
# -----------------------------------------------------------------------------
FROM ubuntu:jammy-20220815 as base

# See: https://pipenv.pypa.io/en/latest/basics/
# See: https://docs.docker.com/build/building/cache/

ENV AWSCLI_VERSION='2.7.35'
ENV DEBIAN_FRONTEND "noninteractive"
ENV HUGO_VERSION='0.104.1'
ENV LANG en_US.utf8
ENV PYENV_GIT_TAG=v2.3.4
ENV PYENV_PYTHON='3.9.13'

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
        # Other
        ca-certificates \
        chromium-browser \
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
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -f awscliv2.zip
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Node
# -----------------------------------------------------------------------------
FROM base as node

ENV VERSION_NVM=0.39.1
ENV VERSION_NODE=14.16.1

# Install Node
RUN --mount=type=cache,target=/root/.nvm,sharing=locked \
    --mount=type=cache,target=/root/.npm,sharing=locked \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v${VERSION_NVM}/install.sh | bash && \
    /bin/bash -c ". ~/.nvm/nvm.sh && \
        nvm install $VERSION_NODE && nvm use $VERSION_NODE && \
        nvm alias default node && nvm cache clear" && \
    # Install Node dependencies
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install netlify-cli -g --unsafe-perm=true' && \
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install critical -g --unsafe-perm=true' && \
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install puppeteer -g --unsafe-perm=true' && \
    /bin/bash -c '. ~/.nvm/nvm.sh && npm install aws-cdk -g --unsafe-perm=true'
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
RUN --mount=type=cache,target=/root/.pyenv/versions,sharing=locked \
    --mount=type=cache,target=/root/.pyenv/cache,sharing=locked \
    bash -i -c "[[ -d /root/.pyenv/versions/$PYENV_PYTHON ]] || /root/.pyenv/bin/pyenv install $PYENV_PYTHON" && \
    bash -i -c "/root/.pyenv/bin/pyenv global $PYENV_PYTHON" && \
    bash -i -c 'pip install --upgrade pip' && \
    bash -i -c 'pip install pipenv' && \
    bash -i -c 'cd /root/ && pipenv install --system --deploy'
# -----------------------------------------------------------------------------
#   Hugo
# -----------------------------------------------------------------------------
FROM base as hugo

RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-arm64.tar.gz | tar -xz && \
    mv hugo /usr/local/bin/hugo
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Final
# -----------------------------------------------------------------------------
FROM base as final

ENV VERSION_NODE=v14.16.1

COPY --from=node /root/.npm /root/.npm
COPY --from=node /root/.nvm /root/.nvm
COPY --from=python /root/.pyenv /root/.pyenv
COPY --from=hugo /usr/local/bin/hugo /usr/local/bin/hugo

RUN apt-get clean && \
    echo 'export PATH="$HOME/.pyenv/bin:/usr/local/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc  && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.nvm/versions/node/${VERSION_NODE}/bin:${PATH}"' >> ~/.bashrc && \
    echo 'export LANG=en_US.utf8' >> ~/.bashrc
# -----------------------------------------------------------------------------