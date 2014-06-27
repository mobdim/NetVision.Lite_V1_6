//
//  ClipInfoV2.m
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

#import "ClipInfo.h"


@implementation ClipInfo

@synthesize lock;
@synthesize duration;
@synthesize size;
@synthesize video_format;
@synthesize audio_format;
@synthesize capture_type;
@synthesize location;
@synthesize file_name;

- (id) init {
	//NSLog(@"ClipInfo init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	lock         = nil;
	duration     = nil;
	size         = nil;
	video_format = nil;
	audio_format = nil;
	capture_type = nil;
	location     = nil;
	file_name    = nil;
	
	
	return self;
}



- (void) dealloc {
	//NSLog(@"ClipInfo dealloc\n");
	[lock         release];
	[duration     release];
	[size         release];
	[video_format release];
	[audio_format release];
	[capture_type release];
	[location     release];
	[file_name    release];
	lock         = nil;
	duration     = nil;
	size         = nil;
	video_format = nil;
	audio_format = nil;
	capture_type = nil;
	location     = nil;
	file_name    = nil;
	[super dealloc];
}


@end
