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

export default TurboModuleRegistry.getEnforcing<Spec>('ReactNativeTextRecognition');

