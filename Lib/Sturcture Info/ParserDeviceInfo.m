//
//  ParserDevInfo.m
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

#import "ParserDeviceInfo.h"


@implementation ParserDeviceInfo


- (id) init {
	//NSLog(@"ParserDeviceInfo init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	isViewerTag = NO;
	
	devList = [[NSMutableArray alloc] init];
	
	currentElement = nil;
	
	return self;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
                                        namespaceURI:(NSString *)namespaceURI 
                                       qualifiedName:(NSString *)qName 
	                                      attributes:(NSDictionary *)attributeDict {
	
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
	currentElement = [[NSString alloc] initWithString:elementName];
	
	if([elementName isEqualToString:@"device"])
		devInfo = [[DeviceInfo alloc]   init];
	else if([elementName isEqualToString:@"viewer"]) 
		isViewerTag = YES;
	
	
	
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
                                      namespaceURI:(NSString *)namespaceURI 
                                     qualifiedName:(NSString *)qName {
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
	
	if([elementName isEqualToString:@"device"]) 
	{
		[devList addObject:devInfo];
		[devInfo release];
		devInfo = nil; 
	}
	else if([elementName isEqualToString:@"viewer"]) 
		isViewerTag = NO;
	

											
	
		
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if(devInfo == nil)
		return;
	
	NSString *info = [[NSString alloc] initWithString:string];
	
	if([currentElement isEqualToString:@"id"])
		devInfo.ID = info;
	else if([currentElement isEqualToString:@"tz"]) 
		devInfo.tz = info;
	else if([currentElement isEqualToString:@"type"]) 
		devInfo.type = info;
	else if([currentElement isEqualToString:@"mac"])
		devInfo.mac = info;
	else if([currentElement isEqualToString:@"name"] && isViewerTag)
		devInfo.username =info;
	else if([currentElement isEqualToString:@"name"])
		devInfo.name = info;
	else if([currentElement isEqualToString:@"internal"])
		devInfo.internal = info;
	else if([currentElement isEqualToString:@"external"])
		devInfo.external = info;
	else if([currentElement isEqualToString:@"relay"])
		devInfo.relay = info;
	else if([currentElement isEqualToString:@"vpns"])
		devInfo.vpns = info;
	else if([currentElement isEqualToString:@"password"])
		devInfo.password = info;
	else if([currentElement isEqualToString:@"status"])
		devInfo.status = info;
	else if([currentElement isEqualToString:@"beacon"])
		devInfo.beacon = info;

	[info release];
	
	
}
	
	
	
- (void) dealloc {
	//NSLog(@"ParserDeviceInfo dealloc\n");	
	[devInfo release];
	[devList removeAllObjects];
	[devList release];
	devInfo = nil;
	devList = nil;
	
	[currentElement release];
	currentElement = nil;

	[super dealloc];
}
	

- (id) getDeviceList {
	
	//NSMutableArray *ret = [[devList mutableCopy] autorelease];
	//[devList removeAllObjects];
	//[devList release];
	//devList = nil; 
	return 	devList;
}

@end
