FROM ubuntu:20.04

# barebones system packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        g++-8 \
        pax-utils \
        python3.9 \
        python3.9-dev \
        python3.9-distutils \
        wget \
    && rm -rf /var/lib/apt/lists/*

# julia
RUN mkdir /opt/julia \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz | tar zxf - -C /opt/julia --strip=1 \
    && chown -R 1000 /opt/julia \
    && ln -s /opt/julia/bin/julia /usr/local/bin

# unprivileged user
ENV USER spt
ENV HOME=/home/$USER
RUN adduser --disabled-password --gecos "Default user" --uid 1000 $USER
USER $USER

# poetry
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PATH="$HOME/.local/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python3.9 -

# install spt3g_software
COPY --chown=1000:1000 spt3g_software $HOME/spt3g_software
COPY --chown=1000:1000 Project.toml $HOME/
COPY --chown=1000:1000 src $HOME/src
RUN julia --project=$HOME -e "using Pkg; Pkg.instantiate()"
RUN mkdir $HOME/spt3g_software/build
WORKDIR $HOME/spt3g_software/build
RUN cmake $(julia --project=$HOME -e "using Spt3GSoftwareBuilder; print(Spt3GSoftwareBuilder.cmake_flags())") ..
RUN make -j 8

# 
WORKDIR $HOME
RUN poetry init -n --python ^3.9
RUN poetry add -e spt3g_software/build
RUN poetry run julia --project=$HOME -e 'using Pkg; Pkg.add("PyCall")'