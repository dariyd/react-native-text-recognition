// RNTextRecognitionSpec.h
// This file is only used when the new architecture is enabled

#ifdef RCT_NEW_ARCH_ENABLED

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NativeTextRecognitionSpec <NSObject>

- (void)recognizeText:(NSString *)fileUrl
              options:(NSDictionary *)options
             callback:(RCTResponseSenderBlock)callback;

- (void)detectText:(NSString *)imgUrl
          callback:(RCTResponseSenderBlock)callback;

- (void)isAvailable:(RCTPromiseResolveBlock)resolve
           rejecter:(RCTPromiseRejectBlock)reject;

- (void)getSupportedLanguages:(RCTPromiseResolveBlock)resolve
                     rejecter:(RCTPromiseRejectBlock)reject;

@end

namespace facebook {
namespace react {

class JSI_EXPORT NativeTextRecognitionSpecJSI : public ObjCTurboModule {
public:
    NativeTextRecognitionSpecJSI(const ObjCTurboModule::InitParams &params);
};

} // namespace react
} // namespace facebook

NS_ASSUME_NONNULL_END

#endif // RCT_NEW_ARCH_ENABLED

