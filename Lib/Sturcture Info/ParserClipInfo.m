//
//  ParserClipInfo.m
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

#import "ParserClipInfo.h"


@implementation ParserClipInfo

- (id) init {
	//NSLog(@"ParserClipInfo init\n");
	if ((self = [super init]) == nil)
		return nil;
		
	clipList = [[NSMutableArray alloc] init];
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
	
	//NSLog(@"start ele %@\n",currentElement);
	
	//[self doesContainSubstring:elementName subString:@"clip_list"]
	if([elementName isEqualToString:@"clip"]) {
		clipInfo = [[ClipInfo alloc] init];
		
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName {
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}	
	if([elementName isEqualToString:@"clip"]) {
		
		[clipList addObject:clipInfo];
		[clipInfo release];
		clipInfo = nil;
	}

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if(clipInfo == nil)
		return;
	
	NSString *info = [[NSString alloc] initWithString:string];
	
	if([currentElement isEqualToString:@"lock"])
		clipInfo.lock = info;
	else if([currentElement isEqualToString:@"duration"]) 
		clipInfo.duration = info;
	else if([currentElement isEqualToString:@"size"]) 
		clipInfo.size = info;
	else if([currentElement isEqualToString:@"video_format"])
		clipInfo.video_format = info;
	else if([currentElement isEqualToString:@"audio_format"])
		clipInfo.audio_format = info;
	else if([currentElement isEqualToString:@"capture_type"])
		clipInfo.capture_type = info;
	else if([currentElement isEqualToString:@"location"])
		clipInfo.location= info;
	else if([currentElement isEqualToString:@"file_name"])
		clipInfo.file_name = info;
	
	[info release];
	
}

- (void) dealloc {
	//NSLog(@"ParserClipInfo dealloc\n");
	[clipInfo release];
	[clipList removeAllObjects];
	[clipList release];
	clipList = nil;
	clipInfo = nil;
	
	[currentElement release];
	currentElement = nil;

	[super dealloc];
}


- (id) getClipList {
	
	//NSMutableArray *ret = [[clipList mutableCopy] autorelease];
	//[clipList removeAllObjects];
	//[clipList release];
	//clipList = nil;
	return clipList;
}


@end
