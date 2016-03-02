FROM centos:7

MAINTAINER Samuel Loretan <tynril@gmail.com>

RUN yum install -y git wget

ENV FACTORIO_VERSION 0.12.24
ENV FACTORIO_SAVE_NAME DockerSave
ENV FACTORIO_SERVER_ARGS --autosave-interval 3 --autosave-slots 10 --latency-ms 175 --disallow-commands --peer-to-peer
ENV GDRIVE_FACTORIO_FOLDER_NAME Factorio
ENV GDRIVE_UPLOAD_SAVES_FREQUENCY_SEC 180

ADD utils/factorio.sh /opt/factorio/factorio.sh
ADD utils/factorio_upload_save.sh /opt/factorio/factorio_upload_save.sh

STOPSIGNAL SIGINT

RUN cd /opt \
	&& wget --no-check-certificate "https://www.factorio.com/get-download/$FACTORIO_VERSION/headless/linux64" -O factorio.tar.gz \
	&& tar xzf factorio.tar.gz \
	&& rm factorio.tar.gz \
	&& chmod +x /opt/factorio/bin/x64/factorio \
	&& chmod +x /opt/factorio/factorio.sh \
	&& chmod +x /opt/factorio/factorio_upload_save.sh \
	&& wget "https://docs.google.com/uc?id=0B3X9GlR6EmbnWksyTEtCM0VfaFE&export=download" -O /opt/gdrive \
	&& chmod +x /opt/gdrive

CMD ["bash", "-c", "/opt/factorio/factorio.sh"]
