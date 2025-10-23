// main index.js

import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-text-recognition' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Try new architecture (TurboModule) first, then fall back to old architecture
let ReactNativeTextRecognition;

if (global.__turboModuleProxy != null) {
  try {
    const TurboModuleRegistry = require('react-native').TurboModuleRegistry;
    ReactNativeTextRecognition = TurboModuleRegistry.get('ReactNativeTextRecognition');
  } catch (e) {
    // New architecture not available, fall back to old arch
    console.log('TurboModule not available, using old architecture');
  }
}

// Fall back to old architecture (NativeModules)
if (!ReactNativeTextRecognition) {
  ReactNativeTextRecognition = NativeModules.ReactNativeTextRecognition;
}

// If still not found, throw a helpful error
if (!ReactNativeTextRecognition) {
  ReactNativeTextRecognition = new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );
}

export default ReactNativeTextRecognition;

/**
 * Recognizes text from an image or PDF file
 * @param {string} fileUrl - Local file URL (file://, content://, or http(s)://)
 * @param {object} options - Recognition options
 * @param {function} callback - Optional callback for compatibility
 * @returns {Promise} Promise with recognition results
 */
export function recognizeText(fileUrl, options, callback) {
  // Handle overloaded signatures
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }
  
  if (!options) {
    options = {};
  }
  
  return new Promise((resolve, reject) => {
    ReactNativeTextRecognition.recognizeText(
      fileUrl,
      options,
      (result) => {
        if (callback) callback(result);
        
        if (result.error) {
          reject(new Error(result.errorMessage || 'Text recognition failed'));
        } else {
          resolve(result);
        }
      }
    );
  });
}

/**
 * Legacy method for backward compatibility
 * @deprecated Use recognizeText instead
 */
export function detectText(imageUrl, callback) {
  return new Promise((resolve) => {
    ReactNativeTextRecognition.detectText(
      imageUrl,
      (result) => {
        if (callback) callback(result);
        resolve(result);
      }
    );
  });
}

/**
 * Check if text recognition is available on this device
 * @returns {Promise<boolean>}
 */
export function isAvailable() {
  return ReactNativeTextRecognition.isAvailable
    ? ReactNativeTextRecognition.isAvailable()
    : Promise.resolve(true);
}

/**
 * Get list of supported languages for text recognition
 * @returns {Promise<string[]>}
 */
export function getSupportedLanguages() {
  return ReactNativeTextRecognition.getSupportedLanguages
    ? ReactNativeTextRecognition.getSupportedLanguages()
    : Promise.resolve(['en']);
}
