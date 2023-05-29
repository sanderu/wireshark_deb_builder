#!/bin/bash

# Ensure programs exits on errors, unset variables used and last command error status in a pipe
set -o errexit
set -o nounset
set -o pipefail

# Variables:
SCRIPTNAME=$0

USER=$(logname)
URL='https://www.wireshark.org/'
DL_URL='https://1.eu.dl.wireshark.org/src/'
BUILD_DIR='/tmp/build_wireshark'
DEB_DIR='/home/'${USER}'/debpackages'

installed_pkgs='/tmp/installed_pkgs.txt'
website_src='/tmp/wireshark_dl_source.txt'


#############
# FUNCTIONS #
#############

_sanity_checks () {
    # Are we root?
    if [ ${UID} -ne 0 ]; then
        logger -t user.info -s "${SCRIPTNAME}: you need to run this script with sudo."
        exit 1
    fi

    # Ensure all needed packages are installed:
    apt install -y wget xz-utils dpkg-dev qtbase5-dev qtbase5-dev-tools qttools5-dev qttools5-dev-tools qtmultimedia5-dev libqt5svg5-dev libpcap0.8-dev flex libz-dev debhelper po-debconf libtool python3-ply libc-ares-dev xsltproc dh-python docbook-xsl docbook-xml libxml2-utils libpcre3-dev libcap-dev bison quilt libparse-yapp-perl libgnutls28-dev libgcrypt-dev libkrb5-dev liblua5.2-dev libsmi2-dev libmaxminddb-dev libsystemd-dev libnl-genl-3-dev libnl-route-3-dev asciidoctor cmake libsbc-dev libnghttp2-dev libssh-gcrypt-dev liblz4-dev libsnappy-dev libspandsp-dev libxml2-dev libzstd-dev libbrotli-dev libspeexdsp-dev

    # Check if BUILD_DIR already exists:
    if [ -d ${BUILD_DIR} ]; then
        rm -rf ${BUILD_DIR}
        mkdir ${BUILD_DIR}
    else
        mkdir ${BUILD_DIR}
    fi

    # Check if debpackages directory exists:
    if [ ! -d ${DEB_DIR} ]; then
        mkdir ${DEB_DIR}
    fi
}

_deb_dirs () {
    DL_VERS=$1
    if [ -d ${DEB_DIR}/${DL_VERS} ]; then
        rm -rf ${DEB_DIR}/${DL_VERS}
        mkdir ${DEB_DIR}/${DL_VERS}
    else
        mkdir ${DEB_DIR}/${DL_VERS}
    fi
    chown -R ${USER}:${USER} ${DEB_DIR}
}

_create_deb () {
    DL_VERS=$1
    # Get and parse download site:
    wget ${URL} -O ${website_src}

    # Get newest version of tarball
    NEWEST_WIRESHARK=$( basename $( grep Source ${website_src} | sed -e 's/>/>\n/g' | grep xz | awk -F '<a href="' '{print $2}' | awk -F '">' '{print $1}' | grep ${DL_VERS} ) )
    DIRECTORY=$( echo ${NEWEST_WIRESHARK} | awk -F '.tar' '{print $1}' )

    # Download newest wireshark source code:
    wget ${DL_URL}/${NEWEST_WIRESHARK} -O ${BUILD_DIR}/${NEWEST_WIRESHARK}

    # Go and unpack xz-compressed tarball
    cd ${BUILD_DIR}
    unxz ${NEWEST_WIRESHARK}

    # And unpack tarball:
    tar -xvf ${DIRECTORY}.tar

    # Now go and create the deb-packages:
    cd ${DIRECTORY}
    if [ ! -d debian ]; then
        cp -a packaging/debian ${BUILD_DIR}/${DIRECTORY}/
    fi
    dpkg-buildpackage -us -uc -rfakeroot

    # Backup deb-files to ${DIRECTORY}
    cp ${BUILD_DIR}/*.deb ${DEB_DIR}/

    # Give commandline hint to install wireshark:
    LIST_OF_FILES=$( find ${DEB_DIR}/ -type f -name "*.deb" ! -name "*-dev*.deb" ! -name "*-dbg*.deb" | tr '\n' ' ' )
    echo "To install wireshark without debug/development tools, run:"
    echo "sudo dpkg -i ${LIST_OF_FILES}"
}

_show_usage () {
    echo "Usage: ${SCRIPTNAME} [-3|-4]"
    echo '       -3 : Wireshark 3'
    echo '       -4 : Wireshark 4'
}

################
# MAIN PROGRAM #
################

_sanity_checks

# Syslog that we start working
logger -t user.info -s "${SCRIPTNAME}: Started."

while getopts "34" ARGUMENT; do
    case "${ARGUMENT}" in
        3)
            # Distro for which symbol-file will be created
            DL_VERS="wireshark-3"
            _deb_dirs ${DL_VERS}
            _create_deb ${DL_VERS}
            ;;
        4)
            # Distro for which symbol-file will be created
            DL_VERS="wireshark-4"
            _deb_dirs ${DL_VERS}
            _create_deb ${DL_VERS}
            ;;
        *)
            # If nothing or anything else is used, show usage
            _show_usage
            ;;
    esac
done

# Syslog that we are finished working
logger -t user.info -s "${SCRIPTNAME}: Done."



