//
//  deviceListTableView.h
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
#import "deviceListCellStyle.h"
#import "deviceProperties.h"
#import "loading.h"
#import "checkData.h"
#import "TerraUIAppDelegate.h"

#import "deviceListDelegate.h"


@interface deviceListTableView : UITableViewController {
	id<deviceListDelegate> delegate;
	NSMutableArray *deviceListArray;
	BOOL singleMode;
	loading *loadingView;
	NSInteger errorDataNumber;
}
- (void)setSelectedDeviceList:(NSMutableArray*)selectedDeviceListName;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil singleMode:(BOOL)mode;
- (NSMutableArray*)queryDeviceList;

@property (nonatomic,retain) id<deviceListDelegate> delegate;
@property (nonatomic,retain) NSMutableArray *deviceListArray;
@property (nonatomic) BOOL singleMode;
@property (nonatomic,retain) loading *loadingView;
@property (nonatomic) NSInteger errorDataNumber;
@end
