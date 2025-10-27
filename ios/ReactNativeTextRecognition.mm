// ReactNativeTextRecognition.mm

#import "ReactNativeTextRecognition.h"
#import <Vision/Vision.h>
#import <VisionKit/VisionKit.h>
#import <PDFKit/PDFKit.h>
#import <React/RCTLog.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactCommon/RCTTurboModule.h>
#import <React/RCTConvert.h>
#endif

using namespace facebook::react;

@interface ReactNativeTextRecognition ()
@property (nonatomic, strong) RCTResponseSenderBlock callback;
// Forward declarations to satisfy compiler for private methods
- (void)processPDFFile:(NSURL *)url
               options:(NSDictionary *)options
              maxPages:(NSInteger)maxPages
                pdfDpi:(NSInteger)pdfDpi
             languages:(NSArray *)languages
      recognitionLevel:(NSString *)recognitionLevel
    useFastRecognition:(BOOL)useFastRecognition
      preprocessImages:(BOOL)preprocessImages;

- (void)processImageFile:(NSURL *)url
               languages:(NSArray *)languages
        recognitionLevel:(NSString *)recognitionLevel
      useFastRecognition:(BOOL)useFastRecognition;

- (NSDictionary *)recognizeTextInImage:(UIImage *)image
                            pageNumber:(NSInteger)pageNumber
                             languages:(NSArray *)languages
                      recognitionLevel:(NSString *)recognitionLevel
                    useFastRecognition:(BOOL)useFastRecognition;

- (VNRecognizeTextRequest *)createTextRecognitionRequest:(NSArray *)languages
                                        recognitionLevel:(NSString *)recognitionLevel
                                      useFastRecognition:(BOOL)useFastRecognition;

- (NSDictionary *)formatRecognitionResults:(NSArray *)results
                                pageNumber:(NSInteger)pageNumber
                            imageDimensions:(CGSize)dimensions
                          recognitionLevel:(NSString *)recognitionLevel;
@end

@implementation ReactNativeTextRecognition

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
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
                  reject:(RCTPromiseRejectBlock)reject)
{
    // Text recognition is available on iOS 13+
    if (@available(iOS 13.0, *)) {
        resolve(@YES);
    } else {
        resolve(@NO);
    }
}

RCT_EXPORT_METHOD(getSupportedLanguages:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 16.0, *)) {
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
    BOOL useFastRecognition = [options[@"useFastRecognition"] boolValue];
    NSInteger maxPages = options[@"maxPages"] ? [options[@"maxPages"] integerValue] : NSIntegerMax;
    // Use 400 DPI by default for high-quality PDF rendering (previously 300)
    NSInteger pdfDpi = options[@"pdfDpi"] ? [options[@"pdfDpi"] integerValue] : 400;
    BOOL preprocessImages = options[@"preprocessImages"] ? [options[@"preprocessImages"] boolValue] : NO;
    
    RCTLogInfo(@"Text recognition started for file: %@", fileUrl);
    
    // Smart defaults: detect if file is a PDF for optimized settings
    BOOL isPDF = [fileUrl.lowercaseString hasSuffix:@".pdf"];
    
    // Apply PDF-optimized defaults when not explicitly specified
    NSString *recognitionLevel;
    if (options[@"recognitionLevel"]) {
        recognitionLevel = options[@"recognitionLevel"];
    } else {
        // PDFs work better with 'line' recognition (handles scanned docs better)
        // Images work better with 'word' recognition (more precise)
        recognitionLevel = isPDF ? @"line" : @"word";
    }
    
    RCTLogInfo(@"Recognition mode: %@ (PDF: %@, level: %@)", 
               fileUrl.lastPathComponent, isPDF ? @"YES" : @"NO", recognitionLevel);
    
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
                  useFastRecognition:useFastRecognition
                   preprocessImages:preprocessImages];
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
        return;
    }
    
    // Get image dimensions for bounding boxes
    NSArray *results = request.results;
    if (results == nil || results.count == 0) {
        // Empty results - still success
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *response = @{
                @"success": @YES,
                @"pages": @[],
                @"totalPages": @0,
                @"fullText": @""
            };
            self.callback(@[response]);
        });
        return;
    }
    
    // Get image size
    CIImage *ciImage = [[CIImage alloc] initWithContentsOfURL:url];
    CGSize imageSize = ciImage ? ciImage.extent.size : CGSizeMake(1024, 1024);
    
    NSDictionary *pageResult = [self formatRecognitionResults:results
                                                    pageNumber:0
                                                imageDimensions:imageSize
                                              recognitionLevel:recognitionLevel];
    
    NSMutableString *fullText = [NSMutableString string];
    if (pageResult[@"fullText"]) {
        [fullText appendString:pageResult[@"fullText"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *response = @{
            @"success": @YES,
            @"pages": @[pageResult],
            @"totalPages": @1,
            @"fullText": fullText
        };
        self.callback(@[response]);
    });
}

