FROM centos:8

COPY baseOS /baseOS

RUN chmod +x /baseOS/os-setup && /baseOS/os-setup

ENTRYPOINT ["/usr/bin/sleep", "infinity"]
