## Prerequisites:
1. Clone 3 git repositories:
```
$ git clone https://github.com/irods/irods_development_environment /full/path/to/irods_development_environment_repository_clone
$ git clone --recursive https://github.com/irods/irods /full/path/to/irods_repository_clone
$ git clone https://github.com/irods/irods_client_icommands /full/path/to/icommands_repository_clone
```
2. Make 3 directories on host machine for docker volume mounts
```
$ mkdir /full/path/to/irods_build_output_dir
$ mkdir /full/path/to/icommands_build_output_dir
$ mkdir /full/path/to/packages_output_dir
```
Note: It may be useful to keep separate build directories across OS flavors in order to ensure
correctness of builds.

## How to build:
1. Build the Docker images:
```
$ cd /full/path/to/irods_docker_repository_clone/irods_developer_environment
$ docker build -f Dockerfile.irods_core_builder.ubuntu16 -t irods-core-builder-ubuntu16 .
$ docker build -f Dockerfile.irods_core_builder.centos7 -t irods-core-builder-centos7 .
$ docker build -f Dockerfile.irods_runner.ubuntu16 -t irods-runner-ubuntu16 .
$ docker build -f Dockerfile.irods_runner.centos7 -t irods-runner-centos7 .
```

## How to run (e.g. Ubuntu 16):
1. Run iRODS Runner container:
```
$ docker run -d --name irods-runner-ubuntu16_whatever \
             -v /full/path/to/packages_output_dir:/irods_packages:ro \
             irods-runner-ubuntu16
```
2. Open a shell inside the running container:
```
$ docker exec -it irods-runner-ubuntu16_whatever /bin/bash
```
Note: iRODS and iCommands are not installed out of the box, nor is the ICAT database prepared.
The usual steps of an initial iRODS installation must be followed on first-time installation.

## How to develop (e.g. Ubuntu 16):
1. Edit iRODS/iCommands source files...
2. Build iRODS and iCommands:
```
$ docker run --rm \
             -v /full/path/to/irods_repository_clone:/irods_source:ro \
             -v /full/path/to/irods_build_output_dir:/irods_build \
             -v /full/path/to/icommands_repository_clone:/icommands_source:ro \
             -v /full/path/to/icommands_build_output_dir:/icommands_build \
             -v /full/path/to/packages_output_dir:/irods_packages \
             irods-core-builder-ubuntu16
```
3. Install packages of interest on iRODS Runner (inside iRODS Runner container):
```
root@19b35a476e2d:/# dpkg -i /irods_packages/irods-{package_name(s)}.deb
```
4. Test your changes
5. Rinse and repeat
