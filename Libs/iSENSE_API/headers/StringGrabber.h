//
//  StringGrabber.h
//  Data_Collector
//
//  Created by Mike Stowell on 12/28/12.
//  Copyright 2013 iSENSE Project, UMass Lowell. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface StringGrabber : NSObject {}    

+ (NSString *) grabString:(NSString *)label;
+ (NSString *) grabField: (NSString *)label;
+ (NSString *) concatenateHardcodedString:(NSString *)label with:(NSString *)string;
+ (NSString *) concatenate:(NSString*)string withHardcodedString:(NSString *)label;

@end
