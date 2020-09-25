# iRODS Development Environment

This repository contains tools for the running troubleshooting of a Docker-containerized iRODS server.

## Contents of this Guide
   1. [General Setup](#general-setup)
      1. [Prerequisites](#prerequisites)
      1. [How to Build](#how-to-build-eg-ubuntu-16)
      1. [How to Run](#how-to-run-eg-ubuntu-16)
      1. [How to Develop](#how-to-develop-eg-ubuntu-16)
   1. [Simplified Setup](#simplified-setup)
   1. [Debugging](#debugging)
      1. [`gdb`](#gdb)
      1. [`rr`](#rr)
      1. [`valgrind`](#valgrind)
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

### How to develop (e.g. Ubuntu 16)
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
  - When rebuilding, esp for another platform (-p), it may be necessary to clear the binary output directories
    ```
      $ sudo cp -rp  ~/dev_root ~/dev_root.ubuntu16.4-2-stable  # (optionally preserve previous work)
      $ sudo rm -fr ~/dev_root/*_output/* ~/dev_root/*_output/.ninja*
    ```

---

## Debugging

In the run/debug container created by the [simplified](#simplified-setup) procedure, placing `/opt/debug_tools/bin`
at the head of the PATH environment variable will cause the shell to invoke updated versions executables of
`gdb`, `rr`, and `valgrind`.  These can be necessary when debugging symbols are larger than what the tool binaries at
the default install paths can handle.

The system calls necessary for `gdb` and `rr` to function properly on the Linux host necessitate:
   - `/proc/sys/kernel/yama/ptrace_scope` no higher than 0
   - `/proc/sys/kernel/perf_event_paranoid` no higher than 1
   
These can be changed by editing the config files under `/etc/sysctl.*` and reloaded via `sysctl --system`.
Doing this on the host machine should be effective for all containerized `gdb`/`rr` runs as well.

### GDB

Start a debugger container.

 - In terminal #1, as iRODS service account:
    - pkill irodsReServer (prevent API's being invoked from delay server)
    - attach to irods server
    ```
    gdb -p PID
    ```

    with PID = the parent (not grandparent) irodsServer process

    parent PID usually = 1 + grandparent PID

    - Inside the GDB console:
    ```
    set follow-fork-mode child
    b rsApiHandler
    c
    ```

 - In terminal #2:

    run the client to invoke the API

### RR

   - [rr](http://github.com/mozilla/rr) is a GDB work-a-like which
      * records the target process being run and allows replay (a "deterministic run") of that record
      * can therefore capture an error and allow the developer step forward and backward through any of
        the captured PIDs

   - `rr` can be used within graphical environments like [gdbgui](https://gdbgui.com/)
      * gdbgui is easy to [install](https://github.com/cs01/gdbgui/blob/master/docs/INSTALLATION.md)

   - instructional links on

      * [building and installing](https://github.com/mozilla/rr/wiki/Building-And-Installing)
      * [using RR under docker](https://github.com/mozilla/rr/wiki/Docker)

   - basic usage under iRODS:
      - install an iRODS server with debug symbols compiled in.
         (*Can insert **rodsLog(LOG_NOTICE,"...%s..",arg,...)** calls to help ascertaining relevant PID later)*
      - as iRODS, do: `~/irodsctl stop`
      - then, also as iRODS: `cd /usr/sbin ; rr record -w /usr/sbin/irodsServer`
      - (as any user) perform the operations requiring troubleshooting
      - again as iRODS, do: `~/irodsctl stop`
      then:
      ```
      rr ps
      rr replay -p <PID> # or if forked without exec, then "-f <PID>"
      ```

### Valgrind

```
# as service account
ubuntu:~$ su - irods
$ cd /var/lib/irods ; ./irodsctl stop
$ cd ..         # Because iRODS can't find the server log otherwise

Sample command line:
```
$ valgrind --tool=memcheck --leak-check=full --trace-children=yes \
      --num-callers=200 --time-stamp=yes --track-origins=yes \
      --keep-stacktraces=alloc-and-free --freelist-vol=10000000000 \
      --log-file=$HOME/valgrind_out_%p.txt /usr/sbin/irodsServer
```
Then everything that happens in irodsServer will be valgrinded.
#  ps -ef | grep valgrind -> yields PID(s); valgrind hides the process name
```
Other valgrind notes
   - can kill valgrind/iRODS processes with `pkill valgrind`
   - between server runs, be sure to `rm -fr /dev/shm/irods*`
