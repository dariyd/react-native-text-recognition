/**
 * Codegen spec for React Native Text Recognition
 * This file is used by React Native Codegen to generate native spec files
 */

import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  recognizeText(
    fileUrl: string,
    options: Object,
    callback: (result: Object) => void,
  ): void;
  
  detectText(
    imgUrl: string,
    callback: (result: Object) => void,
  ): void;
  
  isAvailable(): Promise<boolean>;
  
  getSupportedLanguages(): Promise<string[]>;
}

export default TurboModuleRegistry.get<Spec>('ReactNativeTextRecognition');

