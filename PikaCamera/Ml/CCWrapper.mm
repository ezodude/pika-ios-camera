//
//  ColourClassifierWrapper.m
//  PikaCamera
//
//  Created by Ezo Saleh on 18/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

#import <vector>
#import "CCWrapper.h"
#import "ColorClassifier.h"

@interface CCWrapper () {
  std::shared_ptr<ColorClassifier> _colorClassifier;
}
- (std::vector<std::vector<std::vector<unsigned char>>>)colorsToVector:(NSArray*)colors;

- (NSArray*)getRGBAsFromImage:(UIImage*)image;

@property (strong, atomic) dispatch_queue_t classifierQueue;
@end

@implementation CCWrapper

- (instancetype)initWithModel:(NSString *)title queue:(dispatch_queue_t)classifierQueue {

  self = [super init];
  if (self) {
    self.classifierQueue = classifierQueue;
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:title ofType:@"json"];
    
    const CFIndex MODEL_NAME_LEN = 2048;
    char MODEL_NAME[ MODEL_NAME_LEN ];
    CFStringGetFileSystemRepresentation( (CFStringRef)modelPath, MODEL_NAME, MODEL_NAME_LEN);
    _colorClassifier = std::make_shared<ColorClassifier>(MODEL_NAME);
  }
  
  return self;
}

- (void)isRed:(UIImage*)tile completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    NSArray *colors = [self getRGBAsFromImage:tile];
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:colors];
    handler((bool)_colorClassifier->is_red(colorsASVectors, 0.18));
  });
}

- (void)isBlue:(UIImage*)tile completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    NSArray *colors = [self getRGBAsFromImage:tile];
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:colors];
    handler((bool)_colorClassifier->is_blue(colorsASVectors, 0.18));
  });
}

- (void)isYellow:(UIImage*)tile completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    NSArray *colors = [self getRGBAsFromImage:tile];
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:colors];
    handler((bool)_colorClassifier->is_yellow(colorsASVectors, 0.18));
  });
}

- (NSArray *)computeColorPercentages:(UIImage*)tile{
  return [NSArray arrayWithObject: [NSNumber numberWithDouble:1.5]];
}

- (NSArray*)getRGBAsFromImage:(UIImage*)image
{
  int x = 0;
  int y = 0;
  
  // First get the image into your data buffer
  CGImageRef imageRef = [image CGImage];
  NSUInteger width = CGImageGetWidth(imageRef);
  NSUInteger height = CGImageGetHeight(imageRef);
  NSUInteger count = width * height;
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
  NSUInteger bytesPerPixel = 4;
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
  CGContextRelease(context);
  
  // Now your rawData contains the image data in the RGBA8888 pixel format.
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
  NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
  for (int i = 0 ; i < count ; ++i)
  {
    CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
    CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / alpha;
    CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / alpha;
    CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / alpha;
    byteIndex += bytesPerPixel;
    
    NSArray *pixelColors = [NSArray arrayWithObjects:
                           [NSNumber numberWithInteger:red],
                           [NSNumber numberWithInteger:green],
                           [NSNumber numberWithInteger:blue],
                           nil];
    [result addObject:pixelColors];
  }
  
  free(rawData);
  
  return result;
  
}

- (std::vector<std::vector<std::vector<unsigned char>>>)colorsToVector:(NSArray*)colors{
  std::vector<std::vector<std::vector<unsigned char>>> result;
  
  std::vector<std::vector<unsigned char>> new_line;
  for (int j = 0; j < [colors count]; ++j) {
    std::vector<unsigned char> pixel_v;
    for (int k = 0; k < 3; ++k) {
      NSNumber *color = [[colors objectAtIndex:j] objectAtIndex:k];
      pixel_v.push_back([color unsignedCharValue]);
    }
    new_line.push_back(pixel_v);
  }
  result.push_back(new_line);
  
  return result;
}
@end
