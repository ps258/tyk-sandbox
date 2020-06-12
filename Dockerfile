FROM centos:tyk
EXPOSE 3000
EXPOSE 8080
COPY assets /assets

RUN chmod +x /assets/rpms/install \
	&& /assets/rpms/install \
	&& openssl genrsa -out /privkey.pem 2048 \
	&& openssl rsa -in /privkey.pem -pubout -out /pubkey.pem \
	&& mkdir -p /data/db

COPY scripts /scripts
COPY assets/tyk_analytics.conf /opt/tyk-dashboard/tyk_analytics.conf
COPY assets/tyk.conf /opt/tyk-gateway/
COPY assets/pump.conf /opt/tyk-pump/
COPY assets/tib.conf /opt/tyk-identity-broker/

RUN chmod +x /scripts/*

ENTRYPOINT ["/scripts/startup.sh"]
CMD ["--help"]
