# tyk-sandbox

## Quickly create a sandbox image that runs a specific version of tyk.

* Should be really simple to get started on Linux and MacOS. 
* Checkout this repo.

## WSL setup

* Follow [this to setup your WSL](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly) to interface for docker desktop
* Checkout this repo and read the quickstart

### Quick start guide

Before creating a first sandbox image list the version the script knows about

	$ ./sbctl build -l
	Version:   3.2.1
		Gateway:   3.2.1-1
		Dashboard: 3.2.1-1
		Pump:      1.4.0-1
	Version:   3.1.2
		Gateway:   3.1.2-1
		Dashboard: 3.1.2-1
		Pump:      1.3.0-1
	etc ...

Create an image with for tyk 3.1.2

	$ ./sbctl build -v 3.1.2

List the available images

	$ ./sbctl images
	REPOSITORY    TAG       IMAGE ID       CREATED      SIZE
	tyk-sandbox   3.1.2-1   d78b2ca8c4a2   2 days ago   974MB

Create a sandbox from that image to begin testing/debugging
This sandbox is ready to connect to via a web browser within seconds

	$ ./sbctl create -v 3.1.2-1 -t myticket_number
	[INFO]Creating container sandbox-1
	7371a8690b34a8a4cc34965a181e9ae43d880b6969e9923cbba3819cd87cd733
	[INFO]Starting container sandbox-1
	sandbox-1 (running)
	sandbox.dashurl: http://10.0.0.21:3001/
	sandbox.gateurl: https://10.0.0.21:5001/
	sandbox.mongo: mongo --quiet --host 10.0.0.21 --port 7001
	sandbox.redis: redis-cli -h 10.0.0.21 -p 6001
	sandbox.ticket: myticket_number
	sandbox.version: 3.2.2-1


To remind ourselves of the details of this or other sandboxes later

	$ sbctl info 1
	sandbox-1 (running)
	sandbox.dashurl: http://10.0.0.21:3001/
	sandbox.gateurl: https://10.0.0.21:5001/
	sandbox.mongo: mongo --quiet --host 10.0.0.21 --port 7001
	sandbox.redis: redis-cli -h 10.0.0.21 -p 6001
	sandbox.ticket: myticket_number
	sandbox.version: 3.2.2-1

To get help on various options

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
	sbctl images [-r <image versions to remove|ALL]]
					list the docker images for creating sandboxes
					-r image version to remove|ALL. Removes the image version
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


### Other details
- All the images are based on a baseOS image called 'tbi' (Tyk Base Image) this is a centos 7 image with all the extras added that are either needed or handy to have in the sandboxes. It is build first when builds are done then reused for all subsequest images. This means that the first time a build is done it may take quite a bit longer, after that the builds are faster. How long depends on your machine and internet speeds plus the speed of the local mirrors for the yum repos used.

- The file in the host file system `~/.tyk-sandbox` can be populated with environment variables which are passed into any container created. 
	- If `SBX_LICENSE` is set then the dashboard will be bootstraped. 
	- If `SBX_USER` and `SBX_PASSWORD` are set then an admin user will be created with those login details. See `sbctl help` for details.
	- If `SBX_GW_CNAME` is set then `override_hostname` will be set to it in `/opt/tyk-dashboard/tyk_analytics.conf`
	- If `SBX_DSHB_CNAME` is set then `host_config.hostname` and `http_server_options.certificates.domain_name` will be set. Note that `http_server_options.certificates.domain_name` isn't used because the dashboard runs on http not https, but its there if someone needs to change to https.
	- If `SBX_PTL_CNAME` is set then the portal cname will be set when creating the organisation. Note that because `generate_secure_paths` is true the dashboard menu item 'OPEN YOUR PORTAL' will attempt to open it over https when it's only available on http. I don't see a way around this while keeping the gateway on https.

- A directory hierarchy under `~/tyk` in the host filesystem is also created. When a sandbox container is created a directory under `~/tyk/plugins` is created that matches the version specified in the sandbox and mounted within the sandbox under `/opt/tyk-plugins`. This allows easy loading of plugins into the tyk-sandbox from the host machine.

- Within the container the file `/initial_credentials.txt` is created with useful information like the orgid, licence and user details is created. It can be handy.

- Each sandbox also runs a python http server listening on localhost port 8000. This http server has a working directory of `/opt/tyk-plugins` and can be used to serve plugin bundles into the gateway. The gateway's `/opt/tyk-gateway/tyk.conf` already has `"bundle_base_url": "http://localhost:8000"` set so it's just a matter of putting the bundle in place and configuring the API.

- There are some scripts in the container under `/scripts`
	- `admin-auth` prints the admin auth code for an admin. Handy for scripts.
	- `dump-redis` formats and dumps the entire contents of redis. You can pass in a pattern to limit the results.
	- `start`, `stop` and `restart` can be used with the parameters `dashboard`, `gateway`, `pump`, `redis` or `mongo` to start, stop or restart those processes.

- Logs are kept under `/var/log`