#! /bin/bash -ex

usage() {
cat <<_EOF_
Builds iRODS externals and copies the packages to a volume mount (/irods_externals_packages)

Available options:

    --git-repository    URL or full path to the externals repository in the container (default: https://github.com/irods/externals)
    -b, --branch        Branch to build in git repository (default: main)
    -t, --make-target   The Make target to build (default: all)
    -h, --help          This message
_EOF_
    exit
}

git_repo="https://github.com/irods/externals"
git_branch="main"
make_target="all"
externals_dir="/externals"

while [ -n "$1" ] ; do
    case "$1" in
        --git-repository)        shift; git_repo=$1;;
        -b|--git-branch)         shift; git_branch=$1;;
        -t|--make-target)        shift; make_target=$1;;
        -h|--help)               usage;;
    esac
    shift
done

if [[ -z ${file_extension} ]] ; then
    echo "\$file_extension not defined"
    exit 1
fi

if [[ ! -e "${git_repo}" ]] ; then
    git clone -b "${git_branch}" "${git_repo}" "${externals_dir}"
else
    externals_dir="${git_repo}"
fi

cd "${externals_dir}"

make "${make_target}"

# Copy packages to mounts
cp -r "${externals_dir}"/*."${file_extension}" /irods_externals_packages/
