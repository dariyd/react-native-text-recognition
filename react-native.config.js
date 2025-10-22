// react-native.config.js

module.exports = {
  dependency: {
    platforms: {
      ios: {},
      android: {
        packageImportPath: 'import com.reactnativetextrecognition.ReactNativeTextRecognitionPackage;',
        packageInstance: 'new ReactNativeTextRecognitionPackage()',
      },
    },
  },
};

