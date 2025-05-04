FROM hub.docker.hpecorp.net/vet-tdc/centos:7
LABEL maintainer "craigyang"
# Use ARG to specify build-time only env variable
#ARG http_proxy=
#ARG https_proxy=
ARG url="Please give build argument at run time with '--build-arg url=http://..../xxx.zip'"

RUN yum -y install genisoimage \
    && yum -y install epel-release \
    && yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm \
    && yum -y install golang hg \
    && yum -y install glibc.i686 zip unzip wget make tree file which openssl curl openssh rsync sshpass net-snmp net-snmp-utils net-snmp-libs net-snmp-agent-lib python2 python3 git jq sudo patch \ 
# Install linter for C/C++
    && yum -y install centos-release-scl \
    && yum -y install llvm-toolset-7 llvm-toolset-7-clang-analyzer iwyu \
    && yum -y install unzip tree file which openssl curl rsync sshpass python3 git jq sudo \
    && yum clean all \
    && rm -rf /var/cache/yum

#Install golang
ARG GOLANG_VERSION=1.18.2

ENV PATH=$PATH:/usr/local/go/bin

RUN wget https://dl.google.com/go/go$GOLANG_VERSION.src.tar.gz && tar -C /usr/local -xzf go$GOLANG_VERSION.src.tar.gz \
    && rm go$GOLANG_VERSION.src.tar.gz \
    && cd /usr/local/go/src && ./make.bash


#Shellscript formatter
RUN yum -y install ShellCheck \
 && go install mvdan.cc/sh/v3/cmd/shfmt@latest \
 && yum clean all \
 && rm -rf /var/cache/yum \
 && python3 -m pip --no-cache-dir install -U pip setuptools \ 
 && python3 -m pip --no-cache-dir install poetry pre-commit \
 # Install linter for C/C++
 && python3 -m pip --no-cache-dir install cpplint \
 # Install linter for Python
 && python3 -m pip --no-cache-dir install commitizen black flake8 mypy reorder-python-imports \
 && unset http_proxy https_proxy \
    && file_name="$(basename $url)" \
    && mkdir /download && cd /download \
       && echo $url \
       && for urll in $url; \
       do \
              echo "downloading $urll"; \
	      curl -O -L $urll; \
	      file_name=$(basename $urll);\
	      case "$file_name" in \
      		*.tar*) tar -xf "$file_name" ;; \
        	*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk) unzip "$file_name" ;; \
        	*.sh|*.py) mv $file_name /opt ;; \
        	*.yaml) ls -al && mv pre-commit-config.yaml .pre-commit-config.yaml && git init && pre-commit install ;; \
        	* ) echo "fail to process file $file_name" ;; \
    	      esac; \
       done \
      && rm -rf /download \
# /go/bin will be mounted on top, so get everything into /usr/local/bin
# do not move this line after all golang package are installed 
&& cp -r /root/go/bin/* /usr/local/bin

# Install cmake binary from github release for newer version
ARG CMAKE_LINK=https://github.com/Kitware/CMake/releases/download/v3.20.3/cmake-3.20.3-linux-x86_64.tar.gz
RUN mkdir /download && cd /download \
    && curl -o cmake.tar.gz -L $CMAKE_LINK \
    && tar -xf ./cmake.tar.gz --strip=1 \
    && cp -r bin/* /usr/local/bin/ \
    && cp -r share/* /usr/local/share/ \
    && rm -rf /download

ENV LLVMPATH=/opt/rh/llvm-toolset-7/root/usr/bin/
ENV PATH=$LLVMPATH:$PATH

WORKDIR /workdir

