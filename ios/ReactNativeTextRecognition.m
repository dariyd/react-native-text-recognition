// ReactNativeTextRecognition.m

#import "ReactNativeTextRecognition.h"
#import <Vision/Vision.h>
#import <VisionKit/VisionKit.h>
#import <PDFKit/PDFKit.h>
#import <React/RCTLog.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTConvert.h>
#endif

@interface ReactNativeTextRecognition ()
@property (nonatomic, strong) RCTResponseSenderBlock callback;
@end

@implementation ReactNativeTextRecognition

RCT_EXPORT_MODULE()

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeTextRecognitionSpecJSI>(params);
}
#endif

#pragma mark - Public Methods

RCT_EXPORT_METHOD(recognizeText:(NSString *)fileUrl
                  options:(NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performTextRecognition:fileUrl options:options callback:callback];
    });
}

// Legacy method for backward compatibility
RCT_EXPORT_METHOD(detectText:(NSString *)imgUrl
                  callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recognizeTextLegacy:imgUrl callback:callback];
    });
}

RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // Text recognition is available on iOS 13+
    if (@available(iOS 13.0, *)) {
        resolve(@YES);
    } else {
        resolve(@NO);
    }
}

RCT_EXPORT_METHOD(getSupportedLanguages:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 16.0, *)) {
        NSArray<VNRecognizedTextObservationRequestRevision> *revisions = @[@(VNRecognizeTextRequestRevision3)];
        NSArray *languages = [VNRecognizeTextRequest supportedRecognitionLanguagesForTextRecognitionLevel:VNRequestTextRecognitionLevelAccurate
                                                                                                  revision:VNRecognizeTextRequestRevision3
                                                                                                     error:nil];
        resolve(languages ?: @[@"en"]);
    } else if (@available(iOS 13.0, *)) {
        // iOS 13-15: Limited language support
        resolve(@[@"en", @"fr", @"it", @"de", @"es", @"pt", @"zh-Hans", @"zh-Hant"]);
    } else {
        resolve(@[@"en"]);
    }
}

#pragma mark - Text Recognition

- (void)performTextRecognition:(NSString *)fileUrl
                       options:(NSDictionary *)options
                      callback:(RCTResponseSenderBlock)callback
{
    self.callback = callback;
    
    // Parse options
    NSArray *languages = options[@"languages"];
    NSString *recognitionLevel = options[@"recognitionLevel"] ?: @"word";
    BOOL useFastRecognition = [options[@"useFastRecognition"] boolValue];
    NSInteger maxPages = options[@"maxPages"] ? [options[@"maxPages"] integerValue] : NSIntegerMax;
    NSInteger pdfDpi = options[@"pdfDpi"] ? [options[@"pdfDpi"] integerValue] : 300;
    
    RCTLogInfo(@"Text recognition started for file: %@", fileUrl);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSURL *url = [NSURL URLWithString:fileUrl];
            if (!url) {
                [self sendError:@"Invalid file URL"];
                return;
            }
            
            // Check if it's a PDF
            NSString *extension = [[url pathExtension] lowercaseString];
            if ([extension isEqualToString:@"pdf"]) {
                [self processPDFFile:url
                             options:options
                            maxPages:maxPages
                              pdfDpi:pdfDpi
                           languages:languages
                    recognitionLevel:recognitionLevel
                  useFastRecognition:useFastRecognition];
            } else {
                [self processImageFile:url
                             languages:languages
                      recognitionLevel:recognitionLevel
                    useFastRecognition:useFastRecognition];
            }
        } @catch (NSException *exception) {
            [self sendError:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
    });
}

- (void)processImageFile:(NSURL *)url
               languages:(NSArray *)languages
        recognitionLevel:(NSString *)recognitionLevel
      useFastRecognition:(BOOL)useFastRecognition
{
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithURL:url options:@{}];
    
    VNRecognizeTextRequest *request = [self createTextRecognitionRequest:languages
                                                         recognitionLevel:recognitionLevel
                                                       useFastRecognition:useFastRecognition];
    
    NSError *error = nil;
    [requestHandler performRequests:@[request] error:&error];
    
    if (error) {
        [self sendError:[NSString stringWithFormat:@"Request error: %@", error.localizedDescription]];
    }
}

