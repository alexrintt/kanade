To display all installed apps the [`🔗 device_packages`](https://github.com/alexrintt/device-packages) package is used and the apk extraction (that is a simple copy/paste operation between two files) is possible by [`🔗 shared_storage`](https://pub.dev/packages/shared_storage) package.

The above mentioned packages are using [Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider) along with the [PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager.PackageInfoFlags) API.
