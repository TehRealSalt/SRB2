#!/bin/bash

# Deployer for Travis-CI
# DPUT uploader (e.g., Launchpad PPA)
#

if [[ "$__DEPLOYER_DPUT_ACTIVE" == "1" ]]; then
    # Output the DPUT config
    # Dput only works if you're using secure FTP, so that's what we default to.
    cat > "./dput.cf" << EOM
[deployer-ppa]
fqdn = ${DEPLOYER_DPUT_DOMAIN}
method = ${DEPLOYER_DPUT_METHOD}
incoming = ${DEPLOYER_DPUT_INCOMING}
login = ${DEPLOYER_DPUT_USER}
allow_unsigned_uploads = 0
EOM

    if [[ "$PACKAGE_MAIN_NOBUILD" != "1" ]]; then
        OLDPWD=$PWD;
        PACKAGEFILENAME=${PACKAGE_NAME}_${PACKAGE_VERSION}~${PACKAGE_SUBVERSION};
        cd ../..; # level above repo root

        for f in ${PACKAGEFILENAME}*.changes; do
            dput -c "$OLDPWD/dput.cf" "$f";
        done;

        cd $OLDPWD;
    fi;

    if [[ "$PACKAGE_ASSET_BUILD" == "1" ]]; then
        OLDPWD=$PWD;
        PACKAGEFILENAME=${PACKAGE_NAME}-data_${PACKAGE_VERSION}~${PACKAGE_SUBVERSION};
        cd ..; # repo root

        # Dput only works if you're using secure FTP
        for f in ${PACKAGEFILENAME}*.changes; do
            dput -c "$OLDPWD/dput.cf" "$f";
        done;

        cd $OLDPWD;
    fi;
fi;