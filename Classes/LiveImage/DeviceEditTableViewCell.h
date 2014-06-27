//
//  DeviceEditTableViewCell.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/13.
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


@interface DeviceEditTableViewCell : UITableViewCell 
{
	IBOutlet UILabel *title;
	IBOutlet UITextField *value;
}

@property (nonatomic,retain) IBOutlet UILabel *title;
@property (nonatomic,retain) IBOutlet UITextField *value;

@end
