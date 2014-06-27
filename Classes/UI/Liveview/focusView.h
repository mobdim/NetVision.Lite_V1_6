//
//  focusView.h
//  TerraUI
//
//  Created by Shell on 2011/1/24.
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
#import "deviceListTableView.h"
#import "deviceProperties.h"
#import "liveviewController.h"
#import "focusDelegate.h"

@interface focusView : UIViewController 
<deviceListDelegate>
{
	IBOutlet UILabel *cameraNameLabel;
	IBOutlet UIBarButtonItem *selectDeviceBtn;
	deviceListTableView *deviceListView;
	deviceProperties *deviceObj;
	id<focusDelegate> delegate;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil deviceObject:(id)obj;
- (IBAction)selectDeviceBtn:(id)object;
- (void)setSelectedDevice:(NSMutableArray*)selectedDevice;
- (void)changeDevice:(id)obj;

@property (nonatomic,retain) IBOutlet UILabel *cameraNameLabel;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *selectDeviceBtn;
@property (nonatomic,retain) deviceListTableView *deviceListView;
@property (nonatomic,retain) deviceProperties *deviceObj;
@property (nonatomic,retain) id<focusDelegate> delegate;

@end