- (void)processPDFFile:(NSURL *)url
               options:(NSDictionary *)options
              maxPages:(NSInteger)maxPages
                pdfDpi:(NSInteger)pdfDpi
             languages:(NSArray *)languages
      recognitionLevel:(NSString *)recognitionLevel
    useFastRecognition:(BOOL)useFastRecognition
API_AVAILABLE(ios(11.0))
{
    PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:url];
    
    if (!pdfDocument) {
        [self sendError:@"Failed to load PDF document"];
        return;
    }
    
    NSInteger pageCount = pdfDocument.pageCount;
    NSInteger pagesToProcess = MIN(pageCount, maxPages);
    
    NSMutableArray *allPages = [NSMutableArray array];
    
    for (NSInteger i = 0; i < pagesToProcess; i++) {
        @autoreleasepool {
            PDFPage *pdfPage = [pdfDocument pageAtIndex:i];
            if (!pdfPage) continue;
            
            // Convert PDF page to image
            UIImage *pageImage = [self imageFromPDFPage:pdfPage dpi:pdfDpi];
            if (!pageImage) continue;
            
            // Recognize text in this page
            NSDictionary *pageResult = [self recognizeTextInImage:pageImage
                                                        pageNumber:i
                                                         languages:languages
                                                  recognitionLevel:recognitionLevel
                                                useFastRecognition:useFastRecognition];
            
            if (pageResult) {
                [allPages addObject:pageResult];
            }
        }
    }
    
    // Combine results
    NSMutableString *fullText = [NSMutableString string];
    for (NSDictionary *page in allPages) {
        if (page[@"fullText"]) {
            [fullText appendString:page[@"fullText"]];
            [fullText appendString:@"\n\n"];
        }
    }
    
    NSDictionary *result = @{
        @"success": @YES,
        @"pages": allPages,
        @"totalPages": @(pageCount),
        @"fullText": fullText
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callback(@[result]);
    });
}

- (UIImage *)imageFromPDFPage:(PDFPage *)pdfPage dpi:(NSInteger)dpi API_AVAILABLE(ios(11.0))
{
    CGRect pageRect = [pdfPage boundsForBox:kPDFDisplayBoxMediaBox];
    CGFloat scale = dpi / 72.0; // 72 DPI is the default
    
    CGSize renderSize = CGSizeMake(pageRect.size.width * scale, pageRect.size.height * scale);
    
    UIGraphicsBeginImageContextWithOptions(renderSize, YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill background with white
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, renderSize.width, renderSize.height));
    
    // Scale and render PDF page
    CGContextScaleCTM(context, scale, scale);
    [pdfPage drawWithBox:kPDFDisplayBoxMediaBox toContext:context];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (NSDictionary *)recognizeTextInImage:(UIImage *)image
                            pageNumber:(NSInteger)pageNumber
                             languages:(NSArray *)languages
                      recognitionLevel:(NSString *)recognitionLevel
                    useFastRecognition:(BOOL)useFastRecognition
{
    if (!image) return nil;
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    if (!ciImage) return nil;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    
    __block NSArray *results = nil;
    __block NSError *requestError = nil;
    
    VNRecognizeTextRequest *request = [self createTextRecognitionRequest:languages
                                                         recognitionLevel:recognitionLevel
                                                       useFastRecognition:useFastRecognition];
    
    request.completionHandler = ^(VNRequest *request, NSError *error) {
        if (!error) {
            results = request.results;
        } else {
            requestError = error;
        }
    };
    
    [handler performRequests:@[request] error:&requestError];
    
    if (requestError || !results) {
        return nil;
    }
    
    return [self formatRecognitionResults:results
                               pageNumber:pageNumber
                           imageDimensions:CGSizeMake(image.size.width, image.size.height)
                         recognitionLevel:recognitionLevel];
}

- (VNRecognizeTextRequest *)createTextRecognitionRequest:(NSArray *)languages
                                        recognitionLevel:(NSString *)recognitionLevel
                                      useFastRecognition:(BOOL)useFastRecognition
{
    VNRecognizeTextRequest *request;
    
    if (@available(iOS 16.0, *)) {
        // Use Revision 3 for iOS 16+
        request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:nil];
        request.revision = VNRecognizeTextRequestRevision3;
        
        // Set recognition level
        if (useFastRecognition) {
            request.recognitionLevel = VNRequestTextRecognitionLevelFast;
        } else {
            request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        }
        
        // Set languages if specified
        if (languages && languages.count > 0) {
            request.recognitionLanguages = languages;
        }
        
        // Enable automatic language correction
        request.usesLanguageCorrection = YES;
        
    } else if (@available(iOS 13.0, *)) {
        // Fallback to older revision for iOS 13-15
        request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:nil];
        
        if (useFastRecognition) {
            request.recognitionLevel = VNRequestTextRecognitionLevelFast;
        } else {
            request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        }
        
        // Language support is limited in older versions
        if (languages && languages.count > 0 && @available(iOS 14.0, *)) {
            request.recognitionLanguages = languages;
        }
        
        request.usesLanguageCorrection = YES;
    }
    
    return request;
}

