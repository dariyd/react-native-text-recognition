// ReactNativeTextRecognitionSpec.kt (New Architecture)

package com.reactnativetextrecognition

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.Promise

// Placeholder for new architecture support
// TODO: Implement TurboModule spec when migrating to new architecture
abstract class ReactNativeTextRecognitionSpec(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    
    abstract fun isAvailable(promise: Promise)
    abstract fun getSupportedLanguages(promise: Promise)
}

