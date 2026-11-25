# tyk-sandbox

Run a self-contained Tyk installation, at almost any released version, in a single Docker
container, in seconds.

`dsbctl` (docker sandbox control) is the command-line tool. It builds Docker images that hold a
specific set of Tyk component versions and creates **sandboxes** (containers named `sandbox-1`,
`sandbox-2`, …) from them. Each sandbox runs:

- Tyk Gateway (https)
- Tyk Dashboard
- Tyk Pump (to Mongo)
- Redis and MongoDB
- Tyk Identity Broker, the Enterprise Developer Portal and Tyk Sync, when the chosen version has
  them
- MDCB plus an edge gateway, if you add them later

It is built for support and engineering work: reproducing a customer issue on the exact version
they run, comparing behaviour between versions, and testing plugins or config changes.

### How it differs from Tyk's official Docker images

- **One container, whole stack.** No compose file and no network wiring. `docker exec` gives you
  a full OS shell next to every component.
- **RPM installs.** Components are installed from Tyk's packagecloud RPM repositories into the
  standard `/opt/tyk-*` locations, so the filesystem looks like a typical customer VM install.
- **Bootstrapped.** On first start a licence is applied, an organisation and admin user are
  created and sample APIs are published (when credentials are configured), so you can log in
  straight away.
- **Many in parallel.** Each sandbox gets its own block of host ports, and every detail is
  stored in container labels, so `dsbctl info` can always tell you how to reach it.

> **Security note:** sandboxes are for test machines. Redis and Mongo have no authentication
> and their ports are published on every host interface, together with the dashboard and
> gateway. The default secrets are well known. Don't run sandboxes on a host reachable from
> untrusted networks, and don't put real customer data in them.

