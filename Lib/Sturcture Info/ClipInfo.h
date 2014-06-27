//
//  ClipInfoV2.h
//  TerraUI
//
//  Created by ISBU on 公元2011/12/12.
/*
 * Copyright © 2010 SerComm Corporation. 
 * All Rights Reserved. 
 *
 * SerComm Corporation reserves the right to make changes to this document without notice. 
 * SerComm Corporation makes no warranty, representation or guarantee regarding the suitability 
 * of its products for any particular purpose. SerComm Corporation assumes no liability arising 
 * out of the application or use of any product or circuit. SerComm Corporation specifically 
 * disclaims any and all liability, including without limitation consequential or incidental 
 * damages; neither does it convey any license under its patent rights, nor the rights of others.
 */

#import <Foundation/Foundation.h>


@interface ClipInfo : NSObject {
	NSString *lock;
	NSString *duration;
	NSString *size;
	NSString *video_format;
	NSString *audio_format;
	NSString *capture_type;
	NSString *location;
	NSString *file_name;
}

@property (nonatomic, retain) NSString *lock;
@property (nonatomic, retain) NSString *duration;
@property (nonatomic, retain) NSString *size;
@property (nonatomic, retain) NSString *video_format;
@property (nonatomic, retain) NSString *audio_format;
@property (nonatomic, retain) NSString *capture_type;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *file_name;

@end
