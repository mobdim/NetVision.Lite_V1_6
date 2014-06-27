//
//  PlayTypeController.h
//  NetVision Lite
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

#import <UIKit/UIKit.h>
#import "UserDefDevList.h"

@interface PlayTypeController : UITableViewController {
	IBOutlet UIBarButtonItem *saveBtn;
	UserDefDevice *deviceData;
	id delegate;
	int modelID;
}
@property (nonatomic,assign) IBOutlet UIBarButtonItem *saveBtn;
@property (nonatomic,retain) UserDefDevice *deviceData;
@property (nonatomic, assign) id delegate;
@property(assign) int modelID;

- (IBAction)saveButton:(id)sender;
@end
