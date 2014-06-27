//
//  DeviceCache.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/16.
/*
 * Copyright c 2010 SerComm Corporation. 
 * All Rights Reserved. 
 *
 * SerComm Corporation reserves the right to make changes to this document without notice. 
 * SerComm Corporation makes no warranty, representation or guarantee regarding the suitability 
 * of its products for any particular purpose. SerComm Corporation assumes no liability arising 
 * out of the application or use of any product or circuit. SerComm Corporation specifically 
 * disclaims any and all liability, including without limitation consequential or incidental 
 * damages; neither does it convey any license under its patent rights, nor the rights of others.
 */

#import <UIKit/UIKit.h>

@class DeviceData;
@interface DeviceCache : NSObject 
{
	NSMutableArray *possessions;
	BOOL dirtyFlag;
}
@property(nonatomic, assign) BOOL dirtyFlag;

+(DeviceCache*)sharedDeviceCache;
-(void)setDevice:(DeviceData*)device forKey:(NSString*)key;
-(DeviceData*)deviceForKey:(NSString*)key;
-(NSString*)keyAtIndex:(NSInteger)index;
-(DeviceData*)deviceAtIndex:(NSInteger)index;
-(void)deleteDeviceForKey:(NSString*)key;
-(int)totalDeviceNumber;
-(void)moveDeviceFromIndex:(NSInteger)from toIndex:(NSInteger)to;
-(void)removeAllDevices;
-(void)setDeviceAtIndex:(int)index withFeatures:(int)features;
-(int)getDeviceFeaturesAtIndex:(int)index;

@end
