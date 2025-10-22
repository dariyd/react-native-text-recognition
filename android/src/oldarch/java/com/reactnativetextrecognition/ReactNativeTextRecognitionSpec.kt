// ReactNativeTextRecognitionSpec.kt (Old Architecture)

package com.reactnativetextrecognition

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.Promise

abstract class ReactNativeTextRecognitionSpec(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    
    abstract fun isAvailable(promise: Promise)
    abstract fun getSupportedLanguages(promise: Promise)
}

