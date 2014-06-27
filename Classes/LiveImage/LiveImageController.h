//
//  LiveImageController.h
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
/*
 This view controller provides a multple live viewports with paging ability.
 The relationship among the pages,viewports and devices are mentioned as below:
	1. the total device number is determined by the count of DeviceCache array
	2. the viewport port per page depends on both the number of viewport per row and the number of viewport per column
	3. the total page number depends on both the viewports per page and total device number
	4. all the viewports with associated device object in the DeviceCache are called occupied viewport;otherwise, the viewport
	   without a device object is called empty viewport(willbe marked as "Not Configured").
    5. all the empty viewports must locate behind occupied viewports in the viewport array.
	6. the occupied viewport in the viewport array has one-to-one relationship with the device object in the DeviceCache.
	   Thus, the order in the occupied viewports is determined by the order of object in the DeviceCache. 
	7. if a page contains a device number less than the available viewport number, there must have some viewports on the page 
	   marked as empty viewport("Not Configured").
	8. there must have at least one page and the associated viewport number(viewportPerRow*viewportPerColumn) even though
	   these viewport are all marked as empty.
 
 This view controller has an initial device number determined either by portal server's response(server mode) or by the
 reading from local memory(P2P mode). This initial device number determines the initial page number and initial viewport number.
 All these initial page and viewport are configured and created in viewDidLoad function.
 
 Later on while the program running, there might be viewport arrangement change request due to device order change and/or
 device number change.
 These request are done in viewWillAppear function by dynamically increasing/decreasing the viewport and/or page number.
 
*/

#import <UIKit/UIKit.h>
#import "loading.h"
#include <AudioToolbox/AudioToolbox.h>

#define P2P_MODE					1

#define DEVICE_PER_ROW				2
#define DEVICE_PER_COLUMN			2

#define TOOLBAR_BTN_TERMINATION		0
#define TOOLBAR_BTN_SNAPSHOT		1
#define TOOLBAR_BTN_LED				2
#define TOOLBAR_BTN_ZOOM_RATE		2
#define TOOLBAR_BTN_LABEL			4

@class FocalViewController;
@class DeviceListController;
@class DataCenter;
@class DeviceData;
@class UserDefDevice;
@class Viewport;
@class homeCtrlObject;

#ifdef SERVER_MODE
@class thermostatController;
@class homeCtrl;
#endif

// structure definition for viewport layout for each page
typedef struct ViewportPerPageDef
{
	int row;
	int column;
} ViewportPerPageDef;

typedef struct FocalViewportRecoverData
{
	int focalViewportTag;
	int zPos;
	CGPoint centerPosInSuper;
	CGRect frameInSuper;
} FocalViewportRecoverData;

@interface LiveImageController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate>
{	
	BOOL rowColumnViewportArrangementChanged;
	int pageTTNum;
	FocalViewController *focalViewController;
	DeviceListController *deviceListController;
	UIScrollView *scrollView;
	// a page array for scroll view paging control
	NSMutableArray *pageArray;
	// a viewport array with UIImageView instances for each viewport
	NSMutableArray *viewportArray;
	// data source
	ViewportPerPageDef viewportPerPage;
	ViewportPerPageDef previousViewportPerPage;
	
	UIToolbar *toolBar;
	BOOL cancelMode;
	
	CGRect wholeWindowMain;	
	loading *loadingView;
	UIBarButtonItem *labelDisplay;
	BOOL labelON;
	
	NSMutableDictionary *notifyDictionary;
	UIPageControl *pageControl;
	int curPage;
	int prePage;
	
	CFURLRef		soundFileURLRef;
	SystemSoundID	soundFileObject;
	
	FocalViewportRecoverData focalViewRecoverData;
	UIButton *roundExitBadge;
	UIScrollView *focalViewContainer;
#ifdef SERVER_MODE	
	homeCtrl *hcTableContainer;
	UITableView *hcTable;
	thermostatController *thermostatViewer;
#else	
	UIView *hcTableContainer;
	UITableView *hcTable;
#endif
	int mainScrollViewOffsetY;
	
	UIBarButtonItem *snapshotBtn;
	UIBarButtonItem *zoomRate;
	UIBarButtonItem *ledBtn;
	int toobarBtnClickedIndex;
	
	BOOL doFirstAppearReloadCheck;
	
	UIBarButtonItem *leftBarButtonItem;
	int ledAction;	// must be either 0 or 1

}

