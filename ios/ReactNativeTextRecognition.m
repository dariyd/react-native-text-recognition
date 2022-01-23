// ReactNativeTextRecognition.m

#import "ReactNativeTextRecognition.h"
#import "Vision/Vision.h"
#import "VisionKit/VisionKit.h"


@interface ReactNativeTextRecognition ()

@property (nonatomic, strong) RCTResponseSenderBlock callback;

@end

@implementation ReactNativeTextRecognition

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(detectText:(NSString *)imgUrl callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recognizeText:imgUrl callback:callback];
    });
}

- (void)recognizeText:(NSString *)imgUrl callback:(RCTResponseSenderBlock)callback
{
    self.callback = callback;
    NSLog(@"img url %@", imgUrl);
//    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithURL:[NSURL URLWithString:imgUrl] options:@{}];
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    NSLog(@"VNRecognizeTextRequest error: %@", error);
                    self.callback(@[@{@"error": @YES, @"errorMessage": error.localizedFailureReason}]);
                });
            } else {
                if (request.results.count > 0) {
                    NSMutableArray *words = [NSMutableArray array];
                    for (VNRecognizedTextObservation *observation in request.results) {
                        VNRecognizedText * topCandiate = [[observation topCandidates:1] firstObject];
                        [words addObject:@{@"text": topCandiate.string, @"confidence": @(topCandiate.confidence).stringValue}];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        NSLog(@"DETECTED WORDS %@", words);
                        self.callback(@[@{@"detectedWords": words}]);
                    });
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        self.callback(@[@{@"detectedWords": @[]}]);
                    });
                }
            }
        }];

        NSError *error = nil;
        [requestHandler performRequests:@[request] error:&error];
        if (error) {
            NSLog(@"requestHandler error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self.callback(@[@{@"error": @YES, @"errorMessage": error.localizedFailureReason}]);
            });
            
        }
    });
    
}

@end

