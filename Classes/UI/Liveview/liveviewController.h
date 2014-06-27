//
//  liveviewController.h
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
#import "focusView.h"
#import "deviceProperties.h"
#import "focusDelegate.h"
@class focusView;
@interface liveviewController : UIViewController
<focusDelegate>
{
	IBOutlet UIButton *cameraButton1;
	IBOutlet UIButton *cameraButton2;
	IBOutlet UIButton *cameraButton3;
	IBOutlet UIButton *cameraButton4;
	IBOutlet UILabel *cameraLabel1;
	IBOutlet UILabel *cameraLabel2;
	IBOutlet UILabel *cameraLabel3;
	IBOutlet UILabel *cameraLabel4;
	IBOutlet UIView *cameraView1;
	IBOutlet UIView *cameraView2;
	IBOutlet UIView *cameraView3;
	IBOutlet UIView *cameraView4;
	focusView *focusViewr;
	NSMutableArray *playObjArray;//with devicePro[erties
	NSInteger indexNum ;//record current choose video index of playObjArray
}

- (IBAction)liveViewButtonClick:(id)object;
- (void)setDeviceArray:(id)deviceObject;

@property (nonatomic, retain) IBOutlet UIButton *cameraButton1;
@property (nonatomic, retain) IBOutlet UIButton *cameraButton2;
@property (nonatomic, retain) IBOutlet UIButton *cameraButton3;
@property (nonatomic, retain) IBOutlet UIButton *cameraButton4;
@property (nonatomic, retain) IBOutlet UILabel *cameraLabel1;
@property (nonatomic, retain) IBOutlet UILabel *cameraLabel2;
@property (nonatomic, retain) IBOutlet UILabel *cameraLabel3;
@property (nonatomic, retain) IBOutlet UILabel *cameraLabel4;
@property (nonatomic, retain) IBOutlet UIView *cameraView1;
@property (nonatomic, retain) IBOutlet UIView *cameraView2;
@property (nonatomic, retain) IBOutlet UIView *cameraView3;
@property (nonatomic, retain) IBOutlet UIView *cameraView4;
@property (nonatomic, retain) focusView *focusViewr;
@property (nonatomic, retain) NSMutableArray *playObjArray;
@property (nonatomic) NSInteger indexNum;

@end