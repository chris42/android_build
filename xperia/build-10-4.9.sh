#!/bin/bash
set -e
set -x

_pick_pr() {
    local _remote=$1
    local _pr_id=$2
    local _commits=${3:-1}
    local _max_commits=${4:-$_commits}
    local _index=$(($_commits - 1))
    local _count=0

    git fetch $_remote pull/$_pr_id/head

    while [ $_index -ge 0 -a $_count -lt $_max_commits ]; do
        git cherry-pick -Xtheirs --no-edit FETCH_HEAD~$_index
        _index=$(($_index - 1))
        _count=$(($_count + 1))
    done
}

prepare_sources() {

    # ----------------------------------------------------------------------
    # Cleanup old patching
    # ----------------------------------------------------------------------

    if [ -d device/sony/customization ]; then
       rm -r device/sony/customization
    fi

    for path in \
        device/sony/common \
        device/sony/sepolicy \
        device/sony/$PLATFORM \
        kernel/sony/msm-4.9/kernel \
        kernel/sony/msm-4.9/common-kernel \
        device/sony/kugo \
        device/sony/loire \
        frameworks/base \
        frameworks/opt/net/wifi
    do
        if [ -d $path ]; then
            pushd $path
                git clean -d -f -e "*dtb*"
                git reset --hard m/$TARGET_ANDROID_VERSION
            popd
        fi
    done

    # ----------------------------------------------------------------------
    # Local manifest cleanup
    # ----------------------------------------------------------------------
    pushd .repo/local_manifests
        git clean -d -f
        git fetch
        git reset --hard origin/android-10_legacy

        # --------------------------------------------------------------------
        # Add microg prebuilts manifest
        # --------------------------------------------------------------------
        cat >prebuilt.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

<remote name="github" fetch="https://github.com/" />

<project path="device/sony/customization/prebuiltapks" name="chris42/android_prebuilts_prebuiltapks" remote="github" revision="master" />

</manifest>
EOF
    popd

    # --------------------------------------------------------------------
    # Additional patching
    # --------------------------------------------------------------------
    ./repo_update.sh

    pushd device/sony/common
        # Patch Thermal HW module to silence crash 1/2
        cat >>common-packages.mk <<EOF

# Default thermal hw module:
PRODUCT_PACKAGES += \
    thermal.default
EOF
    popd

    pushd kernel/sony/msm-4.9/kernel
        # Test: Kernel .221
        _pick_pr sony 2244 3
    popd

    pushd device/sony/sepolicy
        # Patch Thermal HW module to silence crash 2/2
        cat >vendor/hal_thermal_default.te <<EOF
allow hal_thermal_default sysfs_thermal:dir r_dir_perms;
allow hal_thermal_default sysfs_thermal:file rw_file_perms;
allow hal_thermal_default proc_stat:file r_file_perms;

# allow hal_thermal_default self:netlink_kobject_uevent_socket create_socket_perms_no_ioctl;

# read thermal_config
# get_prop(hal_thermal_default, vendor_thermal_prop)
EOF
    popd

    pushd device/sony/customization
       	# Add microg and prebuilts to device
        cat >customization.mk <<EOF
PRODUCT_PACKAGES += \
    GmsCore \
    FakeStore \
    GsfProxy \
    OpenCamera \
    FDroid \
    BromiteSystemWebView
#   DejaVuNlpBackend
#   NominatimNlpBackend
#   LocalGSMNlpBackend
#   WLANNlpBackend
#   MozillaNlpBackend
EOF
    popd

    pushd frameworks/base
        # Add signature spoofing for microg
        patch -p1 < $PATCH_DIR/android_frameworks_base-Q.patch
    popd

    pushd frameworks/opt/net/wifi
        # Prevent WifiLayerLinkStatsError
        git fetch https://github.com/LineageOS/android_frameworks_opt_net_wifi refs/changes/24/260124/3
        git cherry-pick 119f4e61cd2164a56ebc4caba8ec735e36f70422
    popd

}

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------

start=`date +%s`

cd $WORK_DIR

# Read android branch from initialized repo
CURRENT_ANDROID_VERSION=`cat .repo/manifests/default.xml|grep default\ revision|sed 's#^.*refs/tags/\(.*\)"#\1#1'`
#CURRENT_ANDROID_VERSION=android-10.0.0_r36

TARGET_ANDROID_VERSION=android-10.0.0_r36

# Hard cleanup on branch change
if [ $CURRENT_ANDROID_VERSION != $TARGET_ANDROID_VERSION ]; then
    cd ..
    rm -r $WORK_DIR/*
    rm -r $WORK_DIR/.*
    mkdir -p $WORK_DIR
    cd $WORK_DIR
    repo init -u $MIRROR_DIR/platform/manifest.git -b $TARGET_ANDROID_VERSION
    pushd .repo
        git clone https://github.com/sonyxperiadev/local_manifests -b android-10_legacy
    popd
    repo sync
    BUILD_ONLY=false
    REBUILD_KERNEL=true
fi

# Only resync sources when needed
if [ $BUILD_ONLY = false ]; then
    prepare_sources
fi

. build/envsetup.sh
lunch $DEVICE_FLAVOUR

# Only cleanup when needed
if [ $BUILD_ONLY = false ]; then
    make clean
fi

# Only rebuild kernel when needed
if [ $REBUILD_KERNEL = true ]; then
    pushd kernel/sony/msm-4.9/common-kernel
        PLATFORM_UPPER=`echo $PLATFORM|tr '[:lower:]' '[:upper:]'`
        sed -i "s/PLATFORMS=.*/PLATFORMS=$PLATFORM/1" build-kernels-gcc.sh
        sed -i "s/$PLATFORM_UPPER=.*/$PLATFORM_UPPER=$DEVICE/1" build-kernels-gcc.sh
        find . -name "*dtb*" -exec rm "{}" \;
        bash ./build-kernels-gcc.sh
    popd
fi

ccache make -j`nproc --all` dist

echo "Compiled branch '$TARGET_ANDROID_VERSION' in: $((($(date +%s)-$start)/60)) minutes"
