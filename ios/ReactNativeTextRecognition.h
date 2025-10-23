// ReactNativeTextRecognition.h

#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactNativeTextRecognitionSpec/ReactNativeTextRecognitionSpec.h>
// The generated protocol name is Native + <SpecName>
@interface ReactNativeTextRecognition : NativeTextRecognitionSpecBase <NativeTextRecognitionSpec>
#else
@interface ReactNativeTextRecognition : NSObject <RCTBridgeModule>
#endif

@end
