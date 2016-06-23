# concourse-rsync-resource
[concourse.ci](https://concourse.ci/ "concourse.ci Homepage") [resource](https://concourse.ci/implementing-resources.html "Implementing a resource") for persisting build artifacts on a shared storage location with rsync and ssh.

##Config
* `server`: *Required* Server on which to persist artifacts
* `base_dir`: *Required* Base directory in which to place the artifacts
* `user`: *Required* User credential for login using ssh
* `private_key`: *Required* Key for the specified user
All config required for each of the `in`, `out` and `check` behaviors. 
###Example
```
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
```

##Behavior
### `check` : Check for new versions of artifacts
The `base_dir` is searched for any new artifacts being stored

### `in` : retrieve a given artifacts from `server`
Given a `version` check for its existance and rsync back the artifacts for the
version.

### `out` : place a new artifact on `server`
Generate a new `version` number an associated directory in `base_dir` on `server`
using the specified user credential. Rsync across artifacts from the input directory to the server storgage location and output the `version`
