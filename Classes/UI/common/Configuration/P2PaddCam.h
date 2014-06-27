//
//  P2PaddCam.h
//  TerraUI
//
//  Created by Shell on 2011/4/26.
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
#import "configureSetting.h"
#import "UserDefDevList.h"
#import "TerraUIAppDelegate.h"
#import "PlayTypeController.h"
#import "ModelNameController.h"


@interface P2PaddCam : UITableViewController <UITextFieldDelegate>
{
	NSArray *sectionTitleArray;
	NSArray *settingItemTitle;
	UserDefDevice *deviceData;
	//navigation button
	IBOutlet UIBarButtonItem *saveBtn;
	IBOutlet UIBarButtonItem *cancelBtn;
	//index of device List
	NSInteger indexofDevList;
	NSMutableArray *UserdevList;
	
	NSString *cameraName;
	NSString *IPAddr;
	NSString *UserName;
	NSString *Password;
	NSString *PortNum;
	NSString *ConfirmPw;
	UITextField* saveField;
	
	
	BOOL panTiltAbility;
	BOOL ledAbility;
	int  playType;
	
	BOOL backFromPlayType;
	
	PlayTypeController *playTypeCon;
	
	ModelNameController *modelNameController;
	int modelID;
	BOOL backFromModelNameSelection;
}


@property (nonatomic,retain) NSArray *sectionTitleArray;
@property (nonatomic,retain) NSArray *settingItemTitle;
@property (nonatomic,retain) UserDefDevice *deviceData;
@property (nonatomic,assign) IBOutlet UIBarButtonItem *saveBtn;
@property (nonatomic,assign) IBOutlet UIBarButtonItem *cancelBtn;
@property (nonatomic) NSInteger indexofDevList;
@property (nonatomic,assign) NSMutableArray *UserdevList;
@property (assign) BOOL panTiltAbility;
@property (assign) BOOL ledAbility;
@property (assign) int  playType;
@property (assign) BOOL backFromPlayType;
@property (nonatomic,retain) PlayTypeController *playTypeCon;
@property (nonatomic,retain) ModelNameController *modelNameController;
@property (assign) int modelID;
@property (assign) BOOL backFromModelNameSelection;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setDeviceDataIndex:(NSInteger)index;
- (IBAction)saveButton:(id)sender;
- (IBAction)cancelButton:(id)sender;
-(NSString*)retrieveModelName;
//-(NSString*)retrieveStreamType;

@end