- (NSDictionary *)formatRecognitionResults:(NSArray *)results
                                pageNumber:(NSInteger)pageNumber
                            imageDimensions:(CGSize)dimensions
                          recognitionLevel:(NSString *)recognitionLevel
{
    NSMutableArray *elements = [NSMutableArray array];
    NSMutableString *fullText = [NSMutableString string];
    
    for (VNRecognizedTextObservation *observation in results) {
        VNRecognizedText *topCandidate = [[observation topCandidates:1] firstObject];
        if (!topCandidate) continue;
        
        CGRect boundingBox = observation.boundingBox;
        
        // Convert Vision coordinates (bottom-left origin) to top-left origin
        CGRect normalizedBox = CGRectMake(
            boundingBox.origin.x,
            1.0 - boundingBox.origin.y - boundingBox.size.height,
            boundingBox.size.width,
            boundingBox.size.height
        );
        
        NSDictionary *element = @{
            @"text": topCandidate.string,
            @"confidence": @(topCandidate.confidence),
            @"level": recognitionLevel,
            @"boundingBox": @{
                @"x": @(normalizedBox.origin.x),
                @"y": @(normalizedBox.origin.y),
                @"width": @(normalizedBox.size.width),
                @"height": @(normalizedBox.size.height),
                @"absoluteBox": @{
                    @"x": @(normalizedBox.origin.x * dimensions.width),
                    @"y": @(normalizedBox.origin.y * dimensions.height),
                    @"width": @(normalizedBox.size.width * dimensions.width),
                    @"height": @(normalizedBox.size.height * dimensions.height)
                }
            }
        };
        
        [elements addObject:element];
        [fullText appendString:topCandidate.string];
        [fullText appendString:@" "];
    }
    
    return @{
        @"pageNumber": @(pageNumber),
        @"dimensions": @{
            @"width": @(dimensions.width),
            @"height": @(dimensions.height)
        },
        @"elements": elements,
        @"fullText": [fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
    };
}

#pragma mark - Legacy Method

- (void)recognizeTextLegacy:(NSString *)imgUrl callback:(RCTResponseSenderBlock)callback
{
    self.callback = callback;
    RCTLogInfo(@"Legacy text recognition for: %@", imgUrl);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:imgUrl];
        VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithURL:url options:@{}];
        
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    RCTLogError(@"VNRecognizeTextRequest error: %@", error);
                    self.callback(@[@{@"error": @YES, @"errorMessage": error.localizedDescription}]);
                });
            } else {
                if (request.results.count > 0) {
                    NSMutableArray *words = [NSMutableArray array];
                    for (VNRecognizedTextObservation *observation in request.results) {
                        VNRecognizedText *topCandidate = [[observation topCandidates:1] firstObject];
                        [words addObject:@{
                            @"text": topCandidate.string,
                            @"confidence": @(topCandidate.confidence).stringValue
                        }];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        RCTLogInfo(@"Detected words: %lu", (unsigned long)words.count);
                        self.callback(@[@{@"detectedWords": words}]);
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.callback(@[@{@"detectedWords": @[]}]);
                    });
                }
            }
        }];
        
        if (@available(iOS 16.0, *)) {
            request.revision = VNRecognizeTextRequestRevision3;
        }
        request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        request.usesLanguageCorrection = YES;
        
        NSError *error = nil;
        [requestHandler performRequests:@[request] error:&error];
        if (error) {
            RCTLogError(@"Request handler error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.callback(@[@{@"error": @YES, @"errorMessage": error.localizedDescription}]);
            });
        }
    });
}

#pragma mark - Helpers

- (void)sendError:(NSString *)errorMessage
{
    RCTLogError(@"%@", errorMessage);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callback(@[@{
            @"success": @NO,
            @"error": @YES,
            @"errorMessage": errorMessage
        }]);
    });
}

@end
