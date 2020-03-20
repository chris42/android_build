# Build a dockerfile for building android
FROM ubuntu:bionic

# Setting directories
ENV MIRROR_DIR=/root/mirror
ENV WORK_DIR=/root/aosp
ENV PATCH_DIR=/root/patches
ENV KEYS_DIR=/root/keys

#Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Set build environment variables
ENV ANDROID_HOME=/opt/android
ENV USE_CCACHE=1
ENV CCACHE_EXEC=/usr/bin/ccache
ENV CCACHE_DIR=/root/ccache
ENV CCACHE_COMPRESS=1
ENV CC="ccache clang"
ENV CXX="ccache clang++"
ENV USER=root
ENV GRADLE_OPTS=-Xmx15360m
ENV DEVICE_FLAVOUR=aosp_f5321-userdebug
ENV PLATFORM=loire
ENV DEVICE=kugo
ENV SIGN_BUILDS=false
ENV REBUILD_KERNEL=true
ENV BUILD_ONLY=false

ARG GIT_USER=to-be-changed
ARG GIT_EMAIL=to-be-changed@to-be.changed
ARG DEBIAN_FRONTEND=noninteractive

# Install needed packages
RUN dpkg --add-architecture i386
RUN apt-get -o Acquire::ForceIPv4=true update
RUN apt-get purge -y openjdk-\* icedtea-\* icedtea6-\*
RUN apt-get -o Acquire::ForceIPv4=true upgrade -y
RUN apt-get -o Acquire::ForceIPv4=true install -y \
    bc \
    bison \
    ccache \
    curl \
    flex \
    g++-multilib \
    git \
    gperf \
    kmod \
    liblz4-tool \
    libncurses5 \
    libssl-dev \
    libxml2-utils \
    make \
    nano \
    openjdk-8-jdk \
    python2.7 \
    rsync \
    software-properties-common \
    wget \
    zlib1g-dev:i386 \
    zip

RUN rm -rf /var/lib/apt/lists/*

#Link python
RUN ln -s /usr/bin/python2.7 /usr/bin/python

# Download Repo Tool
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
RUN chmod 755 /usr/local/bin/repo

# Create Git Config
RUN git config --global user.name "$GIT_USER"
RUN git config --global user.email "$GIT_EMAIL"
RUN git config --global color.ui "auto"

# Download and unzip android sdk tools
RUN mkdir -p /root/.android/
RUN touch /root/.android/repositories.cfg
RUN mkdir /opt/android \
    && cd /opt/android \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip \
    && unzip -q sdk-tools-linux-4333796.zip

# Get build tools and accept licenses
RUN /opt/android/tools/bin/sdkmanager --update
RUN yes | /opt/android/tools/bin/sdkmanager 'build-tools;28.0.3' >> /dev/null
RUN yes | /opt/android/tools/bin/sdkmanager 'platforms;android-28' >> /dev/null
RUN yes | /opt/android/tools/bin/sdkmanager --licenses >> /dev/null

# Link ccache
RUN ln -s /usr/bin/ccache /usr/local/bin/gcc
RUN ln -s /usr/bin/ccache /usr/local/bin/g++
RUN ln -s /usr/bin/ccache /usr/local/bin/cc
RUN ln -s /usr/bin/ccache /usr/local/bin/c++

# Mount points for persistent data
VOLUME "$WORK_DIR"
RUN mkdir -p "$WORK_DIR"
VOLUME "$MIRROR_DIR"
RUN mkdir -p "$MIRROR_DIR"
VOLUME "$CCACHE_DIR"
RUN mkdir -p "$CCACHE_DIR"
VOLUME "$KEYS_DIR"
RUN mkdir -p "$KEYS_DIR"

RUN mkdir -p "$PATCH_DIR"

# Add files
COPY ./build-10-4.9.sh /root/build-10-4.9.sh
RUN chmod +x /root/build-10-4.*.sh
COPY ./android_frameworks_base-Q.patch "$PATCH_DIR"/android_frameworks_base-Q.patch
ENV __FLUSH_LOG yes
#ENTRYPOINT ["/root/build-10-4.9.sh"]
