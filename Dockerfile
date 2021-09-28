FROM tbi:latest
EXPOSE 3000
EXPOSE 8080
EXPOSE 6379
EXPOSE 27017
COPY assets /assets

RUN chmod +x /assets/rpms/install-tyk && mkdir -p /data/db && /assets/rpms/install-tyk

COPY scripts /scripts
COPY assets/tyk_analytics.conf /opt/tyk-dashboard/
COPY assets/tyk_analytics.conf /opt/tyk-dashboard/tyk_analytics.conf.sandbox-original
COPY assets/tyk.conf /opt/tyk-gateway/
COPY assets/tyk.conf /opt/tyk-gateway/tyk.conf.sandbox-original
COPY assets/pump.conf /opt/tyk-pump/
COPY assets/pump.conf /opt/tyk-pump/pump.conf.sandbox-original
COPY assets/tib.conf /opt/tyk-identity-broker/
COPY assets/tib.conf /opt/tyk-identity-broker/tib.conf.sandbox-original

RUN chmod +x /scripts/* && rm /tbi.sh

ENTRYPOINT ["/scripts/entrypoint.sh"]
