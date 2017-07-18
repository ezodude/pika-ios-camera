//
//  ColourClassifierWrapper.m
//  PikaCamera
//
//  Created by Ezo Saleh on 18/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

#import "CCWrapper.h"
#import "./UIImage+OpenCV.h"
#import "ColorClassifier.h"

@interface CCWrapper () {
  std::shared_ptr<ColorClassifier> _colorClassifier;
}
@end

@implementation CCWrapper

- (instancetype)initWithModel:(NSString *)title{

  self = [super init];
  if (self) {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:title ofType:@"json"];
    const CFIndex MODEL_NAME_LEN = 2048;
    char *MODEL_NAME = (char *) malloc(MODEL_NAME_LEN);
    CFStringGetFileSystemRepresentation( (CFStringRef)modelPath, MODEL_NAME, MODEL_NAME_LEN);
    std::shared_ptr<ColorClassifier> _colorClassifier(new ColorClassifier(MODEL_NAME));
    free(MODEL_NAME);
  }
  
  return self;
}

- (BOOL)isBlue:(UIImage*)tile{
//  return _colorClassifier->is_blue(<#const cv::Mat &tile#>, <#float alpha#>)
}

- (BOOL)isRed:(UIImage*)tile{
  
}

- (BOOL)isYellow:(UIImage*)tile{
  
}

- (NSArray *)computeColorPercentages:(UIImage*)tile{
  
}


+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
  NSArray* imageArray = [NSArray arrayWithObject:inputImage];
  UIImage* result = [[self class] processWithArray:imageArray];
  return result;
}

+ (UIImage*) processWithOpenCVImage1:(UIImage*)inputImage1 image2:(UIImage*)inputImage2;
{
  NSArray* imageArray = [NSArray arrayWithObjects:inputImage1,inputImage2,nil];
  UIImage* result = [[self class] processWithArray:imageArray];
  return result;
}

+ (UIImage*) processWithArray:(NSArray*)imageArray
{
  if ([imageArray count]==0){
    NSLog (@"imageArray is empty");
    return 0;
  }
  std::vector<cv::Mat> matImages;
  
  for (id image in imageArray) {
    if ([image isKindOfClass: [UIImage class]]) {
      /*
       All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
       */
//      UIImage* rotatedImage = [image rotateToImageOrientation];
//      cv::Mat matImage = [rotatedImage CVMat3];
      cv::Mat matImage = [image CVMat3];
      NSLog (@"matImage: %@",image);
      matImages.push_back(matImage);
    }
  }
  NSLog (@"stitching...");
//  cv::Mat stitchedMat = stitch (matImages);
//  UIImage* result =  [UIImage imageWithCVMat:stitchedMat];
//  return result;
  return null;
}

@end
