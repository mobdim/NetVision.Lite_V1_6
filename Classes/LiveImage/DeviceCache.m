//
//  DeviceCache.m
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

#import "DeviceCache.h"
#import "DeviceData.h"
#import "ModelNames.h"

static DeviceCache *sharedDeviceCache;

@implementation DeviceCache

@synthesize dirtyFlag;

-(id)init
{
	[super init];
	possessions = [[NSMutableArray alloc] init];
	[self setDirtyFlag:NO];
	
	return self;
}

-(void)setDevice:(DeviceData*)device forKey:(NSString*)key
{
	DeviceData *obj = nil;
	int i = 0;
	for(i=0; i<[possessions count]; i++)
	{
		obj = (DeviceData*)[possessions objectAtIndex:i];
		if(obj)
		{
			NSString *objKey = [obj deviceKey];
			if([objKey compare:key] == NSOrderedSame)
				break;
		}
		
		obj = nil;
	}	
	
	// if an object found, replace the old object at the index position with the new object 
	if(obj)
	{
		if([obj isAttributesChanged:device] ==YES)
		{
			[device setDirtyFlag:NO];
			[possessions replaceObjectAtIndex:i withObject:device];
			[self setDirtyFlag:YES];
			
			NSLog(@"DeviceCache...replace device...");
		}
	}
	// otherwise, add the new object at the end of the array
	else
	{
		[device setDirtyFlag:NO];
		[possessions addObject:device];
		NSLog(@"DeviceCache...add new device...");
		[self setDirtyFlag:YES];
	}		
}

-(DeviceData*)deviceForKey:(NSString*)key
{
	for(int i=0; i<[possessions count]; i++)
	{
		DeviceData *obj = (DeviceData*)[possessions objectAtIndex:i];
		if(obj)
		{
			NSString *objKey = [obj deviceKey];
			if([objKey compare:key] == NSOrderedSame)
				return obj;
		}			
	}
	
	return nil;	
}

-(NSString*)keyAtIndex:(NSInteger)index
{
	//NSLog(@"DeviceCache...enter...");	
	//NSLog(@"DeviceCache...total posessions: %d...", [possessions count]);
	for(int i=0; i<[possessions count]; i++)
	{
		if(i != index)
		{
			//NSLog(@"DeviceCache...required: %d...curSearch: %d", index, i);
			continue;
		}
		
		DeviceData *obj = (DeviceData*)[possessions objectAtIndex:i];
		if(obj)
		{		
			//NSLog(@"DeviceCache...got device data at position: %d...", i+1);
			NSString *key = [obj deviceKey];
			//NSLog(@"DeviceCache...retrieve the key: %d key: %@", i+1, key);			
			return 	key;
		}
	}
	
	//NSLog(@"DeviceCache...no key found");
	return nil;		
}

-(DeviceData*)deviceAtIndex:(NSInteger)index
{
	//NSLog(@"DeviceCache...enter deviceAtIndex...");
	return [possessions objectAtIndex:index];
	
}

-(void)deleteDeviceForKey:(NSString*)key
{
	DeviceData *obj = nil;
	int i = 0;
	for(i=0; i<[possessions count]; i++)
	{
		obj = (DeviceData*)[possessions objectAtIndex:i];
		if(obj)
		{
			NSString *objKey = [obj deviceKey];
			if([objKey compare:key] == NSOrderedSame)
				break;
		}
		
		obj = nil;
	}	
	
	if(obj)
	{
		[possessions removeObjectAtIndex:i];
		[self setDirtyFlag:YES];
	}
}

-(int)totalDeviceNumber
{
	return [possessions count];
}


-(void)moveDeviceFromIndex:(NSInteger)from toIndex:(NSInteger)to
{
	
	DeviceData *p = (DeviceData*)[possessions objectAtIndex:from];
	
	// retain p so that it is not deallocated when it is removed from the array
	[p retain];	// retain count of p is now 2
	
	// remove p from our array, it is automatically sent release
	[possessions removeObjectAtIndex:from];	// retain count of p is now 1
	
	//// re-insert p into the desired position of the data source array
	[possessions insertObject:p atIndex:to];	// retain count of p is now 2
	
	[p release];	// retain count of p is now back to 1
	
	[self setDirtyFlag:YES];
}

-(void)removeAllDevices
{
	[possessions removeAllObjects];
	[self setDirtyFlag:YES];
}

-(void)setDeviceAtIndex:(int)index withFeatures:(int)features
{
	if(index >= [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return;
	
	[[[DeviceCache sharedDeviceCache] deviceAtIndex:index] setExtensionFeatures:features];
}

-(int)getDeviceFeaturesAtIndex:(int)index
{
	if(index >= [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return DEVICE_EXTENSION_PT;	
	
	return [[[DeviceCache sharedDeviceCache] deviceAtIndex:index] extensionFeatures];
	
}


//#pragam mark Singleton stuff

+(DeviceCache*)sharedDeviceCache
{
	if(!sharedDeviceCache)
		sharedDeviceCache = [[DeviceCache alloc] init];
	
	return sharedDeviceCache;
	
}

+(id)allocWithZone:(NSZone*)zone
{
	if(!sharedDeviceCache)
	{
		sharedDeviceCache = [super allocWithZone:zone];	
		return sharedDeviceCache;	
	}
	else
		return nil;
}

-(id)copyWithZone:(NSZone*)zone
{
	return self;
}

-(void)release
{
	// do nothing
}



@end
