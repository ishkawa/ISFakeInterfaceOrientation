default:
	if [ -a Products ]; then rm -R Products; fi;
	mkdir -p Products/ISFakeInterfaceOrientation
	xcodebuild -target ISFakeInterfaceOrientation -sdk iphoneos -arch armv7 -arch armv7s clean build
	xcodebuild -target ISFakeInterfaceOrientation -sdk iphonesimulator -arch i386 clean build
	xcrun lipo -create build/Release-iphonesimulator/libISFakeInterfaceOrientation.a  build/Release-iphoneos/libISFakeInterfaceOrientation.a -output Products/libISFakeInterfaceOrientation.a
	cp ISFakeInterfaceOrientation/*.h Products/ISFakeInterfaceOrientation/
