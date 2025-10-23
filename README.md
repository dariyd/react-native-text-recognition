# react-native-text-recognition

Advanced OCR text recognition for React Native with Vision API (iOS) and ML Kit (Android). Supports multi-language recognition, PDF files, and both old and new React Native architectures.

[![npm version](https://badge.fury.io/js/react-native-text-recognition.svg)](https://badge.fury.io/js/react-native-text-recognition)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 📱 **Cross-platform**: iOS 13+ and Android 21+
- 🚀 **New Architecture Ready**: Full support for React Native new architecture (Fabric/TurboModules) on iOS, old architecture support on Android
- 🔤 **Multi-language Support**: Recognizes text in 100+ languages
- 📄 **PDF Support**: Extract text from PDF documents (both platforms)
- 🎯 **Flexible Results**: Get text with bounding boxes, confidence scores, and coordinates
- 🔍 **Recognition Levels**: Choose between word, line, or block level recognition
- ⚡ **Modern APIs**: 
  - iOS: Uses VNRecognizeTextRequestRevision3 (iOS 16+) with automatic fallback
  - Android: Uses Google ML Kit Text Recognition v2
- 📊 **Rich Metadata**: Get page numbers, dimensions, and hierarchical text structure

## Installation

```bash
npm install react-native-text-recognition
```

or with yarn:

```bash
yarn add react-native-text-recognition
```

### iOS Setup

```bash
cd ios && pod install
```

Add camera permission to your `Info.plist` (if scanning from camera):

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan documents</string>
```

### Android Setup

The module automatically includes ML Kit dependencies. No additional setup required.

Add to your `AndroidManifest.xml` (if scanning from camera):

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Requirements

- **React Native**: 0.77.3 or higher
- **React**: 18.2.0 or higher
- **iOS**: 
  - Minimum: iOS 13.0
  - Recommended: iOS 16.0+ (for VNRecognizeTextRequestRevision3 - best accuracy)
  - Note: Automatically uses best available API for each iOS version
- **Android**: 
  - Min SDK: API 21 (Android 5.0)
  - Target SDK: API 35 (Android 15)
  - Compile SDK: API 35

## Usage

### Basic Usage

```javascript
import { recognizeText } from 'react-native-text-recognition';

// Recognize text from an image
const result = await recognizeText('file:///path/to/image.jpg');

console.log(result.fullText); // All recognized text
console.log(result.pages); // Detailed page-by-page results
```

### With Options

```javascript
// Auto-detect languages (iOS 16+ recommended)
const result = await recognizeText('file:///path/to/image.jpg', {
  languages: [], // Empty array = auto-detect on iOS 16+
  recognitionLevel: 'word',
});

// Or specify known languages for better accuracy
const result = await recognizeText('file:///path/to/document.pdf', {
  languages: ['en', 'es', 'fr'], // Language hints (optional)
  recognitionLevel: 'word', // 'word' | 'line' | 'block'
  maxPages: 10, // For PDFs: limit number of pages
  pdfDpi: 300, // For PDFs: resolution for conversion
});

// Access detailed results
result.pages.forEach((page) => {
  console.log(`Page ${page.pageNumber}:`);
  page.elements.forEach((element) => {
    console.log(`  Text: ${element.text}`);
    console.log(`  Confidence: ${element.confidence}`);
    console.log(`  BoundingBox:`, element.boundingBox);
  });
});
```

### Legacy API (Backward Compatible)

```javascript
import { detectText } from 'react-native-text-recognition';

// Old API still works
const result = await detectText('file:///path/to/image.jpg');
console.log(result.detectedWords);
```

### Check Availability

```javascript
import { isAvailable, getSupportedLanguages } from 'react-native-text-recognition';

const available = await isAvailable();
console.log('Text recognition available:', available);

const languages = await getSupportedLanguages();
console.log('Supported languages:', languages);
```

## API Reference

### `recognizeText(fileUrl, options?, callback?)`

Main method to recognize text from images or PDFs.

**Parameters:**
- `fileUrl` (string): Local file URL (file://, content://, or http(s)://)
- `options` (object, optional): Recognition options
  - `languages` (string[]): Language hints (e.g., ['en', 'es'])
  - `recognitionLevel` ('word' | 'line' | 'block'): Level of text segmentation
  - `useFastRecognition` (boolean): Use fast mode (lower accuracy, faster)
  - `maxPages` (number): For PDFs, maximum pages to process
  - `pdfDpi` (number): For PDFs, DPI for rendering (default: 300)
- `callback` (function, optional): Callback for compatibility

**Returns:** `Promise<TextRecognitionResult>`

### Result Structure

```typescript
interface TextRecognitionResult {
  success: boolean;
  error?: boolean;
  errorMessage?: string;
  pages?: RecognizedPage[];
  totalPages?: number;
  fullText?: string;
}

interface RecognizedPage {
  pageNumber: number;
  dimensions: {
    width: number;
    height: number;
  };
  elements: RecognizedTextElement[];
  fullText: string;
}

interface RecognizedTextElement {
  text: string;
  confidence: number; // 0-1
  level: 'word' | 'line' | 'block';
  boundingBox: {
    x: number; // Normalized 0-1
    y: number; // Normalized 0-1
    width: number; // Normalized 0-1
    height: number; // Normalized 0-1
    absoluteBox?: {
      x: number; // Pixels
      y: number; // Pixels
      width: number; // Pixels
      height: number; // Pixels
    };
  };
  language?: string;
}
```

### Other Methods

- `detectText(imageUrl, callback?)`: Legacy method for backward compatibility
- `isAvailable()`: Check if text recognition is available
- `getSupportedLanguages()`: Get list of supported language codes

## Supported Languages

### iOS (Vision API)

**iOS 16+ (VNRecognizeTextRequestRevision3)** - 100+ languages including:
- Latin scripts: English, Spanish, French, German, Italian, Portuguese, Dutch, Swedish, etc.
- Chinese (Simplified & Traditional)
- Japanese
- Korean
- Arabic
- Hebrew
- Thai
- Vietnamese
- Russian, Ukrainian
- Hindi, Bengali
- And 90+ more languages

**iOS 13-15 (Automatic fallback)** - 20+ languages including:
- English, French, Italian, German, Spanish, Portuguese
- Chinese (Simplified & Traditional)
- Japanese, Korean
- Russian
- Limited coverage compared to iOS 16+

**Note:** The library automatically uses the best available API for your iOS version.

### Android (ML Kit)
- Latin script (English, Spanish, French, German, Italian, Portuguese, etc.)
- Chinese (Simplified & Traditional)
- Japanese
- Korean
- Devanagari (Hindi, Sanskrit, Marathi, Nepali)
- Arabic
- Thai
- Vietnamese

## Platform Differences

While both platforms provide similar functionality, there are some differences:

### iOS
- Uses native Vision framework
- VNRecognizeTextRequestRevision3 on iOS 16+ for best results
- Automatic fallback to earlier revisions on older iOS versions
- Native PDF support via PDFKit
- Provides confidence scores for recognized text

### Android
- Uses Google ML Kit Text Recognition
- Multiple specialized recognizers for different scripts
- PDF rendering via PDF Box Android
- Confidence scores not available (returns 1.0)
- Requires Google Play Services

## React Native New Architecture

This module requires **React Native 0.77.3 or higher** and supports the new architecture on iOS, while using the stable old architecture on Android.

### iOS
✅ **Full support** for new architecture (Fabric/TurboModules)
- Automatically detected when `RCT_NEW_ARCH_ENABLED=1`
- Seamless fallback to old architecture
- Uses VNRecognizeTextRequestRevision3 on iOS 16+ for best accuracy
- Automatically falls back to earlier revisions on iOS 13-15

### Android
⚠️ **Old architecture only** (for now)
- Uses stable bridge implementation
- New architecture support planned for future release
- Keep `newArchEnabled=false` in `gradle.properties`

## Examples

### Recognize Text from Image

```javascript
import { recognizeText } from 'react-native-text-recognition';

const recognizeImage = async (imagePath) => {
  try {
    const result = await recognizeText(imagePath, {
      languages: ['en'],
      recognitionLevel: 'word',
    });

    if (result.success) {
      console.log('Full text:', result.fullText);
      
      // Get all words with their positions
      result.pages[0].elements.forEach((word) => {
        console.log(`"${word.text}" at position:`, word.boundingBox);
      });
    }
  } catch (error) {
    console.error('Recognition failed:', error);
  }
};
```

### Extract Text from PDF

```javascript
import { recognizeText } from 'react-native-text-recognition';

const extractPdfText = async (pdfPath) => {
  try {
    const result = await recognizeText(pdfPath, {
      languages: ['en', 'es'],
      recognitionLevel: 'line',
      maxPages: 5, // Process first 5 pages
      pdfDpi: 200, // Lower DPI for faster processing
    });

    if (result.success) {
      console.log(`Processed ${result.pages.length} of ${result.totalPages} pages`);
      
      result.pages.forEach((page) => {
        console.log(`\nPage ${page.pageNumber + 1}:`);
        console.log(page.fullText);
      });
    }
  } catch (error) {
    console.error('PDF processing failed:', error);
  }
};
```

### Multi-language Recognition

```javascript
const result = await recognizeText('file:///path/to/multilingual.jpg', {
  languages: ['en', 'zh', 'ja', 'ko'], // English, Chinese, Japanese, Korean
  recognitionLevel: 'block',
});
```

## Troubleshooting

### iOS Issues

**"VNRecognizeTextRequest failed"**
- Ensure the image file exists and is readable
- Check that the URL scheme is correct (file://)
- Verify iOS version is 13.0 or higher

**PDF recognition not working**
- PDF support requires iOS 11.0+
- Ensure the PDF is not encrypted or password-protected

### Android Issues

**"ML Kit not available"**
- Ensure Google Play Services is installed
- Check minimum SDK version is 21+
- Verify internet connection for first-time model download

**Out of memory with PDFs**
- Reduce `pdfDpi` option (try 150-200 instead of 300)
- Process fewer pages using `maxPages` option
- Process pages one at a time in a loop

## Performance Tips

1. **Choose appropriate DPI**: For PDFs, 300 DPI provides excellent quality but is slower. Use 150-200 for faster processing.
2. **Limit pages**: Use `maxPages` option when you don't need the entire PDF.
3. **Use fast recognition**: Set `useFastRecognition: true` for real-time scenarios (iOS only).
4. **Recognition level**: 'block' is fastest, 'word' provides most detail.
5. **Language hints**: Providing specific languages improves accuracy and speed.

## Comparison with Other Solutions

| Feature | This Library | react-native-mlkit | react-native-text-detector |
|---------|-------------|-------------------|---------------------------|
| iOS Support | ✅ Vision API | ❌ | ✅ |
| Android Support | ✅ ML Kit v2 | ✅ ML Kit | ✅ |
| PDF Support | ✅ | ❌ | ❌ |
| Multi-language | ✅ 100+ | ✅ | ⚠️ Limited |
| Bounding Boxes | ✅ | ✅ | ✅ |
| New Architecture | ✅ iOS | ❌ | ❌ |
| TypeScript | ✅ | ⚠️ Partial | ❌ |
| Active Maintenance | ✅ | ⚠️ | ❌ |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT © [dariyd](https://github.com/dariyd)

## Acknowledgments

- iOS implementation inspired by [react-native-image-picker](https://github.com/react-native-image-picker/react-native-image-picker)
- Android implementation uses [Google ML Kit](https://developers.google.com/ml-kit)
- Reference architecture from [react-native-document-scanner](https://github.com/dariyd/react-native-document-scanner)

## Related Projects

- [react-native-document-scanner](https://github.com/dariyd/react-native-document-scanner) - Document scanning with VisionKit and ML Kit
- [react-native-vision-camera](https://github.com/mrousavy/react-native-vision-camera) - Camera library for React Native
