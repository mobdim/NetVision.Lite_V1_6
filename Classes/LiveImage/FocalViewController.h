//
//  FocalViewController.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/12.
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

#define FOCAL_VIEW_CONTROL_PANEL_HEIGHT								35
#define NAVIGATION_BAR_HEIGHT										44
#define TAB_BAR_HEIGHT												49
#define PAGE_CONTROL_HEIGHT											6

@class Viewport;
@class DeviceData;
@class UserDefDevice;

@interface FocalViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>
{
	UIToolbar *toolBar;	
	Viewport *imageView;
	int associatedViewTag;
	
	int runMode;	// P2P/Server
	UIBarButtonItem *zoomRate;
	UIScrollView *scrollView;
	BOOL cancelMode;

}

@property(nonatomic, retain) UIToolbar *toolBar;
@property(nonatomic, retain) Viewport *imageView;
@property(nonatomic, assign) int associatedViewTag;
@property(nonatomic, assign) int runMode;
@property(nonatomic, retain) UIBarButtonItem *zoomRate;
@property(nonatomic, retain) UIScrollView *scrollView;
@property(nonatomic, assign) BOOL cancelMode;


-(void)loadStream;
-(void)unloadStream;

-(void)checkReloadRequirement;
-(void)refreshDeviceList:(NSMutableArray*)newDeviceList;
// P2P device attributes comparision
-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray;
-(void)refresh;
-(void)doSnapshot;
-(void)notifySlideThumbnailArrayTreatment:(NSNotification*)aNote;
-(void)notifyStreamingOnOff:(NSNotification*)aNote;	

-(void)showZoomingScale:(float)scale;
-(void)displayZoomRate;
-(void)resetZoomRate:(float)rate;
-(BOOL)updateDeviceExtensionFeatures:(DeviceData*)dev source:(UserDefDevice*)src;

@end
