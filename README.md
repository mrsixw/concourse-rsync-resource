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

Every push to `master` and all pull requests run the CI pipeline:

1. **Shellcheck** — lints all `assets/` bash scripts
2. **Build** — builds the Docker image and pushes to GHCR as a staging registry
3. **Trivy scan** — checks for CRITICAL CVEs (parallel with Scout)
4. **Docker Scout** — posts a CVE breakdown as a PR comment (parallel with Trivy)
5. **Push** — copies the image from GHCR to Docker Hub (master and tags only)

Releases are versioned automatically using [Conventional Commits](https://www.conventionalcommits.org/). On every merge to `master` a new tag is created and the image is published to Docker Hub with full semver tags (`1.2.3`, `1.2`, `1`, `latest`).

| Commit prefix | Version bump |
|---|---|
| `feat:` | minor |
| `fix:`, `ci:`, `chore:`, etc. | patch |
| `feat!:` / `BREAKING CHANGE:` | major |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full development guide.
