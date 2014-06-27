//
//  EventInfoV2.h
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


@interface EventInfo : NSObject {
	
	// event
	NSString *deviceID;//device ID;
	NSString *dev_name;//device name;
	NSString *ID;//event ID;
	NSString *lock;
	NSString *time; //YYYYMMDDHHmmss// by/time
	NSString *triggerDeviceID;
	NSString *type;// by/condition
	/*
	 di		:input port trigger
	 audio	:audio trigger
	 motion	:motion trigger
	 pir	:pir trigger
	 httpc	:HTTP CGI client trigger
	 rf		:RF sensor trigger
	 femto	:Femto cell event trigger
	 */
	NSString *where;
	NSString *status;
	NSString *onlooker_clips;// report
	NSString *source;
	NSString *link; //clip file name
	NSString *duration;
	NSDate *startTime;
	NSDate *endTime;
	

}
@property (nonatomic, retain) NSString *ID;
@property (nonatomic, retain) NSString *dev_name;
@property (nonatomic, retain) NSString *deviceID;
@property (nonatomic, retain) NSString *lock;
@property (nonatomic, retain) NSString *time;
@property (nonatomic, retain) NSString *triggerDeviceID;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *where;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *duration;
@property (nonatomic, retain) NSString *onlooker_clips;
@property (nonatomic, retain) NSDate   *startTime;
@property (nonatomic, retain) NSDate   *endTime;


@end
