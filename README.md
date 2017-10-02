# Qvik's Cloudinary utilities

*This Swift3 library provides common functionality for dealing with the Cloudinary CDN.*

See [Cloudinary](http://cloudinary.com/)

## Changelog

* 4.0.0
   * Swift4 version
* 1.0.1
    * Fixed Xcode 8.3 / Swift 3.1 warnings
* 1.0.0
    * Swift3 conversion, release
* 0.0.1
	* Initial version; very much a beta product at this stage.

## Usage

To use the library in your projects, add the following (or what ever suits your needs) to your Podfile:

```ruby
use_frameworks!
source 'https://github.com/qvik/qvik-podspecs.git'

pod 'QvikCloudinary'
```

And the following to your source:

```ruby
import QvikCloudinary
```

## Dependencies

The library has dependencies to the following external modules:

* [QvikSwift](https://github.com/qvik/qvik-swift-ios)
* [Cloudinary](https://cocoapods.org/pods/Cloudinary)
* [XCGLogger](https://cocoapods.org/?q=XCGLogger)

## Controlling the library's log level

The library may emit logging for errors, and if you tell it to, debug stuff. Enable debug logging as such:

```swift
QvikCloudinary.logLevel = .Debug // Or .Info, .Verbose
```

## Features

This chapter introduces the library's classes.

### CloudinaryService

Image / video uploader service class. 

Example usage:

```swift
let cloudinaryService = CloudinaryService(configUrl: "cloudinary://1231231:asdasdasdad@myapp")
            
cloudinaryService.uploadImage(image, progressCallback: { [weak self] (progress) in
  // handle progress                    
 }, completionCallback: { [weak self] (success: Bool, url: String?, width: Int?, height: Int?) -> Void in
   // handle completion
 }

```

### Utility functions

For whole selection and details, see Utils.swift.

```
// Export (and re-encode) video to a file on disk:
exportVideoDataForAssetUrl()

// Create a scaled version of a Cloudinary media URL:
scaledCloudinaryUrl()
```

## Contributing 

Contributions to this library are welcomed. Any contributions have to meet the following criteria:

* Meaningfulness. Discuss whether what you are about to contribute indeed belongs to this library in the first place before submitting a pull request.
* Code style. Follow our [Swift style guide](https://github.com/qvik/swift) 100%.
* Stability. No code in the library must ever crash; never place *assert()*s or implicit optional unwrapping in library methods.
* Testing. Create a test app for testing the functionality of your classes and/or provide unit tests if appropriate.
* Logging. All code in the library must use the common logging handle (see QvikCloudinary.swift) and sensible log levels. 

### License

The library is distributed with the MIT License. Make sure all your source files contain the license header at the start of the file:

```
// The MIT License (MIT)
//
// Copyright (c) 2015-2016 Qvik (www.qvik.fi)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
```

### Submit your code

All merges to the **master** branch go through a *Merge ('pull') Request* and MUST meet the above criteria.

In other words, follow the following procedure to submit your code into the library:

* Clone the library repository
* Create a feature branch for your code
* Code it, clean it up, test it thoroughly
* Make sure all your methods meant to be public are defined as public
* Push your branch
* Create a merge request

## Updating the pod

As a contributor you do not need to do this; we'll update the pod whenever needed by projects.

* Update QvikCloudinary.podspec and set s.version to match the upcoming tag
* Commit all your changes, merge all pending accepted *Merge ('pull') Requests*
* Create a new tag following [Semantic Versioning](http://semver.org/); eg. `git tag -a 1.2.0 -m "Your tag comment"`
* `git push --tags`
* `pod repo push qvik-podspecs QvikCloudinary.podspec`

Unless already set up, you might do the following steps to set up the pod repo:

* ```pod repo add qvik-podspecs https://github.com/qvik/qvik-podspecs.git```

## Contact

Any questions? Contact matti@qvik.fi.
