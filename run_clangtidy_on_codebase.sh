#! /bin/bash -e

usage() {
cat <<_EOF_
Uses an existing iRODS build to run clang-tidy and show results.

Available options:
    --commitish             Commit-ish (sha, branch, tag, etc.) to checkout (defaults to "main")
    --target-files          Path to specific file or directory to target (e.g. lib/core/src, plugins/database/src/db_plugin.cpp)
    -h, --help              This message
_EOF_
    exit
}

irods_build_directory=/irods_build
irods_source_directory=/irods_source

# Make sure the source code and build directories are all good.
if [[ ! -d "${irods_build_directory}" ]] ; then
    echo "No build directory was found at [${irods_build_directory}]. Exiting."
    exit 1
fi
if [[ ! -d "${irods_source_directory}" ]] ; then
    echo "No source code directory was found at [${irods_source_directory}]. Exiting."
    exit 1
fi

# Get the script options...
base_commitish="main"
target_files_path=""
while [ -n "$1" ] ; do
    case "$1" in
        --commitish)    shift; base_commitish="$1";;
        --target-files) shift; target_files_path="$1";;
        -h|--help)            usage;;
    esac
    shift
done

git_diff_options="-U0 ${base_commitish}"
clang_tidy_options="-p1 -use-color -path ${irods_build_directory}/compile_commands.json -quiet"

# If the user specified a --target-files option, make sure to include that in the options for git diff.
if [[ ! -z ${target_files_path} ]]; then
    git_diff_options="${git_diff_options} -- ${target_files_path}"
fi

# Add clang and clang-tidy helper script to path
clang_version=clang16.0.6-0
PATH=/opt/irods-externals/${clang_version}/share/clang:/opt/irods-externals/${clang_version}/bin:$PATH

# Make sure we can do git things in the source code directory.
git config --global --add safe.directory "${irods_source_directory}"

# Finally, do the thing.
echo "Running clang-tidy on diff with [${base_commitish}]."
cd "${irods_source_directory}"
git diff ${git_diff_options} | clang-tidy-diff.py ${clang_tidy_options}

echo "Done!"
