# android_build
Scripts and docker setup to build Sony AOSP for the Xperia X Compact (Kugo)

I created this for personal use, however it might help others as well and will work for other devices with some adaptations. I will update it infrequently.
Its intention is to support me in building and testing different things. It is not a fully automatic build environment, that poops out ROMs.

If you want to use it, you should look at the following:

* It uses microg out of my prebuilt packages. If you want to change this you need to edit the 'build-10-4.9.sh' script. Also if you want to change the prebuilts that are included in the build.

* The 'Dockerfile' sets your github username and email. You will want to set something in the environment variables in the docker-compose.yml

* The 'docker-compose.yml' file includes mappings to persistent storage, as I do not want to redownload the source files every time. You will need to adapt it to your storage.

* I use a mirror for the android sources. If you do not want to use a local mirror, you will need to change the repo initialization. You can check [https://source.android.com/setup/build/downloading](https://source.android.com/setup/build/downloading) on how to create a local mirror.

* The docker does not compile automatically you will need to enter it via ```docker exec -it android-build bash```. Initial setup of the repo needs to be done by hand. After that you can just call the script to build.

If anything of the above does not make sense for you, then you probably should not use it. ;-)

Thanks to the SONY AOSP team and [stefanhh0](https://github.com/stefanhh0) for help in setting this up!
