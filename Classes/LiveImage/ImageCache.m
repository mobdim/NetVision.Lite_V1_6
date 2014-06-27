//
//  ImageCache.m
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/17.
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

#import "ImageCache.h"

static ImageCache *sharedImageCache;

@implementation ImageCache

 -(id)init
 {
	 [super init];
	 dictionary = [[NSMutableDictionary alloc] init];
 
	 return self;
 }
 
 -(void)setImage:(UIImage*)image forKey:(NSString*)key
 {
	 [dictionary setObject:image forKey:key];
 
 }
 
 -(UIImage*)imageForKey:(NSString*)key
 {
	 
	 return [dictionary objectForKey:key];
 }
 
 -(void)deleteImageForKey:(NSString*)key
 {
	 [dictionary removeObjectForKey:key];
 }


//#pragam mark Singleton stuff

+(ImageCache*)sharedImageCache
{
	if(!sharedImageCache)
		sharedImageCache = [[ImageCache alloc] init];
	
	return sharedImageCache;
	
}

+(id)allocWithZone:(NSZone*)zone
{
	if(!sharedImageCache)
	{
		sharedImageCache = [super allocWithZone:zone];	
		return sharedImageCache;	
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
