//
//  deviceListCellStyle.m
//  TerraUI
//
//  Created by Shell on 2011/1/12.
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

#import "deviceListCellStyle.h"



@implementation deviceListCellStyle

@synthesize deviceCheck;
@synthesize deviceImage;
@synthesize deviceName;
@synthesize deviceIP;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
		}
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
   
}


- (void)dealloc {
    [super dealloc];
}


@end
