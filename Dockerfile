FROM alpine:3.14

# Install build deps
RUN apk add --no-cache \
    curl \
    ca-certificates \
    build-base \
    libffi-dev \
    openssl-dev \
    bzip2-dev \
    zlib-dev \
    xz-dev \
    readline-dev \
    sqlite-dev \
    make \
    gcc \
    musl-dev \
    wget

# Install Python 3.12 manually
ENV PYTHON_VERSION=3.12.3
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar -xf Python-${PYTHON_VERSION}.tar.xz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --prefix=/usr/local && make -j$(nproc) && make install && \
    cd .. && rm -rf Python-${PYTHON_VERSION}*

# Download & run uv's installer script
RUN apk add --no-cache curl ca-certificates
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Move the binary into PATH
RUN mv ~/.local/bin/uv /usr/local/bin/uv

# Optional: clean up installer directory
RUN rm -rf ~/.local

# Verify installation
RUN uv --version

# Install the project into `/app`
WORKDIR /app

COPY pyproject.toml uv.lock ./

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy
# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]