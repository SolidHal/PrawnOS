#!/bin/bash

# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2018 Hal Emmerich <hal@halemmerich.com>
# Copyright (c) 2020 Fil Bergamo <fil@filberg.eu>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


# ------------------------------------------------------
#                 STATIC CONFIGURATION
# ------------------------------------------------------
#
# Get the project's root, to help define paths
PRAWNOS_ROOT=$(git rev-parse --show-toplevel)
#
# Upstream url to be checked for source updates
# Gets variable-expanded by filling in the version string "w.x.y"
# through funcion expand_version_pattern()
# Here, VER means the main version number,
#       MAJ the major revision number,
#       MIN the minor revision number
# (e.g. "LATEST-VER.MAJ.N" + becomes "LATEST-5.4.N" for "5.4.43")
src_url="https://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-VER.MAJ.N"
#
# Timeout, in seconds, for remote operations (rsyc, wget..)
remote_timeout=15
#
# Number of retires after a remote operation times out
remote_retries=2
#
# Seconds to wait before retrying failed remote operations
remote_wait_retry=5
#
# The tool to be used to search for updates
# can only choose between "rsync" and "wget"
remote_tool="wget"
#
# The naming pattern of the actual source archive
# as found in ${src_url}/${src_tar_pattern}
# follows the same variable expansion as $src_url
src_tar_pattern="linux-libre-VER.MAJ.MIN-gnu.tar.xz"
#
# Then naming pattern of the signature for the source archive
src_tar_sig_pattern="${src_tar_pattern}.sign"
#
# The log file path (leave empty to disable logging)
logfile=
#
# The file containing the KVER variable definition
# that's used for the kernel building process
kver_file=$PRAWNOS_ROOT/scripts/BuildScripts/BuildCommon.mk
#
sed_versnum_pattern='[0-9]\+.[0-9]\+.[0-9]\+'
#
# Controls the behaviour of build_latest_kernel()
# Set to 0 (zero) to skip building the kernel
# if it's already at the newest version.
# Set to 1 (one) to build it anyway.
rebuild_kernel_if_latest=0
#
# Reset global variables used to parse version strings
PRAWNOS_KVER_VER=
PRAWNOS_KVER_MAJ=
PRAWNOS_KVER_MIN=
PRAWNOS_KVER_FULLSTR=
# ------------------------------------------------------

log()
{
    [ ! -z "$logfile" ] &&
	echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> $logfile
}

print_err()
{
    printf "\033[0;31m%s\n" "[ERR] $1" 1>&2
    log "[ERR] $1"
}

print_warn()
{
    echo "[WRN] $1" 1>&2
    log "[WRN] $1"
}

print_msg()
{
    echo "[INF] $1"
    log "[INF] $1"
}

