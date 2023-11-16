ARG TBI_IMAGE=tbi8:latest
FROM --platform=linux/amd64 $TBI_IMAGE

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

COPY scripts /scripts
RUN chmod +x /scripts/*

RUN /scripts/install-tyk 

ENTRYPOINT ["/scripts/entrypoint.sh"]
