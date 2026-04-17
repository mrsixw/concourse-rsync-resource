# concourse-rsync-resource

![CI](https://github.com/mrsixw/concourse-rsync-resource/actions/workflows/ci.yml/badge.svg)

[concourse.ci](https://concourse.ci/ "concourse.ci Homepage") [resource](https://concourse.ci/implementing-resources.html "Implementing a resource") for persisting build artifacts on a shared storage location with rsync and ssh.

## Config
* `server|servers`: *Required* Server or list of servers on which to persist artifacts. If `servers` are used first one in the list will be used for `in` and `check` origins.
* `port`: *Optional* Server SSH port, default is port 22
* `base_dir`: *Required* Base directory in which to place the artifacts
* `user`: *Required* User credential for login using ssh
* `private_key`: *Required* Key for the specified user
* `disable_version_path`: default is `false`. Then `false` `out` will put content in a directory named by the version name. This directory is omitted when this option is enabled. Note that `check` and `in` origins will treat all the files in the `base_dir` as versions in this case.

All config required for each of the `in`, `out` and `check` behaviors.

### Example

``` yaml
resource_types:
- name: rsync-resource
  type: docker-image
  source:
      repository: mrsixw/concourse-rsync-resource
      tag: latest

resources:
- name: sync-resource
  type: rsync-resource
  source:
    server: server
    base_dir: /sync_directory
    user : user
    private_key: |
            ...

- name: sync-resource-multiple
  type: rsync-resource
  source:
    servers:
      - server1
      - server2
    base_dir: /sync_directory
    user : user
    disable_version_path: false
    private_key: |
            ...

jobs:
-name: my_great_job
  plan:
    ...
    put: sync-resource
      params: {"sync_dir" : "my_output_dir" }
    put: sync-resource
      params: {
          "sync_dir" : "my_output_dir",
          "rsync_opts": ["-Pav", "--del", "--chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r"]
      }
```

## Behavior
### `check` : Check for new versions of artifacts
The `base_dir` is searched for any new artifacts being stored

### `in` : retrieve a given artifacts from `server`
Given a `version` check for its existence and rsync back the artifacts for the
version.

### `out` : place a new artifact on `server`
Generate a new `version` number an associated directory in `base_dir` on `server`
using the specified user credential. Rsync across artifacts from the input directory to the server storage location and output the `version`
#### Parameters

* `sync_dir`: *Optional.* Directory to be sync'd. If specified limit the directory to be sync'd to sync_dir. If not specified everything in the `put` will be sent (which could include container resources, whole build trees etc.)

## CI / Releasing

Every push to `master` and all pull requests run the CI pipeline, defined in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### Pipeline jobs

```
shellcheck → build → scan  ─┐
                   → scout  ├→ push (master / tags only)
```

**Shellcheck** lints all bash scripts in `assets/` using [shellcheck](https://www.shellcheck.net/) before anything is built.

**Build** compiles the Docker image and pushes it to [GitHub Container Registry (GHCR)](https://ghcr.io) using the commit SHA as the tag. GHCR acts as a staging registry so subsequent jobs can pull the already-built image rather than rebuilding it.

**Scan** (runs in parallel with Scout) pulls the image from GHCR and runs two checks:
- [Trivy](https://trivy.dev/) scans for CRITICAL CVEs and fails the build if any are found that aren't listed in `.trivyignore.yaml`. Currently suppressed CVEs are all due to the Alpine 3.7 EOL base image and are tracked for resolution in [#30](https://github.com/mrsixw/concourse-rsync-resource/issues/30).
- An Alpine version check ensures the base image minor version (`3.x`) matches the currently published image on Docker Hub, catching accidental base image upgrades.

**Scout** (runs in parallel with Scan) runs [Docker Scout](https://docs.docker.com/scout/) against the GHCR image and posts a CRITICAL/HIGH CVE breakdown as a comment on the PR. Scout failures are informational and do not block the push.

**Push** only runs on pushes to `master` or version tags. It copies the image directly from GHCR to Docker Hub using `docker buildx imagetools create` — a registry-to-registry manifest copy with no rebuild. The image is published with full semver tags.

### Versioning

Releases are versioned automatically using [Conventional Commits](https://www.conventionalcommits.org/). When a PR is merged to `master`, [`.github/workflows/tag.yml`](.github/workflows/tag.yml) creates a single git tag (regardless of how many commits the PR contained), which then triggers the push job to publish a versioned image to Docker Hub.

| Commit prefix | Version bump | Docker Hub tags published |
|---|---|---|
| `feat:` | minor | `1.2.0`, `1.2`, `1`, `latest` |
| `fix:`, `ci:`, `chore:`, etc. | patch | `1.1.1`, `1.1`, `1`, `latest` |
| `feat!:` / `BREAKING CHANGE:` | major | `2.0.0`, `2.0`, `2`, `latest` |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full development guide.
