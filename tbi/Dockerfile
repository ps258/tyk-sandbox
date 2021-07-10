FROM centos:7

COPY assets /assets
COPY tbi.sh /tbi.sh

RUN chmod +x /assets/baseOS/os-setup /tbi.sh \
  && /assets/baseOS/os-setup

ENTRYPOINT ["/tbi.sh"]
