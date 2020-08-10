# --- use '-V' option from run_debugger.sh to source this file ---

if [ -d "${DEVROOT:=.}" ] ; then
    DEVROOT=$(realpath "${DEVROOT}")
    exit_code=''
else
    echo Please set DEVROOT to something reasonable
    echo '(For example the parent of the source code'
    echo ' and binary and package output directories)'
    exit_code=126
fi >&2

volumes_ro=(
    ["/irods_source"]="${DEVROOT}/irods"
    ["/icommands_source"]="${DEVROOT}/irods_client_icommands"
)

volumes_rw=(
    ["/irods_packages"]="${DEVROOT}/irods_package_output"
    ["/irods_build"]="${DEVROOT}/irods_build_output"
    ["/icommands_build"]="${DEVROOT}/icommands_build_output"
)
