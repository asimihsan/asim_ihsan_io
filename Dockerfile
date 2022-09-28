# -----------------------------------------------------------------------------
#   Base Ubuntu
# -----------------------------------------------------------------------------
FROM ubuntu:latest as base

# See: https://pipenv.pypa.io/en/latest/basics/
# See: https://docs.docker.com/build/building/cache/

ENV DEBIAN_FRONTEND "noninteractive"
ENV LANG en_US.utf8
ENV PYENV_GIT_TAG=v2.3.4
ENV PYENV_PYTHON='3.9.13'

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
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
    git \
    locales \
    moreutils && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Node
# -----------------------------------------------------------------------------
FROM base as node

ENV VERSION_NVM=0.39.1
ENV VERSION_NODE=14.16.1

# Install Node
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${VERSION_NVM}/install.sh | bash
RUN /bin/bash -c ". ~/.nvm/nvm.sh && \
    nvm install $VERSION_NODE && nvm use $VERSION_NODE && \
    nvm alias default node && nvm cache clear"

# Install Node dependencies
RUN /bin/bash -c '. ~/.nvm/nvm.sh && npm install netlify-cli -g --unsafe-perm=true'
RUN /bin/bash -c '. ~/.nvm/nvm.sh && npm install critical -g --unsafe-perm=true'
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#   Python
# -----------------------------------------------------------------------------
FROM base as python

# Setup pyenv and install extra python versions
RUN curl https://pyenv.run | bash && \
    echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc  && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc && \
    bash -i -c "pyenv install $PYENV_PYTHON" && \
    bash -i -c "pyenv global $PYENV_PYTHON" && \
    bash -i -c 'pip install --upgrade pip' && \
    bash -i -c 'pip install pipenv'

ADD Pipfile Pipfile.lock /root/
RUN bash -i -c 'cd /root/ && pipenv install --system --deploy'

# -----------------------------------------------------------------------------
#   Final
# -----------------------------------------------------------------------------
FROM base as final

ENV VERSION_NODE=v14.16.1

COPY --from=node /root/.npm /root/.npm
COPY --from=node /root/.nvm /root/.nvm

COPY --from=python /root/.local /root/.local
COPY --from=python /root/.pyenv /root/.pyenv

RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc  && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.nvm/versions/node/${VERSION_NODE}/bin:${PATH}"' >> ~/.bashrc
# -----------------------------------------------------------------------------