# AGENTS.md — tyk-sandbox

`dsbctl` builds Docker images that hold a complete Tyk stack and runs sandboxes from them. A
sandbox is one container called `sandbox-N`, running gateway, dashboard, pump, Redis and Mongo,
plus TIB, the Enterprise Developer Portal or MDCB when the version includes them. Tyk is
installed from packagecloud RPMs, not from the official Tyk images. The tool is used for
reproducing support tickets on specific Tyk versions. `README.md` is the user guide; this file
is for changing the repo.

## Layout

| Path | What it is |
|---|---|
| `dsbctl` | The CLI. **ksh** (`#!/bin/ksh -u`), runs on the host. The `case $1 in` block at the end routes each subcommand |
| `tyk-versions.list` | Each row is a refNo followed by the RPM version of every component. Builds read it, and it is also the record of which component versions shipped together |
| `Dockerfile` | Sandbox image. Builds `FROM $TBI_IMAGE`, copies `assets/` → `/assets` and `scripts/` → `/scripts`, runs `scripts/install-tyk` |
| `tbi/` | "Tyk Base Image": the OS plus tools, yum repos (`baseOS/repos`) and `baseOS/os-setup`. Tagged `saintpeter/tbi7` (2.x/3.x, CentOS 7), `tbi8` (4.x/5.0.x, Alma 8), `tbi9` (5.1+, Alma 9). See `setTbiVersions` in `dsbctl` |
| `scripts/` | Scripts that run **inside** the container (bash): `entrypoint.sh`, `init-dashboard.sh`, `start-*/stop-*`, `start`/`stop`/`restart` wrappers, `publish-apis`, `init-mdcb.sh`, `upgrade-*.sh`, helpers |
| `assets/` | Config templates (`tyk.conf`, `tyk_analytics.conf`, `pump.conf`, …) and sample APIs (`assets/APIs/*.json`, published at bootstrap) |

## How the pieces fit

1. `dsbctl build -v X` → `buildTykBaseImage` builds the tbi image only if it isn't already
   local. Then `docker build` runs with `--build-arg SBX_*_VERS=tyk-gateway-<rpmver>` (see
   `echoBuildArgs`), tagged `tyk-sandbox:X-<next rev>`. Builds use `--no-cache`.
2. `scripts/install-tyk` (build time) yum-installs those RPMs. For major version > 4 it rewrites
   the repo paths from EL7 to EL8. It skips tyk-sync on non-x86.
3. `dsbctl create` → `docker create`. Ports are base port + (index−1). Container labels
   (`sandbox.*`) are where `info`/`get` read their data. The `SBX_*` env vars come from
   `~/.tyk-sandbox`, from `-E`, and from values dsbctl computes.
4. `scripts/entrypoint.sh` (container start). On first boot only (no `/initialised` yet) it
   copies the `assets/*.conf` templates into `/opt/...` and `sed`s placeholders such as
   `SBX_GW_HOST`/`SBX_GW_PORT` into them. It also makes the certificates. Then it starts
   services in order. `init-dashboard.sh` bootstraps the licence, org and admin user, writes
   `/initial_credentials.txt`, and publishes the sample APIs.

Consequences:
- A change to `assets/` or `scripts/` only appears in a **newly built image**, and only in
  containers created from it. Existing images and sandboxes keep the old files. You can patch a
  running sandbox by hand with `docker cp`.
- A change to `tbi/` needs the local tbi image removed first, e.g.
  `docker image rm saintpeter/tbi9:latest`. Otherwise it gets reused.
- New template placeholders need a matching `sed` in `entrypoint.sh` (or `init-mdcb.sh` for the
  rpc/sink configs), plus the env var passed in by `dsbctl create`.

## Conventions

- **`dsbctl` must stay portable across Linux and macOS** (there are `$OS == Linux|Darwin`
  branches; see the "macos safe mktemp" commit). It is ksh: declare function-local variables
  with `typeset` (the script also uses `typeset -A` arrays). Avoid GNU-only flags, or branch on
  `$OS`.
- **Container scripts must work on every base image**: CentOS 7 through Alma 9, including old
  tools such as python 3.6 (see `serve-plugins.sh`). They must also cope with very old Tyk
  versions (see "start-pump.sh: compatibility with earliest pumps"). Each script sets its own
  `PATH` at the top. Follow that pattern.
- Match the existing style: two-space indent, `[INFO]`/`[WARN]`/`[FATAL]` message prefixes,
  `[[ ]]` tests.
- `tyk-versions.list`:
  - Format: `refNo,gateway,dashboard,pump,tib,sync,mdcb,portal`.
  - Empty fields are allowed.
  - **A refNo must not contain `-`**, because the image tag is `refNo-rev`.
  - `_ee` / `_fips` suffixes mark EE/FIPS rows; their RPM versions carry an `ee-`/`fips-` prefix.
  - Keep rows grouped under their `# X.Y` heading, newest first.
  - Pair each release with the pump/TIB/sync/MDCB/portal versions that were current when it
    shipped.
- Commit messages: `<file(s) changed>: <what changed>`, lowercase. Examples:
  `tyk-versions.list: added 5.8.20`, `dsbctl: added -g to the ssh command …`. Keep one logical
  change per commit.
- Keep `README.md` and the `help` function in `dsbctl` in step with option changes. Both are
  slightly stale already (`rm` vs `delete`, `-d` is missing from the README).

## Checking changes

There is no test suite. Verify like this:
- Syntax: `ksh -n dsbctl`, `bash -n scripts/<file>`. `ksh -n` prints many "obsolete" / "is
  slower than" style warnings for code that is already there. Ignore them; only a non-zero exit
  or a new error matters.
- Safe to run: `./dsbctl build -l [ver]`, `./dsbctl images`, `./dsbctl info`.
- End to end, for a change to the image, entrypoint or create:
  1. Build an image, `./dsbctl build -v <ver>`. It takes minutes, so run it in the background.
  2. Create a sandbox, `./dsbctl create -v <ver> -t "test <change>"`.
  3. Wait for `./dsbctl get N key` to return a key.
  4. Check the logs, `docker exec sandbox-N tail /var/log/init-dashboard.log` (also
     `tyk-gateway.log` and `tyk-dashboard.log`).
  5. Curl the dashboard over http and the gateway over https with `-k`.
  6. Delete the sandbox you created.
- If a change could behave differently across base images, test one version per tbi family it
  affects (for example a 4.x and a 5.x image).

## Safety

- `~/.tyk-sandbox` and `/initial_credentials.txt` inside containers hold Tyk licences. Never
  print them, commit them, or copy them into the repo.
- `.gitignore` excludes `*.rpm` and `*.pem`. Don't commit generated keys or certificates.
- `dsbctl delete` is `docker rm -f`. Only delete sandboxes you created or were told to delete.
  Other sandboxes and images on the host may belong to live investigations.
- `build -v all` builds every row in the list (hours, lots of disk). Don't run it unless asked.
