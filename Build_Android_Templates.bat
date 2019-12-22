
cd ./engine

call scons -j6 platform=android target=release_debug android_arch=armv7 entities_2d=yes
call scons -j6 platform=android target=release_debug android_arch=arm64v8 entities_2d=yes
call scons -j6 platform=android target=release_debug android_arch=x86 entities_2d=yes

cd ./platform/android/java

rem call .\gradlew.bat build
call .\gradlew.bat generateGodotTemplates


cd ..
cd ..
cd ..
cd ..