- (void)processPDFFile:(NSURL *)url
               options:(NSDictionary *)options
              maxPages:(NSInteger)maxPages
                pdfDpi:(NSInteger)pdfDpi
             languages:(NSArray *)languages
      recognitionLevel:(NSString *)recognitionLevel
    useFastRecognition:(BOOL)useFastRecognition
      preprocessImages:(BOOL)preprocessImages
API_AVAILABLE(ios(11.0))
{
    PDFDocument *pdfDocument = [[PDFDocument alloc] initWithURL:url];
    if (!pdfDocument) {
        [self sendError:@"Failed to load PDF document"];
        return;
    }

    NSInteger pageCount = pdfDocument.pageCount;
    NSInteger pagesToProcess = MIN(pageCount, maxPages);

    RCTLogInfo(@"Processing PDF (smart): %ld/%ld pages", (long)pagesToProcess, (long)pageCount);

    NSMutableArray *allPages = [NSMutableArray arrayWithCapacity:pagesToProcess];
    NSMutableString *fullText = [NSMutableString string];

    for (NSInteger i = 0; i < pagesToProcess; i++) {
        @autoreleasepool {
            PDFPage *pdfPage = [pdfDocument pageAtIndex:i];
            if (!pdfPage) { continue; }

            // Try searchable text extraction first
            NSString *pageText = pdfPage.string;
            BOOL hasSearchableText = (pageText != nil && pageText.length > 0);

            if (hasSearchableText) {
                // Build elements by line using PDF selections
                CGRect pageRect = [pdfPage boundsForBox:kPDFDisplayBoxMediaBox];
                NSMutableArray *elements = [NSMutableArray array];

                // Get selection for the entire page using page bounds
                PDFSelection *entireSelection = [pdfPage selectionForRect:pageRect];
                
                if (entireSelection) {
                    NSArray<PDFSelection *> *lineSelections = [entireSelection selectionsByLine];

                    for (PDFSelection *sel in lineSelections) {
                        NSString *lineText = sel.string ?: @"";
                        if (lineText.length == 0) { continue; }
                        CGRect bounds = [sel boundsForPage:pdfPage];

                        // Normalize to [0,1] with top-left origin
                        CGFloat normX = bounds.origin.x / pageRect.size.width;
                        CGFloat normY = 1.0 - ((bounds.origin.y + bounds.size.height) / pageRect.size.height);
                        CGFloat normW = bounds.size.width / pageRect.size.width;
                        CGFloat normH = bounds.size.height / pageRect.size.height;

                        NSDictionary *element = @{
                            @"text": lineText,
                            @"confidence": @1.0, // Text comes from PDF, assume perfect
                            @"level": @"line",
                            @"boundingBox": @{
                                @"x": @(normX),
                                @"y": @(normY),
                                @"width": @(normW),
                                @"height": @(normH),
                                @"absoluteBox": @{
                                    @"x": @(bounds.origin.x),
                                    @"y": @(pageRect.size.height - bounds.origin.y - bounds.size.height),
                                    @"width": @(bounds.size.width),
                                    @"height": @(bounds.size.height)
                                }
                            }
                        };
                        [elements addObject:element];
                    }
                }

                NSDictionary *pageResult = @{
                    @"pageNumber": @(i),
                    @"dimensions": @{ @"width": @(pageRect.size.width), @"height": @(pageRect.size.height) },
                    @"elements": elements,
                    @"fullText": pageText ?: @""
                };

                [allPages addObject:pageResult];
                if (pageText.length > 0) {
                    [fullText appendString:pageText];
                    [fullText appendString:@"\n\n"];
                }

            } else {
                // Fallback to OCR for image-based/scanned PDFs
                CGSize targetSize = CGSizeMake(2000, 2800); // High-quality thumbnail
                UIImage *thumb = [pdfPage thumbnailOfSize:targetSize forBox:kPDFDisplayBoxMediaBox];
                if (!thumb) { continue; }

                NSDictionary *pageResult = [self recognizeTextInImage:thumb
                                                            pageNumber:i
                                                             languages:languages
                                                      recognitionLevel:@"line"
                                                    useFastRecognition:useFastRecognition];
                if (pageResult) {
                    [allPages addObject:pageResult];
                    NSString *ptext = pageResult[@"fullText"];
                    if (ptext.length > 0) {
                        [fullText appendString:ptext];
                        [fullText appendString:@"\n\n"];
                    }
                }
            }
        }
    }

    NSDictionary *result = @{
        @"success": @YES,
        @"pages": allPages,
        @"totalPages": @(pageCount),
        @"fullText": [fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
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
    
    RCTLogInfo(@"Rendering PDF page at %ldx%ld px (DPI: %ld, scale: %.2fx)", 
               (long)renderSize.width, (long)renderSize.height, (long)dpi, scale);
    
    // Use 0.0 for scale to use device's native scale, improves quality
    UIGraphicsBeginImageContextWithOptions(renderSize, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set high-quality rendering
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetRenderingIntent(context, kCGRenderingIntentDefault);
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    
    // Fill background with white
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, renderSize.width, renderSize.height));
    
    // Scale and render PDF page with high quality
    CGContextScaleCTM(context, scale, scale);
    [pdfPage drawWithBox:kPDFDisplayBoxMediaBox toContext:context];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    RCTLogInfo(@"PDF page rendered, image scale: %.1fx", image.scale);
    
    return image;
}

// Preprocessing to improve OCR on scanned/low-quality PDFs
// Converts to grayscale and increases contrast
- (UIImage *)preprocessImageForOCR:(UIImage *)image
{
    CIImage *input = [[CIImage alloc] initWithImage:image];
    if (!input) return image;

    // Convert to grayscale for better OCR
    CIFilter *mono = [CIFilter filterWithName:@"CIPhotoEffectMono"];
    [mono setValue:input forKey:kCIInputImageKey];
    CIImage *monoImage = mono.outputImage ?: input;

    // Increase contrast more aggressively for scanned documents
    CIFilter *contrast = [CIFilter filterWithName:@"CIColorControls"];
    [contrast setValue:monoImage forKey:kCIInputImageKey];
    [contrast setValue:@(1.3) forKey:kCIInputContrastKey];  // Increased from 1.1 to 1.3
    [contrast setValue:@(0.05) forKey:kCIInputBrightnessKey]; // Slight brightness boost
    [contrast setValue:@(0.0) forKey:kCIInputSaturationKey];
    CIImage *output = contrast.outputImage ?: monoImage;

    // Use high-quality context for rendering
    CIContext *context = [CIContext contextWithOptions:@{
        kCIContextUseSoftwareRenderer: @NO,
        kCIContextPriorityRequestLow: @NO
    }];
    CGImageRef cgimg = [context createCGImage:output fromRect:[output extent]];
    if (!cgimg) return image;
    UIImage *result = [UIImage imageWithCGImage:cgimg scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cgimg);
    return result;
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
    
    NSError *requestError = nil;
    
    VNRecognizeTextRequest *request = [self createTextRecognitionRequest:languages
                                                         recognitionLevel:recognitionLevel
                                                       useFastRecognition:useFastRecognition];
    
    [handler performRequests:@[request] error:&requestError];
    
    NSArray *results = request.results;
    if (requestError || results == nil) {
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
        // iOS 16+ uses the latest available revision by default
        request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:nil];
        
        // Set recognition level
        if (useFastRecognition) {
            request.recognitionLevel = VNRequestTextRecognitionLevelFast;
        } else {
            request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        }
        
        // Prefer explicit language hints when provided
        if (languages && languages.count > 0) {
            request.recognitionLanguages = languages;
        }
        // Enable automatic language detection for mixed-language documents
        if (@available(iOS 16.0, *)) {
            request.automaticallyDetectsLanguage = YES;
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
        
        // On iOS 16+ the system uses latest revision automatically
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
