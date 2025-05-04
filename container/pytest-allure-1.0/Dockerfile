FROM centos:7
LABEL maintainer "craigyang"
# Use ARG to specify build-time only env variable

ARG http_proxy=http://proxy.houston.hpecorp.net:8080
ARG https_proxy=http://proxy.houston.hpecorp.net:8080
ARG url="Please give build argument at run time with '--build-arg url=http://..../xxx.zip'"

# Add 32-bit loader, dependent packages
RUN yum -y install epel-release \
    && yum -y install glibc.i686 zip unzip wget make tree file which openssl curl openssh rsync sshpass net-snmp net-snmp-utils net-snmp-libs net-snmp-agent-lib python3 git jq sudo patch \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && pip3 install -U pip wheel \
    && pip3 install python-ilorest-library==3.2.1 \
    && pip3 install -U pytest pytest-html jsonschema requests pysnmp pytest-testinfra paramiko allure-pytest \
# Download all files 
# if it is an archieved file (tar,zip...), unarchieve and install rpm
# if it is a script file, copy to /opt
    && mkdir /download && cd /download \
       && echo $url \
       && for urll in $url; \
       do \
              echo "downloading $urll"; \
	      curl -O -L $urll; \
	      file_name=$(basename $urll);\
	      case "$file_name" in \
      		*.tar*) tar -xf "$file_name" && rpm -ivh --nodeps $(find -name "*.rpm") ;; \
        	*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk) unzip "$file_name" && rpm -ivh --nodeps $(find -name "*.rpm") ;; \
        	*.sh|*.py) mv $file_name /opt ;; \
        	* ) echo "fail to process file $file_name" ;; \
    	      esac; \
	      rm -rf *; \
       done \
       && chmod a+x /opt/* \
       && rm -rf /download
WORKDIR /workdir

