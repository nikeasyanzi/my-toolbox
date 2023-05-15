FROM ubuntu:18.04
LABEL maintainer "craigyang"
# Use ARG to specify build-time only env variable
#ARG http_proxy=
#ARG https_proxy=

ARG url="Please give build argument at run time with '--build-arg url=http://..../xxx.zip'"

# Add 32-bit loader, dependent packages
RUN apt-get update \
    && apt-get install -y gcc g++ curl tar git python3 build-essential \ 
    && apt-get clean \
    && apt-get auto-clean

# Install cmake binary from github release for newer version
ARG CMAKE_LINK=https://github.com/Kitware/CMake/releases/download/v3.20.3/cmake-3.20.3-linux-x86_64.tar.gz
RUN mkdir /download && cd /download \
    && curl -o cmake.tar.gz -L $CMAKE_LINK \
    && tar -xf ./cmake.tar.gz --strip=1 \
    && cp -r bin/* /usr/local/bin/ \
    && cp -r share/* /usr/local/share/ \
    && mkdir my_project && cd my_project \
    && echo $url \
    && for urll in $url; \
    do \
           echo "downloading $urll"; \
           curl -O -L $urll; \
    done \
     && ls -al && pwd \
    && cmake -DBUILD_SHARED_LIBS=ON -G"Unix Makefiles" -S . -B ./build \ 
    && cmake --build build \
    && cd build/_deps/googletest-build/ && make install \
    && rm -rf /download

ENV GTEST_HOME=/usr/local
ENV LD_LIBRARY_PATH=$GTEST_HOME/lib:$LD_LIBRARY_PATH

WORKDIR /workdir

