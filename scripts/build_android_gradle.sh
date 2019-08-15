#!/usr/bin/env bash
#FIXME: set -eux -o pipefail

echo "build_android_gradle.sh"
echo "$(pwd)"

# ---------------------------------
# Installing openjdk-8
# https://hub.docker.com/r/picoded/ubuntu-openjdk-8-jdk/dockerfile/

sudo apt-get update && \
    sudo apt-get install -y openjdk-8-jdk && \
    sudo apt-get install -y ant && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /var/cache/oracle-jdk8-installer;

sudo apt-get update && \
    sudo apt-get install -y ca-certificates-java && \
    sudo apt-get clean && \
    sudo update-ca-certificates -f && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /var/cache/oracle-jdk8-installer;

# ---------------------------------
# Installing android sdk
# https://github.com/circleci/circleci-images/blob/staging/android/Dockerfile.m4

export sdk_version=sdk-tools-linux-3859397.zip
export android_home=/opt/android/sdk

rm -rf ${android_home}
sudo mkdir -p ${android_home}
curl --silent --show-error --location --fail --retry 3 --output /tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version}
sudo unzip -q /tmp/${sdk_version} -d ${android_home}
rm /tmp/${sdk_version}

export ANDROID_HOME=${android_home}
export ADB_INSTALL_TIMEOUT=120

export PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}"
echo "PATH:${PATH}"
sudo mkdir ~/.android && sudo echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

export sdkmanager_path="${ANDROID_HOME}/tools/bin/sdkmanager"
ls -la "sdkmanager_path:${sdkmanager_path}"

yes | sudo ${sdkmanager_path} --licenses

yes | sudo ${sdkmanager_path} --update

sudo ${sdkmanager_path} \
  "tools" \
  "platform-tools" \
   "emulator"

sudo ${sdkmanager_path} \
  "build-tools;28.0.3"

export API_LEVEL=28
# API_LEVEL string gets replaced by m4
sudo ${sdkmanager_path} "platforms;android-${API_LEVEL}"
sudo ${sdkmanager_path} --list

# ---------------------------------
# Installing android sdk
# https://github.com/keeganwitt/docker-gradle/blob/a206b4a26547df6d8b29d06dd706358e3801d4a9/jdk8/Dockerfile
export GRADLE_VERSION=5.1.1
export gradle_home=/opt/gradle
sudo rm -rf ${gradle_home}
sudo mkdir -p ${gradle_home}

wget --no-verbose --output-document=/tmp/gradle.zip \
"https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

sudo unzip -q /tmp/gradle.zip -d ${gradle_home}
rm /tmp/gradle.zip

export GRADLE_HOME=${gradle_home}/gradle-${GRADLE_VERSION}

export gradle_path="${GRADLE_HOME}/bin/gradle"
echo "gradle_path:${gradle_path}"

${gradle_path} --version

# ---------------------------------
# Libtorch build results linking to pytorch_android

TMP_ANDROID_ABI=x86 # parse from arguments or etc.
BUILD_ANDROID_INCLUDE_DIR=~/workspace/build_android/install/include/
BUILD_ANDROID_LIB_DIR=~/workspace/build_android/install/lib/

PYTORCH_ANDROID_SRC_MAIN_DIR=~/workspace/android/pytorch_android/src/main/

JNI_LIBS_DIR=${PYTORCH_ANDROID_SRC_MAIN_DIR}/jniLibs/${TMP_ANDROID_ABI}/

cp -R ${BUILD_ANDROID_INCLUDE_DIR} ${PYTORCH_ANDROID_SRC_MAIN_DIR}/cpp/
#cp -R ${BUILD_ANDROID_INCLUDE_DIR}/* ${PYTORCH_ANDROID_SRC_MAIN_DIR}/cpp/libtorch_include/${TMP_ANDROID_ABI}/

LIBC10_SO=${BUILD_ANDROID_LIB_DIR}/libc10.so
ls -la ${LIBC10_SO}
LIBTORCH_SO=${BUILD_ANDROID_LIB_DIR}/libtorch.so
ls -la ${LIBTORCH_SO}

ln -s ${LIBC10_SO} ${JNI_LIBS_DIR}/libc10.so
ln -s ${LIBTORCH_SO} ${JNI_LIBS_DIR}/libtorch.so

echo "ANDROID_HOME:${ANDROID_HOME}"
echo "ANDROID_NDK_HOME:${ANDROID_NDK_HOME}"

sudo ${gradle_path} -p ~/workspace/android/pytorch_android buildRelease

echo "build_android_gradle.sh end"
