#!/bin/bash

# Deployer for Travis-CI
# Launchpad PPA uploader
#

if [[ "$__DEPLOYER_PPA_ACTIVE" == "1" ]]; then
    # Get the key to sign
    # Do this AFTER debuild so that we can specify the passphrase in command line
	echo "$DEPLOYER_PPA_KEY_PRIVATE" | base64 --decode > key.asc;
    echo "$DEPLOYER_PPA_KEY_PASSPHRASE" > phrase.txt;
	gpg --import key.asc;

    if [[ "$PACKAGE_MAIN_NOBUILD" != "1" ]]; then
        OLDPWD=$PWD;
        PACKAGEFILENAME=${PACKAGE_NAME}_${PACKAGE_VERSION}~${PACKAGE_SUBVERSION};
        LAUNCHPADFTP="ftp://ppa.launchpad.net:21/~${DEPLOYER_PPA_PATH}/"
        cd ../..; # level above repo root

        debsign ${PACKAGEFILENAME}_source.changes \
            -p"gpg --passphrase-file $OLDPWD/phrase.txt --batch";

        wput ./${PACKAGEFILENAME}.dsc ./${PACKAGEFILENAME}.tar.xz \
            ./${PACKAGEFILENAME}_source.buildinfo ./${PACKAGEFILENAME}_source.changes \
            ${LAUNCHPADFTP}${PACKAGEFILENAME}.dsc ${LAUNCHPADFTP}${PACKAGEFILENAME}.tar.xz \
            ${LAUNCHPADFTP}${PACKAGEFILENAME}_source.buildinfo ${LAUNCHPADFTP}${PACKAGEFILENAME}_source.changes;

        #dput -d -d ppa:${DEPLOYER_PPA_PATH} "${PACKAGEFILENAME}_source.changes";
        #echo cat < ./${PACKAGEFILENAME}_source.ppa.upload;

        cd $OLDPWD;
    fi;

    if [[ "$PACKAGE_ASSET_BUILD" == "1" ]]; then
        OLDPWD=$PWD;
        PACKAGEFILENAME=${PACKAGE_NAME}-data_${PACKAGE_VERSION}~${PACKAGE_SUBVERSION};
        LAUNCHPADFTP="ftp://ppa.launchpad.net:21/~${DEPLOYER_PPA_PATH}/"
        cd ..; # repo root

        debsign ${PACKAGEFILENAME}_source.changes \
            -p"gpg --passphrase-file $OLDPWD/phrase.txt --batch";

        wput ./${PACKAGEFILENAME}.dsc ./${PACKAGEFILENAME}.tar.xz \
            ./${PACKAGEFILENAME}_source.buildinfo ./${PACKAGEFILENAME}_source.changes \
            ${LAUNCHPADFTP}${PACKAGEFILENAME}.dsc ${LAUNCHPADFTP}${PACKAGEFILENAME}.tar.xz \
            ${LAUNCHPADFTP}${PACKAGEFILENAME}_source.buildinfo ${LAUNCHPADFTP}${PACKAGEFILENAME}_source.changes;

        #dput -d -d ppa:${DEPLOYER_PPA_PATH} "${PACKAGEFILENAME}_source.changes";
        #echo cat < ./${PACKAGEFILENAME}_source.ppa.upload;

        cd $OLDPWD;
    fi;

    srm key.asc;
    srm phrase.txt;
fi;
