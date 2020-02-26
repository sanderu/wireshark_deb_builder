#!/bin/bash

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

sanity_check () {
    # Are we root?
    if [ ${UID} -ne 0 ]; then
        logger -t user.info -s "${SCRIPTNAME}: you need to be root for this to run."
    fi

    # Ensure all needed packages are installed:
    apt install wget xz-utils dpkg-dev qtbase5-dev qtbase5-dev-tools qttools5-dev qttools5-dev-tools qtmultimedia5-dev libqt5svg5-dev libpcap0.8-dev flex libz-dev debhelper po-debconf libtool python3-ply libc-ares-dev xsltproc dh-python docbook-xsl docbook-xml libxml2-utils libpcre3-dev libcap-dev bison quilt libparse-yapp-perl libgnutls28-dev libgcrypt-dev libkrb5-dev liblua5.2-dev libsmi2-dev libmaxminddb-dev libsystemd-dev libnl-genl-3-dev libnl-route-3-dev asciidoctor cmake libsbc-dev libnghttp2-dev libssh-gcrypt-dev liblz4-dev libsnappy-dev libspandsp-dev libxml2-dev libzstd-dev libbrotli-dev libspeexdsp-dev

    # Check if BUILD_DIR already exists:
    if [ -d ${BUILD_DIR} ]; then
        rm -rf ${BUILD_DIR}
        mkdir ${BUILD_DIR}
    else
        mkdir ${BUILD_DIR}
    fi

    # Check if debpackages directory exists:
    if [ -d ${DEB_DIR} ]; then
        rm -rf ${DEB_DIR}
        mkdir ${DEB_DIR}
    else
        mkdir ${DEB_DIR}
    fi
    chown ${USER}:${USER} ${DEB_DIR}
}


################
# MAIN PROGRAM #
################

# Syslog that we start working
logger -t user.info -s "${SCRIPTNAME}: Started."

sanity_check

# Get and parse download site:
wget ${URL} -O ${website_src}

# Get newest version of tarball
NEWEST_WIRESHARK=$( basename $( grep 'Source Code' ${website_src} | head -n1 | awk -F 'href="' '{print $2}' | awk -F '">Source' '{print $1}' ) )
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
dpkg-buildpackage -us -uc -rfakeroot

# Backup deb-files to ${DIRECTORY}
cp ${BUILD_DIR}/*.deb ${DEB_DIR}/

# Give commandline hint to install wireshark:
LIST_OF_FILES=$( find ${DEB_DIR}/ -type f -name "*.deb" ! -name "*-dev*.deb" ! -name "*-dbg*.deb" | tr '\n' ' ' )
echo "To install wireshark without debug/development tools, run:"
echo "sudo dpkg -i ${LIST_OF_FILES}"

# Syslog that we are finished working
logger -t user.info -s "${SCRIPTNAME}: Done."
