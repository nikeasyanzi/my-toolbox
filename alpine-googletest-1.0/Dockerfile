#Dev note:
# 1. CMAKE
# 2. Rely on cmake to pull google test for build cuz install from package does not work

FROM alpine:3.16
LABEL maintainer "craigyang"

# Use ARG to specify build-time only env variable
#ARG http_proxy=
#ARG https_proxy=

ARG url="Please give build argument at run time with '--build-arg url=http://..../xxx.zip'"

RUN env \
  && apk update && apk upgrade \
  && apk add --no-cache -q -f git gcc g++ tree build-base linux-headers lcov gettext-base jq curl tar python3 \
  cmake=3.23.5-r0
#gtest=1.13.0-r1

RUN mkdir /download && cd /download \
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

