FROM tbi:latest
EXPOSE 3000
EXPOSE 8080
EXPOSE 6379
EXPOSE 27017

COPY assets /assets

ARG SBX_GATEWAY_VERS=""
ARG SBX_DASHBOARD_VERS=""
ARG SBX_PUMP_VERS=""
ARG SBX_TIB_VERS=""
ARG SBX_SYNC_VERS=""
ARG SBX_SCHEMA_URL=""

RUN chmod +x /assets/rpms/install-tyk && /assets/rpms/install-tyk 

COPY scripts /scripts
RUN chmod +x /scripts/*

ENTRYPOINT ["/scripts/entrypoint.sh"]
