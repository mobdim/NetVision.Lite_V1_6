//
//  DeviceInfoV2.h
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


@interface DeviceInfo : NSObject {
	
	NSString *ID;
	NSString *tz;
	NSString *type;
	NSString *mac;
	NSString *name;
	NSString *internal;
	NSString *external;
	NSString *relay;
	NSString *vpns;
	//viewer
	NSString *username;
	NSString *password;
	NSString *status;
	NSString *beacon;
	
	NSMutableArray *objList;
	
}
@property (nonatomic, retain) NSString *ID;
@property (nonatomic, retain) NSString *tz;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *mac;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *internal;
@property (nonatomic, retain) NSString *external;
@property (nonatomic, retain) NSString *relay;
@property (nonatomic, retain) NSString *vpns;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *beacon;
@property (nonatomic, retain) NSMutableArray *objList;

@end
