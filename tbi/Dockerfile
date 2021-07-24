FROM centos:7

COPY baseOS /baseOS
COPY tbi.sh /tbi.sh

RUN chmod +x /baseOS/os-setup /tbi.sh \
  && /baseOS/os-setup

ENTRYPOINT ["/tbi.sh"]
