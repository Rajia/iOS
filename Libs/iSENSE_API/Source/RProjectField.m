/*
 * iSENSE Project - isenseproject.org
 * This file is part of the iSENSE iOS API and applications.
 *
 * Copyright (c) 2015, University of Massachusetts Lowell. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer. Redistributions in binary
 * form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials
 * provided with the distribution. Neither the name of the University of
 * Massachusetts Lowell nor the names of its contributors may be used to
 * endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * BSD 3-Clause License
 * http://opensource.org/licenses/BSD-3-Clause
 *
 * Our work is supported by grants DRL-0735597, DRL-0735592, DRL-0546513, IIS-1123998,
 * and IIS-1123972 from the National Science Foundation and a gift from Google Inc.
 *
 */

//
// RProjectField.m
// iSENSE_API
//
// Created by Michael Stowell on 8/21/13.
//

#import "RProjectField.h"

@implementation RProjectField

@synthesize field_id = _field_id, name = _name, recognized_name = _recognized_name, type = _type, unit = _unit;

- (id) init {

    if (self = [super init]) {
        self.type = [NSNumber numberWithInt:TYPE_TEXT];
        self.unit = @"";
        self.name = @"";
        self.restrictions = [[NSArray alloc] init];
    }
    return self;
}

- (id) initWithName:(NSString *)uname type:(NSNumber *)utype unit:(NSString *)uunit andRestrictions:(NSArray *)urestrictions {

    self = [super init];
    if (self) {

        self.type = utype;
        self.unit = uunit;
        self.name = uname;
        self.restrictions = urestrictions;
    }
    return self;
}

// Overridden setter for the name variable, which will call the getRecognizedNameFromUserDefinedName function
- (void) setName:(NSString *)name {
    _name = name;
    [self getRecognizedNameFromUserDefinedName];
}

- (NSString *) description {

    return [NSString stringWithFormat:@"RProjectField: {\n\tfield_id: %@\n\tname: %@\n\trecognized_name: %@\n\ttype: %@\n\tunit: %@\n}",
            _field_id, _name, _recognized_name, _type, _unit];
}

// Parses the name field to attempt to obtain a recognized name for the field
- (void) getRecognizedNameFromUserDefinedName {
    
    // parse the field and try to match the name with recognized field names
    switch (self.type.intValue) {
            
        case TYPE_NUMBER:
            // Temperature
            if ([self.name.lowercaseString rangeOfString:@"temp"].location != NSNotFound) {
                if ([self.unit.lowercaseString rangeOfString:@"c"].location != NSNotFound) {
                    self.recognized_name = sTEMPERATURE_C;
                } else if ([self.unit.lowercaseString rangeOfString:@"k"].location != NSNotFound) {
                    self.recognized_name = sTEMPERATURE_K;
                } else {
                    self.recognized_name = sTEMPERATURE_F;
                }
                break;
            }
            
            // Altitude
            else if ([self.name.lowercaseString rangeOfString:@"altitude"].location != NSNotFound) {
                self.recognized_name = sALTITUDE;
                break;
            }
            
            // Light
            else if ([self.name.lowercaseString rangeOfString:@"light"].location != NSNotFound ||
                     [self.name.lowercaseString rangeOfString:@"lumin"].location != NSNotFound) {
                self.recognized_name = sLUX;
                break;
            }
            
            // Heading
            else if ([self.name.lowercaseString rangeOfString:@"heading"].location != NSNotFound ||
                     [self.name.lowercaseString rangeOfString:@"angle"].location != NSNotFound) {
                if ([self.unit.lowercaseString rangeOfString:@"rad"].location != NSNotFound) {
                    self.recognized_name = sANGLE_RAD;
                } else {
                    self.recognized_name = sANGLE_DEG;
                }
                break;
            }
            
            // Magnetic
            else if ([self.name.lowercaseString rangeOfString:@"magnetic"].location != NSNotFound) {
                if ([self.name.lowercaseString rangeOfString:@"x"].location != NSNotFound) {
                    self.recognized_name = sMAG_X;
                } else if ([self.name.lowercaseString rangeOfString:@"y"].location != NSNotFound) {
                    self.recognized_name = sMAG_Y;
                } else if ([self.name.lowercaseString rangeOfString:@"z"].location != NSNotFound) {
                    self.recognized_name = sMAG_Z;
                } else {
                    self.recognized_name = sMAG_TOTAL;
                }
                break;
            }
            
            // Acceleration
            else if ([self.name.lowercaseString rangeOfString:@"accel"].location != NSNotFound) {
                if ([self.name.lowercaseString rangeOfString:@"x"].location != NSNotFound) {
                    self.recognized_name = sACCEL_X;
                } else if ([self.name.lowercaseString rangeOfString:@"y"].location != NSNotFound) {
                    self.recognized_name = sACCEL_Y;
                } else if ([self.name.lowercaseString rangeOfString:@"z"].location != NSNotFound) {
                    self.recognized_name = sACCEL_Z;
                } else {
                    self.recognized_name = sACCEL_TOTAL;
                }
                break;
            }
            
            // Pressure
            else if ([self.name.lowercaseString rangeOfString:@"pressure"].location != NSNotFound) {
                self.recognized_name = sPRESSURE;
                break;
            }
            
            // Gyroscope
            else if ([self.name.lowercaseString rangeOfString:@"gyro"].location != NSNotFound) {
                if ([self.name.lowercaseString rangeOfString:@"x"].location != NSNotFound) {
                    self.recognized_name = sGYRO_X;
                } else if ([self.name.lowercaseString rangeOfString:@"y"].location != NSNotFound) {
                    self.recognized_name = sGYRO_Y;
                } else {
                    self.recognized_name = sGYRO_Z;
                }
                break;
            }
            
            // No match found
            else {
                self.recognized_name = sNULL_STRING;
                break;
            }
            
            break;
            
        case TYPE_TIMESTAMP:
            // Timestamp
            self.recognized_name = sTIME_MILLIS;
            break;
            
        case TYPE_LAT:
            // Latitude
            self.recognized_name = sLATITUDE;
            break;
            
        case TYPE_LON:
            // Longitude
            self.recognized_name = sLONGITUDE;
            break;
            
        default:
            // No match found
            self.recognized_name = sNULL_STRING;
            break;
    }
}

@end
