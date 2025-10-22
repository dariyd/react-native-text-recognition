# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-22

### 🎉 Major Release - Complete Rewrite

This is a major release with breaking changes and significant improvements.

### Added

#### iOS
- ✨ **VNRecognizeTextRequestRevision3 support** (iOS 16+) for improved accuracy
- 📄 **PDF support** - Extract text from PDF documents with configurable DPI
- 🌍 **Multi-language support** - Recognition in 100+ languages
- 🔍 **Flexible recognition levels** - Choose word, line, or block level
- 📊 **Bounding box coordinates** - Both normalized and absolute pixel coordinates
- 🚀 **New Architecture support** - Full Fabric/TurboModules compatibility
- ⚡ **Fast recognition mode** - Optional faster processing with lower accuracy
- 🔄 **Automatic API fallback** - Uses best available API version per iOS version

#### Android
- ✨ **ML Kit Text Recognition v2** - Modern Google ML Kit implementation
- 📄 **PDF support** - Extract text from PDF documents
- 🌍 **Multi-language support** - Latin, Chinese, Japanese, Korean, Devanagari, etc.
- 🔍 **Multiple specialized recognizers** - Optimized for different scripts
- 📊 **Bounding box coordinates** - Both normalized and absolute pixel coordinates
- 🏗️ **Kotlin implementation** - Modern, type-safe codebase
- 📦 **Architecture ready** - Prepared for new architecture migration

#### Cross-Platform
- 📋 **Unified API** - Same interface for iOS and Android
- 📄 **TypeScript definitions** - Full type safety with detailed types
- 🔄 **Promise-based API** - Modern async/await support
- 📊 **Rich result structure** - Detailed page, element, and confidence data
- 🔍 **Language detection** - Automatic language detection when not specified
- ⚙️ **Configurable options** - Fine-tune recognition behavior
- 📖 **Comprehensive documentation** - Detailed README with examples

### Changed

- 🔄 **Breaking**: Updated minimum requirements:
  - React Native >= 0.77.3 (was >= 0.60.0)
  - React >= 18.2.0 (was >= 16.8.1)
  - iOS >= 13.0 (iOS 16.0+ recommended for best results)
  - Android minSDK 21, targetSDK 35 (was 16, 28)
  
- 🔄 **Breaking**: Result structure completely redesigned:
  - Old: `{ detectedWords: [...] }`
  - New: `{ success, pages: [{ pageNumber, elements: [...], fullText }], totalPages, fullText }`

- 🔄 **Breaking**: Package structure reorganized:
  - Android: `com.reactlibrary` → `com.reactnativetextrecognition`
  - Kotlin implementation instead of Java

- 📝 Improved error handling with detailed error messages
- ⚡ Better performance with optimized processing pipelines
- 🎯 More accurate text recognition using latest APIs

### Fixed

- 🐛 Fixed memory leaks in image processing
- 🐛 Fixed coordinate system inconsistencies between platforms
- 🐛 Fixed crashes with large images
- 🐛 Improved error handling for invalid file paths
- 🐛 Fixed threading issues in async processing

### Deprecated

- ⚠️ `detectText()` method is now deprecated (still works for backward compatibility)
  - Use `recognizeText()` instead for new projects

### Migration Guide

#### For existing users:

**Option 1: Keep using legacy API (no changes needed)**
```javascript
import { detectText } from 'react-native-text-recognition';
const result = await detectText('file:///path/to/image.jpg');
// Works as before
```

**Option 2: Migrate to new API (recommended)**
```javascript
import { recognizeText } from 'react-native-text-recognition';
const result = await recognizeText('file:///path/to/image.jpg', {
  languages: ['en'],
  recognitionLevel: 'word',
});

// Access results
console.log(result.fullText); // All text
result.pages[0].elements.forEach(element => {
  console.log(element.text, element.boundingBox);
});
```

## [1.0.0] - Previous Release

### Initial release
- Basic text recognition for iOS using Vision framework
- Simple API with callback-based interface
- Single language support (English)
- Image-only support

---

## Links

- [GitHub Repository](https://github.com/dariyd/react-native-text-recognition)
- [npm Package](https://www.npmjs.com/package/react-native-text-recognition)
- [Issue Tracker](https://github.com/dariyd/react-native-text-recognition/issues)

