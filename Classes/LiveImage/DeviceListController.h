//
//  DeviceListController.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/12.
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

@class DeviceDetailViewController;
@class DeviceData;
@class UserDefDevice;
@interface DeviceListController : UITableViewController 
{
	// data source - an array of DeviceData instances that come from ListImageViewController
	//NSMutableArray *possessions;
	DeviceDetailViewController *detailViewController;
	
	BOOL newItemFlag;
	int focalRow;
	int runMode;
}


@property(nonatomic, assign) BOOL newItemFlag;
@property(nonatomic, assign) int focalRow;
@property(nonatomic, assign) int runMode;


-(id)initWithMode:(int)mode;
-(void)runModeChanged:(int)mode;
-(void)pushDeviceEditingView:(NSIndexPath*)indexPath;

-(void)checkReloadRequirement;
-(void)refreshDeviceList:(NSMutableArray*)newDeviceList;
// P2P device attributes comparision
-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray;
-(BOOL)updateDeviceExtensionFeatures:(DeviceData*)dev source:(UserDefDevice*)src;

@end
