// ReactNativeTextRecognition.h

#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTTurboModule.h>
#import "RNTextRecognitionSpec.h"

@interface ReactNativeTextRecognition : NSObject <RCTBridgeModule, RCTTurboModule>
#else
@interface ReactNativeTextRecognition : NSObject <RCTBridgeModule>
#endif

@end
