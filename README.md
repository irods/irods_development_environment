# iRODS Development Environment

This repository contains tools for the running troubleshooting of a Docker-containerized iRODS server.

## Contents of this Guide
  1. [General Setup](#general-setup)
    1. [Prerequisites](#prerequisites)
    1. [How to Build](#how-to-build-eg-ubuntu-16)
    1. [How to Run](#how-to-run-eg-ubuntu-16)
    1. [How to Develop](#how-to-develop-eg-ubuntu-16)
  1. [Simplified Setup](#simplified-setup)
  1. Debugging
    1. `gdb`
    1. `rr`
    1. `valgrind`
    1. ( `cppcheck`,  clang static analyzer, ... ?)
---

## General Setup

### Prerequisites

1. Create custom paths.
```
$ git clone https://github.com/irods/irods_development_environment /full/path/to/irods_development_environment_repository_clone
$ git clone --recursive https://github.com/irods/irods /full/path/to/irods_repository_clone
$ git clone https://github.com/irods/irods_client_icommands /full/path/to/icommands_repository_clone
```
2. Make 3 directories on host machine for docker volume mounts:
```
$ mkdir /full/path/to/irods_build_output_dir
$ mkdir /full/path/to/icommands_build_output_dir
$ mkdir /full/path/to/packages_output_dir
```
Note: It may be useful to keep separate build directories across OS flavors in order to ensure
correctness of builds.

3. Build the Docker images:
```
$ cd /full/path/to/irods_development_environment_repository_clone
$ docker build -f Dockerfile.irods_core_builder.centos7 -t irods-core-builder-centos7 .
$ docker build -f Dockerfile.irods_core_builder.ubuntu16 -t irods-core-builder-ubuntu16 .
$ docker build -f Dockerfile.irods_core_builder.ubuntu18 -t irods-core-builder-ubuntu18 .
$ docker build -f Dockerfile.irods_runner.centos7 -t irods-runner-centos7 .
$ docker build -f Dockerfile.irods_runner.ubuntu16 -t irods-runner-ubuntu16 .
$ docker build -f Dockerfile.irods_runner.ubuntu18 -t irods-runner-ubuntu18 .
```

### How to build (e.g. Ubuntu 16)
1. Run iRODS builder container:
```
$ docker run --rm \
             -v /full/path/to/irods_repository_clone:/irods_source:ro \
             -v /full/path/to/irods_build_output_dir:/irods_build \
             -v /full/path/to/icommands_repository_clone:/icommands_source:ro \
             -v /full/path/to/icommands_build_output_dir:/icommands_build \
             -v /full/path/to/packages_output_dir:/irods_packages \
             irods-core-builder-ubuntu16
```

Usage notes (available by running the above with -h):
```
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --server-only           Only builds the server
    -j, --jobs              Number of jobs to use with make
    -h, --help              This message
```

### How to run (e.g. Ubuntu 16)
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

## How to develop (e.g. Ubuntu 16)
1. Edit iRODS/iCommands source files...
2. Build iRODS and iCommands (see "How to build")
3. Install packages of interest on iRODS Runner (inside iRODS Runner container):
```
root@19b35a476e2d:/# dpkg -i /irods_packages/irods-{package_name(s)}.deb
```
4. Test your changes
5. Rinse and repeat

It is encouraged to build your own wrapper script with your commonly used volume mounts to make this process easier.

---

## Simplified Setup

If coming to iRODS for the first time, a more automated approach will do for an introduction:

1. Into a new or initially empty directory, clone this repository:
```
$ mkdir ~/dev_root
$ cd ~/dev_root ; git clone https://github.com/irods/irods_development_environment
```

2. Also clone the source code repos from which to build:
```
$ git clone --recursive https://github.com/irods/irods
$ git clone https://github.com/irods/irods_client_icommands
```

3. Create binary and package output directories:
```
$ mkdir irods_build_output icommands_build_output irods_package_output
```

4. Now we can build and run model setup, using the source and output directories just created.
```
$ cd irods_development_environment
$ ./run_debugger.sh -d .. -V volumes.include.sh --debug
```

5.  This will build a docker image suitable for
   - *initially* running an iRODS server (an old version) installed from the iRODS internet repo
   - upgrading from there to a just-built iRODS server, eg. built from source
   - leveraging debugging tools (currently `gdb`, `rr`, and `valgrind`) against the running iRODS server
     (if we used `--debug` as in the previous step)

6. These are possible informative but otherwise no-op invocations of `run_debugger.sh` :
   - Explain usage:
   ```
   $ ./run_debugger.sh -h
   ```
   - Print out settings but do nothing.
   ```
   $ ./run_debugger.sh  -V volumes.include.sh -d .. --dry-run
   ```
7. Notes
  - when rebuilding, esp for another platform (-p), clear the binary output directories
    * ```
      sudo rm -fr ~/dev_root/*_output/* ~/dev_root/*_output/.ninja*
      ```
