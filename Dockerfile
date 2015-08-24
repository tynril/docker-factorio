FROM centos:7

MAINTAINER Lee Fenlan <lee@fenlan.co.uk>

RUN yum install -y git curl

ENV FACTORIO_VERSION = 0.12.4

RUN cd /opt \
    && curl --header="Cookie:${SESSION}" "https://www.factorio.com/get-download/${FACTORIO_VERSION}/alpha/linux64" -o factorio.tar.gz
    && tar xzf factorio.tar.gz
    && rm factorio.tar.gz
    && git clone --recursive https://github.com/Themodem/factorio-init.git

CMD ["bash", "-c", "/opt/factorio-init/factorio"]
