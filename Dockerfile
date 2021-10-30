# ================================
# Build image
# ================================
FROM swift:5.5-focal as build

# Install OS updates and, if needed, sqlite3 and setcap
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build everything, with optimizations
RUN swift build -c release

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./

# Copy any resouces from the public directory and views directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM swift:5.5-focal-slim

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \ 
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libcap2-bin \
    && rm -r /var/lib/apt/lists/*

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /staging /app

# Let app run on 80 port
RUN setcap 'cap_net_bind_service=+ep' /app/Run

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Default port
ARG PORT=8080
ENV PORT ${PORT}

# Let Docker bind to selected port
EXPOSE ${PORT}

# Start the Vapor service when the image is run, default to listening on selected port in production environment
ENTRYPOINT ["sh"]
CMD ["-c", "./Run serve --env production --hostname 0.0.0.0 --port ${PORT}"]
