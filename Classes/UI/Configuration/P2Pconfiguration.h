//
//  P2Pconfiguration.h
//  TerraUI
//
//  Created by Shell on 2011/4/25.
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
#import "TerraUIAppDelegate.h"
#import "deviceListCellStyle.h"
#import "DataCenter.h"
#import "P2PaddCam.h"


@interface P2Pconfiguration : UITableViewController 
{
	NSMutableArray *UserDefinedDeviceArray;
	//normal mode button
	IBOutlet UIBarButtonItem *EditBtn;
	IBOutlet UIBarButtonItem *DoneBtn;
	//edit mode button
	IBOutlet UIBarButtonItem *AddCameraBtn;
	IBOutlet UIBarButtonItem *EndEditBtn;
	//add camera page
	P2PaddCam *addCameraPage;
	
	int totalDeviceNum;
	
}
- (IBAction)saveUserDefArray:(id)object;
- (IBAction)editMode:(id)object;
- (IBAction)endEditMode:(id)object;
- (IBAction)addCamera:(id)object;

@property (nonatomic,retain) NSMutableArray *UserDefinedDeviceArray;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *EditBtn;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *DoneBtn;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *AddCameraBtn;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *EndEditBtn;
@property (nonatomic,retain) P2PaddCam *addCameraPage;
@property (nonatomic,assign) int totalDeviceNum;

@end
