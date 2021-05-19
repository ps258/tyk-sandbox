FROM centos:latest
EXPOSE 3000
EXPOSE 8080
COPY assets /assets

RUN chmod +x /assets/rpms/install \
	&& /assets/rpms/install \
	&& mkdir -p /data/db

COPY scripts /scripts
COPY assets/tyk_analytics.conf /opt/tyk-dashboard/
COPY assets/tyk.conf /opt/tyk-gateway/
COPY assets/pump.conf /opt/tyk-pump/

RUN chmod +x /scripts/*

ENTRYPOINT ["/scripts/startup.sh"]