die()
{
    print_err "$1"
    [ $# -gt 1 ] && exit $2
    exit 255
}

# function expand_version_pattern()
# Replace VER, MAJ, MIN in the given pattern
#   with the given 'w', 'x' and 'y' values.
# $1 = pattern
# $2 = main version number ('w')
# $3 = major revision number ('x')
# $4 = minor revision number ('y')
expand_version_pattern()
{
    expanded=${1//VER/$2}
    expanded=${expanded//MAJ/$3}
    echo ${expanded//MIN/$4}
}


# function get_running_kver()
# Print the upstream version of the currently running kernel
# i.e. < w.x[.y] > without any trailing distro-specific version
get_running_kver()
{
    uname -r | cut -d '-' -f 1
}


# function split_version_string()
# Split a 'w.x.y' version string into separate values.
# Set $PRAWNOS_KVER_VER with the main version number ('w').
# Set $PRAWNOS_KVER_MAJ wiht the major revision number ('x').
# Set $PRAWNOS_KVER_MIN with the minor revision number ('y').
# Return 0 on success, return 1 on failure.
# $1 = version string in the 'w.x.y' format
split_version_string()
{
    target=$1
    anynum="[0-9]{1,}"
    match_ver="($anynum)\.($anynum)\.($anynum)"

    if [[ $target =~ $match_ver ]];then
	export PRAWNOS_KVER_VER=${BASH_REMATCH[1]}
	export PRAWNOS_KVER_MAJ=${BASH_REMATCH[2]}
	export PRAWNOS_KVER_MIN=${BASH_REMATCH[3]}
	return 0
    else
	return 1
    fi
}

# function rsync_list_remote()
# List contents of remote directory via rsync.
# Return rsync's exit code.
# $1 = remote rsync url to be listed
rsync_list_remote()
{
    rsync --timeout=$remote_timeout --list-only "$1" 2>&1
    ec=$?

    # rsync exit codes 30, 35 = timeout
    case $ec in
	30|35)
	    print_warn "rsync timeout while connecting to remote server"
	    if [ $remote_retries -lt 1 ];then
		return $ec
	    fi
	    export remote_retries=$(( remote_retries - 1 ))
	    print_warn "Waiting $remote_wait_retry seconds before retrying"
	    sleep $remote_wait_retry
	    rsync_list_remote $@
	    return $?
	    ;;
	*)
	    return $ec
	    ;;
    esac
}

# function rsync_search_url_pattern()
# Search $src_url for the presence of a file
#   that matches $src_tar_pattern.
# Print the bare file name matching the search.
# $1 = main version number ('w')
# $2 = major revision number ('x')
rsync_search_url_pattern()
{
    file_pattern=$(expand_version_pattern \
		       "$src_url/$src_tar_pattern" $1 $2 "*")

    print_msg "Attempting to list remote file pattern $file_pattern..."
    file=$(rsync_list_remote $file_pattern)
    ec=$?
    if [ $ec -ne 0 ];then
	print_err "Failed to list remote file pattern"
	print_err "Output from rsync:"
	print_err "$file"
	return $ec
    fi

    fields=( $file )
    echo ${fields[-1]}
}

# function wget_search_url_pattern()
# Search $src_url for an 'href' pointing to a file
#   that matches $src_tar_pattern.
# Print the bare file name matching the search.
# $1 = main version number ('w')
# $2 = major revision number ('x')
wget_search_url_pattern()
{
    baseurl=$(expand_version_pattern "$src_url" "$1" "$2")
    outfile=$(tempfile)

    wget --timeout=$remote_timeout \
	 --tries=$(( $remote_retries + 1 )) \
	 --output-document="$outfile" \
	 "$baseurl"

    ec=$?
    if [ $? -ne 0 ];then
	print_err "Failed to download url with wget."
	return $ec
    fi

    search_string=$(expand_version_pattern $src_tar_pattern "$1" "$2" "*")

    grep -o "href=\"$search_string\"" "$outfile" | grep -o "$search_string"

    rm "$outfile"
}

# function parse_value_from_template()
# Match "$target" against "$template" and print
#   the first occurrence in "$target"
#   that matches the "$placeholder" part in "$template"
# i.e. parse "$placeholder" out of "$target" using "$template"
# $1 = template
# $2 = target
# $3 = placeholder
# $4 = matching pattern
parse_value_from_template()
{
    template=$1
    target=$2
    phold=$3

    # replace $phold with a matching group in $template
    search_fmt=$(sed "s/$phold/($4)/g" <<< $template)

    [[ $target =~ $search_fmt ]] &&
	echo ${BASH_REMATCH[1]}
}

# function parse_version_from_filename()
# Extract the version string from the given filename
#   and print it to stdout
# $1 = filename matching $src_tar_pattern
parse_version_from_filename()
{
    if [ -z "$1" ];then
	print_err "Failed parsing version: empty file name received;"
	return 1
    fi

    anynum="[0-9]{1,}"

    template_ver=$(expand_version_pattern "$src_tar_pattern" "VER" "$anynum" "$anynum")
    template_maj=$(expand_version_pattern "$src_tar_pattern" "$anynum" "MAJ" "$anynum")
    template_min=$(expand_version_pattern "$src_tar_pattern" "$anynum" "$anynum" "MIN")

    ver=$(parse_value_from_template "$template_ver" "$1" "VER" "$anynum")
    maj=$(parse_value_from_template "$template_maj" "$1" "MAJ" "$anynum")
    min=$(parse_value_from_template "$template_min" "$1" "MIN" "$anynum")

    echo "${ver}.${maj}.${min}"
}

# function get_latest_src_kver()
# Check the upstream url for the latest source release.
# Print the latest version available in the format 'w.x.y'
# $1 = main version number ('w')
# $2 = major revision number ('x')
get_latest_src_kver()
{
    case $remote_tool in
	 wget)
	     fname=$(wget_search_url_pattern $1 $2)
	     ;;
	 rsync)
	     fname=$(rsync_search_url_pattern $1 $2)
	     ;;
	 *)
	     print_err "Unknown remote tool: $remote_tool"
	     return 1
    esac

    parse_version_from_filename "$fname"
}

