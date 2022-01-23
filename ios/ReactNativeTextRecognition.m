// ReactNativeTextRecognition.m

#import "ReactNativeTextRecognition.h"
#import "VisionKit/VisionKit.h"


@interface ReactNativeTextRecognition ()

@property (nonatomic, strong) RCTResponseSenderBlock callback;
@property (nonatomic, copy) NSDictionary *options;
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
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]]];
    
    //VNImageRequestHandler * requestHandler = [VNImageRequestHandler initWithURL:options:]
    
//    dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
//    dispatch_queue_t recordingQueue = dispatch_queue_create("recognitionQueue", qos);

    
}

//lazy var textRecognitionRequest: VNRecognizeTextRequest = {
//    let req = VNRecognizeTextRequest { (request, error) in
//        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
//        
//        var resultText = ""
//        for observation in observations {
//            guard let topCandidate = observation.topCandidates(1).first else { return }
//            resultText += topCandidate.string
//            resultText += "\n"
//        }
//        
//        DispatchQueue.main.async {
//            self.txt.text = self.txt.text + "\n" + resultText
//        }
//    }
//    return req
//}()
//
//func recognizeText(inImage: UIImage) {
//    guard let cgImage = inImage.cgImage else { return }
//    
//    workQueue.async {
//        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        do {
//            try requestHandler.perform([self.textRecognitionRequest])
//        } catch {
//            print(error)
//        }
//    }
//}

@end

