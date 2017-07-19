//
//  ColourClassifierWrapper.m
//  PikaCamera
//
//  Created by Ezo Saleh on 18/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

#import "./UIImage+OpenCV.h"
#import "CCWrapper.h"
#import "ColorClassifier.h"

@interface CCWrapper () {
  std::shared_ptr<ColorClassifier> _colorClassifier;
}
@end

@implementation CCWrapper

- (instancetype)initWithModel:(NSString *)title{

  self = [super init];
  if (self) {
    NSLog(@"Title: [%@]", title);
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:title ofType:@"json"];
    NSLog(@"Model path: [%@]", modelPath);
    
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
  return false;
}

- (BOOL)isRed:(UIImage*)tile{
  return false;
}

- (BOOL)isYellow:(UIImage*)tile{
  return false;
}

- (NSArray *)computeColorPercentages:(UIImage*)tile{
  return [NSArray arrayWithObject: [NSNumber numberWithDouble:1.5]];
}
@end
