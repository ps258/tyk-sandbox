# tyk-sandbox

## Quickly create a sandbox image that runs a specific version of tyk.

* Should be really simple to get started on Linux and MacOS. 
* Checkout this repo.

## WSL setup

* Follow [this to setup your WSL](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly) to interface for docker desktop
* Checkout this repo and read the quickstart

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

				$ sbctl info 1
				sandbox-1 (running)
				sandbox.dashurl: http://10.0.0.21:3001/
				sandbox.gateurl: https://10.0.0.21:5001/
				sandbox.mongo: mongo --quiet --host 10.0.0.21 --port 7001
				sandbox.redis: redis-cli -h 10.0.0.21 -p 6001
				sandbox.ticket: N/A
				sandbox.version: 3.2.2-1

To get help on various options

	$ sbctl -h
	[USAGE]:
		sbctl build -l | -v tyk-gateway-version-number [-r image version]
			builds a sandbox image for that version if its not already available
			-v version to build ('ALL' to build all versions)
			-l list versions that images can be made for (incompatible with -v and -r)
		sbctl create -v tyk-version [-t ticket no] [-i index-number] [-n]
			-i index number (skip for autoallocation of the next free)
			-l log level. Set to debug, info, warn or error. Defaults to debug
			-n IGNORE ~/.tyk-sandbox even if it exists
					 You can populate ~/.tyk-sandbox with values to bootstrap the sandbox with:
					 These will be used when -n is NOT present
					 SBX_LICENSE=licence string
					 SBX_USER=user email
					 SBX_PASSWORD=base64 encoded password
					 Note: create a base64 encoded password with:
					 echo password | base64
				-t ticket or comment field
				-v tyk version of sandbox image. Required
			sbctl images
				list the docker images for creating sandboxes
			sbctl list <index number...>
				details about the named sandbox or all
			sbctl publish api.json <index number...>
				 publish the API in api.json into the sandbox
			sbctl script scriptfile <index number...>
				copy the script into the container and run it
			sbctl shell <index number...>
				Open a bash shell in the sandboxes named
			sbctl [start|stop|restart|rm] <index number...>
				take the action named on the listed sandboxes



