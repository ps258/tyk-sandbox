FROM centos:8
EXPOSE 3000
EXPOSE 8080
EXPOSE 6379
EXPOSE 27017

COPY assets /assets

RUN chmod +x /assets/baseOS/os-setup && /assets/baseOS/os-setup
RUN chmod +x /assets/rpms/install-tyk && mkdir -p /data/db && /assets/rpms/install-tyk

COPY scripts /scripts
RUN chmod +x /scripts/*

ENTRYPOINT ["/scripts/entrypoint.sh"]
