//
//  setSettingCell.m
//  TerraUI
//
//  Created by Shell on 2011/1/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "setSettingCell.h"


@implementation setSettingCell
@synthesize icon,titleText,detailText;

-(id)initWithIcon:(id)image Title:(NSString*)first Detail:(NSString*)secondary
{
	self.icon = image;
	self.titleText = first;
	self.detailText = secondary;
	return self;
}

@end
