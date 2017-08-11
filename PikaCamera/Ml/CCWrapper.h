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

typedef void(^CCHandler)(BOOL);

- (instancetype)initWithModel:(NSString *)title queue:(dispatch_queue_t)classifierQueue;
//- (void)isRed:(UIImage*)tile completion:(CCHandler) handler;
- (void)isRed:(CGImageRef)tile completion:(CCHandler) handler;
//- (void)isRed:(NSArray *)colors completion:(CCHandler) handler;
- (void)isBlue:(UIImage*)tile completion:(CCHandler) handler;
- (void)isYellow:(UIImage*)tile completion:(CCHandler) handler;
- (NSArray *)computeColorPercentages:(UIImage*)tile;

@end
NS_ASSUME_NONNULL_END

#endif /* CCWrapper_h */
