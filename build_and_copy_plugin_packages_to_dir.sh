#! /bin/bash -ex


# Build iRODS
"${python}" /irods_plugin_source/irods_consortium_continuous_integration_build_hook.py \
    --irods_packages_root_directory /irods_packages $@

# Copy packages to mounts
cp -r /irods_plugin_build/*."${file_extension}" /irods_plugin_packages/
