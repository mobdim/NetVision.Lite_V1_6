//
//  ModelNameController.h
//  NetVision Lite
//
//  Created by Yen Jonathan on 2011/7/11.
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
#import "UserDefDevList.h"


@interface ModelNameController : UITableViewController 
{
	IBOutlet UIBarButtonItem *backBtn;
	UserDefDevice *deviceData;
	id delegate;
	
	// test
	int mForcedStop;
}

@property (nonatomic,assign) IBOutlet UIBarButtonItem *backBtn;
@property (nonatomic,retain) UserDefDevice *deviceData;
@property (nonatomic, assign) id delegate;
// test
@property (nonatomic, assign) int mForcedStop;
//
- (IBAction)backButton:(id)sender;

@end
