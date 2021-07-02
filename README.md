# tyk-sandbox

# Quickly create a sandbox image that can be used to run different versions of tyk

## Quick start guide

    % cd assets/rpms/tyk
    % rm tyk*.rpm
    % ./get-rpms -g 3.1.2
    % cd ../../..
    % docker build --tag tyk-sandbox:3.1.2-1 .
    % ./up -v 3.1.2-1 -t ticket-number
    [INFO]Creating container sandbox-2
    9ec1c1da88c0f5e5803330e4e65de2302c3985118fe5aad88bedaa885a08974a
    [INFO]Starting container sandbox-2
    sandbox-2
    sandbox.dashurl: http://192.168.0.79:3001/
    sandbox.gateurl: https://192.168.0.79:8081/
    sandbox.index: 2
    sandbox.label: sandbox-2
    sandbox.ticket: ticket-number
    sandbox.version: 3.1.2-1
