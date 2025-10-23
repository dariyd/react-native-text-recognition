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
import {launchImageLibrary} from 'react-native-image-picker';
import DocumentPicker from 'react-native-document-picker';
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
        await processImage(asset.uri);
      }
    } catch (error: any) {
      Alert.alert('Error', error.message);
    }
  };

  const selectFromFiles = async () => {
    try {
      const result = await DocumentPicker.pick({
        type: [
          DocumentPicker.types.images,
          DocumentPicker.types.pdf,
        ],
        allowMultiSelection: false,
      });

      const file = result[0];
      if (file?.uri) {
        await processImage(file.uri);
      }
    } catch (error: any) {
      if (DocumentPicker.isCancel(error)) {
        return;
      }
      Alert.alert('Error', error.message);
    }
  };

  const processImage = async (uri: string) => {
    setLoading(true);
    setImage(null);
    setResult(null);

    try {
      console.log('Processing:', uri);

      // Get image dimensions
      Image.getSize(
        uri,
        async (width, height) => {
          // Calculate display dimensions
          const aspectRatio = height / width;
          const displayWidth = Math.min(width, IMAGE_MAX_WIDTH);
          const displayHeight = displayWidth * aspectRatio;

          setImage({
            uri,
            width,
            height,
            displayWidth,
            displayHeight,
          });

          // Perform OCR
          const ocrResult = await recognizeText(uri, {
            languages: ['en'],
            recognitionLevel: 'word',
          });

          console.log('OCR Result:', JSON.stringify(ocrResult, null, 2));

          if (ocrResult.success) {
            setResult(ocrResult);
            Alert.alert(
              'Success',
              `Found ${ocrResult.pages?.[0]?.elements.length || 0} text elements`,
            );
          } else {
            Alert.alert('Error', ocrResult.errorMessage || 'Recognition failed');
          }

          setLoading(false);
        },
        error => {
          console.error('Image size error:', error);
          Alert.alert('Error', 'Failed to load image');
          setLoading(false);
        },
      );
    } catch (error: any) {
      console.error('Process error:', error);
      Alert.alert('Error', error.message);
      setLoading(false);
    }
  };

  const renderBoundingBoxes = () => {
    if (!image || !result?.pages?.[0]?.elements || !showBoxes) {
      return null;
    }

    const {displayWidth, displayHeight} = image;
    const elements = result.pages[0].elements;

    return (
      <Svg
        width={displayWidth}
        height={displayHeight}
        style={styles.svgOverlay}>
        {elements.map((element: RecognizedTextElement, index: number) => {
          const box = element.boundingBox;
          // Convert normalized coordinates to display coordinates
          const x = box.x * displayWidth;
          const y = box.y * displayHeight;
          const width = box.width * displayWidth;
          const height = box.height * displayHeight;

          return (
            <React.Fragment key={index}>
              {/* Draw boxes only when they do not overlap text by placing them behind image (handled by z-order). */}
              <Rect
                x={x}
                y={y}
                width={width}
                height={height}
                stroke="#00ff00"
                strokeWidth="1.5"
                fill="none"
              />
            </React.Fragment>
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

          {image && (
            <TouchableOpacity
              style={[styles.button, styles.toggleButton]}
              onPress={() => setShowBoxes(!showBoxes)}>
              <Text style={styles.buttonTextDark}>
                {showBoxes ? '🔲 Hide Boxes' : '📦 Show Boxes'}
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
