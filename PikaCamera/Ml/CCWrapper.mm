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

- (void)isRed:(NSArray *)colors completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:[NSArray arrayWithObjects: colors, nil]];
    handler((bool)_colorClassifier->is_red(colorsASVectors, 0.18));
  });
}

- (void)isBlue:(NSArray *)colors completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:[NSArray arrayWithObjects: colors, nil]];
    handler((bool)_colorClassifier->is_blue(colorsASVectors, 0.18));
  });
}

- (void)isYellow:(NSArray *)colors completion:(CCHandler) handler{
  dispatch_async(self.classifierQueue, ^{
    std::vector<std::vector<std::vector<unsigned char>>> colorsASVectors = [self colorsToVector:[NSArray arrayWithObjects: colors, nil]];
    handler((bool)_colorClassifier->is_yellow(colorsASVectors, 0.18));
  });
}

- (NSArray *)computeColorPercentages:(UIImage*)tile{
  return [NSArray arrayWithObject: [NSNumber numberWithDouble:1.5]];
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