@property(nonatomic, assign) ViewportPerPageDef viewportPerPage;
@property(nonatomic, retain) loading *loadingView;
@property(nonatomic, assign) BOOL rowColumnViewportArrangementChanged;
@property(nonatomic, assign) int pageTTNum;
@property(nonatomic, retain) UIScrollView *scrollView;
@property(nonatomic, retain) NSMutableArray *viewportArray;
@property(nonatomic, retain) NSMutableArray *pageArray;
@property(nonatomic, assign) BOOL cancelMode;
@property(nonatomic, retain) UIBarButtonItem *labelDisplay;
@property(nonatomic, assign) BOOL labelON;
@property(nonatomic, retain) NSMutableDictionary *notifyDictionary;
@property(nonatomic, retain) UIPageControl *pageControl;
@property(nonatomic, assign) int curPage;
@property(nonatomic, assign) int prePage;
@property(nonatomic, assign) BOOL pageOutOfBound;
@property(readwrite) CFURLRef soundFileURLRef;
@property(readonly) SystemSoundID soundFileObject;
#ifdef SERVER_MODE
@property(nonatomic, retain) homeCtrl *hcTableContainer;
@property(nonatomic, retain) UITableView *hcTable;
@property(nonatomic, retain) thermostatController *thermostatViewer;
#else
@property(nonatomic, retain) UIView *hcTableContainer;
@property(nonatomic, retain) UITableView *hcTable;
#endif
@property(nonatomic, retain) UIButton *roundExitBadge;
@property(nonatomic, copy) Viewport *focalView;
@property(nonatomic, retain) UIScrollView *focalViewContainer;
@property(nonatomic, assign) int mainScrollViewOffsetY;
@property(nonatomic, retain) UIBarButtonItem *snapshotBtn;
@property(nonatomic, retain) UIBarButtonItem *zoomRate;
@property(nonatomic, retain) UIBarButtonItem *ledBtn;
@property(nonatomic, assign) int toobarBtnClickedIndex;
@property(nonatomic, assign) BOOL doFirstAppearReloadCheck;
@property(nonatomic, retain) UIBarButtonItem *leftBarButtonItem;
@property(nonatomic, assign) int ledAction;

- (void) loadingData:(id) data;
- (void) reloadData;
- (void) appearData;
// designated initializer
-(id)initWithRowPerPage:(NSInteger)row columnPerPage:(NSInteger)column;

// retrieve run mode from data center
-(int)retrieveRunMode;
// retrieve device data list from data center
// return value:
// 0 - fail
// others - the retrieved device number
-(int)retrieveDeviceListFromDataCenter;
-(void)refreshDeviceList:(NSMutableArray*)newDeviceList;
// P2P device attributes comparision
-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray;

// initial viewport layout
-(void)changeRowViewPerPage:(NSInteger)row columnViewPerPage:(NSInteger)column;
-(void)viewportLayoutWithRow:(NSInteger)row column:(NSInteger)column;
// viewport re-arrangemenet request
-(void)checkViewportRearrangement:(NSInteger)row column:(NSInteger)column;

-(void)layoutWithoutEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column;
-(void)layoutWithEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column;
-(void)doPageViewportRearrangementWithoutEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column;
-(void)doPageViewportRearrangementWithEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column;

-(void)checkReloadRequirement;
-(void)doViewportContentChange;
-(void)doPageViewportRearrangement:(NSInteger)row column:(NSInteger)column;

-(void)resetStreamingStatus;
-(void)loadStreams;
-(void)unloadStreams:(BOOL)pageChanged;

-(void)enterMapEditing;
-(void)refresh;

-(void)notifyViewportTouched:(NSNotification*)aNote;
-(void)notifyStreamingOnOff:(NSNotification*)aNote;
-(void)notifyPageChanged:(NSNotification*)aNote;
-(void)pushFocalViewWithTag:(NSInteger)index;

-(void)doTermination;
-(void)labelOnOff;
-(void)doLedOnOff;

-(BOOL)updateDeviceExtensionFeatures:(DeviceData*)dev source:(UserDefDevice*)src;

-(void)presentFocalView:(NSInteger)num;
-(void)disableSiblingActivity:(NSInteger)num;
-(void)backFromFocalView;
-(void)forcedOutFromFocalView;
-(void)enableSiblingActivity:(NSInteger)num;
-(void)disableAllSiblingActivity:(NSInteger)num;
-(void)presentFocalViewDone:(NSInteger)num;
-(void)backFromFocalViewDone:(NSInteger)num;
-(void)badgeLayout:(BOOL)flush;

-(void)showZoomingScale:(float)scale;
-(void)displayZoomRate;
-(void)resetZoomRate:(float)rate;

-(void)addFocalViewAssociatedToolbarButtons;
-(void)removeFocalViewAssociatedToolbarButtons;
-(void)doSnapshot;

#ifdef SERVER_MODE
-(void)embeddedHCTableItemReload;
-(void)embeddedHCTableLoadingData;
-(void)pushThermostateControllerWithHomeObj:(homeCtrlObject*)hmgObj;
#endif

// the function to check to see if remote device is reachable(for P2P mode use only since we use
// connectToServer to check the reachability in server mode)
-(BOOL)DeviceReachabilityCheck;

@end
