//
//  CCWrapper.h
//  PikaCamera
//
//  Created by Ezo Saleh on 18/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

#ifndef CCWrapper_h
#define CCWrapper_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface CCWrapper : NSObject

- (instancetype)initWithModel:(NSString *)path;

- (BOOL)isBlue:(UIImage*)tile;

- (BOOL)isRed:(UIImage*)tile;

- (BOOL)isYellow:(UIImage*)tile;

- (NSArray *)computeColorPercentages:(UIImage*)tile;

@end
NS_ASSUME_NONNULL_END

#endif /* CCWrapper_h */
