//
//  setSelectionCell.m
//  TerraUI
//
//  Created by Shell on 2011/1/27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "setSelectionCell.h"

@implementation setSelectionCell

@synthesize checkOption;
@synthesize titleLabel,cgiType;

-(id) initWithTitle:(NSString*)t check:(BOOL)c cgi:(NSString*)type
{
	self.titleLabel = t;
	self.checkOption = c;
	self.cgiType = type;
	return self;
}

@end
