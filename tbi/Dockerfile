ARG BASE_UBI=centos:8
FROM --platform=linux/amd64 $BASE_UBI

COPY baseOS /baseOS
ENV PATH=/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin/:/tyk-scripts/python:/tyk-scripts/bastion

RUN chmod +x /baseOS/os-setup && /baseOS/os-setup

ENTRYPOINT ["/usr/bin/sleep", "infinity"]
