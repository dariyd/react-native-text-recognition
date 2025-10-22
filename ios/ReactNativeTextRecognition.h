// ReactNativeTextRecognition.h

#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactNativeTextRecognitionSpec/ReactNativeTextRecognitionSpec.h>
@interface ReactNativeTextRecognition : NSObject <NativeTextRecognitionSpec>
#else
@interface ReactNativeTextRecognition : NSObject <RCTBridgeModule>
#endif

@end