# function set_makefile_kver()
# Replace the KVER variable in the given file
# with the given value, so that next kernel build
# uses the given kernel version
# $1 = full version string
# $2 = target file
set_build_kver()
{
    sed -i -e "s/KVER=$sed_versnum_pattern\$/KVER=$1/g" "$2"
    return $?
}

# function get_build_kver()
# Extract the current value of $KVER in the given file.
# Print the version number to stdout.
# Split the value into "ver" "maj" "min".
# Set $PRAWNOS_KVER_FULLSTR with the full version string ('w.x.z')
# Set $PRAWNOS_KVER_VER with the main version number ('w').
# Set $PRAWNOS_KVER_MAJ wiht the major revision number ('x').
# Set $PRAWNOS_KVER_MIN with the minor revision number ('y').
# $1 = target file
get_build_kver()
{
    kver=$(sed -n "/KVER=$sed_versnum_pattern\$/p" "$1" \
	       | sed 's/KVER=//') ||
	return 1

    export PRAWNOS_KVER_FULLSTR=$kver
    echo "$kver"

    split_version_string "$kver"
    return $?
}

build_latest_kernel()
{
    get_build_kver "$kver_file" ||
	die "FAILED to fetch current KVER version from $kver_file"

    # $PRAWNOS_KVER_FULLSTR is exported
    # by the call to get_build_kver() hereabove
    currver=$PRAWNOS_KVER_FULLSTR
    
    ver=$(get_latest_src_kver "$PRAWNOS_KVER_VER" "$PRAWNOS_KVER_MAJ") ||
	die "FAILED to retrieve latest kernel version."

    print_msg "Latest upstream version is $ver"

    if [ "$currver" = "$ver" ]
    then
	print_warn "Current KVER is already the latest version!"

	if [ $rebuild_kernel_if_latest = 0 ]
	then
	    print_msg "Settings prevent kernel rebuilding. Stopping."
	    exit 0
	fi
	
	print_warn "Proceeding to build anyway."
    fi

    print_msg "Beginning kernel build for version $ver..."

    # ------------------------------------------------------------------
    # explicitly inject the desired version to buildKernel.sh
    # so that we don't depend upon the hard-coded KVER in BuildCommon.mk
    # ------------------------------------------------------------------
    export PRAWNOS_KVER=$ver

    # ------------------------------------------------------------------
    # alternatively, we can overwrite KVER in BuildCommon.mk
    #  (uncomment the following lines to do so)
    # -----------------------------------------------------------------
    # set_build_kver "$ver" "$kver_file" ||
    # 	die "FAILED to replace KVER in $kver_file"
    # print_msg "Replaced KVER=$ver in $kver_file"
    
    print_msg "cd'ing into project root..."

    cd "$PRAWNOS_ROOT" ||
	die "FAILED to cd into $PRAWNOS_ROOT"

    make kernel

    return $?
}