---

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration: ~/.tyk-sandbox](#configuration-tyk-sandbox)
- [Quick start](#quick-start)
- [Concepts](#concepts)
- [Command reference](#command-reference)
- [Inside a sandbox](#inside-a-sandbox)
- [Common tasks](#common-tasks)
- [Adding a new Tyk version](#adding-a-new-tyk-version)
- [Running on AWS EC2](#running-on-aws-ec2)
- [WSL setup](#wsl-setup)
- [Troubleshooting](#troubleshooting)
- [Customising the images](#customising-the-images)
- [AI coding agents](#ai-coding-agents)

---

## Requirements

- Linux or macOS (or Windows with WSL, see [WSL setup](#wsl-setup)).
- Docker, with the current user able to run `docker` without sudo.
- `ksh`, because `dsbctl` is a Korn shell script. It is preinstalled on macOS. On Linux install
  it with `apt install ksh` or `dnf install ksh`.
- On Linux, `ip` (iproute2), used to find the host's IP address.
- Disk space: each image is roughly 1.5–3 GB.
- Internet access during image builds (packagecloud, the MongoDB repositories, the OS mirrors).
- Optional on the host: `redis-cli`, `mongosh`/`mongo`, `jq`, `curl`.

Apple Silicon: images build and run, but tyk-sync is skipped on non-x86 hosts.

## Installation

```sh
git clone <this repo> ~/code/tyk-sandbox
export PATH="$PATH:$HOME/code/tyk-sandbox"      # add to ~/.bashrc or ~/.zshrc
dsbctl help
```

`dsbctl` works out where it lives and finds `tyk-versions.list`, the `Dockerfile` and the rest
of the repo relative to itself, so it can be run from any directory.

## Configuration: `~/.tyk-sandbox`

If `~/.tyk-sandbox` exists, it is passed to every new sandbox as a Docker `--env-file` (unless
you use `create -n`). It is the place for a dashboard licence and default admin credentials, so
that sandboxes come up ready to use.

```sh
SBX_LICENSE=eyJhbGciOi...            # Tyk Dashboard licence. Applied at first start
SBX_USER=me@example.com              # admin user to create
SBX_PASSWORD=Y2hhbmdlbWUK            # that user's password, base64 encoded: echo 'changeme' | base64
SBX_MDCB_LICENSE=eyJhbGciOi...       # optional: MDCB licence, used by 'dsbctl mdcb'
SBX_HOST_ENTRIES=$SBX_HOST_IP_ADDR:httpbin.org   # optional: extra /etc/hosts entries, see below
SBX_GW_CNAME=gw.example.test         # optional: hostname to advertise for the gateway
SBX_DSHB_CNAME=dash.example.test     # optional: hostname for the dashboard
SBX_PTL_CNAME=portal.example.test    # optional: classic portal CNAME for the org
```

What each variable does:

| Variable | Effect |
|---|---|
| `SBX_LICENSE` | Posted to the dashboard's `/license` endpoint. Also used as the Developer Portal licence. Without it you'll get the dashboard licence screen |
| `SBX_USER` + `SBX_PASSWORD` | When both are set, an organisation (`Default Org.`) and an admin user are created, the admin user's API key is saved, and the sample APIs are published. Without them you must bootstrap through the dashboard UI or API yourself, and `dsbctl get N key` / `org` will return nothing |
| `SBX_MDCB_LICENSE` | Written into `tyk_sink.conf` by `dsbctl mdcb` |
| `SBX_HOST_ENTRIES` | Comma-separated `ip:name:alias,…` entries appended to the container's `/etc/hosts` at every start. `$SBX_HOST_IP_ADDR` (the Docker host's IP) is expanded inside the container |
| `SBX_GW_CNAME` | Used as the dashboard's `host_config.override_hostname` (the gateway address it shows) and added to the generated certificate's SAN and CN |
| `SBX_DSHB_CNAME` | Used as `host_config.hostname` (and `certificates.domain_name`), and added to the certificate SAN |
| `SBX_PTL_CNAME` | Set as the organisation's portal CNAME when it is created; added to the certificate SAN. The dashboard's "Open your portal" link uses https while the portal is served over http, so expect to edit the URL |

The file is a licence store, so keep it `chmod 600`.

**Tip: keeping test traffic local.** The sample APIs proxy to `http://httpbin.org`. Run a local
httpbin on the host, then point `httpbin.org` at the host for every sandbox:

```sh
docker run -d --name httpbin --restart unless-stopped -p 80:80 kennethreitz/httpbin
echo 'SBX_HOST_ENTRIES=$SBX_HOST_IP_ADDR:httpbin.org' >> ~/.tyk-sandbox
```

## Quick start

```sh
# 1. What versions can be built?
dsbctl build -l | head -20

# 2. Create a sandbox for 5.8.20. If there is no image yet, it is built first
#    (several minutes the first time, more if the base image also needs building)
dsbctl create -v 5.8.20 -t "TT-12345 rate limit repro"
```

```
[INFO]Creating container sandbox-1
[INFO]Starting container sandbox-1
sandbox-1 (running)
sandbox.dashurl: http://192.168.1.20:3001/
sandbox.edpurl: http://192.168.1.20:3101/
sandbox.gateurl: https://192.168.1.20:5001/
sandbox.mongo: mongo --quiet --host 192.168.1.20 --port 7001
sandbox.redis: redis-cli -h 192.168.1.20 -p 6001
sandbox.ticket: TT-12345 rate limit repro
sandbox.version: 5.8.20-1
```

```sh
# 3. Bootstrap takes 10–30 seconds. Then get the full details, including org id and admin key
dsbctl info 1

# 4. Use it
GW=$(dsbctl get 1 gateway); DASH=$(dsbctl get 1 dashboard); KEY=$(dsbctl get 1 key)
curl -sk ${GW}httpbin/get                          # sample keyless API
curl -s -H "Authorization: $KEY" ${DASH}api/apis | jq '.apis[].api_definition.name'
docker exec -it sandbox-1 bash                     # or: dsbctl shell 1

# 5. Tidy up
dsbctl delete 1
```

Log in to the dashboard at the `dashurl` with `SBX_USER` and the password you base64-encoded.

---

## Concepts

### Versions (refNo)

`tyk-versions.list` maps a **refNo** to the RPM version of every component released alongside
it:

```
#refNo,tyk-gateway,tyk-dashboard,tyk-pump,tyk-identity-broker,tyk-sync,tyk-mdcb,tyk-portal
5.8.20,5.8.20-1,5.8.20-1,1.18.0-1,1.8.4-1,2.3.0-1,2.14.0-1,1.20.0-1
5.13.0_ee,ee-5.13.0-1,5.13.0-1,1.15.0-1,1.7.2-1,2.1.8-1,2.11.0-1,1.17.2-1
```

- The refNo is usually the gateway version. Variants use a suffix: `_ee` for the EE gateway
  build, `_fips` for FIPS builds of everything.
- Empty fields mean "don't install". For example, older releases have no portal.
- The file also records which component versions were current at each release, so it's useful
  even when you aren't building.
- `dsbctl build -l` lists every row except the `_ee`/`_fips` ones. `dsbctl build -l 5.8.20` shows
  a single row, including variants.

The MDCB column is for reference only. MDCB isn't installed at build time; see
[`dsbctl mdcb`](#mdcb).

### Images and revisions

Images are tagged `tyk-sandbox:<refNo>-<rev>`, e.g. `tyk-sandbox:5.8.20-1`. Rebuilding the same
refNo creates `-2`, `-3` and so on (useful after changing `assets/` or `scripts/`). Wherever an
image version is expected you can give just the refNo (`5.8.20`), which means the highest local
revision, or pin one (`5.8.20-1`).

All images build on a base image, the **TBI** (Tyk Base Image), built from `tbi/`. It holds the
OS, MongoDB, Redis, Python and tools, and is built automatically the first time it is needed:

| Tyk versions | Base OS | TBI tag | MongoDB repo |
|---|---|---|---|
| 2.x, 3.x | CentOS 7 | `saintpeter/tbi7` | 4.4 |
| 4.x, 5.0.x | AlmaLinux 8 | `saintpeter/tbi8` | 5.0 |
| 5.1 and later | AlmaLinux 9 | `saintpeter/tbi9` | 7.0 |

### Sandbox index and ports

Each sandbox has an index N, the lowest free number unless you pass `-i`. Host ports are a base
port plus (N − 1):

| Service | Host port (sandbox 1, 2, 3 …) | Container port | Protocol |
|---|---|---|---|
| Dashboard | 3001, 3002, 3003 … | 3000 | http |
| Gateway | 5001, 5002, 5003 … | 443 | **https** (self-signed) |
| Redis | 6001, 6002 … | 6379 | no auth |
| MongoDB | 7001, 7002 … | 27017 | no auth, db `tyk_analytics` |
| Developer Portal | 3101, 3102 … | 3001 | http (if the version has one) |
| Identity Broker | 4001, 4002 … | 3010 | http (2.x images only) |

URLs use the host's primary IP address (the interface of the default route), so they work from
other machines on your network too.

Wherever a sandbox is expected, any command accepts `3` or `sandbox-3`, and most accept several,
e.g. `dsbctl stop 2 3 5`.

### Labels

Everything `dsbctl` knows about a sandbox lives in its Docker labels (`sandbox.version`,
`sandbox.dashurl`, `sandbox.gateurl`, `sandbox.ticket`, `sandbox.redis`, `sandbox.mongo`,
`sandbox.mode`, …). `dsbctl` keeps no state of its own, so ordinary `docker` commands are safe to
mix in:

```sh
docker container inspect sandbox-1 --format '{{json .Config.Labels}}' | jq
```

---

## Command reference

Run `dsbctl` or `dsbctl help` for the built-in summary.

### build

```
dsbctl build -l [refNo]       # list buildable versions (or one version's components)
dsbctl build -v <refNo>       # build tyk-sandbox:<refNo>-<next rev>
dsbctl build -v all           # build every version in the list. Takes hours and lots of disk
```

Builds use `--no-cache` so the RPMs are always fetched fresh. The base TBI image is built first
if it isn't present locally. Output is shown in `--progress=plain` form.

### images

```
dsbctl images                         # list tyk-sandbox images
dsbctl images -r 5.8.15-1 5.8.17-1    # remove specific images
dsbctl images -r all                  # remove all tyk-sandbox images
```

### create

```
dsbctl create -v <refNo[-rev]> [-t "description"] [-i N] [-s] [-d] [-n] [-E envfile] [-l level]
```

| Option | Meaning |
|---|---|
| `-v` | Image version (required). If the image doesn't exist, it is built first |
| `-t` | Free-text description, e.g. ticket number and purpose. Shown by `info`. Defaults to `N/A` |
| `-i` | Use this index instead of the next free one |
| `-s` | Standalone (CE) gateway: only Redis and the gateway are started, with `tyk-CE.conf`, file-based APIs/policies and nothing preloaded |
| `-d` | Don't publish the sample APIs from `assets/APIs/*.json` |
| `-n` | Ignore `~/.tyk-sandbox`: no licence, org or user. Useful for testing bootstrap or licence handling yourself |
| `-E file` | An extra `--env-file`. Variables reach every Tyk process, so `TYK_GW_*`, `TYK_DB_*`, `TYK_PMP_*` overrides work |
| `-l` | `TYK_LOGLEVEL`: `debug` (default), `info`, `warn` or `error` |

Configuration happens at **first start**: config templates are copied into place, certificates
generated, and the dashboard bootstrapped. Stopping and starting a sandbox keeps all its state.

### info / list

```
dsbctl info [N ...]           # all sandboxes if none given. 'list' is identical
```

Shows status, URLs, Redis/Mongo connection commands, the description and, for running
dashboard sandboxes, the org id and admin API key.

### get

Prints a single value, for use in scripts:

```
dsbctl get N <field>
```

| Field | Value |
|---|---|
| `key` | Admin user's dashboard API key (`Authorization:` header) |
| `admin_secret` | Dashboard admin secret (`admin-auth:` header for `/admin/*`) |
| `secret` | Gateway API secret (`x-tyk-authorization:` header for `/tyk/*`) |
| `org` | Organisation id |
| `dashboard` | Dashboard URL |
| `gateway` | Gateway URL |
| `desc` | Description (`-t`) |
| `version` | Image version |
| `redis` | `-h <host> -p <port>`, ready to append to `redis-cli` |
| `mongo` | `--host <host> --port <port>`, ready to append to `mongosh`/`mongo` |

`key`, `admin_secret`, `secret` and `org` read from inside the container, so it must be running.

### publish

```
dsbctl publish <file> N [N ...]
```

Copies an API definition into each sandbox and creates it through the dashboard API. The format
is detected automatically:

- Tyk OAS, JSON or YAML (detects `x-tyk-api-gateway`, or an `{"oas": …}` wrapper) → `/api/apis/oas`
- Plain OpenAPI YAML → `/api/apis/oas/import`
- A classic payload containing `api_definition` → `/api/apis`
- A raw classic definition, e.g. a dashboard export → wrapped, then `/api/apis`

There is one file per call. Needs a dashboard and the bootstrapped admin user. More examples are
in `assets/APIs/samples/`.

### script

```
dsbctl script ./setup.sh N [N ...]
```

Copies an executable script to `/` in each running sandbox and runs it. Handy for repeatable
repro setup.

### shell

```
dsbctl shell N                # interactive bash (alias: bash). Same as docker exec -it sandbox-N bash
```

### mdcb

```
dsbctl mdcb tyk-sink-2.7.1 N
```

Turns a sandbox into an MDCB control plane with a local edge (data plane) gateway:

1. yum-installs the named MDCB RPM. It tries the stable repo first, then unstable. Only versions
   in packagecloud can be installed.
2. Writes `tyk_sink.conf` with `SBX_MDCB_LICENSE` and enables hybrid mode on every org.
3. Moves the original (management) gateway to port 444. Starts an edge gateway from
   `/opt/tyk-gateway/tyk.conf-rpc` on 443, with its own Redis on 6380.

The sandbox's published gateway URL now reaches the **edge** gateway. The `dump-redis` helper is
renamed to `dump-control-redis` and `dump-edge-redis`. This can't be undone; create a fresh
sandbox to go back.

### start / stop / restart / delete / rm

```
dsbctl stop N ...       dsbctl start N ...       dsbctl restart N ...
dsbctl delete N ...     # docker rm -f: removes the sandbox even if running. 'all' removes every sandbox
dsbctl rm N ...         # docker rm: only removes stopped sandboxes
```

Deleting removes the container and everything in it. Plugin directories under `~/.tyk/plugins`
are kept.

---

## Inside a sandbox

| What | Where |
|---|---|
| Gateway | `/opt/tyk-gateway/` (`tyk.conf`, `apps/`, `policies/`, `middleware/`) |
| Dashboard | `/opt/tyk-dashboard/tyk_analytics.conf` |
| Pump | `/opt/tyk-pump/pump.conf` (mongo, mongo-aggregate and mongo-selective pumps) |
| Developer Portal | `/opt/portal/portal.conf` (SQLite) |
| Identity Broker | `/opt/tyk-identity-broker/tib.conf` |
| MDCB | `/opt/tyk-sink/tyk_sink.conf` (after `dsbctl mdcb`) |
| Tyk Sync | `/opt/tyk-sync/` (on `PATH`) |
| Certificates | `/opt/tyk-certificates/`: self-signed cert/key used by the gateway |
| Logs | `/var/log/`: `tyk-gateway.log`, `tyk-dashboard.log`, `tyk-pump.log`, `tyk-portal.log`, `tyk-identity-broker.log`, `tyk-sink.log`, `mongod.log`, `init-dashboard.log`, `plugin-server.log`, `tyk-dashboard-security_audit.log` |
| Bootstrap results | `/initial_credentials.txt`: licence, org id, user and admin API key |
| Plugin directory | `/opt/tyk-plugins`, mounted from the host's `~/.tyk/plugins/<image-version>/` |

Notable defaults in the supplied configs:

- Gateway: listens on 443 with TLS, policies from the dashboard (`policy_source: service`),
  analytics on, JSVM and Python coprocess on, hashed key listing on, access logs on.
  `bundle_base_url` is `http://localhost:8000` and the bundle downloader is enabled.
- Secrets: gateway `secret` is `Secret`, `node_secret` is `shared_node_secret`, dashboard
  `admin_secret` is `admin_secret`.
- Dashboard: plain http on 3000, the `mongo-go` driver, ownership and Open Policy enabled, CSRF
  "allow missing origin" enabled.
- Environment: `TYK_LOGLEVEL` from `create -l`, `GODEBUG=gctrace=1` (GC traces in gateway
  logs), and `TYK_GW_OPENTELEMETRY_RESOURCENAME=sandbox-N`. Bash history is kept in
  `/.bash_history`.
- `host.docker.internal` resolves to the Docker host.

### Helper scripts (`/scripts`, on `PATH`)

| Script | Purpose |
|---|---|
| `start` / `stop` / `restart <service ...>` | Control `gateway`, `dashboard`, `pump`, `redis`, `mongo`, `tib`, `portal`, `mdcb`/`sink`. There is no systemd; processes run in the background from these scripts |
| `admin-auth` | Print an admin user's dashboard API key |
| `dump-redis [pattern ...]` | Dump Redis keys with type, TTL and pretty-printed JSON. E.g. `dump-redis 'apikey-*'`. Takes `-h`, `-p`, `-a` |
| `publish-apis <file ...>` | What `dsbctl publish` runs |
| `upgrade-gateway.sh <ver>` (also `-dashboard`, `-pump`, `-portal`) | Install another version alongside the current one and switch to it. Running it again with an installed version switches back |
| `enable-hybrid.sh` | Set `hybrid_enabled` on every org |
| `ci <file>` | Lightweight versioning: keeps a timestamped copy in `.revisions/` next to the file, with `.latest`/`.previous` links. The start scripts run it on their config each time, so you get a history of your edits |
| `cols` | Align whitespace-separated output into columns |

---

## Common tasks

### Change a config and restart a component

```sh
docker exec -it sandbox-1 bash
vi /opt/tyk-gateway/tyk.conf
restart gateway
tail -f /var/log/tyk-gateway.log
```

To compare with an earlier version of the file:
`diff /opt/tyk-gateway/.revisions/tyk.conf.previous /opt/tyk-gateway/tyk.conf`.

### Override settings with environment variables

```sh
cat > /tmp/env.list <<'EOF'
TYK_GW_HTTPSERVEROPTIONS_ENABLEHTTP2=true
TYK_DB_NOTIFYONCHANGE=false
EOF
dsbctl create -v 5.8.20 -E /tmp/env.list -t "http2 test"
```

### Load a plugin bundle

The host directory `~/.tyk/plugins/<image-version>/` (created on first use) is mounted at
`/opt/tyk-plugins` and served on `http://localhost:8000` inside the sandbox. The gateway's
`bundle_base_url` already points there.

```sh
cp bundle.zip ~/.tyk/plugins/5.8.20-1/
# then set  "custom_middleware_bundle": "bundle.zip"  in the API definition
```

Go plugins and Python/JS middleware files can also be placed there and referenced by their path
under `/opt/tyk-plugins/`. Every sandbox created from the same image version shares the
directory.

### Talk to Redis and Mongo from the host

```sh
redis-cli $(dsbctl get 1 redis) --scan --pattern 'apikey-*'
mongosh $(dsbctl get 1 mongo) tyk_analytics --eval 'db.tyk_apis.countDocuments()'
```

Or from inside, where the clients match the server version:
`docker exec sandbox-1 redis-cli keys '*'`.

### Upgrade a component in place

```sh
docker exec sandbox-1 upgrade-gateway.sh 5.8.21
docker exec sandbox-1 upgrade-gateway.sh 5.8.20     # switch back
```

This is useful for checking whether an upgrade fixes or breaks something while keeping the same
data.

### Test a standalone (open-source) gateway

```sh
dsbctl create -v 5.8.20 -s -t "CE file-based"
docker exec -it sandbox-1 bash
cd /opt/tyk-gateway/apps    # add API definitions, then
restart gateway             # or: curl -k -H 'x-tyk-authorization: <secret>' https://localhost/tyk/reload
```

### Compare two versions side by side

```sh
dsbctl create -v 5.3.0 -t "TT-12345 before"
dsbctl create -v 5.8.20 -t "TT-12345 after"
for n in 1 2; do dsbctl publish ./customer-api.json $n; done
```

---

## Adding a new Tyk version

1. Find the RPM versions released together. The package lists on packagecloud
   (`tyk/tyk-gateway`, `tyk/tyk-dashboard`, `tyk/tyk-pump`, …) and Tyk's release notes are the
   sources.
2. Add a row to `tyk-versions.list` under the matching `# X.Y` heading, newest first:
   ```
   5.8.21,5.8.21-1,5.8.21-1,1.18.0-1,1.8.4-1,2.3.0-1,2.14.0-1,1.20.0-1
   ```
   The refNo **must not contain `-`**, because it becomes part of the image tag (`5.8.21rc1` is
   fine, `5.8.21-rc1` isn't). Use `_ee` / `_fips` suffixes for variants, with the `ee-` / `fips-`
   prefixed RPM versions.
3. Check it with `dsbctl build -l 5.8.21`, then `dsbctl build -v 5.8.21`.

If an RPM version doesn't exist, the build's `yum install` fails and you'll see it in the build
output.

## Running on AWS EC2

On an EC2 instance the host IP that dsbctl detects is the instance's private VPC address, which
you usually can't reach from your laptop. dsbctl detects EC2 (by checking the DMI board vendor)
and adds an SSH tunnelling command to the end of each sandbox's block in `dsbctl info`:

```
ssh -g -L localhost:3001:10.0.1.23:3001 -L localhost:5001:10.0.1.23:5001 -L localhost:3101:10.0.1.23:3101 <aws hostname>
```

- Run it **on your laptop**, replacing `<aws hostname>` with the instance's public DNS name or
  your ssh config alias. Then browse to `http://localhost:3001/` and `https://localhost:5001/`.
- It forwards the URL-type ports: dashboard, gateway, portal and TIB. Add
  `-L localhost:6001:<ip>:6001` etc. yourself if you need Redis or Mongo.
- `-g` lets other machines on your network use the tunnel too.
- Standalone (`-s`) sandboxes don't get a tunnel command.
- The dashboard's configured hostnames are still the private IP, so addresses shown inside the
  dashboard UI will show it. Set `SBX_GW_CNAME` / `SBX_DSHB_CNAME` if that matters.

## WSL setup

- Follow
  [this guide to set up WSL](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly)
  to work with Docker Desktop.
- Install `ksh` in your WSL distribution, clone this repo inside WSL, then follow the
  [Quick start](#quick-start).

---

## Troubleshooting

| Symptom | Things to check |
|---|---|
| `dsbctl get N key` is empty | Bootstrap still running (wait 10–30 s), or `SBX_USER`/`SBX_PASSWORD` missing from `~/.tyk-sandbox`, or `create -n` was used. Look at `docker exec sandbox-N cat /var/log/init-dashboard.log` |
| Dashboard asks for a licence | `SBX_LICENSE` missing or expired |
| Sample APIs return 5xx | Upstream `httpbin.org` unreachable. Is the local httpbin container running, and is `SBX_HOST_ENTRIES` set? Check `docker exec sandbox-N getent hosts httpbin.org` |
| A component isn't running | `docker exec sandbox-N tail -100 /var/log/tyk-<component>.log`, then `docker exec sandbox-N start <component>` |
| `create` fails on ports | Another process or a non-dsbctl container holds that port block. Use `-i` to pick another index |
| Build fails at `yum install` | The RPM version in `tyk-versions.list` doesn't exist in packagecloud, or the repository or mirror is unavailable. Retry, or fix the row |
| Change to `assets/` or `scripts/` has no effect | Existing images and sandboxes keep the old files. Rebuild (`dsbctl build -v X` makes a new rev) and create a new sandbox |
| Change to `tbi/` has no effect | The base image is reused if present. `docker image rm saintpeter/tbi9:latest` (or tbi7/tbi8), then build again |
| Wrong IP in URLs | dsbctl uses the default-route interface. Sandboxes created while on another network keep the old IP in their labels and config; recreate them |

## Customising the images

| To change | Edit | Takes effect |
|---|---|---|
| Default Tyk configs | `assets/*.conf` | New images (rebuild), new sandboxes |
| Sample APIs published at bootstrap | `assets/APIs/*.json` | New images |
| Startup and bootstrap behaviour | `scripts/entrypoint.sh`, `scripts/init-dashboard.sh` | New images |
| OS packages and tools | `tbi/baseOS/os-setup` | After removing the TBI image and rebuilding |
| Yum repositories | `tbi/baseOS/repos/` | After removing the TBI image and rebuilding |

Config templates contain placeholders (`SBX_GW_HOST`, `SBX_GW_PORT`, `SBX_DSHB_HOST`,
`SBX_DSHB_PORT`, `SBX_LICENSE`, `SBX_ORG_ID`, …) that `entrypoint.sh` and `init-mdcb.sh` fill in
with `sed` at first boot. See `AGENTS.md` for more on the repo's internals and conventions.

## AI coding agents

Two files help AI coding agents such as Claude Code or Codex work with this tool. They split the
job in two: one is for changing the repo, the other for using `dsbctl`.

- **`AGENTS.md`** (in this repo) is for agents that **change the repo**. It covers how the build,
  create and first-boot steps fit together, the coding conventions, how to check changes, and
  safety rules: never expose licences, only delete sandboxes you created. Many agent tools read
  `AGENTS.md` automatically. It's also a useful short summary of the internals for people.
- **The `dsbctl` skill** is a Claude Code skill for **using** `dsbctl`: creating sandboxes,
  getting URLs and keys, publishing APIs, loading plugins and tunnelling from EC2. With it,
  Claude Code can spin up a sandbox at a given version or tear one down when asked in plain
  language. It lives in this repo at `skills/SKILL.md`. Claude Code doesn't load it from there
  automatically. Install it for your user with
  `mkdir -p ~/.claude/skills/dsbctl && cp skills/SKILL.md ~/.claude/skills/dsbctl/`, or make it
  a project skill by placing it at `.claude/skills/dsbctl/SKILL.md`.

Both assume the same safety rules as this README: `~/.tyk-sandbox` holds licences and is never
printed, and other people's sandboxes are left alone.
