/**
 * React Native Text Recognition Demo
 * Demonstrates OCR with bounding boxes and text extraction
 */

import React, {useState} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  Alert,
  ActivityIndicator,
  Dimensions,
  useColorScheme,
} from 'react-native';
import {launchImageLibrary, Asset} from 'react-native-image-picker';
import {pick, types} from '@react-native-documents/picker';
import {openDocument} from '@react-native-documents/viewer';
import Svg, {Rect} from 'react-native-svg';
import {recognizeText, isAvailable, getSupportedLanguages} from '@dariyd/react-native-text-recognition';
import type {
  TextRecognitionResult,
  RecognizedTextElement,
} from '@dariyd/react-native-text-recognition';

const {width: SCREEN_WIDTH} = Dimensions.get('window');
const IMAGE_MAX_WIDTH = SCREEN_WIDTH - 40;

interface ProcessedImage {
  uri: string;
  width: number;
  height: number;
  displayWidth: number;
  displayHeight: number;
}

function App() {
  const isDarkMode = useColorScheme() === 'dark';
  const [loading, setLoading] = useState(false);
  const [image, setImage] = useState<ProcessedImage | null>(null);
  const [result, setResult] = useState<TextRecognitionResult | null>(null);
  const [showBoxes, setShowBoxes] = useState(true);
  const [currentPdfUri, setCurrentPdfUri] = useState<string | null>(null);

  const backgroundColor = isDarkMode ? '#000' : '#fff';
  const textColor = isDarkMode ? '#fff' : '#000';
  const cardBg = isDarkMode ? '#1c1c1e' : '#f2f2f7';

  const checkAvailability = async () => {
    try {
      const available = await isAvailable();
      const languages = await getSupportedLanguages();
      Alert.alert(
        'Text Recognition',
        `Available: ${available}\n\nSupported Languages:\n${languages.slice(0, 10).join(', ')}${languages.length > 10 ? `\n...and ${languages.length - 10} more` : ''}`,
      );
    } catch (error: any) {
      Alert.alert('Error', error.message);
    }
  };

  const selectFromGallery = async () => {
    try {
      const result = await launchImageLibrary({
        mediaType: 'photo',
        quality: 1,
        selectionLimit: 1,
      });

      if (result.didCancel) {
        return;
      }

      if (result.errorCode) {
        Alert.alert('Error', result.errorMessage || 'Failed to pick image');
        return;
      }

      const asset = result.assets?.[0];
      if (asset?.uri) {
        await processImage(asset.uri, asset);
      }
    } catch (error: any) {
      Alert.alert('Error', error.message);
    }
  };

  const selectFromFiles = async () => {
    try {
      const result = await pick({
        mode: 'open',
        type: [types.images, types.pdf],
        allowMultiSelection: false,
      });

      const file = result[0];
      if (file?.uri) {
        await processImage(file.uri);
      }
    } catch (error: any) {
      // User cancelled the picker
      if (error?.message?.includes('cancel')) {
        return;
      }
      Alert.alert('Error', error.message || 'Failed to pick file');
    }
  };

  const viewPdf = async () => {
    if (!currentPdfUri) {
      Alert.alert('Error', 'No PDF selected');
      return;
    }
    
    try {
      await openDocument({
        url: currentPdfUri,
        fileName: 'document.pdf',
      });
    } catch (error: any) {
      Alert.alert('Error', `Failed to open PDF: ${error.message}`);
    }
  };

  const processImage = async (uri: string, asset?: Asset) => {
    setLoading(true);
    setImage(null);
    setResult(null);
    
    // Track if this is a PDF
    const isPdf = uri.toLowerCase().endsWith('.pdf');
    setCurrentPdfUri(isPdf ? uri : null);

    try {
      console.log('Processing:', uri);

      // Helper to get size with fallbacks to avoid eternal spinner on some URIs (e.g., ph://)
      const getSize = (): Promise<{w: number; h: number}> => {
        // Prefer asset-provided size if available
        if (asset?.width && asset?.height) {
          return Promise.resolve({w: asset.width, h: asset.height});
        }
        return new Promise((resolve, _reject) => {
          let done = false;
          const timer = setTimeout(() => {
            if (!done) {
              done = true;
              // Fallback size (square) to allow UI to proceed
              resolve({w: IMAGE_MAX_WIDTH, h: IMAGE_MAX_WIDTH});
            }
          }, 5000);
          Image.getSize(
            uri,
            (w, h) => {
              if (!done) {
                done = true;
                clearTimeout(timer);
                resolve({w, h});
              }
            },
            _e => {
              if (!done) {
                done = true;
                clearTimeout(timer);
                resolve({w: IMAGE_MAX_WIDTH, h: IMAGE_MAX_WIDTH});
              }
            },
          );
        });
      };

      const {w, h} = await getSize();
      const aspectRatio = h / w;
      const displayWidth = Math.min(w, IMAGE_MAX_WIDTH);
      const displayHeight = displayWidth * aspectRatio;

      setImage({
        uri,
        width: w,
        height: h,
        displayWidth,
        displayHeight,
      });

      // Perform OCR with timeout to prevent eternal spinner
      const timeout = new Promise<any>((resolve) =>
        setTimeout(() => {
          console.log('OCR timeout after 30s');
          resolve({success: false, error: true, errorMessage: 'OCR timeout after 30s'});
        }, 30000),
      );

      try {
        // Smart defaults: PDFs automatically use 400 DPI + line recognition
        // Images automatically use word recognition
        console.log('Starting OCR with smart defaults');
        
        const ocrResult = await Promise.race([
          recognizeText(uri), // That's it! Smart defaults handle everything
          timeout,
        ]);

        console.log('OCR Result:', JSON.stringify(ocrResult, null, 2));

        if (ocrResult.success) {
          setResult(ocrResult);
          Alert.alert('Success', `Found ${ocrResult.pages?.[0]?.elements?.length || 0} text elements`);
        } else {
          Alert.alert('Error', ocrResult.errorMessage || 'Recognition failed');
        }
      } catch (err: any) {
        console.error('OCR exception:', err);
        Alert.alert('Error', err?.message || 'OCR failed with exception');
      } finally {
        setLoading(false);
      }
    } catch (error: any) {
      console.error('Process error:', error);
      Alert.alert('Error', error.message);
      setLoading(false);
    }
  };

  const renderBoundingBoxes = () => {
    if (!showBoxes || !result?.pages?.[0]?.elements || !image) {
      return null;
    }

    const page = result.pages[0];
    const {displayWidth, displayHeight} = image;

    return (
      <Svg
        style={StyleSheet.absoluteFill}
        width={displayWidth}
        height={displayHeight}
        viewBox={`0 0 ${displayWidth} ${displayHeight}`}>
        {page.elements.map((element, index) => {
          const box = element.boundingBox;
          
          // Convert normalized coordinates (0-1) to display coordinates
          const x = box.x * displayWidth;
          const y = box.y * displayHeight;
          const width = box.width * displayWidth;
          const height = box.height * displayHeight;

          return (
            <Rect
              key={`box-${index}`}
              x={x}
              y={y}
              width={width}
              height={height}
              stroke="#00FF00"
              strokeWidth="2"
              fill="none"
              opacity={0.8}
            />
          );
        })}
      </Svg>
    );
  };

  const renderRecognizedText = () => {
    if (!result?.pages?.[0]) {
      return null;
    }

    const page = result.pages[0];

    return (
      <View style={[styles.textContainer, {backgroundColor: cardBg}]}>
        <View style={styles.textHeader}>
          <Text style={[styles.textTitle, {color: textColor}]}>
            Recognized Text
          </Text>
          <Text style={[styles.textStats, {color: textColor}]}>
            {page.elements.length} elements
          </Text>
        </View>

        <View style={styles.divider} />

        <ScrollView style={styles.textScroll}>
          <Text style={[styles.fullText, {color: textColor}]}>
            {page.fullText}
          </Text>

          <View style={styles.divider} />

          <Text style={[styles.elementsTitle, {color: textColor}]}>
            Individual Elements:
          </Text>

          {page.elements.map((element: RecognizedTextElement, index: number) => (
            <View key={index} style={[styles.elementCard, {backgroundColor: isDarkMode ? '#2c2c2e' : '#fff'}]}>
              <View style={styles.elementHeader}>
                <Text style={[styles.elementText, {color: textColor}]}>
                  {element.text}
                </Text>
                <Text style={[styles.confidence, {color: '#00ff00'}]}>
                  {(element.confidence * 100).toFixed(0)}%
                </Text>
              </View>
              <Text style={[styles.elementInfo, {color: isDarkMode ? '#999' : '#666'}]}>
                Level: {element.level} | Position: ({element.boundingBox.x.toFixed(3)}, {element.boundingBox.y.toFixed(3)})
              </Text>
            </View>
          ))}
        </ScrollView>
      </View>
    );
  };

  return (
    <SafeAreaView style={[styles.container, {backgroundColor}]}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />

      <ScrollView style={styles.scrollView}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.title, {color: textColor}]}>
            Text Recognition Demo
          </Text>
          <Text style={[styles.subtitle, {color: isDarkMode ? '#999' : '#666'}]}>
            OCR with bounding boxes visualization
          </Text>
        </View>

        {/* Action Buttons */}
        <View style={styles.buttonContainer}>
          <TouchableOpacity
            style={[styles.button, styles.primaryButton]}
            onPress={selectFromGallery}
            disabled={loading}>
            <Text style={styles.buttonText}>📷 Select from Gallery</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.secondaryButton]}
            onPress={selectFromFiles}
            disabled={loading}>
            <Text style={styles.buttonText}>📁 Select from Files</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.infoButton]}
            onPress={checkAvailability}>
            <Text style={styles.buttonTextDark}>ℹ️ Check Availability</Text>
          </TouchableOpacity>

          {result && (
            <TouchableOpacity
              style={[styles.button, styles.toggleButton]}
              onPress={() => setShowBoxes(!showBoxes)}>
              <Text style={styles.buttonText}>
                {showBoxes ? '👁️ Hide Boxes' : '👁️‍🗨️ Show Boxes'}
              </Text>
            </TouchableOpacity>
          )}

          {currentPdfUri && (
            <TouchableOpacity
              style={[styles.button, styles.viewPdfButton]}
              onPress={viewPdf}>
              <Text style={styles.buttonText}>
                📄 View PDF
              </Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Loading Indicator */}
        {loading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#007AFF" />
            <Text style={[styles.loadingText, {color: textColor}]}>
              Processing image...
            </Text>
          </View>
        )}

        {/* Image with Bounding Boxes */}
        {image && !loading && (
          <View style={styles.imageContainer}>
            <Text style={[styles.sectionTitle, {color: textColor}]}>
              Image with OCR Results
            </Text>
            <View
              style={[
                styles.imageWrapper,
                {
                  width: image.displayWidth,
                  height: image.displayHeight,
                },
              ]}>
              <Image
                source={{uri: image.uri}}
                style={{
                  width: image.displayWidth,
                  height: image.displayHeight,
                }}
                resizeMode="contain"
              />
              {renderBoundingBoxes()}
            </View>
            <Text style={[styles.imageInfo, {color: isDarkMode ? '#999' : '#666'}]}>
              Original: {image.width} x {image.height}px | Display: {Math.round(image.displayWidth)} x {Math.round(image.displayHeight)}px
            </Text>
          </View>
        )}

        {/* Recognized Text */}
        {result && !loading && renderRecognizedText()}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
  },
  buttonContainer: {
    padding: 20,
    gap: 12,
  },
  button: {
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: '#007AFF',
  },
  secondaryButton: {
    backgroundColor: '#5856D6',
  },
  infoButton: {
    backgroundColor: '#FF9500',
  },
  toggleButton: {
    backgroundColor: '#34C759',
  },
  viewPdfButton: {
    backgroundColor: '#AF52DE',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonTextDark: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  loadingContainer: {
    padding: 40,
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
  },
  imageContainer: {
    padding: 20,
    alignItems: 'center',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  imageWrapper: {
    position: 'relative',
    borderRadius: 12,
    overflow: 'hidden',
  },
  svgOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
  },
  imageInfo: {
    marginTop: 8,
    fontSize: 12,
  },
  textContainer: {
    margin: 20,
    padding: 20,
    borderRadius: 12,
    maxHeight: 500,
  },
  textHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  textTitle: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  textStats: {
    fontSize: 14,
  },
  divider: {
    height: 1,
    backgroundColor: '#ccc',
    marginVertical: 12,
  },
  textScroll: {
    maxHeight: 400,
  },
  fullText: {
    fontSize: 16,
    lineHeight: 24,
  },
  elementsTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 8,
    marginBottom: 12,
  },
  elementCard: {
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  elementHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  elementText: {
    fontSize: 15,
    fontWeight: '500',
    flex: 1,
  },
  confidence: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  elementInfo: {
    fontSize: 11,
  },
});

export default App;
