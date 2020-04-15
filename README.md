![bitrise-step-apk-info](imgs/logo.svg)

# Bitrise Step - APK Info

Bitrise step that produces metadata to given APK file.

## Usage

Add this step using standard Workflow Editor and provide required input environment variables.

### Input

`$BITRISE_APK_PATH` - File path to APK file to get info from. 
      
### Outputs 
`$ANDROID_APP_PACKAGE_NAME` - Android application package name, ex. com.package.my

`$ANDROID_APK_FILE_SIZE` - Android APK file size, in bytes
 
`$ANDROID_APP_NAME` - Android application name from APK
 
`$ANDROID_APP_VERSION_NAME` - Android application version name from APK, ex. 1.0.0

`$ANDROID_APP_VERSION_CODE` - Android application version code from APK, ex. 10
 
`$ANDROID_ICON_PATH` - File path to android application icon     

## Contributors

Current maintainer and main contributor is [Lukáš Sztefek](https://github.com/skywall), <lukas.sztefek@futured.app>.

We want to thank other contributors, namely:

- [Radim Vaculík](https://github.com/radimvaculik)

## License

Bitrise Step - APK Info is available under the MIT license. See the [LICENSE](LICENSE) for more information.
