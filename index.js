// main index.js

import { NativeModules } from 'react-native';

const { ReactNativeTextRecognition } = NativeModules;

export default ReactNativeTextRecognition;

export function recognizeText(imagUrl, callback) {
  return new Promise(resolve => {
    ReactNativeTextRecognition.detectText(
      imagUrl,
      (result) => {
        if(callback) callback(result);
        resolve(result);
      },
    );
  });  
}
