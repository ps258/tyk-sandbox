# tyk-sandbox

## Quickly create a sandbox image that runs a specific version of tyk.

Should be really simple to get started on Linux and MacOS. Checkout this repo.

### Quick start guide

Before creating a first sandbox image list the version the script knows about

      % ./sbctl build -l
      Version:   3.2.1
          Gateway:   3.2.1-1
          Dashboard: 3.2.1-1
          Pump:      1.4.0-1
      Version:   3.1.2
          Gateway:   3.1.2-1
          Dashboard: 3.1.2-1
          Pump:      1.3.0-1
      Version:   3.1.1
          Gateway:   3.1.1-1
          Dashboard: 3.1.1-1
          Pump:      1.3.0-1
      Version:   3.0.6
          Gateway:   3.0.6-1
          Dashboard: 3.0.6-1
          Pump:      1.3.0-1
      Version:   3.0.5
          Gateway:   3.0.5-1
          Dashboard: 3.0.4-1
          Pump:      1.3.0-1
      Version:   3.0.4
          Gateway:   3.0.4-1
          Dashboard: 3.0.4-1
          Pump:      1.3.0-1
      Version:   3.0.3
          Gateway:   3.0.3-1
          Dashboard: 3.0.3-1
          Pump:      1.3.0-1
      Version:   3.0.2
          Gateway:   3.0.2-1
          Dashboard: 3.0.2-1
          Pump:      1.3.0-1
      Version:   3.0.1
          Gateway:   3.0.1-1
          Dashboard: 3.0.1-1
          Pump:      1.3.0-1
      Version:   2.9.5
          Gateway:   2.9.5-1
          Dashboard: 1.9.5-1
          TIB:       0.7.2-1
          Pump:      0.8.5.1-1
      Version:   2.9.4.3
          Gateway:   2.9.4.3-1
          Dashboard: 1.9.4.3-1
          TIB:       0.7.2-1
          Pump:      0.8.5.1-1
      Version:   2.8.7
          Gateway:   2.8.7-1
          Dashboard: 1.8.6-1
          TIB:       0.7.1-1
          Pump:      0.6.0-1

Create an image with for tyk 3.1.2

      % ./sbctl build -v 3.1.2
      [INFO]Pulled tyk-gateway-3.1.2-1.x86_64.rpm
      [INFO]Pulled tyk-dashboard-3.1.2-1.x86_64.rpm
      [INFO]Pulled tyk-pump-1.3.0-1.x86_64.rpm
      tyk-gateway-3.1.2-1.x86_64.rpm
      /Users/pstubbs/code/tyk-sandbox
      [+] Building 1.1s (15/15) FINISHED

List the available images

      % ./sbctl images
      REPOSITORY    TAG       IMAGE ID       CREATED      SIZE
      tyk-sandbox   3.1.2-1   d78b2ca8c4a2   2 days ago   974MB

Create a sandbox from that image to begin testing/debugging
This sandbox is ready to connect to via a web browser within seconds

      % ./sbctl create -v 3.1.2-1 -t myticket_number
      [INFO]Creating container sandbox-1
      7371a8690b34a8a4cc34965a181e9ae43d880b6969e9923cbba3819cd87cd733
      [INFO]Starting container sandbox-1
      sandbox-1
      sandbox-1
      sandbox.dashurl: http://192.168.0.79:3000/
      sandbox.gateurl: https://192.168.0.79:8080/
      sandbox.index: 1
      sandbox.label: sandbox-1
      sandbox.ticket: myticket_number
      sandbox.version: 3.1.2-1


To remind ourselves of the details of this or other sandboxes later

      % ./sbctl list
      sandbox-1
      sandbox.dashurl: http://192.168.0.79:3000/
      sandbox.gateurl: https://192.168.0.79:8080/
      sandbox.index: 1
      sandbox.label: sandbox-1
      sandbox.ticket: myticket_number
      sandbox.version: 3.1.2-1

To get help on various options

      % ./sbctl help
      [USAGE]:
      ./sbctl build -l | -v tyk-gateway-version-number [-r image version]
              builds a sandbox image for that version if its not already available
              -v version to build
              -r package revision
              -l list versions that images can be made for (incompatible with -v and -r)
      ./sbctl create -v tyk-version [-t ticket no] [-i index-number]
              -i index number (skip for autoallocation of the next free)
              -t ticket or comment field
              -v tyk version of sandbox image. Defaults to 'latest'
      ./sbctl images
              list the docker images for creating sandboxes
      ./sbctl list <index number...>
              details about the named sandbox or all
      ./sbctl script <index number...>
              run a shell in the sandboxes named
      ./sbctl [start|stop|restart|rm] <index number...>
              take the action named on the listed sandboxes

## WSL setup

* Follow [this to setup your WSL](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly) to interface for docker desktop
* Checkout this repo and read the quickstart
