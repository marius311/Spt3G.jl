FROM ubuntu:20.04

# barebones system packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        curl \
        g++-8 \
        pax-utils \
    && rm -rf /var/lib/apt/lists/*

# julia
RUN mkdir /opt/julia \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz | tar zxf - -C /opt/julia --strip=1 \
    && chown -R 1000 /opt/julia \
    && ln -s /opt/julia/bin/julia /usr/local/bin

# unprivileged user
ENV USER spt
ENV HOME=/home/$USER
ENV JULIA_PROJECT=@.
RUN adduser --disabled-password --gecos "Default user" --uid 1000 $USER
USER $USER
WORKDIR $HOME

# build spt3g_software
COPY --chown=1000:1000 spt3g_software $HOME/spt3g_software
COPY --chown=1000:1000 Project.toml $HOME/
COPY --chown=1000:1000 src $HOME/src
RUN julia -e "using Pkg; Pkg.instantiate()"
RUN mkdir $HOME/spt3g_software/build
WORKDIR $HOME/spt3g_software/build
RUN julia -e "using Spt3G; Spt3G.cmake()" ..
RUN make -j 8

# only now install system python
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        python3 \
        python3-pip \
        chrpath \
        patchelf \
    && rm -rf /var/lib/apt/lists/*
USER $USER
RUN pip install poetry
ENV PATH=$HOME/.local/bin:$PATH

# make poetry environment where we simulate adding spt3g_software
WORKDIR $HOME
RUN poetry init -n --python ^3.8
RUN poetry env use $(julia -e "using Python_jll; print(Python_jll.python_path)")
RUN poetry add -e spt3g_software/build
RUN echo "export LD_LIBRARY_PATH=\"\$(julia --project=$HOME -e \"using Python_jll; print(Python_jll.LIBPATH[])\"):\$LD_LIBRARY_PATH\"" >> $(poetry env info --path)/bin/activate

# add/build PyCall with this environment's Python
RUN LD_LIBRARY_PATH="$(julia --project=$HOME -e 'using Python_jll; print(Python_jll.LIBPATH[])'):$LD_LIBRARY_PATH" \
        PYTHON=$(poetry run which python) \
        julia -e 'using Pkg; Pkg.add("PyCall")'

# COPY python $HOME/python

ENTRYPOINT ["poetry", "run", "julia"]