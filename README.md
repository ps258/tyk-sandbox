# tyk-sandbox

# Quickly create a sandbox image that runs a specific version of tyk.

Should be really simple to get started on Linux and MacOS

## Quick start guide

List available images

    % ./sbctl images
    REPOSITORY    TAG       IMAGE ID       CREATED          SIZE
    tyk-sandbox   3.2.1     7a5e51190570   38 seconds ago   961MB
    tyk-sandbox   3.1.2-1   d78b2ca8c4a2   2 hours ago      974MB

Create a sandbox to work on a ticket

    % ./sbctl create -v 3.2.1 -t ticket
    [WARN]Creating ~/tyk/plugins/3.2.1: It will be empty
    [INFO]Creating container sandbox-1
    4ef23532f30969f1d08ab2b60a8c6a55dc0598f6dc11ab37e18360d3dcab8b1c
    [INFO]Starting container sandbox-1
    sandbox-1
    sandbox.dashurl: http://192.168.0.79:3000/
    sandbox.gateurl: https://192.168.0.79:8080/
    sandbox.index: 1
    sandbox.label: sandbox-1
    sandbox.ticket: ticket
    sandbox.version: 3.2.1

Grab the details of the sandbox to remind ourselves of the URLs and version

    % ./sbctl list 1
    sandbox-1
    sandbox.dashurl: http://192.168.0.79:3000/
    sandbox.gateurl: https://192.168.0.79:8080/
    sandbox.index: 1
    sandbox.label: sandbox-1
    sandbox.ticket: ticket
    sandbox.version: 3.2.1

Build a new sandbox image for gateway version 3.0.6

    % ./sbctl build -v 3.0.6
    ...
    => => writing image sha256:6cf6c207ceca1b9e431f7d87b67e551aa8035aa93fa12ab41f11ed13049da06d     0.0s
    => => naming to docker.io/library/tyk-sandbox:3.0.6

Read the fine help

    % ./sbctl help
    [USAGE]:
    ./sbctl create -v tyk-version -i index-number -h
            -i index number (skip for autoallocation of the next free)
            -t Ticket or comment field
            -v tyk version of sandbox image. Defaults to 'latest'
    ./sbctl [start|stop|restart|rm] <index number...>
            take the action named on the listed sandboxes
    ./sbctl images
            lists the available docker images for creating sandboxes
    ./sbctl build -v tyk-gateway-version-number
            builds a sandbox image for that version if its not already available
    ./sbctl list <index number...>
            gives details about the named sandbox or all

