//
//  DeviceDetailViewController.h
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

#define DEVICE_DETAILED_TABLE_VIEW_TOTAL_CELL					5

@class DeviceData;
@interface DeviceDetailViewController : UITableViewController <UITextFieldDelegate>
{
	NSArray *sectionTitleArray;		//section title
	NSArray *cellTitleArray;		//row title
	
	DeviceData *editingPossession;
	DeviceData *temp;
	BOOL confirmed;
	int focalRow;
	UIButton *doneButton;
	BOOL numberKeyPadON;
}

@property (nonatomic,retain) NSArray *sectionTitleArray;
@property (nonatomic,retain) NSArray *cellTitleArray;
@property(nonatomic, retain) DeviceData *editingPossession;
@property(nonatomic, retain) DeviceData *temp;
@property(nonatomic, assign) BOOL confirmed;
@property(nonatomic, assign) int focalRow; 
@property(nonatomic, assign) BOOL numberKeyPadON;
@property(nonatomic, retain) UIButton *doneButton;

-(void)save;

// when keyboard type is numeric
-(void)numberPadShouldHide:(id)sender;
-(void)addDoneButtonOnNumberKeyPad;

@end
