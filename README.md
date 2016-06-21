# concourse-rsync-resource
[concourse.ci](https://concourse.ci/ "concourse.ci Homepage") [resource](https://concourse.ci/implementing-resources.html "Implementing a resource") for persisting build artifacts on a shared storage location with rsync.

##Usage
`resource_types:
- name: rsync-resource
  type: docker-image
  source:
      repository: mrsixw/concourse-rsync-resource/
      tag: latest

resources:
- name: skyd-sync-resource
  type: rsync-resource`

##Testing
Ensure that a `/mnt/concourse_share` directory is available and writable but the current user and that `bash` and `python` are accessible for the current user.  

Source the test environment data using `. ./test/test_env.sh` and then run the relevant asset script, for example `cat ./test/test.json | ./assets/out $PWD ` with the relevant directory passed as `$1` and the relevant metadata passed on `stdin`
