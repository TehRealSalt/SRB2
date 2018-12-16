#!/bin/bash

# Deployer for Travis-CI
# Initialization
#
# Performs validity checks to ensure that Deployer is allowed to run
# e.g., is an FTP hostname specified? Are we whitelisted by OSNAMES and BRANCHES?
#
# Set these environment variables in your Travis-CI settings, where they are stored securely.
# See other shell scripts for more options.
#
# DPL_ENABLED = 1                       (leave blank to disable)
# DPL_JOB_ALL = 1                       (run Deployer on all jobs; leave blank to act on specific jobs, see below)
# DPL_OSNAMES = osx                     (whitelist of OS names to allow uploading; leave blank to upload from all OSes)
# DPL_BRANCHES = master,branch1,branch2 (whitelist of branches to upload; leave blank to upload all branches)
#
# To enable Deployer on specific jobs, set _DPL_JOB_ENABLED=1 for that job. Example:
# - matrix:
#   - os: osx
#     env:
#     - _DPL_JOB_ENABLED=1
#
# DO NOT set __DPL_ACTIVE, because that would bypass these validity checks.

# Validate Deployer state
if [[ "$DPL_ENABLED" == "1" ]] && [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    # Logging message for trigger word
    if [[ "$DPL_TRIGGER" != "" ]]; then
        echo "Testing for trigger $DPL_TRIGGER, commit message: $TRAVIS_COMMIT_MESSAGE";
        echo "[${DPL_TRIGGER}]";
        echo "[${DPL_TRIGGER}-${_DPL_JOB_NAME}]";
        echo "[${DPL_TRIGGER}-${TRAVIS_OS_NAME}]";
    fi;

    #
    # Search for the trigger word
    #
    if [[ "$DPL_TRIGGER" == "" ]] || [[ $TRAVIS_COMMIT_MESSAGE == *"[$DPL_TRIGGER]"* ]] \
    || [[ $TRAVIS_COMMIT_MESSAGE == *"[${DPL_TRIGGER}-${_DPL_JOB_NAME}]"* ]] \
    || [[ $TRAVIS_COMMIT_MESSAGE == *"[${DPL_TRIGGER}-${TRAVIS_OS_NAME}]"* ]]; then
        #
        # Whitelist by branch name
        #
        if [[ "$DPL_BRANCHES" == "" ]] || [[ $DPL_BRANCHES == *"$TRAVIS_BRANCH"* ]]; then
            # Set this so we only early-terminate builds when we are specifically deploying
            # Trigger string and branch are encompassing conditions; the rest are job-specific
            __DPL_ACTIVE_GLOBALLY=1;

            #
            # Is the job enabled for deployment?
            #
            if [[ "$DPL_JOB_ALL" == "1" ]] || [[ "$_DPL_JOB_ENABLED" == "1" ]]; then
                #
                # Whitelist by OS names
                #
                if [[ "$DPL_OSNAMES" == "" ]] || [[ $DPL_OSNAMES == *"$TRAVIS_OS_NAME"* ]]; then
                    # Base Deployer is eligible for becoming active

                    # Are we building for Linux?
                    if [[ "$_DPL_PACKAGE_BINARY" == "1" ]] || [[ "$_DPL_PACKAGE_SOURCE" == "1" ]]; then
                        if [[ "$_DPL_PACKAGE_MAIN" == "1" ]] || [[ "$_DPL_PACKAGE_ASSET" == "1" ]]; then
                            if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
                                __DPL_DEBIAN_ACTIVE=1;
                            fi;
                        fi;
                    fi;

                    # Now check for deployment targets
                    if [[ "$_DPL_FTP_TARGET" == "1" ]] && [[ "$DPL_FTP_HOSTNAME" != "" ]]; then
                        if [[ "$TRAVIS_OS_HOST" == "linux" ]] && [[ "$DPL_FTP_PROTOCOL" == "ftp" ]]; then
                            echo "Non-secure FTP will not work on Linux Travis-CI jobs!";
                            echo "Try SFTP or another target. Details:";
                            echo "https://blog.travis-ci.com/2018-07-23-the-tale-of-ftp-at-travis-ci";
                        else
                            if [[ "$__DPL_DEBIAN_ACTIVE" == "1" ]] || [[ "$_DPL_PACKAGE_BINARY" == "1" ]] || [[ "$_DPL_BINARY" == "1" ]]; then
                                echo "Deployer FTP target is enabled";
                                __DPL_FTP_ACTIVE=1;
                            else
                                echo "Deployer FTP target cannot be enabled: You must specify _DPL_PACKAGE_BINARY=1,";
                                echo "and/or _DPL_BINARY=1 in your job's environment variables.";
                            fi;
                        fi;
                    fi;

                    if [[ "$_DPL_DPUT_TARGET" == "1" ]] && [[ "$__DPL_DEBIAN_ACTIVE" == "1" ]] \
                    && [[ "$DPL_DPUT_INCOMING" != "" ]]; then
                        if [[ "$DPL_DPUT_METHOD" == "ftp" ]]; then
                            echo "DPUT will not work with non-secure FTP on Linux Travis-CI jobs!";
                            echo "Try SFTP or another method for DPUT. Details:";
                            echo "https://blog.travis-ci.com/2018-07-23-the-tale-of-ftp-at-travis-ci";
                        else
                            echo "Deployer DPUT target is enabled";
                            __DPL_DPUT_ACTIVE=1;
                        fi;
                    fi;

                    # If any deployment targets are active, then so is the Deployer at large
                    if [[ "$__DPL_FTP_ACTIVE" == "1" ]] || [[ "$__DPL_DPUT_ACTIVE" == "1" ]]; then
                        __DPL_ACTIVE=1;
                    fi;
                fi;
            fi;
        fi;
    else
        if [[ "$DPL_TRIGGER" != "" ]]; then
            echo "Testing for global trigger [$DPL_TRIGGER, commit message: $TRAVIS_COMMIT_MESSAGE";
        fi;
        if [[ "$DPL_TRIGGER" != "" ]] && [[ $TRAVIS_COMMIT_MESSAGE == *"[$DPL_TRIGGER"* ]]; then
            if [[ "$DPL_BRANCHES" == "" ]] || [[ $DPL_BRANCHES == *"$TRAVIS_BRANCH"* ]]; then
                # Assume that some job received the trigger, so mark this for early termination
                __DPL_ACTIVE_GLOBALLY=1;
            fi;
        fi;
    fi;
fi;

if [[ "$__DPL_ACTIVE_GLOBALLY" == "1" ]] && [[ "$__DPL_ACTIVE" != "1" ]]; then
    echo "Deployer is active in another job";
    if [[ "$DPL_JOB_TERMINATE_DISABLED" == "1" ]]; then
        echo "Terminating this job due to non-deployment";
    fi;
fi;

if [[ "$__DPL_ACTIVE_GLOBALLY" != "1" ]] && [[ "$__DPL_ACTIVE" != "1" ]]; then
    echo "Deployer is not active";
fi;