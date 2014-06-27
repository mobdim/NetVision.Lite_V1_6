//
//  EventInfoV2.m
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

#import "EventInfo.h"


@implementation EventInfo

@synthesize ID;
@synthesize deviceID;
@synthesize dev_name;
@synthesize lock;
@synthesize time;
@synthesize triggerDeviceID;
@synthesize type;
@synthesize where;
@synthesize status;
@synthesize source;
@synthesize link;
@synthesize duration;
@synthesize startTime;
@synthesize endTime;
@synthesize onlooker_clips;


- (id) init {
	//NSLog(@"EventInfo init %d\n", ++ggg);
	if ((self = [super init]) == nil)
		return nil;
	
	ID              = nil;
	deviceID        = nil;
	dev_name        = nil;
	lock            = nil;
	time            = nil;
	triggerDeviceID = nil;
	type            = nil;
	where           = nil;
	status          = nil;
	source          = nil;
	link            = nil;
	duration        = nil;
	startTime       = nil;
	endTime         = nil;
	onlooker_clips  = nil;
	
	
	return self;
}

- (void) dealloc {
	//NSLog(@"EventInfo dealloc %d\n",ggg--);
	[deviceID        release];
	[dev_name        release];
	[ID              release];
	[lock            release];
	[time            release];
	[triggerDeviceID release];
	[type            release];
	[where           release];
	[status          release];
	[onlooker_clips  release];
	[source          release];
	[link            release];
	[duration        release];
	[startTime       release];
	[endTime         release];
	
	ID              = nil;
	deviceID        = nil;
	dev_name        = nil;
	lock            = nil;
	time            = nil;
	triggerDeviceID = nil;
	type            = nil;
	where           = nil;
	status          = nil;
	source          = nil;
	link            = nil;
	duration        = nil;
	startTime       = nil;
	endTime         = nil;
	onlooker_clips  = nil;
	
	
	[super dealloc];
}


@end
