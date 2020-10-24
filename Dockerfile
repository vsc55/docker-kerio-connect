FROM centos:8

LABEL version="2.0" maintainer="vsc55@cerebelum.net" description="Contenedor de Kerio Connect"

ARG KERIO_CONNECT_VER
ENV ADMIN_PORT=4040 MODE_RUN=production KERIO_CONNECT_VER=${KERIO_CONNECT_VER}

RUN	tmp_rpm=/tmp/kerio-connect-linux-x86_64.rpm; \
	\
	if [ "$KERIO_CONNECT_VER" = "" -o "$KERIO_CONNECT_VER" = "dev" ] ; \
	then \
		url_file=kerio-connect-linux-64bit.rpm; \
		url_path=dwn/$url_file; \
	else \
		KERIO_CONNECT_VER_MINI = $(cut -d'-' -f1 <<< ${KERIO_CONNECT_VER})-$(cut -d'-' -f2 <<< ${KERIO_CONNECT_VER}); \
		url_file=kerio-connect-${KERIO_CONNECT_VER}-linux-x86_64.rpm; \
		url_path=dwn/connect/connect-${KERIO_CONNECT_VER_MINI}/$url_file; \
	fi; \
	\
	curl -sf http://cdn.kerio.com/$url_path --output "$tmp_rpm"; \
	if [ ! -f "$tmp_rpm" ] ; \
	then \
		curl -sf http://download.kerio.com/$url_path --output "$tmp_rpm"; \
	fi; \
	if [ ! -f "$tmp_rpm" ] ; \
	then \
		echo "ERROR Downloading $url_file !!!"; \
		exit 1; \
	fi; \
	\
	yum -y update; \
 	yum -y install \
 	nano \
 	net-tools; \
	\
	yum -y install "$tmp_rpm"; \
	rm -f "$tmp_rpm"; \
	\
	yum clean all; \
	rm -rf /var/cache/yum;

WORKDIR /
COPY --chown=root:root ["entrypoint.sh", "health_check.sh", "runKerioConnect.sh", "./"]

#Fix, hub.docker.com auto buils
RUN chmod +x /*.sh

VOLUME ["/config"]

EXPOSE ${ADMIN_PORT}/tcp 80/tcp 443/tcp 25/tcp 465/tcp 587/tcp 110/tcp 995/tcp 143/tcp 993/tcp 119/tcp 563/tcp 389/tcp 636/tcp 5222/tcp 5223/tcp

HEALTHCHECK --interval=30s --timeout=15s --start-period=15s --retries=4 CMD /health_check.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]