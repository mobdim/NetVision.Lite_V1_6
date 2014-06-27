//
//  deviceListCellStyle.h
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

#import <UIKit/UIKit.h>

@interface deviceListCellStyle : UITableViewCell 
{
	IBOutlet UIImageView *deviceCheck;
	IBOutlet UIImageView *deviceImage;
	IBOutlet UILabel *deviceName;
	IBOutlet UILabel *deviceIP;
}

@property (nonatomic,retain) UIImageView *deviceCheck;
@property (nonatomic,retain) UIImageView *deviceImage;
@property (nonatomic,retain) UILabel *deviceName;
@property (nonatomic,retain) UILabel *deviceIP;

@end
