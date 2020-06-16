#!/bin/bash

# This file is part of PrawnOS (http://www.prawnos.com)
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
# can only chose between "rsync" and "wget"
remote_tool="wget"
#
# The naming pattern of the actual source archive
# on as found in ${src_url}/${src_tar_pattern}
# follows the same variable expansion as $src_url
src_tar_pattern="linux-libre-VER.MAJ.MIN-gnu.tar.lz"
#
# Then naming pattern of the signature for the source archive
src_tar_sig_pattern="${src_tar_pattern}.sign"
#
# The log file path (leave empty to disable logging)
logfile=
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
#    ver=$1
#    IFS='.' read -ra vscheme <<< "$ver"
#    PRAWNOS_KVER_VER=${vscheme[0]}
#    PRAWNOS_KVER_MAJ=${vscheme[1]}
#    PRAWNOS_KVER_MIN=${vscheme[2]}

    anynum="[0-9]{1,}"
    match_ver="($anynum)\.($anynum)\.($anynum)"

    if [[ $target =~ $search_fmt ]];then
	PRAWNOS_KVER_VER=${BASH_REMATCH[1]}
	PRAWNOS_KVER_MAJ=${BASH_REMATCH[2]}
	PRAWNOS_KVER_MIN=${BASH_REMATCH[3]}
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

# function parse_version_from_filname()
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

    set -x
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

    echo $fname

    parse_version_from_filename "$fname"
}

