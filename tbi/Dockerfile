ARG BASE_UBI=centos:8
FROM --platform=linux/amd64 $BASE_UBI

COPY baseOS /baseOS

RUN chmod +x /baseOS/os-setup && /baseOS/os-setup

ENTRYPOINT ["/usr/bin/sleep", "infinity"]
