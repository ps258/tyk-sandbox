FROM tbi:latest
EXPOSE 3000
EXPOSE 8080
COPY assets /assets

RUN chmod +x /assets/rpms/install-tyk && mkdir -p /data/db
RUN /assets/rpms/install-tyk

COPY scripts /scripts
COPY assets/tyk_analytics.conf /opt/tyk-dashboard/
COPY assets/tyk.conf /opt/tyk-gateway/
COPY assets/pump.conf /opt/tyk-pump/
COPY assets/tib.conf /opt/tyk-identity-broker/

RUN chmod +x /scripts/*
RUN rm /tbi.sh

ENTRYPOINT ["/scripts/entrypoint.sh"]
