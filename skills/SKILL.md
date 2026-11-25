---
name: dsbctl
description: Build, create, inspect, drive and delete Tyk docker sandboxes (single containers named sandbox-N running gateway, dashboard, pump, Redis, Mongo, optional TIB/EDP/MDCB) with the dsbctl script from ~/code/tyk-sandbox. Use whenever asked to spin up / reproduce on / tear down a Tyk install in docker (not k8s/helm — that's hsbctl) at a given Tyk version, to build a tyk-sandbox image, to get a sandbox's dashboard/gateway URL, admin key, org id, gateway secret or Redis/Mongo connection, to shell into or run a script in a sandbox, to publish test APIs, to add MDCB + an edge gateway, to load a plugin bundle, or to add a new version row to tyk-versions.list.
---

# dsbctl — Tyk docker sandbox control

`dsbctl` (ksh script, on PATH, source at `~/code/tyk-sandbox/dsbctl`; alias `ds`) runs a whole
Tyk stack inside **one docker container per sandbox**: `sandbox-1`, `sandbox-2`, … built from
local images `tyk-sandbox:<refNo>-<rev>` (e.g. `tyk-sandbox:5.8.20-1`). Components are installed
from packagecloud RPMs, not the official docker images, so the container is a full OS
(AlmaLinux/CentOS) with bash, curl, jq, redis-cli, mongo shell, etc.

For the Kubernetes/helm equivalent use the `hsbctl` skill. Pick dsbctl when the user says
"docker sandbox", "dsbctl", "sandbox-N", or wants a quick single-box repro / RPM-style install.

It is a personal test tool. When behaviour is unclear, read the script — the `case $1 in`
dispatcher at the end is the source of truth; `help`/README are slightly stale (see "Gotchas").

## Environment facts

- `~/.tyk-sandbox` is passed to every container as `--env-file` (unless `create -n`). Holds
  `SBX_LICENSE`, `SBX_MDCB_LICENSE`, `SBX_USER`, `SBX_PASSWORD` (base64), CNAME vars and
  `SBX_HOST_ENTRIES`. **It contains licences — never cat/print it**; grep a single non-secret key.
- `SBX_HOST_ENTRIES=$SBX_HOST_IP_ADDR:httpbin.org` → inside sandboxes `httpbin.org` resolves to
  the host, where an `httpbin` container listens on :80. The sample APIs (`/httpbin/`, `/echo/`)
  target `http://httpbin.org/...`, so test traffic stays local. If the httpbin container isn't
  running (`docker ps --filter name=httpbin`), those APIs will fail.
- Host IP = address of the default-route interface. Ports per sandbox index N (offset N-1):

  | Service | Host port | Container port | Notes |
  |---|---|---|---|
  | Dashboard | 3001+off | 3000 | http |
  | Gateway | 5001+off | 443 | **https, self-signed → `curl -k`** |
  | Redis | 6001+off | 6379 | no password |
  | Mongo | 7001+off | 27017 | db `tyk_analytics`, no auth |
  | EDP (portal) | 3101+off | 3001 | only if row has an EDP version |
  | TIB | 4001+off | 3010 | only 2.x images |

- Plugins: host `~/.tyk/plugins/<image-version>/` (e.g. `~/.tyk/plugins/5.8.20-1/`) is mounted at
  `/opt/tyk-plugins` and served by `python3 -m http.server` on `localhost:8000` inside the
  container. tyk.conf already has `bundle_base_url: http://localhost:8000` and the bundle
  downloader enabled — drop the bundle zip in that host dir and reference it by name.
- Secrets in the default config: gateway `secret` = `Secret`, `node_secret` =
  `shared_node_secret`, dashboard `admin_secret` = `admin_secret`. Gateway listens on 443 (444
  after `mdcb`).
- Running on an EC2 instance changes how URLs are reached — see "Running on AWS EC2" below.

## Sandbox arguments

Commands take `3` or `sandbox-3`; several may be given. `list`/`info`/`delete`/`stop`… accept
`all`/`ALL`. `shell`, `script`, `publish`, `mdcb` require explicit names (or `all` = running only).

## Commands

### Versions & images
```
dsbctl build -l                 # all known refNos with component versions (hides _ee/_fips rows)
dsbctl build -l 5.8.20          # one row
dsbctl images                   # local tyk-sandbox images
dsbctl build -v 5.8.20          # build tyk-sandbox:5.8.20-<next rev>
dsbctl images -r 5.8.15-1       # remove an image (or 'all')
```
Versions come from `~/code/tyk-sandbox/tyk-versions.list`, format
`refNo,gateway,dashboard,pump,tib,sync,mdcb,portal` (RPM versions like `5.8.20-1`; empty fields
allowed; `#` lines are comments). refNo must not contain `-`. `_ee` / `_fips` suffixes give EE/FIPS
RPMs (e.g. gateway `ee-5.13.0-1`). Check with `grep '^5.8.20,' ~/code/tyk-sandbox/tyk-versions.list`.
To add a version, copy the nearest row, adjust versions, put it under the right heading (the git
history has many `tyk-versions.list: added X` commits — follow that style if committing).

Base image: a `tbi` image (`saintpeter/tbi7` for 2.x/3.x, `tbi8` for 4.x/5.0.x, `tbi9` for
5.1+) is built from `tbi/` first if missing. Builds use `--no-cache` and take several minutes
(longer if the tbi must be built) — **run in the background**. `build -v all` builds every row;
don't do that unless asked.

### create
```
dsbctl create -v <refNo|refNo-rev> -t "<description>" [options]
```
- `-v 5.8.20` uses the highest local rev; `-v 5.8.20-1` pins one. **If no image exists, create
  builds it first** (slow → background it).
- Always give `-t` a meaningful description (ticket + purpose) — it's how sandboxes are identified.

| Option | Meaning |
|---|---|
| `-t text` | description, stored as label `sandbox.ticket` |
| `-i N` | explicit index (default: next free) |
| `-s` | standalone CE gateway only (no dashboard/mongo/pump; gateway uses `tyk-CE.conf`, empty apps/policies) |
| `-d` | don't publish the sample APIs from `assets/APIs/*.json` |
| `-n` | ignore `~/.tyk-sandbox` → no licence, no org, no admin user (bootstrap manually) |
| `-E file` | extra `--env-file` (e.g. `TYK_GW_*` / `TYK_DB_*` / `TYK_PMP_*` overrides) |
| `-l debug\|info\|warn\|error` | `TYK_LOGLEVEL` (default debug) |

The container is started immediately; the entrypoint then starts redis, mongo, dashboard,
bootstraps (licence, org "Default Org.", admin user `$SBX_USER`, sample APIs), then pump, TIB/EDP
if present, then gateway. Allow ~10–30 s after create before the dashboard/admin key are ready;
poll `dsbctl get N key` until it returns non-empty. Bootstrap log: `/var/log/init-dashboard.log`.

### info / list
```
dsbctl info [N...]     # status, version, URLs, redis/mongo commands, ticket, OrgId, AdminKey
```
With no args covers all sandboxes. Output includes the admin key — fine locally, redact before
sharing.

### get — single values for scripting
```
dsbctl get N key|admin_secret|secret|dashboard|gateway|desc|org|mongo|redis|version
```
`key` = dashboard admin user API key (from Redis), `admin_secret` = dashboard admin secret,
`secret` = gateway secret, `mongo`/`redis` = `--host H --port P` / `-h H -p P` args.
Examples:
```
KEY=$(dsbctl get 1 key); DASH=$(dsbctl get 1 dashboard); GW=$(dsbctl get 1 gateway)
curl -s -H "Authorization: $KEY" ${DASH}api/apis | jq '.apis[].api_definition.name'
curl -sk ${GW}httpbin/get
curl -sk -H "x-tyk-authorization: $(dsbctl get 1 secret)" ${GW}tyk/apis | jq length
redis-cli $(dsbctl get 1 redis) --scan --pattern 'apikey-*'
```
`key`, `org`, `admin_secret`, `secret` exec into the container — it must be running.

### publish — load API definitions into the dashboard
```
dsbctl publish api.json N [N...]     # one file per call
```
Copies the file in and runs `/scripts/publish-apis`, which handles Tyk OAS (JSON/YAML, detects
`x-tyk-api-gateway` or an `oas` wrapper), plain OAS YAML (import), classic `api_definition`
payloads and raw dashboard exports. Needs a dashboard (not `-s`). Extra samples live in
`~/code/tyk-sandbox/assets/APIs/samples/`.

### script / shell — running things inside
```
dsbctl script ./myscript.sh N...     # docker cp to /<name> and exec it (must be executable, has a shebang)
dsbctl shell N                       # interactive bash — NOT usable by an agent
```
As an agent prefer `docker exec sandbox-N bash -c '...'` directly. Useful in-container bits
(`/scripts` is on PATH):
- `start|stop|restart dashboard|gateway|pump|redis|mongo|tib|portal|mdcb|sink`
- `admin-auth` (admin key), `dump-redis [pattern...]` (pretty dump), `enable-hybrid.sh`,
  `upgrade-gateway.sh 5.8.21` / `upgrade-dashboard.sh` / `upgrade-pump.sh` / `upgrade-portal.sh`
  (yum-install another version and switch the symlink in place)
- `ci <file>` keeps timestamped copies in `.revisions/` (start scripts `ci` their config each run)
- Configs: `/opt/tyk-gateway/tyk.conf`, `/opt/tyk-dashboard/tyk_analytics.conf`,
  `/opt/tyk-pump/pump.conf`, `/opt/portal/portal.conf`, `/opt/tyk-sink/tyk_sink.conf`
- Logs in `/var/log`: `tyk-gateway.log` (edge gateway after `mdcb`: `tyk-gateway-<port>.log`),
  `tyk-dashboard.log`, `tyk-pump.log`, `tyk-portal.log`, `tyk-sink.log`,
  `tyk-identity-broker.log`, `mongod.log`, `init-dashboard.log`, `plugin-server.log`
  (e.g. `docker exec sandbox-1 tail -200 /var/log/tyk-gateway.log`)
- `/initial_credentials.txt` holds `SBX_LICENSE`, `SBX_ORG_ID`, `SBX_USER`, `SBX_ADMIN_API_KEY`
  — contains the licence, don't print it whole.
- Edit config then `restart gateway` (no container restart needed). `/initialised` marks first
  boot done; config templates are only copied in on first boot.

### mdcb — turn a sandbox into control plane + edge gateway
```
dsbctl mdcb tyk-sink-2.7.1 N
```
yum-installs that MDCB RPM (stable repo, falls back to unstable), configures it with
`SBX_MDCB_LICENSE`, enables hybrid on all orgs, moves the management gateway to 444, starts an
edge gateway on 443 (`/opt/tyk-gateway/tyk.conf-rpc`, its own Redis on 6380) — so the sandbox's
published gateway URL now hits the **edge** gateway. Renames `dump-redis` to
`dump-control-redis` / `dump-edge-redis`. One-way; recreate the sandbox to undo.

### start / stop / restart / delete
```
dsbctl stop N...   dsbctl start N...   dsbctl restart N...
dsbctl delete N... # docker rm -f — destroys the container and all its data
dsbctl rm N...     # plain docker rm — fails on a running container
```
**Delete is irreversible — only delete sandboxes the user named or that you created in this
session; check `dsbctl info N` (ticket) first and confirm before deleting anything else.**
`delete all` removes every sandbox — never without explicit instruction. Plugin dirs under
`~/.tyk/plugins` are left behind.

## Running on AWS EC2
dsbctl detects EC2 by reading `/sys/devices/virtual/dmi/id/board_vendor` and checking for
`Amazon EC2`. Detection only works on Linux; this machine reports `Dell Inc.`, so the EC2 path
is not active here. On EC2 the host IP that dsbctl finds is the instance's **private** VPC
address. The sandbox URLs therefore only work from inside the VPC, and normally a user reaches
them from their laptop through an SSH tunnel.

To help with that, `dsbctl info` / `list` (the verbose output) adds a ready-made command at the
end of each non-CE sandbox's block, for example:
```
ssh -g -L localhost:3001:<private-ip>:3001 -g -L localhost:5001:<private-ip>:5001 -g -L localhost:3101:<private-ip>:3101 <aws hostname>
```
- It is built from every container label whose line contains `url`: `dashurl`, `gateurl`,
  `edpurl`, and `tiburl` on 2.x images. Redis and Mongo ports are **not** forwarded; add
  `-L localhost:600N:<private-ip>:600N` by hand if the user needs them.
- `<aws hostname>` is a literal placeholder. The user swaps in the instance's public DNS or ssh
  config alias. The command runs **on the user's laptop**, not on the instance.
- `-g` lets other machines on the laptop's network use the forwarded ports. Added in commit
  e50f5ee.
- Once the tunnel is up, the URLs are `http://localhost:3001/` (dashboard) and
  `https://localhost:5001/` (gateway, `-k`), with the port numbers matching the sandbox index.
- CE (`-s`) sandboxes get no ssh line. `create` prints the short info without the ssh line, so
  run `dsbctl info N` afterwards to get it.
- Caveat: the dashboard config has the gateway and dashboard host set to the private IP. Links
  and addresses shown inside the dashboard UI will show that IP, not `localhost`. Setting
  `SBX_GW_CNAME` / `SBX_DSHB_CNAME` in `~/.tyk-sandbox` before `create` changes them.

As an agent running **on** the EC2 instance, use the private-IP URLs from `dsbctl get` directly;
they work locally. When reporting to the user, give them the ssh line from `dsbctl info N`
together with the localhost URLs, not the private-IP URLs.

## Gotchas (vs help/README)
- Help lists `delete`; README says `rm`. They differ: `del*` force-removes, `rm` doesn't.
- `create` requires at least two args after `create`, so `-v X` is the minimum.
- Gateway URL is **https** with a self-signed cert; dashboard is http.
- `get`'s `gateway` match is `[Gg]*`, `mongo` is `[Mm]*` etc. — single-letter prefixes work.
- `list` and `info` are the same thing (verbose form).
- dsbctl `-s` (CE) sandboxes have no OrgId/AdminKey/dashboard — `get key/org/dashboard` are useless.

## Working pattern
1. `dsbctl info` to see existing sandboxes (don't repurpose someone's sandbox) and
   `dsbctl images` / `dsbctl build -l <ver>` to see what's available.
2. If the version row is missing from `tyk-versions.list`, add it (ask before committing).
3. `dsbctl create -v <ver> -t "<ticket> <purpose>"` — background it if an image build is needed.
4. Wait until `dsbctl get N key` is non-empty, then drive it with `get` values + curl /
   redis-cli / `docker exec sandbox-N ...`.
5. Report the sandbox name and URLs to the user; delete only if asked.
