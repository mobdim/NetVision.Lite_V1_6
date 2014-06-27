//
//  ParserObj.m
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

#import "ParserObj.h"


@implementation ParserObj
@synthesize beacon;

- (id) init {
	//NSLog(@"ParserObj init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	isObjListTag = NO;
	
	objList = [[NSMutableArray alloc] init];
	//NSLog(@"objlist count = %d\n", [objList count]);
	currentElement = nil;
	beacon = nil;
	
	devList = [[NSMutableArray alloc] init];
	isViewerTag = NO;
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
	
	
	if([elementName isEqualToString:@"device"]) {
		devInfo = [[DeviceInfo alloc] init]; 
	}
	else if([elementName isEqualToString:@"viewer"]) {
		isViewerTag = YES;
	}
	else if([elementName isEqualToString:@"object_list"]) {
		
		isObjListTag = YES;
	}
	else if([elementName isEqualToString:@"object"] && isObjListTag) {
		objInfo = [[ObjectCluster alloc] init];
	}
}



- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName {
	
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
	
	if([elementName isEqualToString:@"device"]) {
		devInfo.objList = [[objList mutableCopy] autorelease];
		[objList removeAllObjects];
		[devList addObject:devInfo];
		[devInfo release];
		devInfo = nil;
		
	}
	else if([elementName isEqualToString:@"viewer"]) {
		isViewerTag = NO;
	}
	else if([elementName isEqualToString:@"object_list"]) {
		isObjListTag = NO;
	}
	else if([elementName isEqualToString:@"object"] && isObjListTag) {
		objInfo.beacon = beacon;
		[objList addObject:objInfo];
		[objInfo release];
		objInfo = nil;
		
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	NSString *info = [[NSString alloc] initWithString:string];
	
	if(devInfo) {
		if([currentElement isEqualToString:@"id"])
			devInfo.ID = info;
		else if([currentElement isEqualToString:@"tz"]) 
			devInfo.tz = info;
		else if([currentElement isEqualToString:@"type"] && (!isObjListTag)) 
			devInfo.type = info;
		else if([currentElement isEqualToString:@"mac"])
			devInfo.mac = info;
		else if([currentElement isEqualToString:@"name"] && isViewerTag && (!isObjListTag))
			devInfo.username =info;
		else if([currentElement isEqualToString:@"name"] && (!isObjListTag))
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
	}
	
	//if ([currentElement isEqualToString:@"beacon"]) {
	//	if(beacon != nil)
	//		[beacon release];
	//	beacon = [[NSString alloc] initWithString:info];
	//}
	
	if(isObjListTag && (objInfo)) {
	
		if([currentElement isEqualToString:@"index"])
			objInfo.index = info;
		else if([currentElement isEqualToString:@"name"])
			objInfo.name = info;
		else if([currentElement isEqualToString:@"enable"])
			objInfo.enable = info;
		else if([currentElement isEqualToString:@"node_id"])
			objInfo.node_id = info;
		else if([currentElement isEqualToString:@"type"])
			objInfo.type = info;
		else if([currentElement isEqualToString:@"category"])
			objInfo.category = info;
		else if([currentElement isEqualToString:@"connectivity"])
			objInfo.connectivity = info;
		else if([currentElement isEqualToString:@"state"])
			objInfo.state = info;
		else if([currentElement isEqualToString:@"allowed_values"])
			objInfo.allow_values = info;
		else if([currentElement isEqualToString:@"current_value"])
			objInfo.current_Value = info;

	}
	[info release];
	
	
}

- (void) dealloc {
	//NSLog(@"ParserObj dealloc\n");
	[objInfo release];
	[objList removeAllObjects];
	[objList release];
	[beacon  release];
	beacon  = nil;
	objInfo = nil;
	objList = nil;
	
	[currentElement release];
	currentElement = nil;

	[devList release];
	devList =nil;
	
	[super dealloc];
}

- (id) getDevWithObjList {
	
	return devList;
}

@end
