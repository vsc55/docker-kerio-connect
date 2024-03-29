FROM centos:8

ARG KERIO_CONNECT_VER

LABEL version="3.0" maintainer="vsc55@cerebelum.net" description="Contenedor de Kerio Connect v${KERIO_CONNECT_VER:-DEV}"

ENV ADMIN_PORT=4040 MODE_RUN=production LANG=en_US.utf8

RUN	tmp_rpm=/tmp/kerio-connect-linux-x86_64.rpm; \
	\
	if [ "${KERIO_CONNECT_VER}" = "" -o "${KERIO_CONNECT_VER}" = "dev" ] ; \
	then \
		url_file=kerio-connect-linux-64bit.rpm; \
		url_path=dwn/$url_file; \
	else \
		KERIO_CONNECT_VER_MINI=$(cut -d'-' -f1 <<< ${KERIO_CONNECT_VER})-$(cut -d'-' -f2 <<< ${KERIO_CONNECT_VER}); \
		url_file=kerio-connect-${KERIO_CONNECT_VER}-linux-x86_64.rpm; \
		url_path=dwn/connect/connect-$KERIO_CONNECT_VER_MINI/$url_file; \
	fi; \
	\
	curl -sfL http://cdn.kerio.com/$url_path --output "$tmp_rpm"; \
	if [ ! -f "$tmp_rpm" ] ; \
	then \
		curl -sfL http://download.kerio.com/$url_path --output "$tmp_rpm"; \
	fi; \
	if [ ! -f "$tmp_rpm" ] ; \
	then \
		echo "[ERROR] - Failed Downloading $url_file !!!!!"; \
		exit 1; \
	fi; \
	\
	find /etc/yum.repos.d/ -type f -exec sed -i 's/mirrorlist=/#mirrorlist=/g' {} +; \
	find /etc/yum.repos.d/ -type f -exec sed -i 's/#baseurl=/baseurl=/g' {} +; \
	find /etc/yum.repos.d/ -type f -exec sed -i 's/mirror.centos.org/vault.centos.org/g' {} +; \
	yum -y update; \
 	yum -y install \
	glibc-langpack-en \
	glibc-langpack-es \
 	nano \
 	net-tools; \
	\
	yum -y install "$tmp_rpm"; \
	rm -f "$tmp_rpm"; \
	\
	version_installed=$(echo $(cut -d':' -f2 <<< $( yum info kerio-connect | grep Version ) ) | xargs);\
	echo "***** INSTALLED VERSION ($version_installed) *****";\
	echo $version_installed > /KERIO_VERSION; \
	\
	yum clean all; \
	rm -rf /var/cache/yum;

WORKDIR /
COPY --chown=root:root /rootfs /

#Fix, hub.docker.com auto buils
RUN chmod +x /*.sh

VOLUME ["/config"]

EXPOSE ${ADMIN_PORT}/tcp 80/tcp 443/tcp 25/tcp 465/tcp 587/tcp 110/tcp 995/tcp 143/tcp 993/tcp 119/tcp 563/tcp 389/tcp 636/tcp 5222/tcp 5223/tcp

HEALTHCHECK --interval=30s --timeout=15s --start-period=15s --retries=4 CMD /health_check.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]