//
//  LiveImageController.m
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

#import <unistd.h>
#import <QuartzCore/QuartzCore.h>
#import "LiveImageController.h"
#import "DeviceListController.h"
#import "FocalViewController.h"
#import "Viewport.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ImageCache.h"
#import "ConstantDef.h"
#import "checkData.h"
#import "UserDefDevList.h"
#import "TerraUIAppDelegate.h"
#import "ModelNames.h"

#ifdef SERVER_MODE
#import "homeCtrl.h"
#import "thermostatController.h"
#import "homeCtrlObject.h"
#endif

@implementation LiveImageController

@synthesize scrollView;
@synthesize pageArray;
@synthesize viewportArray;
@synthesize pageTTNum;
@synthesize rowColumnViewportArrangementChanged;
@synthesize cancelMode;
@synthesize labelON;
@synthesize labelDisplay;
@synthesize notifyDictionary;
@synthesize pageControl;
@synthesize curPage;
@synthesize prePage;
@synthesize pageOutOfBound;
@synthesize soundFileURLRef;
@synthesize soundFileObject;
@synthesize loadingView;
@synthesize hcTableContainer;
@synthesize hcTable;
@synthesize roundExitBadge;
@synthesize viewportPerPage;
@synthesize focalViewContainer;
@synthesize focalView;
@synthesize mainScrollViewOffsetY;
@synthesize snapshotBtn;
@synthesize zoomRate;
@synthesize ledBtn;
@synthesize toobarBtnClickedIndex;
#ifdef SERVER_MODE
@synthesize thermostatViewer;
#endif
@synthesize doFirstAppearReloadCheck;
@synthesize leftBarButtonItem;
@synthesize ledAction;

-(id)init
{
	// Call the superclass's designated initializer
	[super initWithNibName:nil bundle:nil];
	
	// Get the tab bar item
	UITabBarItem *tbi = [self tabBarItem];
	
	// Give it label
	[tbi setTitle:@"Live View"];
	UIImage *i = [UIImage imageNamed:@"liveview.png"];
	[tbi setImage:i];	
	
	focalViewController = nil;
	deviceListController = nil;
	viewportArray = nil;
	viewportPerPage.row = DEVICE_PER_ROW;
	viewportPerPage.column = DEVICE_PER_COLUMN;
	scrollView = nil;
	// at least one page
	pageArray = nil;
	[self setPageTTNum:1];
	[self setRowColumnViewportArrangementChanged:NO];
	[self setCancelMode:NO];
	[self setLabelDisplay:nil];
	
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	[self setNotifyDictionary:dictionary];
	[dictionary release];
	
	[self setPageControl:nil];
	[self setCurPage:0];
	[self setPrePage:0];
	[self setPageOutOfBound:NO];
	
	focalViewRecoverData.focalViewportTag = 0;
	focalViewRecoverData.zPos = 0;
	focalViewRecoverData.centerPosInSuper.x = 0;
	focalViewRecoverData.centerPosInSuper.y = 0;
	focalViewRecoverData.frameInSuper = CGRectMake(0,0,0,0);
	
	// badge for exiting focal view mode
	[self setRoundExitBadge:nil];
	[self setFocalViewContainer:nil];
	[self setFocalView:nil];
	
	[self setHcTableContainer:nil];
	[self setHcTable:nil];
	[self setZoomRate:nil];
	[self setSnapshotBtn:nil];
	[self setLedBtn:nil];
	
	[self setLeftBarButtonItem:nil];
	[self setLedAction:0];
	
	return self;
}

-(id)initWithRowPerPage:(NSInteger)row columnPerPage:(NSInteger)column
{
	[self init];
	
	if(row == 0)
		row = 2;
	if(column == 0)
		column = 2;
	
	viewportPerPage.row = row;
	viewportPerPage.column = column;
		
	return self;
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	/*
	 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	 if (self) {
	 // Custom initialization.
	 [self init];
	 }
	 return self;
	 */
	
	return [self init];
}


-(void)changeRowViewPerPage:(NSInteger)row columnViewPerPage:(NSInteger)column
{
	if(row == 0)
		row = 2;
	if(column == 0)
		column = 2;
	
	previousViewportPerPage.row = viewportPerPage.row;
	previousViewportPerPage.column = viewportPerPage.column;
	viewportPerPage.row = row;
	viewportPerPage.column = column;
	
	if((previousViewportPerPage.row != viewportPerPage.row)
	   || (previousViewportPerPage.column != viewportPerPage.column))
		[self setRowColumnViewportArrangementChanged:YES];
}

static BOOL isFirstAppear = YES;
-(void)reloadData 
{	
	NSLog(@"enter reloadData...");

	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	
	if(isFirstAppear) 
	{
		// configure the navigation bar
		// prepare the required navigationItem stuff
		//NSLog(@"LiveImageController configure navugation bar...begin...\r\n");
		
		// right bar item button		
		UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
		[[self navigationItem] performSelectorOnMainThread:@selector(setRightBarButtonItem:)withObject:(id)rightBarButtonItem waitUntilDone:NO];		
		// left bar item button
		//UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Mapping" style:UIBarButtonItemStylePlain target:self action:@selector(enterMapEditing)];
		if(leftBarButtonItem)
			[leftBarButtonItem release];
		leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Mapping" style:UIBarButtonItemStylePlain target:self action:@selector(enterMapEditing)];					
		[[self navigationItem] performSelectorOnMainThread:@selector(setLeftBarButtonItem:)withObject:(id)leftBarButtonItem waitUntilDone:NO];
		// title view
		[[self navigationItem] performSelectorOnMainThread:@selector(setTitle:)withObject:(id)@"Live View" waitUntilDone:NO];	
		
		[rightBarButtonItem release];
		//[leftBarButtonItem release];
		//NSLog(@"LiveImageController configure navugation bar...end...\r\n");

		int runMode = [[appDelegate dataCenter] getMobileMode];
		//NSLog(@"sever mode: %d", runMode);
		if(!deviceListController)
		{
			NSLog(@"LiveImageView...reloadData...create deviceListController...");
			deviceListController = [[DeviceListController alloc] initWithMode:runMode];
		}
	
		//if(!focalViewController)
		//{
		//	NSLog(@"LiveImageView...reloadData...create focalViewController...");
		//	focalViewController = [[FocalViewController alloc] init];
		//	[focalViewController setRunMode:runMode];
		//}		

		// for test only - temp disabled
		// if in server mode, we need to check to see if user click 'CANCEL' button
		if(runMode == RUN_SERVER_MODE)
		{
			NSError *err = [[appDelegate dataCenter] ConnecttoServer];
			if([err code] == 3)
				[self setCancelMode:YES];
			// if something wrong in server, do not retrieve device list
			if(err != nil)
				goto LiveImageController_viewDidLoad_Exit;
		}
	
		// read in the device data, then decide the number of device 
		if([self cancelMode] == NO)
			[self retrieveDeviceListFromDataCenter];	
			
LiveImageController_viewDidLoad_Exit:
		// prepare the page and associated viewport
		//NSLog(@"reload...viewportLayoutWithRow...row: %d...column: %d...", viewportPerPage.row, viewportPerPage.column);
		[self viewportLayoutWithRow:(NSInteger)(viewportPerPage.row) column:(NSInteger)(viewportPerPage.column)];
		isFirstAppear = NO;	
		doFirstAppearReloadCheck = YES;
		//goto LiveImageController_viewWillAppear;	// ++++++ 0707
	}
	else
		doFirstAppearReloadCheck = NO;
	
	///===================================

	int runMode = [[appDelegate dataCenter] getMobileMode];	
	if(runMode == RUN_SERVER_MODE)
	{
		NSError *err = [[appDelegate dataCenter] ConnecttoServer];
		if([err code] == 3)
			[self setCancelMode:YES];
		else
			[self setCancelMode:NO];
		// if something wrong in server, do not retrieve device list
		if(err != nil)
			goto LiveImageController_viewWillAppear;
	}			
	
	if([self cancelMode] == YES)
		goto LiveImageController_viewWillAppear;
	
	[self checkReloadRequirement];
	
LiveImageController_viewWillAppear:	
	// register as an observer for "NotifyViewportTouched" notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(notifyViewportTouched:)
												 name:NOTIFICATION_VIEWPORT_TOUCHED
											   object:nil];
	
	// register as an observer for "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(notifyStreamingOnOff:)
												 name:NOTIFICATION_LIVEVIEW_ON_OFF
											   object:nil];	
	
	// register as an observer for "NotifyliveViewPageChanged" notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(notifyPageChanged:)
												 name:NOTIFICATION_LIVEVIEW_PAGE_CHANGED
											   object:nil];		
	
	// tell application delegate that we are on	
	if(appDelegate != nil)
		appDelegate.liveViewON++;
}

static BOOL isViewerLoading = NO;
-(void)loadingData:(id) data 
{	
	if(isViewerLoading)
	{
		[loadingView.view removeFromSuperview];
		return;
	}
	
	isViewerLoading = YES;
	
	NSLog(@"loadingData into ========================\n");
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	
	LiveImageController* myCon = (LiveImageController*) data;
	[myCon reloadData];
	
	UIApplication *app =  (UIApplication*)[UIApplication sharedApplication];	
	if(app != nil)	
	{
		if([[DeviceCache sharedDeviceCache] totalDeviceNumber] > 0)
			[app setIdleTimerDisabled:YES];
		else
			[app setIdleTimerDisabled:NO];
	}	
	NSLog(@"LiveImageController...loadingData...total device count: %d", [[DeviceCache sharedDeviceCache] totalDeviceNumber]);	
	
	[loadingView.view removeFromSuperview];
	[pool release];
	NSLog(@"loadingData out ========================\n");
	
	isViewerLoading = NO;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void)viewDidLoad 
{
	NSLog(@"LiveImageController viewDidLoad\r\n");
    [super viewDidLoad];
	wholeWindowMain = [[self view] bounds];
	self.title = @"Live View";
	loadingView = [[loading alloc] initWithNibName:@"loading" bundle:nil];
	[self setLabelON:NO];
	
    //NSURL *tapSound   = [[NSBundle mainBundle] URLForResource: @"tap"
    //                                            withExtension: @"aif"];
    // Store the URL as a CFURLRef instance
    // self.soundFileURLRef = (CFURLRef) [tapSound retain];		
	self.soundFileURLRef = CFBundleCopyResourceURL(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.UIKit")), 
												   CFSTR("Tock"), CFSTR("aiff"), NULL);			
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (soundFileURLRef,  &soundFileObject);
		
	//nash
	
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	[appDelegate setLiveVw:self];
	
	[self setLeftBarButtonItem:nil];
	
	return;	
}

static BOOL isViewerAppear = NO;
-(void)appearData 
{
	if(isViewerAppear)
		return;

	isViewerAppear = NO;
}


-(void)viewWillAppear:(BOOL)animated
{
	NSLog(@"ListImageController...viewWillAppear...");
	[loadingView showLoadingView:self.navigationController];
	[super viewWillAppear:animated];
	
}


- (void)viewDidAppear:(BOOL)animated 
{	
	[super viewDidAppear:animated];
	
	[NSThread detachNewThreadSelector:@selector(loadingData:) toTarget:self withObject:self];	
}


-(void)viewWillDisappear:(BOOL)animated
{
	NSLog(@"ListImageController...viewWillDisappear...");
	[super viewWillDisappear:animated];
	
	// go back to multiple viewport mode
	[self forcedOutFromFocalView];	
	
	// unload the streams
	[self unloadStreams:NO];	
	[self resetStreamingStatus];
	
	// unregistry the observer role for "NotifyViewportTouched" notification 
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_VIEWPORT_TOUCHED object:nil];
	
	// unregistry the observer role "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_ON_OFF object:nil];
	
	// unregistry the observer role "NotifyliveViewPageChanged" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_PAGE_CHANGED object:nil];		
	
	// tell application delegate that we are on
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate*)[[UIApplication sharedApplication] delegate];	
	if(appDelegate != nil)
		appDelegate.liveViewON--;
	
	UIApplication *app =  (UIApplication*)[UIApplication sharedApplication];	
	if(app != nil)	
		[app setIdleTimerDisabled:NO];	

}

- (void)viewDidUnload 
{
	NSLog(@"LiveImageView...viewDidUnload...");
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	// go back to multiple viewport mode
	[self forcedOutFromFocalView];		
	
	// unregistry the observer role for "NotifyViewportTouched" notification 
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_VIEWPORT_TOUCHED object:nil];
	
	// unregistry the observer role "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_ON_OFF object:nil];
	
	// unregistry the observer role "NotifyliveViewPageChanged" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_PAGE_CHANGED object:nil];				
	
	// if we release the controllers here due to LowMamoryWarning, the program will crash once we
	// go back to multiple live viewport page
	//if(deviceListController)
	//{
	//	NSLog(@"LiveImageController...viewDidUnload...delete deviceListController");
	//	[deviceListController release];
	//	deviceListController = nil;
	//}	
	//
	//if(focalViewController)
	//{
	//	NSLog(@"LiveImageController...viewDidUnload...delete focalViewController");
	//	[focalViewController release];
	//	focalViewController = nil;
	//}
	AudioServicesDisposeSystemSoundID(soundFileObject);
    CFRelease (soundFileURLRef);
		
	deviceListController = nil;
	focalViewController = nil;
	scrollView = nil;
	[viewportArray release];
	viewportArray = nil;
	[pageArray release];
	pageArray = nil;
	hcTableContainer = nil;
	hcTable = nil;
	
	isFirstAppear = YES;	
	leftBarButtonItem = nil;
}

-(BOOL)DeviceReachabilityCheck
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return NO;

	int runMode = [[appDelegate dataCenter] getMobileMode];
	if(runMode == RUN_SERVER_MODE)	
		return YES;
	
	if(focalViewRecoverData.focalViewportTag == 0)
	{
		// in multiple viewport mode check
		NSLog(@"enter DeviceReachabilityCheck...");
	
	
	
		return YES;
	}
	else
	{
		Viewport *vw = [viewportArray objectAtIndex:focalViewRecoverData.focalViewportTag-1];
		return [vw DeviceReachabilityCheck];
	}
	
	
}

-(void)checkReloadRequirement
{	
	NSLog(@"LiveImageController...checkReloadRequirement...");
	BOOL dcAttrChanged = NO;	
	
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	
	NSLog(@"LiveImageController...checkReloadRequirement...check network condition....");
	int err = [[appDelegate dataCenter] isConnectToNetworkWithMsg:YES];
	if(err == MB_NETWORK_NONE)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error" 
														message:@"No Internet connection available. Please connect to the Internet." 
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];			
		[alert show];
		[alert release];		
		return;	
	}
	
	int runMode = [[appDelegate dataCenter] getMobileMode];
	if(runMode == RUN_SERVER_MODE)
	{
		NSLog(@"LiveImageController...checkReloadRequirement...connect to server....");
		NSError *errE = [[appDelegate dataCenter] ConnecttoServer];
		// something wrong in server
		if(errE != nil)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server error" 
															message:@"Can not connect to server." 
														   delegate:nil 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];			
			[alert show];
			[alert release];			
			return;
		}
	}
	else
	{
		// check to see if we can connect to device. Let's issue a cgi command to see if device response
		// can be obtained
		//if([self DeviceReachabilityCheck] == NO)
		//	return;
		;
	}
	
	NSLog(@"LiveImageController...checkReloadRequirement...retrieve device list to see if any change.....");
	int count = 0;	
	NSMutableArray *deviceArray;	
	if(runMode == RUN_SERVER_MODE)	
		deviceArray = [[appDelegate dataCenter] GetDeviceListWithRefresh:&dcAttrChanged
															 withDevType:0
															 withSubType:1
												     withRetrievingCount:count];
	else
	{
		deviceArray = [[appDelegate dataCenter] getUserDeviceList];
		// check to see if array object changed. If yes, flush and reproduce the DataCache array
		dcAttrChanged = [self deviceAttrChanged:deviceArray];
		if(dcAttrChanged == YES)
			NSLog(@"device attributes changed: YES");
	}
		
	if(dcAttrChanged == YES)
	{
		// unload the streams first since we need to do mapping rearrangement
		[self unloadStreams:NO];		
		[self refreshDeviceList:deviceArray];
	}
#ifdef SERVER_MODE	
	else
	{
		// if in server mode, we need to check to see if the stream type changed or not
		
		// stream type check
		if(runMode == RUN_SERVER_MODE)
		{
			//NSLog(@"LiveImageController...checkReloadRequirement...update stream type info for each device...");
			ServerInfo *serverInfo = nil;
			TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
			if(appDelegate != nil)
			{
				serverInfo = (ServerInfo*)[[appDelegate dataCenter] getConfigurationData];
				int st = serverInfo.streamType;
				NSLog(@"LiveImageController...checkReloadRequirement...update stream type info for each device...streamType: %d", st);
				for(int i = 0; i < [[DeviceCache sharedDeviceCache] totalDeviceNumber]; i++)
				{
					DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:i];					
					//NSLog(@"device #: %d streamType before: %d", i+1, [dev playType]);
					[dev setPlayType:st];
					//NSLog(@"device #: %d streamType after: %d", i+1, st);
				}
			}
		}								
	}
#endif
	
	// we might need to re-arrange the page and associated viewport
	if(([[DeviceCache sharedDeviceCache] dirtyFlag] == YES) ||
	   ([self rowColumnViewportArrangementChanged] == YES))
		[self checkViewportRearrangement:(NSInteger)(viewportPerPage.row) column:(NSInteger)(viewportPerPage.column)];
	
	// check to see if embedded homeCtrl items reload requirement
#ifdef SERVER_MODE	
	if(doFirstAppearReloadCheck == NO)
		[self embeddedHCTableItemReload];
#endif	
	// loading the streams
	[self loadStreams];	
	
}


-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray
{
	if([self retrieveRunMode] != RUN_P2P_MODE)
		return YES;	// to qaurantee user will update the device list
		
	if([deviceArray count] != [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return YES;
	
	for(int i=0; i<[deviceArray count]; i++)
	{
		UserDefDevice *newObj;
		DeviceData *dev;
		newObj = [deviceArray objectAtIndex:i];
		dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:i];
		
		NSLog(@"viewportTag: %d deviceAttribute:streamType- old: %d  new: %d", i+1, [dev playType], [newObj playType]);
		NSLog(@"viewportTag: %d deviceAttribute:modelName- old: %d  new: %d", i+1, [dev modelNameID], [newObj modelNameID]);		
		NSLog(@"viewportTag: %d deviceAttribute:extensionAbility- old: %d  new: %d", i+1, [dev extensionFeatures], [newObj extensionAbilities]);		
		// update the extension features
		if([self updateDeviceExtensionFeatures:dev source:newObj])
			return YES;
		
		if([[dev title] isEqualToString:newObj.cameraName] == NO)
			return YES;
		if([[dev authenticationName] isEqualToString:newObj.UserName] == NO)
			return YES;		
		if([[dev authenticationPassword] isEqualToString:newObj.Password] == NO)
			return YES;		
		if([[dev IP] isEqualToString:newObj.IPAddr] == NO)
			return YES;
		NSString *port = [[NSString alloc] initWithFormat:@"%d", [dev portNum]];
		if([port isEqualToString:newObj.PortNum] == NO) {
			[port release];
			return YES;
		}
		
		[port release];
	}
	
	// all the same, return NO
	return NO;
}

-(BOOL)updateDeviceExtensionFeatures:(DeviceData*)dev source:(UserDefDevice*)src
{
	/*
	 int value = [dev extensionFeatures];
	 if([src panTiltAbility] == YES)
	 value |= DEVICE_FEATURE_PAN_TILT;
	 else
	 value &= (~DEVICE_FEATURE_PAN_TILT);
	 
	 if([src ledAbility] == YES)
	 value |= DEVICE_FEATURE_LED;
	 else
	 value &= (~DEVICE_FEATURE_LED);
	 
	 [dev setExtensionFeatures:value];
	 */
	
	BOOL changed = NO;
	
	if([dev modelNameID] != [src modelNameID])
	{
		[dev setModelNameID: [src modelNameID]];
		changed = YES;
	}
	if([dev extensionFeatures] != [src extensionAbilities])
	{
		[dev setExtensionFeatures:[src extensionAbilities]];
		changed = YES;
	}
	if([dev playType] != [src playType])
	{
		[dev setPlayType: [src playType]];
		changed = YES;
	}
	
	return changed;
	
}

-(void)resetStreamingStatus
{
	for(int i=0; i<[viewportArray count]; i++)
	{
		Viewport *port = [viewportArray objectAtIndex:i];
		[port resetStreamingStatus];
	}
}

-(void)loadStreams
{
	NSLog(@"LiveImageController...load streams...");

	int viewportCountPerPage = viewportPerPage.row*viewportPerPage.column;
	//NSLog(@"viewportCountPerPage: %d", viewportCountPerPage);
	// if curPage not exist(after deleting devices and doPageViewportRearrangement), switch to page one
	if([self curPage] >= [self pageTTNum])
		[self setCurPage:0];
	
	int ttDeviceNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	int start = [self curPage]*viewportCountPerPage;
	int end = ([self curPage]+1)*viewportCountPerPage;
	//NSLog(@"loadStreams...start:%d end: %d", start, end);
	for(int i=start; i<end; i++)
	{		
		Viewport *vw = [viewportArray objectAtIndex:i];
		// if in focal view mode, just do streaming for the focal viewport
		if(focalViewRecoverData.focalViewportTag > 0)
		{
			if(focalViewRecoverData.focalViewportTag == i+1)
			{
				[[vw streaming] setConnectionRetryEnabled:YES];
				[[vw streaming] play];
			}
		}
		else	
		{
			[[vw streaming] setConnectionRetryEnabled:YES];
			[[vw streaming] play];		
			// to avoid data corruption if we do have streaming job
			if(ttDeviceNum && (i<ttDeviceNum))
				[NSThread sleepForTimeInterval:0.2];	// wait for 200 ms
		}
	}
}

-(void)unloadStreams:(BOOL)pageChanged
{
	NSLog(@"LiveImageController...unload streams...");
	
	if(pageChanged == NO)
	{
		int viewportCountPerPage = viewportPerPage.row*viewportPerPage.column;	
		// if curPage not exist(after deleting devices and doPageViewportRearrangement), switch to page one
		if([self curPage] >= [self pageTTNum])
			return;		
		
		int start = [self curPage]*viewportCountPerPage;
		int end = ([self curPage]+1)*viewportCountPerPage;	
		
		for(int i=start; i<end; i++)
		{		
			[[[viewportArray objectAtIndex:i] streaming] stop];
			[[[viewportArray objectAtIndex:i] streaming] setConnectionRetryEnabled:NO];
		}		
		/*
		//safe stop - nash
		int wait = 100;
		while(wait--)
		{
			int ok = 1;
			for(int i=start; i<end; i++)
			{
				if([[[[viewportArray objectAtIndex:i] streaming] mjpeg] stream_t] != NULL)
				{
					if(![[[[[viewportArray objectAtIndex:i] streaming] mjpeg] stream_t] isFinished])
					{
						//NSLog(@"wait close!\n");
						ok = 0;
						break;
					}
				}
				if(!ok)
					break;
				if([[[[viewportArray objectAtIndex:i] streaming] ffmpeg] stream_t] != NULL)
				{
					if(![[[[[viewportArray objectAtIndex:i] streaming] ffmpeg] stream_t] isFinished])
					{
						ok = 0;
						break;
					}
				}
			}
			if(ok)
				break;
			else
				[NSThread sleepForTimeInterval:0.01];
		}
		*/	
		return;
	}
	
	int viewportCountPerPage = viewportPerPage.row*viewportPerPage.column;	
	int start = [self prePage]*viewportCountPerPage;
	int end = ([self prePage]+1)*viewportCountPerPage;
	
	for(int i=start; i<end; i++)
	{		
		[[[viewportArray objectAtIndex:i] streaming] stop];
		[[[viewportArray objectAtIndex:i] streaming] setConnectionRetryEnabled:NO];
	}		
	//safe stop - nash
	/*
	int wait = 100;
	while(wait--)
	{
		int ok = 1;
		for(int i=start; i<end; i++)
		{
			if([[[[viewportArray objectAtIndex:i] streaming] mjpeg] stream_t] != NULL)
			{
				if(![[[[[viewportArray objectAtIndex:i] streaming] mjpeg] stream_t] isFinished])
				{
					ok = 0;
					break;
				}
			}
			if(!ok)
				break;
			if([[[[viewportArray objectAtIndex:i] streaming] ffmpeg] stream_t] != NULL)
			{
				if(![[[[[viewportArray objectAtIndex:i] streaming] ffmpeg] stream_t] isFinished])
				{
					ok = 0;
					break;
				}
			}
				
		}
		if(ok)
			break;
		else
			[NSThread sleepForTimeInterval:0.01];
		
	}
	*/
}

// The returned mode determines how to consist the urls and associated cgi commands
-(int)retrieveRunMode
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return RUN_SERVER_MODE;
	
	return [[appDelegate dataCenter] getMobileMode];
}
	
// this function will be called whenever we need to retrieve(refresh) device list
-(int)retrieveDeviceListFromDataCenter
{		
	// If I have my own dataCenter(no need toborrow from application delegate), use
	// following codes	
	// flush all the objects in DeviceData cache
	// before we remove all devices in the DeviceCache, we should remove the associated imafe in ImageCache first
	// since ImageCache is a dictionnary that needs a key to remove the associated content	
	if([[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		for(int i=0; i<[[DeviceCache sharedDeviceCache] totalDeviceNumber]; i++)
		{
			NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:i];
			[[ImageCache sharedImageCache] deleteImageForKey:key];
		}
		
		[[DeviceCache sharedDeviceCache] removeAllDevices];
	}
	
	// check the device network ability
	NSLog(@"check network capability...");
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return 0;
	
	int err = [[appDelegate dataCenter] isConnectToNetworkWithMsg:YES];
	if(err == MB_NETWORK_NONE)
		return 0;
	
	NSMutableArray *deviceArray;
	if([self retrieveRunMode] == RUN_P2P_MODE)
	{
		deviceArray = [[appDelegate dataCenter] getUserDeviceList];
		for(int i = 0 ; i<[deviceArray count]; i++) 	
		{		
			UserDefDevice *device_info = [deviceArray objectAtIndex:i];
			DeviceData *device = [DeviceData deviceDataCreationWthAssignedIndex:i];	
			NSString *str = [NSString stringWithString:device_info.cameraName]; 	
			[device setTitle:str];			
			str = [NSString stringWithString:device_info.IPAddr];
			[device setIP:str];
			str = [NSString stringWithString:device_info.UserName];
			[device setAuthenticationName:str];
			str = [NSString stringWithString:device_info.Password];
			[device setAuthenticationPassword:str];	
			int port = (int)CFStringGetIntValue((CFStringRef)device_info.PortNum);
			[device setPortNum:port];
			//nash
			[device setPlayType:device_info.playType];
			//extension ability
			[device setExtensionFeatures:device_info.extensionAbilities];
			[device setModelNameID:device_info.modelNameID];
			// put the device object into the shared device cache
			NSString *key = [device deviceKey];
			//NSLog(@"Device key: %@", key);
			[[DeviceCache sharedDeviceCache] setDevice:device forKey:key];													
		}
		
		return [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	}	
		
	int count = 0;
	NSLog(@"connect to server...");
	//something wrong in server
	NSError *errE = [[appDelegate dataCenter] ConnecttoServer];
	if(errE != nil)
		return 0;
	
	NSLog(@"server found, retrieve device list from server...");
	deviceArray = [[appDelegate dataCenter] GetDeviceList:0 
											  withSubType:1 
									  withRetrievingCount:count];
	NSLog(@"device count from server: %d", [deviceArray count]);
	//check ip address and return number of wrong data
	checkData *check = [[checkData alloc] init];
	int deviceIndex = 0;
	for(int i = 0 ; i<[deviceArray count]; i++) 	
	{
		DeviceInfo *device_info = [deviceArray objectAtIndex:i];
		
		//check ip address and return number of wrong data		
		NSArray *ipAddressArray = [[device_info internal] componentsSeparatedByString:@":"];//get ip address
		if ([check checkIPAddress:[ipAddressArray objectAtIndex:0]] == NO)
		{
			NSLog(@"IP Address Error");
			continue;
		}
		
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			if(device_info.relay==nil)
				continue;
		}		
		
		DeviceData *device = [DeviceData deviceDataCreationWthAssignedIndex:deviceIndex];	
		NSString *str = [NSString stringWithString:device_info.name]; 	
		[device setTitle:str];
		str = [NSString stringWithString:device_info.internal];
		[device setIP:str];
		[device setPortNum:80];
		//NSString *imageName = [NSString stringWithFormat:@"device01.png"];
		//[device setSnapshot:[UIImage imageNamed:imageName] autorelease];
		str = [NSString stringWithString:device_info.username];
		[device setAuthenticationName:str];
		str = [NSString stringWithString:device_info.password];
		[device setAuthenticationPassword:str];
#ifdef SERVER_MODE		
		// stream type check
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			ServerInfo *serverInfo = nil;
			TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
			if(appDelegate != nil)
			{
				serverInfo = (ServerInfo*)[[appDelegate dataCenter] getConfigurationData];
				[device setPlayType:serverInfo.streamType];
			}
			else
				[device setPlayType:IMAGE_CODEC_MJPEG];
			
			NSLog(@"viewport tag: %d streamType:%d", i+1, serverInfo.streamType);
		}
		//		
#endif		
		NSString *strIP;
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			str = [NSString stringWithString:device_info.beacon];		
			[device setAuthenticationToken:str];
			
			str = device_info.relay;
			NSLog(@"port: %d relayInfo: %@", i+1, str);
			NSRange range = [str rangeOfString:@":"];
			// if there is no ":", then the given relayip contains server ip only
			if(range.length == 0)
			{
				NSString *relayip = [NSString stringWithString:device_info.relay];
				[device setRelayIP:relayip];
				[device setRelayPort:80];
			}
			else
			{
				strIP = [str substringToIndex:range.location];
				NSString *relayip = [NSString stringWithString:strIP];
				[device setRelayIP:relayip];
				// if ":" is the last character, there is no port assigned in the given relayip string
				int strLen = [device_info.relay length];
				if(range.location == (strLen - 1))
					[device setRelayPort:80];
				else
				{
					NSString *rPort = [device_info.relay substringFromIndex:(range.location+1)];
					[device setRelayPort:(int)CFStringGetIntValue((CFStringRef)rPort)];
				}
			}
			
			str = device_info.external;
			range = [str rangeOfString:@":"]; 
			strIP = [str substringToIndex:range.location];
			NSString *strPORT = [str substringFromIndex:range.location+range.length];
			NSString *extIP = [NSString stringWithString:strIP];
			[device setDeviceExtIP:extIP];
			NSString *extPort = [NSString stringWithString:strPORT];
			[device setDeviceExtPort:extPort];
			
			//NSLog(@"port: %d ip: %@ port: %d userName: %@  pswd: %@ becon: %@", i+1, 
			//																	[device relayIP], 
			//																	[device relayPort],
			//																	[device authenticationName],
			//																	[device authenticationPassword],
			//																	[device authenticationToken]);
			
		}
		
		// put the device object into the shared device cache
		NSString *key = [device deviceKey];
		//NSLog(@"Device key: %@", key);
		[[DeviceCache sharedDeviceCache] setDevice:device forKey:key];		
		
	}
	
	[check release];
	
	return [[DeviceCache sharedDeviceCache] totalDeviceNumber];	

}

-(void)refreshDeviceList:(NSMutableArray*)newDeviceList
{
	// flush all the objects in DeviceData cache
	// before we remove all devices in the DeviceCache, we should remove the associated image in ImageCache first
	// since ImageCache is a dictionnary that needs a key to remove the associated contents	
	if([[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		for(int i=0; i<[[DeviceCache sharedDeviceCache] totalDeviceNumber]; i++)
		{
			NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:i];
			[[ImageCache sharedImageCache] deleteImageForKey:key];
		}
		
		[[DeviceCache sharedDeviceCache] removeAllDevices];
	}
	
	if([self retrieveRunMode] == RUN_P2P_MODE)
	{		
		for(int i = 0 ; i<[newDeviceList count]; i++) 	
		{		
			UserDefDevice *device_info = [newDeviceList objectAtIndex:i];
			DeviceData *device = [DeviceData deviceDataCreationWthAssignedIndex:i];	
			NSString *str = [NSString stringWithString:device_info.cameraName]; 	
			[device setTitle:str];			
			str = [NSString stringWithString:device_info.IPAddr];
			[device setIP:str];
			str = [NSString stringWithString:device_info.UserName];
			[device setAuthenticationName:str];
			str = [NSString stringWithString:device_info.Password];
			[device setAuthenticationPassword:str];	
			int port = (int)CFStringGetIntValue((CFStringRef)device_info.PortNum);
			[device setPortNum:port];

			// nash
			[device setPlayType:device_info.playType];
			//extension ability
			[device setExtensionFeatures:device_info.extensionAbilities];
			[device setModelNameID:device_info.modelNameID];			
			// put the device object into the shared device cache
			NSString *key = [device deviceKey];
			//NSLog(@"Device key: %@", key);
			[[DeviceCache sharedDeviceCache] setDevice:device forKey:key];													
		}
		
		return;
	}		
	
	//check ip address and return number of wrong data
	checkData *check = [[checkData alloc] init];
	int deviceIndex = 0;
	for(int i = 0 ; i<[newDeviceList count]; i++) 	
	{
		DeviceInfo *device_info = [newDeviceList objectAtIndex:i];
		
		//check ip address and return number of wrong data		
		NSArray *ipAddressArray = [[device_info internal] componentsSeparatedByString:@":"];//get ip address
		if ([check checkIPAddress:[ipAddressArray objectAtIndex:0]] == NO)
		{
			NSLog(@"IP Address Error");
			continue;
		}
		
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			if(device_info.relay==nil)
				continue;
		}		
		
		DeviceData *device = [DeviceData deviceDataCreationWthAssignedIndex:deviceIndex];	
		NSString *str = [NSString stringWithString:device_info.name]; 	
		[device setTitle:str];
		str = [NSString stringWithString:device_info.internal];
		[device setIP:str];
		[device setPortNum:80];
		//NSString *imageName = [NSString stringWithFormat:@"device01.png"];
		//[device setSnapshot:[UIImage imageNamed:imageName] autorelease];
		str = [NSString stringWithString:device_info.username];
		[device setAuthenticationName:str];
		str = [NSString stringWithString:device_info.password];
		[device setAuthenticationPassword:str];
#ifdef SERVER_MODE		
		// stream type check
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			ServerInfo *serverInfo = nil;
			TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
			if(appDelegate != nil)
			{
				serverInfo = (ServerInfo*)[[appDelegate dataCenter] getConfigurationData];
				[device setPlayType:serverInfo.streamType];
			}
			else
				[device setPlayType:IMAGE_CODEC_MJPEG];
			
			//NSLog(@"viewport tag: %d streamType:%d", i+1, serverInfo.streamType);
		}
		//
#endif		
		NSString *strIP;
		if([self retrieveRunMode] == RUN_SERVER_MODE)
		{
			str = [NSString stringWithString:device_info.beacon];		
			[device setAuthenticationToken:str];
			
			str = device_info.relay;
			NSRange range = [str rangeOfString:@":"];
			// if there is no ":", then the given relayip contains server ip only
			if(range.length == 0)
			{
				NSString *relayip = [NSString stringWithString:device_info.relay];
				[device setRelayIP:relayip];
				[device setRelayPort:80];
			}
			else
			{
				strIP = [str substringToIndex:range.location];
				NSString *relayip = [NSString stringWithString:strIP];
				[device setRelayIP:relayip];
				// if ":" is the last character, there is no port assigned in the given relayip string
				int strLen = [device_info.relay length];
				if(range.location == (strLen - 1))
					[device setRelayPort:80];
				else
				{
					NSString *rPort = [device_info.relay substringFromIndex:(range.location+1)];
					[device setRelayPort:(int)CFStringGetIntValue((CFStringRef)rPort)];
				}
			}
			
			str = device_info.external;
			range = [str rangeOfString:@":"]; 
			strIP = [str substringToIndex:range.location];
			NSString *strPORT = [str substringFromIndex:range.location+range.length];
			NSString *extIP = [NSString stringWithString:strIP];
			[device setDeviceExtIP:extIP];
			NSString *extPort = [NSString stringWithString:strPORT];
			[device setDeviceExtPort:extPort];
			
		}
		
		// put the device object into the shared device cache
		NSString *key = [device deviceKey];
		//NSLog(@"Device key: %@", key);
		[[DeviceCache sharedDeviceCache] setDevice:device forKey:key];				
	}	
	
	[check release];	
}


-(void)layoutWithoutEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column
{
	int deviceTTNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	//NSLog(@"LiveImageController viewportLayout...totaldevice...%d...\n", deviceTTNum);
	// prepare the page and associated viewport
	int pageWidth, pageHeight;
	// nash
	pageWidth = 0;
	pageHeight = 0;
	CGRect ttRect;
	CGRect wholeWindow;
	int tabBarHeight;
	
	UIView *myView = [[UIView alloc] initWithFrame:wholeWindowMain];
	[myView setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
	[self setView:myView];
	//nash ui
	//[self performSelectorOnMainThread:@selector(setView:)withObject:(id)myView waitUntilDone:YES];
	
	[myView release];	
	//NSLog(@"Nash wholeWindowMain frame... x = %f,y = %f,width = %f,height = %f",wholeWindowMain.origin.x,wholeWindowMain.origin.y,wholeWindowMain.size.width,wholeWindowMain.size.height);
	
	// create the viewport array according to the device number retrieved from data center
	int delta = 0;
	if(!viewportArray)
	{
		viewportArray = [[NSMutableArray alloc] init];
		if(!pageArray)
			pageArray = [[NSMutableArray alloc] init]; 
		
		wholeWindow = wholeWindowMain;
		//NSLog(@"parent...bound: X= %f Y= %f W= %f H= %f", wholeWindow.origin.x, wholeWindow.origin.y, wholeWindow.size.width, wholeWindow.size.height);
		// take navigation bar and tab bar into account
		UINavigationBar *navigationBar = [[self navigationController] navigationBar];
		int navBarHeight = [navigationBar bounds].size.height;
		//NSLog(@"navigationBar height: %d", navBarHeight);
		wholeWindow.size.height -= navBarHeight;
		UITabBar *tabBarCtrl = [[self tabBarController] tabBar];
		tabBarHeight = [tabBarCtrl bounds].size.height; 
		//NSLog(@"tabBar height: %d", tabBarHeight);
		wholeWindow.size.height -= tabBarHeight;
		wholeWindow.size.height -= FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
		wholeWindow.size.height -= PAGE_CONTROL_HEIGHT;
		
		// let's have w:h = 4:3
		int viewPortW = (wholeWindow.size.width-(MARGIN_BETWEEN_VIEWPORT*(2+(column-1))))/row;
		int unit =  viewPortW/4;
		int viewportH = unit*3;
		int scrollH = (viewportH*row)+(MARGIN_BETWEEN_VIEWPORT*(2+(row-1))); 
		
		delta = wholeWindow.size.height-scrollH;
		delta = delta/2;
		mainScrollViewOffsetY = delta;
		NSLog(@"main scrollView offset Y: %d", mainScrollViewOffsetY);
		// center the viewport
		wholeWindow.origin.y = 0;
		NSLog(@"scrollView Y offset: %d", delta);
		wholeWindow.size.height = scrollH;
		//NSLog(@"Nash scrollView frame... x = %f,y = %f,width = %f,height = %f",wholeWindow.origin.x,wholeWindow.origin.y,wholeWindow.size.width,wholeWindow.size.height);
		
		// create the scroll view
		if(!scrollView)
		{
			scrollView = [[UIScrollView alloc] initWithFrame:wholeWindow];
			if(!scrollView)
				return;
		}
		
		ttRect = [scrollView bounds];
		//NSLog(@"Nash scrollView bounds... x = %f,y = %f,width = %f,height = %f",ttRect.origin.x,ttRect.origin.y,ttRect.size.width,ttRect.size.height);
		
		pageWidth = ttRect.size.width; pageHeight = ttRect.size.height;
		NSLog(@"pageWidth: %d...pageHeight: %d...", pageWidth, pageHeight);
		
		// determine the total page number
		int r = deviceTTNum % ((column)*(row));
		if(deviceTTNum < (column)*(row))
			[self setPageTTNum:1];
		else 
		{
			if(r == 0)			
				[self setPageTTNum:deviceTTNum/((column)*(row))];
			else
				[self setPageTTNum:(deviceTTNum/((column)*(row)) + 1)];
		}
		NSLog(@"total page number: %d", [self pageTTNum]);
		// prepare the pages for the scroll view
		int index = 0;	// act as viewport tag		
		for(int p=0; p<[self pageTTNum]; p++)
		{
			UIView *page = [[UIView alloc] initWithFrame:wholeWindow];
			//[page setBackgroundColor:[UIColor lightGrayColor]];
			[page setBackgroundColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:0.8f]];
			// reset the z-position for viewports on next page
			int zPos = Z_POSITION_MIN_ON_PAGE;				
			CGRect rect; int deltaX, deltaY; int margin = MARGIN_BETWEEN_VIEWPORT;
			deltaX = (pageWidth - margin*(column+1))/column;
			deltaY = (pageHeight - margin*(row+1))/row;			
			NSString *label;
			
			rect.origin.x = margin;
			rect.origin.y = margin;
			rect.size.width = deltaX; rect.size.height = deltaY;
			for(int i=0; i<row; i++)
			{
				//NSLog(@"viewportLayoutWithRow...outerLoop... %d", i);
				BOOL defaultViewportTitleON;
				for(int j=0; j<column; j++)
				{
					//NSLog(@"viewportLayoutWithRow...innerLoop... %d", j);
					// update the tag
					index++;
					// retrieve the device title
					NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:index-1];
					if(key != nil)
					{
						//NSLog(@"viewportLayoutWithRow...got the key of device# :%d", index);
						label = [[[DeviceCache sharedDeviceCache] deviceForKey:key] title]; 
						defaultViewportTitleON = NO;
					}
					else
					{
						label = [NSString stringWithFormat:@"Not Configured"];
						defaultViewportTitleON = YES;
					}
					
					Viewport *port = [Viewport viewportCreationWithLocation:rect inLabel:label assignedIndex:index associatedServer:[self retrieveRunMode]];
					[[port streaming] setDelegate:port];
					[port doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
					if([self labelON] == YES)						
						[[port titleView] setHidden:NO];
					else
					{
						if(defaultViewportTitleON)
						{
							[[port titleView] setHidden:NO];
							[port setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
							[port showStatus];	// clear possible remained message
						}
					}
					// assign a z-position
					port.layer.zPosition = zPos+j*Z_POSITION_DELTA_ON_PAGE;					
					// because we send 'autorelease' message to port while creating it, thus, we don't need to
					// release it here after adding it to the scroll view.
					[page addSubview:port];
					
					// all the viewports with index equal or larger than deviceTTNum in the viewportArray are
					// empty viewport(i.e., there is no corresponding device in the DeviceCache)
					// we must keep the viewport reference count to 2 here so that we will have chance to
					// re-arrange the viewport layout even though the pages have been removed.
					// thus, we don't release the port after adding the port into viewportArray.
					[viewportArray addObject:port];
					
					rect.origin.x += (deltaX+margin);
				}
				// update the rect
				rect.origin.y += (deltaY+margin);
				rect.origin.x = margin;
			}
			NSLog(@"viewportLayoutWithRow...viewport adding done");
			// add the page into scroll view
			[scrollView addSubview:page];			
			NSLog(@"viewportLayoutWithRow...add page to scroll view done");
			[pageArray addObject:page];
			// nash
			[page release];
			// we don,t release the page(i.e., keep the reference count to 2) so that we will have chance
			// to do pages/viewport rearrangement after adding/deleting devices.			
			// update the page origin
			wholeWindow.origin.x += wholeWindow.size.width;
		}
	}
	
	[scrollView setContentSize:CGSizeMake([self pageTTNum]*pageWidth, pageHeight)];
	[scrollView setPagingEnabled:YES];
	[scrollView setDelegate:self];
	//nash
	[scrollView setShowsHorizontalScrollIndicator:NO];
	CGRect fR = [scrollView frame];
	//NSLog(@"layoutWithoutEmbeddedHomeControlTable...scrollViewBefore...frame: X= %f Y= %f W= %f H= %f", fR.origin.x, fR.origin.y, fR.size.width, fR.size.height);
	fR.origin.y = delta;
	//NSLog(@"layoutWithoutEmbeddedHomeControlTable...scrollViewAfter...frame: X= %f Y= %f W= %f H= %f shiftY: %d", fR.origin.x, fR.origin.y, fR.size.width, fR.size.height, delta);
	[scrollView setFrame:fR];
	[[self view] addSubview:scrollView];
	//nash ui
	//[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)scrollView waitUntilDone:YES];
	
	// reset the dirty flag in device cache since we have finished device list updating
	[[DeviceCache sharedDeviceCache] setDirtyFlag:NO];
	
	// toolbar treatment
	CGRect tbRect = CGRectMake(0,
							   fR.origin.y+fR.size.height+delta+PAGE_CONTROL_HEIGHT, 
							   pageWidth, 
							   FOCAL_VIEW_CONTROL_PANEL_HEIGHT);		
	
	//NSLog(@"Nash toolbar... x = %f,y = %f,width = %f,height = %f",tbRect.origin.x,tbRect.origin.y,tbRect.size.width,tbRect.size.height);
	
	toolBar = [[UIToolbar alloc] init];
	[toolBar setFrame:tbRect];	
	
	UIBarButtonItem *terminate = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(doTermination)];
	[terminate setStyle:UIBarButtonItemStyleBordered];
	// position the zoomrate button for right edge alignment
	UIBarButtonItem *spaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	labelDisplay = [[UIBarButtonItem alloc] initWithTitle:@"Label ON" style:UIBarButtonItemStyleBordered target:self action:@selector(labelOnOff)];
	NSArray *items = [NSArray arrayWithObjects:terminate, spaceBtn, labelDisplay, nil];
	[terminate release];
	[spaceBtn  release];
	[labelDisplay release];
	[toolBar setItems:items animated:YES];	
	[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)toolBar waitUntilDone:YES];
	
	// calculate the page control location
	tbRect = CGRectMake(0,
						fR.origin.y+fR.size.height+MARGIN_BETWEEN_VIEWPORT, 
						pageWidth, 
						PAGE_CONTROL_HEIGHT);				
	
	//NSLog(@"Nash pageControl... x = %f,y = %f,width = %f,height = %f",tbRect.origin.x,tbRect.origin.y,tbRect.size.width,tbRect.size.height);	
	pageControl = [[UIPageControl alloc] init];	
	[pageControl setFrame:tbRect];
	[pageControl setUserInteractionEnabled:NO];
	if([self pageTTNum] == 1)
	{
		NSLog(@"hide page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:YES];		
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}
	else
	{
		NSLog(@"display page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:NO];
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}	
}

-(void)layoutWithEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column
{
	int deviceTTNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	NSLog(@"layoutWithEmbeddedHomeControlTable...");
	// prepare the page and associated viewport
	int pageWidth, pageHeight;
	// nash
	pageWidth = 0;
	pageHeight = 0;
	CGRect ttRect;
	CGRect wholeWindow;
	int tabBarHeight;
	
	UIView *myView = [[UIView alloc] initWithFrame:wholeWindowMain];
	[myView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
	//[self setView:myView];	
	//[myView release];
	
	//NSLog(@"Nash wholeWindowMain frame... x = %f,y = %f,width = %f,height = %f",wholeWindowMain.origin.x,wholeWindowMain.origin.y,wholeWindowMain.size.width,wholeWindowMain.size.height);
	
	// create the viewport array according to the device number retrieved from data center
	int delta = 0;
	if(!viewportArray)
	{
		viewportArray = [[NSMutableArray alloc] init];
		if(!pageArray)
			pageArray = [[NSMutableArray alloc] init]; 
		
		wholeWindow = wholeWindowMain;
		//NSLog(@"parent...bound: X= %f Y= %f W= %f H= %f", wholeWindow.origin.x, wholeWindow.origin.y, wholeWindow.size.width, wholeWindow.size.height);
		// take navigation bar and tab bar into account
		UINavigationBar *navigationBar = [[self navigationController] navigationBar];
		int navBarHeight = [navigationBar bounds].size.height;
		//NSLog(@"navigationBar height: %d", navBarHeight);
		wholeWindow.size.height -= navBarHeight;
		UITabBar *tabBarCtrl = [[self tabBarController] tabBar];
		tabBarHeight = [tabBarCtrl bounds].size.height; 
		//NSLog(@"tabBar height: %d", tabBarHeight);
		wholeWindow.size.height -= tabBarHeight;
		wholeWindow.size.height -= FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
		wholeWindow.size.height -= PAGE_CONTROL_HEIGHT;
		
		// let's have w:h = 4:3
		int viewPortW = (wholeWindow.size.width-(MARGIN_BETWEEN_VIEWPORT*(2+(column-1))))/row;
		int unit =  viewPortW/4;
		int viewportH = unit*3;
		int scrollH = (viewportH*row)+(MARGIN_BETWEEN_VIEWPORT*(2+(row-1))); 
		
		delta = wholeWindow.size.height-scrollH;
		delta = delta/2;
		// center the viewport
		wholeWindow.origin.y = 0;
		mainScrollViewOffsetY = wholeWindow.origin.y;
		NSLog(@"main scrollView offset Y: %d", mainScrollViewOffsetY);
		NSLog(@"scrollView Y offset: %d", delta);
		wholeWindow.size.height = scrollH;
		//NSLog(@"Nash scrollView frame... x = %f,y = %f,width = %f,height = %f",wholeWindow.origin.x,wholeWindow.origin.y,wholeWindow.size.width,wholeWindow.size.height);
		
		// create the scroll view
		if(!scrollView)
		{
			scrollView = [[UIScrollView alloc] initWithFrame:wholeWindow];
			if(!scrollView)
				return;
		}
		
		ttRect = [scrollView bounds];
		//NSLog(@"Nash scrollView bounds... x = %f,y = %f,width = %f,height = %f",ttRect.origin.x,ttRect.origin.y,ttRect.size.width,ttRect.size.height);
		
		pageWidth = ttRect.size.width; pageHeight = ttRect.size.height;
		NSLog(@"pageWidth: %d...pageHeight: %d...", pageWidth, pageHeight);
		
		// determine the total page number
		int r = deviceTTNum % ((column)*(row));
		if(deviceTTNum < (column)*(row))
			[self setPageTTNum:1];
		else 
		{
			if(r == 0)			
				[self setPageTTNum:deviceTTNum/((column)*(row))];
			else
				[self setPageTTNum:(deviceTTNum/((column)*(row)) + 1)];
		}
		NSLog(@"total page number: %d", [self pageTTNum]);
		// prepare the pages for the scroll view
		int index = 0;	// act as viewport tag		
		for(int p=0; p<[self pageTTNum]; p++)
		{
			UIView *page = [[UIView alloc] initWithFrame:wholeWindow];
			//[page setBackgroundColor:[UIColor lightGrayColor]];
			[page setBackgroundColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:0.8f]];
			// reset the z-position for viewports on next page
			int zPos = Z_POSITION_MIN_ON_PAGE;			
			CGRect rect; int deltaX, deltaY; int margin = MARGIN_BETWEEN_VIEWPORT;
			deltaX = (pageWidth - margin*(column+1))/column;
			deltaY = (pageHeight - margin*(row+1))/row;			
			NSString *label;
			
			rect.origin.x = margin;
			rect.origin.y = margin;
			rect.size.width = deltaX; rect.size.height = deltaY;
			for(int i=0; i<row; i++)
			{
				//NSLog(@"viewportLayoutWithRow...outerLoop... %d", i);
				BOOL defaultViewportTitleON;
				for(int j=0; j<column; j++)
				{
					//NSLog(@"viewportLayoutWithRow...innerLoop... %d", j);
					// update the tag
					index++;
					// retrieve the device title
					NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:index-1];
					if(key != nil)
					{
						//NSLog(@"viewportLayoutWithRow...got the key of device# :%d", index);
						label = [[[DeviceCache sharedDeviceCache] deviceForKey:key] title]; 
						defaultViewportTitleON = NO;
					}
					else
					{
						label = [NSString stringWithFormat:@"Not Configured"];
						defaultViewportTitleON = YES;
					}
					
					Viewport *port = [Viewport viewportCreationWithLocation:rect inLabel:label assignedIndex:index associatedServer:[self retrieveRunMode]];
					[[port streaming] setDelegate:port];
					[port doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
					if([self labelON] == YES)						
						[[port titleView] setHidden:NO];
					else
					{
						if(defaultViewportTitleON)
						{
							[[port titleView] setHidden:NO];
							[port setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
							[port showStatus];	// clear possible remained message
						}
					}
					// assign a z-position
					port.layer.zPosition = zPos+j*Z_POSITION_DELTA_ON_PAGE;
					// because we send 'autorelease' message to port while creating it, thus, we don't need to
					// release it here after adding it to the scroll view.
					[page addSubview:port];
					
					// all the viewports with index equal or larger than deviceTTNum in the viewportArray are
					// empty viewport(i.e., there is no corresponding device in the DeviceCache)
					// we must keep the viewport reference count to 2 here so that we will have chance to
					// re-arrange the viewport layout even though the pages have been removed.
					// thus, we don't release the port after adding the port into viewportArray.
					[viewportArray addObject:port];
					
					rect.origin.x += (deltaX+margin);
				}
				// update the rect
				rect.origin.y += (deltaY+margin);
				rect.origin.x = margin;
			}
			NSLog(@"viewportLayoutWithRow...viewport adding done");
			// add the page into scroll view
			[scrollView addSubview:page];			
			NSLog(@"viewportLayoutWithRow...add page to scroll view done");
			[pageArray addObject:page];
			[page release];
			// we don,t release the page(i.e., keep the reference count to 2) so that we will have chance
			// to do pages/viewport rearrangement after adding/deleting devices.			
			// update the page origin
			wholeWindow.origin.x += wholeWindow.size.width;
		}
	}
	
	[scrollView setContentSize:CGSizeMake([self pageTTNum]*pageWidth, pageHeight)];
	[scrollView setPagingEnabled:YES];
	[scrollView setDelegate:self];

	//nash
	[scrollView setShowsHorizontalScrollIndicator:NO];
	//CGRect fR = [scrollView frame];
	//NSLog(@"layoutWithEmbeddedHomeControlTable...scrollViewAfter...frame: X= %f Y= %f W= %f H= %f shiftY: %d", fR.origin.x, fR.origin.y, fR.size.width, fR.size.height, delta);	
	//fR.origin.y = delta;
	//[scrollView setFrame:fR];
	[myView addSubview:scrollView];
	[self setView:myView];	
	[myView release];		
	
	// reset the dirty flag in device cache since we have finished device list updating
	[[DeviceCache sharedDeviceCache] setDirtyFlag:NO];

	// page control location treatment
	CGRect tbRect = CGRectMake(0,
							   [scrollView bounds].size.height+MARGIN_PAGE_CONTROL, 
							   pageWidth, 
							   PAGE_CONTROL_HEIGHT);				
	
	//NSLog(@"Nash pageControl... x = %f,y = %f,width = %f,height = %f",tbRect.origin.x,tbRect.origin.y,tbRect.size.width,tbRect.size.height);	
	pageControl = [[UIPageControl alloc] init];	
	[pageControl setFrame:tbRect];
	[pageControl setUserInteractionEnabled:NO];
	if([self pageTTNum] == 1)
	{
		NSLog(@"hide page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:YES];		
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}
	else
	{
		NSLog(@"display page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:NO];
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}
	
	// insert the embedded 'Home Controller' table
	int htOffsetY, htHeight;
	if([self pageTTNum] > 1)
	{
		htOffsetY = MARGIN_PAGE_CONTROL+PAGE_CONTROL_HEIGHT+MARGIN_PAGE_CONTROL;
		htHeight = FOCAL_VIEW_CONTROL_PANEL_HEIGHT+PAGE_CONTROL_HEIGHT;
	}
	else 
	{
		htOffsetY = 0;
		htHeight = 0;
	}
	
	tbRect = CGRectMake(0,
						[scrollView bounds].size.height+htOffsetY, 
						pageWidth, 
						wholeWindowMain.size.height-[scrollView bounds].size.height-FOCAL_VIEW_CONTROL_PANEL_HEIGHT-htHeight);
	//NSLog(@"remained height: %d", wholeWindowMain.size.height-[scrollView bounds].size.height-htHeight);
#ifdef SERVER_MODE	
	NSLog(@"server mode embedded HC table...");
	//hcTableContainer = [[homeCtrl alloc] initWithStyle:UITableViewStyleGrouped];	
	//hcTable = [hcTableContainer tableView];
	//tbRect.size.height = ttRect.size.height;
	//[hcTable setFrame:tbRect];
	//[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)hcTable waitUntilDone:YES];
	if(hcTableContainer == nil)
		hcTableContainer = [[homeCtrl alloc] initWithNibName:@"homeCtrl" bundle:nil];

	//hcTable = [hcTableContainer tableView];
	//tbRect.size.height = ttRect.size.height;
	//[hcTable setFrame:tbRect];
	//[hcTableContainer setView:hcTable];
	tbRect.size.height = 88;	// given two visible table cell lines
	[[hcTableContainer tableView] setFrame:tbRect];
	[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)[hcTableContainer view] waitUntilDone:YES];
	UINib *nib = [UINib nibWithNibName:@"homeCtrl" bundle:nil];
	[nib instantiateWithOwner:hcTableContainer options:nil];
	[NSThread detachNewThreadSelector:@selector(embeddedHCTableLoadingData) toTarget:self withObject:nil];
	[hcTableContainer setResidentMode:ROLE_AS_EMBEDDED owner:(id)self residentArea:(CGRect)tbRect];
#else
	NSLog(@"P2P mode embedded HC table...");
	if(hcTableContainer == nil)
		hcTableContainer = [[UIView alloc] initWithFrame:tbRect];
	if(hcTable == nil)
		hcTable = [[UITableView alloc] initWithFrame:ttRect style:UITableViewStylePlain];
	[hcTableContainer addSubview:hcTable];
	[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)self waitUntilDone:YES];	
#endif
	/*
	NSLog(@"1..tbRect...frame: X= %f Y= %f W= %f H= %f", tbRect.origin.x, 
		  tbRect.origin.y, 
		  tbRect.size.width, 
		  tbRect.size.height);	
	NSLog(@"1..hcTableContainer...bound: X= %f Y= %f W= %f H= %f", [[hcTableContainer view] bounds].origin.x, 
		  [[hcTableContainer view] bounds].origin.y, 
		  [[hcTableContainer view] bounds].size.width, 
		  [[hcTableContainer view] bounds].size.height);
	NSLog(@"1..hcTableContainer...frame: X= %f Y= %f W= %f H= %f", [[hcTableContainer view] frame].origin.x, 
		  [[hcTableContainer view] frame].origin.y, 
		  [[hcTableContainer view] frame].size.width, 
		  [[hcTableContainer view] frame].size.height);
	*/
	NSLog(@"1..hcTable...frame: X= %f Y= %f W= %f H= %f", [hcTable frame].origin.x, 
		  [hcTable frame].origin.y, 
		  [hcTable frame].size.width, 
		  [hcTable frame].size.height);	
	NSLog(@"1..hcTable...bounds: X= %f Y= %f W= %f H= %f", [hcTable bounds].origin.x, 
		  [hcTable bounds].origin.y, 
		  [hcTable bounds].size.width, 
		  [hcTable bounds].size.height);		
	
	
	// toolbar treatment
	tbRect = CGRectMake(0,
						delta+[scrollView bounds].size.height+delta+PAGE_CONTROL_HEIGHT+1, 
						pageWidth, 
						FOCAL_VIEW_CONTROL_PANEL_HEIGHT);		
	
	//NSLog(@"Nash toolbar... x = %f,y = %f,width = %f,height = %f",tbRect.origin.x,tbRect.origin.y,tbRect.size.width,tbRect.size.height);
	
	toolBar = [[UIToolbar alloc] init];
	[toolBar setFrame:tbRect];	
	
	UIBarButtonItem *terminate = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(doTermination)];
	[terminate setStyle:UIBarButtonItemStyleBordered];
	
	// position the zoomrate button for right edge alignment
	UIBarButtonItem *spaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	labelDisplay = [[UIBarButtonItem alloc] initWithTitle:@"Label ON" style:UIBarButtonItemStyleBordered target:self action:@selector(labelOnOff)];
	NSArray *items = [NSArray arrayWithObjects:terminate, spaceBtn, labelDisplay, nil];
	[terminate release];
	[spaceBtn  release];
	[labelDisplay release];
	[toolBar setItems:items animated:YES];	
	[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)toolBar waitUntilDone:YES];
	
}

// first time initialization will call this function in viewDidLoad
-(void)viewportLayoutWithRow:(NSInteger)row column:(NSInteger)column
{
	if(row == 0)
		row = 2;
	if(column == 0)
		column = 2;
	
	previousViewportPerPage.row = row;
	previousViewportPerPage.column = column;
	viewportPerPage.row = row;
	viewportPerPage.column = column;	
	//NSLog(@"LiveImageController viewportLayout...row: %d column: %d...\n", row, column);	

	if([self retrieveRunMode] == RUN_SERVER_MODE)
		[self layoutWithEmbeddedHomeControlTable:row column:column];
	else
		//[self layoutWithEmbeddedHomeControlTable:row column:column];
		[self layoutWithoutEmbeddedHomeControlTable:row column:column];
}

-(void)checkViewportRearrangement:(NSInteger)row column:(NSInteger)column
{
	NSLog(@"ListImageController...checkViewportRearrangement...");
	NSLog(@"checkViewportRearrangement...row: %d...column: %d...", row, column);
	// check the total required viewports
	int deviceTTNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	
	// check currently existing page number and associated viewports
	int curPages = [[self pageArray] count];
	
	// determine the total required page number
	int r = deviceTTNum % ((column)*(row));
	if(deviceTTNum < (column)*(row))
		[self setPageTTNum:1];
	else 
	{
		if(r == 0)			
			[self setPageTTNum:deviceTTNum/((column)*(row))];
		else
			[self setPageTTNum:(deviceTTNum/((column)*(row)) + 1)];
	}
	NSLog(@"required total page number: %d", [self pageTTNum]);
	
	// if total required page and the number of vieport per row and viewport per column on
	// each page are unchanged, we only need to modify the viewport content(attributes)
	if((curPages == [self pageTTNum]) && (row == previousViewportPerPage.row)
	   && (column == previousViewportPerPage.column))
		[self doViewportContentChange];
	
	// else, there might be new page creation, old page deletion, number of viewport per row
	// number of viewport per column on each page changed.
	// For simplicity, lets delete all the old paged and associated viewports on each page and
	// create the new viewports and pages according to the new request
	else
		[self doPageViewportRearrangement:row column:column];		
}

-(void)doViewportContentChange
{
	NSLog(@"ListImageController...doViewportContentChange...");
	int ttViewportNum = [viewportArray count];
	for(int p=0; p<ttViewportNum; p++)
	{
		Viewport *pView = [viewportArray objectAtIndex:p];
		DeviceData *dev;
		//NSLog(@"doViewportContentChange...viewport %d...", p);
		if(p < [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:p];
			[pView setTitle:[dev title]];
			[[pView titleView] setText:[pView title]];
			if([self labelON] == YES)
				[[pView titleView] setHidden:NO];
			else
				[[pView titleView] setHidden:YES];
			//nash
			imageAttributesDef attr;
			attr = [[pView streaming] imageAttributes];
			if([dev playType] == 1)
				attr.codec = IMAGE_CODEC_MPEG4;
			else
				attr.codec = IMAGE_CODEC_MJPEG; // default
			[[pView streaming] setImageAttributes:attr];
		
			[dev setDirtyFlag:NO];
			//NSLog(@"doViewportContentChange...viewport %d...attributes changed", p);
		}
		else 
		{
			[pView setTitle:@"Not Configured"];
			[[pView titleView] setText:[pView title]];
			[[pView titleView] setHidden:NO];
			[pView setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
			[pView showStatus];	// clear possible remained message
			// set the background color to white
			[[pView layer] performSelectorOnMainThread:@selector(setContents:) withObject:nil waitUntilDone:NO];						
			//NSLog(@"doViewportContentChange...viewport %d...not configured", p);
		}	
	}
	
	
	// reset the dirty flag in device cache
	[[DeviceCache sharedDeviceCache] setDirtyFlag:NO];			
}

-(void)doPageViewportRearrangement:(NSInteger)row column:(NSInteger)column
{
	NSLog(@"ListImageController...doPageViewportRearrangement...");
	// let's remove all the old viewports and old pages first
	NSLog(@"old viewportArray count: %d", [viewportArray count]);
	for(int i=1; [viewportArray count]>0; i++)
	{
		Viewport *vw = [viewportArray lastObject];
		[vw clean];
		[viewportArray removeLastObject];
		NSLog(@"remove old viewport object: %d", i);
	}
	NSLog(@"doPageViewportRearrangement...remove old viewport objects done");

	NSLog(@"old pageArray count: %d", [pageArray count]);	
	for(int i=1; [pageArray count]>0; i++)
	{
		[pageArray removeLastObject];
		NSLog(@"remove old page object: %d", i);
	}	

	NSLog(@"doPageViewportRearrangement...remove old pages done");
		
	// now, let's rearrange the viewport layout
	if(row == 0)
		row = 2;
	if(column == 0)
		column = 2;
	
	viewportPerPage.row = row;
	viewportPerPage.column = column;			
	//NSLog(@"LiveImageController viewportLayout...row: %d column: %d...\n", row, column);
	
	if([self retrieveRunMode] == RUN_SERVER_MODE)
		[self doPageViewportRearrangementWithEmbeddedHomeControlTable:row column:column];
	else
		//[self doPageViewportRearrangementWithEmbeddedHomeControlTable:row column:column];
		[self doPageViewportRearrangementWithoutEmbeddedHomeControlTable:row column:column];			
}

-(void)doPageViewportRearrangementWithoutEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column
{
	int deviceTTNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	//NSLog(@"LiveImageController viewportLayout...totaldevice...%d...\n", deviceTTNum);
	// prepare the page and associated viewport
	int pageWidth, pageHeight;

	CGRect wholeWindow = wholeWindowMain;
	UINavigationBar *navigationBar = [[self navigationController] navigationBar];
	int navBarHeight = [navigationBar bounds].size.height;
	wholeWindow.size.height -= navBarHeight;
	UITabBar *tabBarCtrl = [[self tabBarController] tabBar];
	int tabBarHeight = [tabBarCtrl bounds].size.height; 
	wholeWindow.size.height -= tabBarHeight;
	wholeWindow.size.height -= FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
	wholeWindow.size.height -= PAGE_CONTROL_HEIGHT;	
	//wholeWindow.size.height -= ((FOCAL_VIEW_CONTROL_PANEL_HEIGHT/2)-4);
	
	// let's have w:h = 4:3
	int viewPortW = (wholeWindow.size.width-(MARGIN_BETWEEN_VIEWPORT*(2+(column-1))))/row;
	int unit =  viewPortW/4;
	int viewportH = unit*3;
	int scrollH = (viewportH*row)+(MARGIN_BETWEEN_VIEWPORT*(2+(row-1))); 
	
	int delta = wholeWindow.size.height-scrollH;
	delta /= 2;
	// center the viewport
	wholeWindow.origin.y = 0;//delta;
	wholeWindow.size.height = scrollH;	
	[scrollView setFrame:wholeWindow];
	
	CGRect ttRect = [scrollView bounds];
	NSLog(@"doPageViewportRearrangement...1");
	pageWidth = ttRect.size.width; pageHeight = ttRect.size.height;
	//NSLog(@"scrollView...bound: X= %f Y= %f W= %f H= %f", ttRect.origin.x, ttRect.origin.y, ttRect.size.width, ttRect.size.height);
	
	// determine the total page number
	int r = deviceTTNum % ((column)*(row));
	if(deviceTTNum < (column)*(row))
		[self setPageTTNum:1];
	else 
	{
		if(r == 0)			
			[self setPageTTNum:deviceTTNum/((column)*(row))];
		else
			[self setPageTTNum:(deviceTTNum/((column)*(row)) + 1)];
	}
	NSLog(@"doPageViewportRearrangement...total page number: %d", [self pageTTNum]);
	// prepare the pages for the scroll view
	int index = 0;	// act as viewport tag		
	for(int p=0; p<[self pageTTNum]; p++)
	{
		UIView *page = [[UIView alloc] initWithFrame:wholeWindow];
		//[page setBackgroundColor:[UIColor lightGrayColor]];
		[page setBackgroundColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha: 0.8f]];
		// reset the z-position for viewports on next page
		int zPos = Z_POSITION_MIN_ON_PAGE;		
		CGRect rect; int deltaX, deltaY; int margin = MARGIN_BETWEEN_VIEWPORT;
		deltaX = (pageWidth - margin*(column+1))/column;
		deltaY = (pageHeight - margin*(row+1))/row;
		NSString *label;
		
		rect.origin.x = margin; rect.origin.y = margin;
		rect.size.width = deltaX; rect.size.height = deltaY;
		for(int i=0; i<row; i++)
		{
			//NSLog(@"doPageViewportRearrangement...outerLoop... %d", i);
			BOOL defaultViewportTitleON;
			for(int j=0; j<column; j++)
			{
				//NSLog(@"doPageViewportRearrangement...innerLoop... %d", j);
				DeviceData *dev;
				if(index < deviceTTNum)
				{
					dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:index];
					label = [dev title];
					defaultViewportTitleON = NO;
					[dev setDirtyFlag:NO];
				}
				else
				{
					label = [NSString stringWithFormat:@"Not Configured"];
					defaultViewportTitleON = YES;
				}
				
				// update the tag
				index++;								
				Viewport *port = [Viewport viewportCreationWithLocation:rect inLabel:label assignedIndex:index associatedServer:[self retrieveRunMode]];
				[[port streaming] setDelegate:port];
				[port doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
				if([self labelON] == YES)
					[[port titleView] setHidden:NO];
				else
				{
					if(defaultViewportTitleON == YES)
					{
						[[port titleView] setHidden:NO];
						[port setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
						[port showStatus];	// clear possible remained message
					}
				}
				// assign a z-position
				port.layer.zPosition = zPos+j*Z_POSITION_DELTA_ON_PAGE;				
				// because we send 'autorelease' message to port while creating it, thus, we don't need to
				// release it here after adding it to the scroll view.
				[page addSubview:port];
				
				// all the viewports with index equal or larger than deviceTTNum in the viewportArray are
				// empty viewport(i.e., there is no corresponding device in the DeviceCache)
				// we must keep the viewport reference count to 2 here so that we will have chance to
				// re-arrange the viewport layout even though the pages have been removed.
				// thus, we don't release the port after adding the port into viewportArray.
				[viewportArray addObject:port];
				//[port release];
				
				rect.origin.x += (deltaX+margin);
			}
			// update the rect
			rect.origin.y += (deltaY+margin);
			rect.origin.x = margin;
		}
		//NSLog(@"doPageViewportRearrangement...one page viewport adding done");
		// add the page into scroll view
		[scrollView addSubview:page];
		//NSLog(@"doPageViewportRearrangement...add page to scroll view done");
		//[page release];
		[pageArray addObject:page];
		[page release];
		// don't release the page with the same reason as did for port mentioned above 
		//[page release];
		// update the page origin
		wholeWindow.origin.x += wholeWindow.size.width;
	}
	
	NSLog(@"viewportArray count: %d", [viewportArray count]);
	NSLog(@"pagetArray count: %d", [pageArray count]);
	NSLog(@"doPageViewportRearrangement...pages/viewports adding done");
	[scrollView setContentSize:CGSizeMake([self pageTTNum]*pageWidth, pageHeight)];
	[scrollView setPagingEnabled:YES];
	[scrollView setDelegate:self];
	NSLog(@"doPageViewportRearrangement...change scroll view content size done");
	CGRect fR = [scrollView frame];
	fR.origin.y = delta;
	[scrollView setFrame:fR];
	mainScrollViewOffsetY = delta;
	
	// remember to reset the toolbat width
	//CGRect tbRect;	
	//tbRect.origin.x = 0;
	//tbRect.origin.y = [scrollView bounds].size.height+wholeWindow.origin.y*2;
	//tbRect.size.width = [self pageTTNum];		
	//tbRect.size.height = FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
	//[toolBar setFrame:tbRect];
	
	CGRect tbRect = CGRectMake(0,
							   fR.origin.y+fR.size.height+MARGIN_BETWEEN_VIEWPORT, 
							   pageWidth, 
							   PAGE_CONTROL_HEIGHT);				
	
	[pageControl setFrame:tbRect];
	[pageControl setUserInteractionEnabled:NO];
	
	if([self pageTTNum] == 1)
	{
		NSLog(@"hide page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:YES];		
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}
	else
	{
		NSLog(@"display page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:NO];
	}	
	
	// reset row/column viewport changed flag
	[self setRowColumnViewportArrangementChanged:NO];
	
	// reset the dirty flag in device cache
	[[DeviceCache sharedDeviceCache] setDirtyFlag:NO];	
}

-(void)doPageViewportRearrangementWithEmbeddedHomeControlTable:(NSInteger)row column:(NSInteger)column
{
	int deviceTTNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	//NSLog(@"LiveImageController viewportLayout...totaldevice...%d...\n", deviceTTNum);
	// prepare the page and associated viewport
	int pageWidth, pageHeight;
	
	//NSLog(@"doPageViewportRearrangement...1...");
	//UIView *myView = [[UIView alloc] initWithFrame:wholeWindowMain];
	//[myView setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
	//[self setView:myView];	
	//[myView release];		
	//NSLog(@"doPageViewportRearrangement...2...");
	
	CGRect wholeWindow = wholeWindowMain;
	UINavigationBar *navigationBar = [[self navigationController] navigationBar];
	int navBarHeight = [navigationBar bounds].size.height;
	wholeWindow.size.height -= navBarHeight;
	UITabBar *tabBarCtrl = [[self tabBarController] tabBar];
	int tabBarHeight = [tabBarCtrl bounds].size.height; 
	wholeWindow.size.height -= tabBarHeight;
	wholeWindow.size.height -= FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
	wholeWindow.size.height -= PAGE_CONTROL_HEIGHT;	
	
	// let's have w:h = 4:3
	int viewPortW = (wholeWindow.size.width-(MARGIN_BETWEEN_VIEWPORT*(2+(column-1))))/row;
	int unit =  viewPortW/4;
	int viewportH = unit*3;
	int scrollH = (viewportH*row)+(MARGIN_BETWEEN_VIEWPORT*(2+(row-1))); 
	
	int delta = wholeWindow.size.height-scrollH;
	delta /= 2;
	// center the viewport
	wholeWindow.origin.y = 0;//delta;	
	wholeWindow.size.height = scrollH;	
	[scrollView setFrame:wholeWindow];
	
	CGRect ttRect = [scrollView bounds];
	NSLog(@"doPageViewportRearrangement...1");
	pageWidth = ttRect.size.width; pageHeight = ttRect.size.height;
	//NSLog(@"scrollView...bound: X= %f Y= %f W= %f H= %f", ttRect.origin.x, ttRect.origin.y, ttRect.size.width, ttRect.size.height);
	
	// determine the total page number
	int r = deviceTTNum % ((column)*(row));
	if(deviceTTNum < (column)*(row))
		[self setPageTTNum:1];
	else 
	{
		if(r == 0)			
			[self setPageTTNum:deviceTTNum/((column)*(row))];
		else
			[self setPageTTNum:(deviceTTNum/((column)*(row)) + 1)];
	}
	NSLog(@"doPageViewportRearrangement...total page number: %d", [self pageTTNum]);
	// prepare the pages for the scroll view
	int index = 0;	// act as viewport tag		
	for(int p=0; p<[self pageTTNum]; p++)
	{
		UIView *page = [[UIView alloc] initWithFrame:wholeWindow];
		//[page setBackgroundColor:[UIColor lightGrayColor]];
		[page setBackgroundColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha: 0.8f]];
		// reset the z-position for viewports on next page
		int zPos = Z_POSITION_MIN_ON_PAGE;		
		CGRect rect; int deltaX, deltaY; int margin = MARGIN_BETWEEN_VIEWPORT;
		deltaX = (pageWidth - margin*(column+1))/column;
		deltaY = (pageHeight - margin*(row+1))/row;
		NSString *label;
		
		rect.origin.x = margin; rect.origin.y = margin;
		rect.size.width = deltaX; rect.size.height = deltaY;
		for(int i=0; i<row; i++)
		{
			//NSLog(@"doPageViewportRearrangement...outerLoop... %d", i);
			BOOL defaultViewportTitleON;
			for(int j=0; j<column; j++)
			{
				//NSLog(@"doPageViewportRearrangement...innerLoop... %d", j);
				DeviceData *dev;
				if(index < deviceTTNum)
				{
					dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:index];
					label = [dev title];
					defaultViewportTitleON = NO;
					[dev setDirtyFlag:NO];
				}
				else
				{
					label = [NSString stringWithFormat:@"Not Configured"];
					defaultViewportTitleON = YES;
				}
				
				// update the tag
				index++;								
				Viewport *port = [Viewport viewportCreationWithLocation:rect inLabel:label assignedIndex:index associatedServer:[self retrieveRunMode]];
				[[port streaming] setDelegate:port];
				[port doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
				if([self labelON] == YES)
					[[port titleView] setHidden:NO];
				else
				{
					if(defaultViewportTitleON == YES)
					{
						[[port titleView] setHidden:NO];
						[port setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
						[port showStatus];	// clear possible remained message
					}
				}
				// assign a z-position
				port.layer.zPosition = zPos+j*Z_POSITION_DELTA_ON_PAGE;				
				// because we send 'autorelease' message to port while creating it, thus, we don't need to
				// release it here after adding it to the scroll view.
				[page addSubview:port];
				
				// all the viewports with index equal or larger than deviceTTNum in the viewportArray are
				// empty viewport(i.e., there is no corresponding device in the DeviceCache)
				// we must keep the viewport reference count to 2 here so that we will have chance to
				// re-arrange the viewport layout even though the pages have been removed.
				// thus, we don't release the port after adding the port into viewportArray.
				[viewportArray addObject:port];
				//[port release];
				
				rect.origin.x += (deltaX+margin);
			}
			// update the rect
			rect.origin.y += (deltaY+margin);
			rect.origin.x = margin;
		}
		//NSLog(@"doPageViewportRearrangement...one page viewport adding done");
		// add the page into scroll view
		[scrollView addSubview:page];
		//NSLog(@"doPageViewportRearrangement...add page to scroll view done");
		//[page release];
		[pageArray addObject:page];
		[page release];
		// don't release the page with the same reason as did for port mentioned above 
		//[page release];
		// update the page origin
		wholeWindow.origin.x += wholeWindow.size.width;
	}
	
	NSLog(@"viewportArray count: %d", [viewportArray count]);
	NSLog(@"pagetArray count: %d", [pageArray count]);
	NSLog(@"doPageViewportRearrangement...pages/viewports adding done");
	[scrollView setContentSize:CGSizeMake([self pageTTNum]*pageWidth, pageHeight)];
	[scrollView setPagingEnabled:YES];
	[scrollView setDelegate:self];
	NSLog(@"doPageViewportRearrangement...change scroll view content size done");
	CGRect fR = [scrollView frame];
	fR.origin.y = 0;
	[scrollView setFrame:fR];
	mainScrollViewOffsetY = 0;
	
	// page control treatment
	CGRect tbRect = CGRectMake(0,
							   [scrollView bounds].size.height+MARGIN_PAGE_CONTROL, 
							   pageWidth, 
							   PAGE_CONTROL_HEIGHT);				
	
	[pageControl setFrame:tbRect];
	[pageControl setUserInteractionEnabled:NO];
	
	if([self pageTTNum] == 1)
	{
		NSLog(@"hide page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:YES];		
		[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)pageControl waitUntilDone:YES];
	}
	else
	{
		NSLog(@"display page control...");
		[[self pageControl] setNumberOfPages:[self pageTTNum]];
		[[self pageControl] setCurrentPage:[self curPage]]; 
		[[self pageControl] setHidden:NO];
	}
	
	

/*	
	// insert the embedded 'Home Controller' table
	int htOffsetY, htHeight;
	if([self pageTTNum] > 1)
	{
		htOffsetY = MARGIN_PAGE_CONTROL+PAGE_CONTROL_HEIGHT+MARGIN_PAGE_CONTROL;
		htHeight = FOCAL_VIEW_CONTROL_PANEL_HEIGHT+PAGE_CONTROL_HEIGHT;
	}
	else 
	{
		htOffsetY = 0;
		htHeight = 0;
	}	

#ifdef SERVER_MODE	
	tbRect = CGRectMake(0,
						[scrollView bounds].size.height+htOffsetY, 
						pageWidth, 
						[[hcTableContainer tableView] bounds].size.height);		
	tbRect.size.height = ttRect.size.height;;		
	[hcTable setFrame:tbRect];	
#else
	tbRect = CGRectMake(0,
						[scrollView bounds].size.height+htOffsetY, 
						pageWidth, 
						[hcTableContainer bounds].size.height);		
	[hcTableContainer setFrame:tbRect];		
	[hcTable setFrame:ttRect];	
#endif
	//NSLog(@"2..hcTableContainer...bound: X= %f Y= %f W= %f H= %f", [hcTableContainer bounds].origin.x, 
	//	  [hcTableContainer bounds].origin.y, 
	//	  [hcTableContainer bounds].size.width, 
	//	  [hcTableContainer bounds].size.height);
	//NSLog(@"2..hcTableContainer...frame: X= %f Y= %f W= %f H= %f", tbRect.origin.x, 
	//	  tbRect.origin.y, 
	//	  tbRect.size.width, 
	//	  tbRect.size.height);
*/	
	
	// reset row/column viewport changed flag
	[self setRowColumnViewportArrangementChanged:NO];
	
	// reset the dirty flag in device cache
	[[DeviceCache sharedDeviceCache] setDirtyFlag:NO];	
	
}

#ifdef SERVER_MODE	
-(void)embeddedHCTableItemReload
{
	NSLog(@"enter embeddedHCTableItemReload...");
	CGRect fR = [scrollView frame];
	fR.origin.y = 0;
	[scrollView setFrame:fR];
	mainScrollViewOffsetY = 0;
	CGRect ttRect = [scrollView bounds];
	int pageWidth = ttRect.size.width;
	
	CGRect tbRect = CGRectMake(0,
							   [scrollView bounds].size.height+MARGIN_PAGE_CONTROL, 
							   pageWidth, 
							   PAGE_CONTROL_HEIGHT);	
	
	// insert the embedded 'Home Controller' table
	int htOffsetY, htHeight;
	if([self pageTTNum] > 1)
	{
		htOffsetY = MARGIN_PAGE_CONTROL+PAGE_CONTROL_HEIGHT+MARGIN_PAGE_CONTROL;
		htHeight = FOCAL_VIEW_CONTROL_PANEL_HEIGHT+PAGE_CONTROL_HEIGHT;
	}
	else 
	{
		htOffsetY = 0;
		htHeight = 0;
	}	
	
#ifdef SERVER_MODE	
	//NSLog(@"enter embeddedHCTableItemReload...1");
	tbRect = CGRectMake(0,
						[scrollView bounds].size.height+htOffsetY, 
						pageWidth, 
						[[hcTableContainer tableView] bounds].size.height);		
	tbRect.size.height = ttRect.size.height;
	//NSLog(@"enter embeddedHCTableItemReload...2");
	//[hcTable setFrame:tbRect];
	//NSLog(@"enter embeddedHCTableItemReload...3");
	[NSThread detachNewThreadSelector:@selector(embeddedHCTableLoadingData) toTarget:self withObject:nil];
	//NSLog(@"enter embeddedHCTableItemReload...3");
#else
	tbRect = CGRectMake(0,
						[scrollView bounds].size.height+htOffsetY, 
						pageWidth, 
						[hcTableContainer bounds].size.height);		
	[hcTableContainer setFrame:tbRect];		
	[hcTable setFrame:ttRect];	
#endif
	//NSLog(@"2..hcTableContainer...bound: X= %f Y= %f W= %f H= %f", [hcTableContainer bounds].origin.x, 
	//	  [hcTableContainer bounds].origin.y, 
	//	  [hcTableContainer bounds].size.width, 
	//	  [hcTableContainer bounds].size.height);
	//NSLog(@"2..hcTableContainer...frame: X= %f Y= %f W= %f H= %f", tbRect.origin.x, 
	//	  tbRect.origin.y, 
	//	  tbRect.size.width, 
	//	  tbRect.size.height);	
	
}
#endif

-(void)enterMapEditing
{
	// if we are in multipleview port mode, let's do the mapping job	
	// otherwise, we must be in focal viewport mode, let's back to multiple viewport mode
	if([[[self leftBarButtonItem] title] isEqualToString:@"Mapping"] == YES)
	{	
		if(!deviceListController)
		{
			NSLog(@"LiveImageController...reloadData...create deviceListController");
			TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
			if(appDelegate == nil)
				return;			
			int runMode = [[appDelegate dataCenter] getMobileMode];		
			deviceListController = [[DeviceListController alloc] initWithMode:runMode];
		}		
	
		[[self navigationController] pushViewController:deviceListController animated:YES];
	}
	else 
	{
		[self backFromFocalView];
	}

}

// do the streaming connection retry for those viewports with disconnected status
-(void)refresh
{
	if([self cancelMode] == YES)
		[self setCancelMode:NO];
	
	// check to see if we need to do mapping rearrangement
	[self checkReloadRequirement];
	
}

-(void)badgeLayout:(BOOL)flush
{
	//NSLog(@"enter badgeLayout...");
	if(flush == YES)
	{
		if([self roundExitBadge] != nil)
		{
			[[self roundExitBadge] removeFromSuperview];
			roundExitBadge = nil;
		}
		
		return;
	}
	
	// we must have the badge on
	if([self roundExitBadge] == nil)
	{
		UIImage *ptImage = [UIImage imageNamed:@"exitBadge.png"];
		UIImageView *vw = [[UIImageView alloc] initWithImage: ptImage];
		roundExitBadge = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[roundExitBadge addSubview:vw];
		[vw release];
	}	
	
	CGRect location = [scrollView frame];
	
	//NSLog(@"badgeLayout...scrollView...frame: X= %f Y= %f W= %f H= %f", location.origin.x, location.origin.y, location.size.width, location.size.height);
	/*
	int deltaY = 6;
	int deltaX = 6;
	CGRect badgeR;;
	
	badgeR = CGRectMake(location.origin.x+deltaX,
						location.origin.y+deltaY,
						BADGE_SIDE_WIDTH, 
						BADGE_SIDE_WIDTH);
	float r = (float)BADGE_SIDE_WIDTH;
	[[self roundExitBadge] setFrame:badgeR];
	roundExitBadge.layer.cornerRadius = r/2.0;
	// center is in coordinates of its superview
	CGPoint cp;
	cp.x = r/2.0; cp.y = mainScrollViewOffsetY+r/2.0;		
	*/
	

	int deltaY = 12;
	int deltaX = 12;
	CGRect badgeR;;
	
	badgeR = CGRectMake(location.origin.x+deltaX,
						location.origin.y+deltaY,
						BADGE_SIDE_WIDTH-8, 
						BADGE_SIDE_WIDTH-8);
	float r = (float)BADGE_SIDE_WIDTH;
	[[self roundExitBadge] setFrame:badgeR];
	roundExitBadge.layer.cornerRadius = r/4.0;
	// center is in coordinates of its superview
	CGPoint cp;
	cp.x = BADGE_SIDE_WIDTH/4; 
	cp.y = mainScrollViewOffsetY+BADGE_SIDE_WIDTH/4;

	 
	[[self roundExitBadge] setCenter:cp];
	[[self roundExitBadge] setUserInteractionEnabled:YES];
	
	// assign tap action for the badge
	[roundExitBadge addTarget:self
					   action:@selector(backFromFocalView)
			 forControlEvents:UIControlEventTouchUpInside];

	//NSLog(@"LiveImageController...add exitBadge...");
	[[self view] addSubview:roundExitBadge];
}


// num: the focal viewport tag
-(void)disableSiblingActivity:(NSInteger)num
{ 
	// decide the page number of all the sibling on the same page
	int vwPerPage = viewportPerPage.row*viewportPerPage.column;
	int residentPage;
	if(num <= vwPerPage)
		residentPage = 1;
	else 
	{
		int r = num%vwPerPage;
		if(r==0)
			residentPage = num/vwPerPage;
		else
			residentPage = num/vwPerPage+1;
	}
	
	// decide the start/end index for the sibling
	int start, end;
	start = (residentPage-1)*vwPerPage;
	end = residentPage*vwPerPage-1;
	for(int i=start; i<=end; i++)
	{
		// if be myself, do nothing
		if(i == (num-1))
			continue;
		
		// disable all the other siblings' activity
		Viewport *vw = [viewportArray objectAtIndex:i];
		[vw setUserInteractionEnabled:NO];
		[[vw streaming] setConnectionRetryEnabled:NO];
		[[vw streaming] stop];
	}
}

-(void)disableAllSiblingActivity:(NSInteger)num
{
	// decide the page number of all the sibling on the same page
	NSLog(@"shutdown all sibling...");
	int vwPerPage = viewportPerPage.row*viewportPerPage.column;
	int residentPage;
	if(num <= vwPerPage)
		residentPage = 1;
	else 
	{
		int r = num%vwPerPage;
		if(r==0)
			residentPage = num/vwPerPage;
		else
			residentPage = num/vwPerPage+1;
	}
	
	// decide the start/end index for the sibling
	int start, end;
	start = (residentPage-1)*vwPerPage;
	end = residentPage*vwPerPage-1;
	for(int i=start; i<=end; i++)
	{		
		// disable all the siblings' activity
		Viewport *vw = [viewportArray objectAtIndex:i];
		[vw setUserInteractionEnabled:NO];
		[[vw streaming] setConnectionRetryEnabled:NO];
		[[vw streaming] stop];
	}		
}

-(void)enableSiblingActivity:(NSInteger)num
{
	// decide the page number of all the sibling on the same page
	int vwPerPage = viewportPerPage.row*viewportPerPage.column;
	int residentPage;
	if(num <= vwPerPage)
		residentPage = 1;
	else 
	{
		int r = num%vwPerPage;
		if(r==0)
			residentPage = num/vwPerPage;
		else
			residentPage = num/vwPerPage+1;
	}
	
	// decide the start/end index for the sibling
	int start, end;
	start = (residentPage-1)*vwPerPage;
	end = residentPage*vwPerPage-1;
	for(int i=start; i<=end; i++)
	{
		// if be myself, do nothing
		if(i == (num-1))
			continue;
		
		// disable all the other siblings' activity
		Viewport *vw = [viewportArray objectAtIndex:i];
		[vw setUserInteractionEnabled:YES];
		[[vw streaming] setConnectionRetryEnabled:YES];
		[[vw streaming] play];
	}	
}

-(void)presentFocalViewDone:(NSInteger)num
{
	UIView *recoverView = (UIView*)[viewportArray objectAtIndex:num-1];
	// re-do the layout for the focal viewport
	[(Viewport*)recoverView doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
	// display the focal viewport title on the navigation bar
	[[self navigationItem] performSelectorOnMainThread:@selector(setTitle:)withObject:(id)[(Viewport*)recoverView title] waitUntilDone:NO];
	// add the exit badge for back to multiple view later
	BOOL pullUpHCTable = NO;	//need to pull up the embedded hcTable flag
	CGRect newHCTableR;
	if([self pageTTNum] > 1)
	{
		[[self pageControl] setHidden:YES];		
		// if we have embedded hcTable, we also need to pull it up to fill up the hidden pageControl space
		if(hcTableContainer)
		{
			pullUpHCTable = YES;
#ifdef SERVER_MODE			
			newHCTableR = [[hcTableContainer tableView] frame];
#else			
			newHCTableR = [hcTableContainer frame];
#endif			
			newHCTableR.origin.y -= (MARGIN_PAGE_CONTROL+PAGE_CONTROL_HEIGHT+MARGIN_PAGE_CONTROL);
		}
	}	
	
	if(pullUpHCTable)
		[UIView animateWithDuration:0.5 
							  delay:0.0 
							options:UIViewAnimationCurveEaseIn
						 animations:^{ //[self badgeLayout:NO];
#ifdef SERVER_MODE							 
									   [[hcTableContainer tableView] setFrame:newHCTableR];	
#else
									   [hcTableContainer setFrame:newHCTableR];							 
#endif							 
									   [self addFocalViewAssociatedToolbarButtons];	
						 }
						 completion:nil];
	else
		[UIView animateWithDuration:0.5 
							  delay:0.0 
							options:UIViewAnimationCurveEaseIn
						 animations:^{ //[self badgeLayout:NO];
									   [self addFocalViewAssociatedToolbarButtons];	
						 }
						 completion:nil];	
	
	// reset the left UIBarButtonItem text
	if(leftBarButtonItem)
		[leftBarButtonItem setTitle:@"Back"];	
	
	// if the connection broken, we should automatically do the connection retry here
	if(num <= [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		Viewport *vw = [viewportArray objectAtIndex:num-1];
		if([vw streamTerminated] == YES)
			[self loadStreams];
	}
}

-(void)backFromFocalViewDone:(NSInteger)num
{
	// decide the page number of all the sibling on the same page
	int vwPerPage = viewportPerPage.row*viewportPerPage.column;
	int residentPage;
	if(num <= vwPerPage)
		residentPage = 1;
	else 
	{
		int r = num%vwPerPage;
		if(r==0)
			residentPage = num/vwPerPage;
		else
			residentPage = num/vwPerPage+1;
	}
	
	// add the focal view back to the resident page
	UIView *resPage = [pageArray objectAtIndex:residentPage-1];
	[resPage addSubview:focalView];
	// re-do the layout for the recovery focal viewport
	[(Viewport*)focalView doInternalLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
	// recover the navigation title bar
	[[self navigationItem] performSelectorOnMainThread:@selector(setTitle:)withObject:(id)@"Live View" waitUntilDone:NO];	
	// reset the focal view recovery data
	/*
	focalViewRecoverData.focalViewportTag = 0;
	focalViewRecoverData.zPos = 0;
	focalViewRecoverData.centerPosInSuper.x = 0;
	focalViewRecoverData.centerPosInSuper.y = 0;
	focalViewRecoverData.frameInSuper = CGRectMake(0,0,0,0);
	*/
	// embedded hc table tratment
	BOOL pushDownHCTable = NO;	//need to pull up the embedded hcTable flag
	CGRect newHCTableR;
	if([self pageTTNum] > 1)
	{	
		// if we have embedded hcTable, we also need to push it down to provide space for the pageControl
		if(hcTableContainer)
		{
			pushDownHCTable = YES;
#ifdef SERVER_MODE
			newHCTableR = [[hcTableContainer tableView] frame];
#else			
			newHCTableR = [hcTableContainer frame];
#endif			
			newHCTableR.origin.y += (MARGIN_PAGE_CONTROL+PAGE_CONTROL_HEIGHT+MARGIN_PAGE_CONTROL);
		}
	}
	
	// recover the user interaction for all viewport on current page
	int viewportCountPerPage = viewportPerPage.row*viewportPerPage.column;			
	int start = [self curPage]*viewportCountPerPage;
	int end = ([self curPage]+1)*viewportCountPerPage;		
	
	for(int i=start; i<end; i++)
	{
		Viewport *vw = [viewportArray objectAtIndex:i];
		[vw setRunMode:RUN_MODE_NON_FOCAL];
		[vw setUserInteractionEnabled:YES];
	}
	
	if(pushDownHCTable)
		[UIView animateWithDuration:0.5 
							  delay:0.0 
							options:UIViewAnimationCurveEaseIn
						 animations:^{ 
#ifdef SERVER_MODE	
										[[hcTableContainer tableView] setFrame:newHCTableR];
#else							 
										[hcTableContainer setFrame:newHCTableR];
#endif									    
										[self removeFocalViewAssociatedToolbarButtons];
						 }
						 completion:nil];
	else
		[UIView animateWithDuration:0.5 
							  delay:0.0 
							options:UIViewAnimationCurveEaseIn
						 animations:^{  
							 [self removeFocalViewAssociatedToolbarButtons];
						 }
						 completion:nil];
	
	// reset the focal view recovery data
	focalViewRecoverData.focalViewportTag = 0;
	focalViewRecoverData.zPos = 0;
	focalViewRecoverData.centerPosInSuper.x = 0;
	focalViewRecoverData.centerPosInSuper.y = 0;
	focalViewRecoverData.frameInSuper = CGRectMake(0,0,0,0);		
	
	// restore the left UIBarButtonItem text
	if(leftBarButtonItem)
		[leftBarButtonItem setTitle:@"Mapping"];	
}

// num: the tag number for the focal view
-(void)presentFocalView:(NSInteger)num
{
	// if no focal viewport, do nothing
	if(num == 0)
		return;
	
	// disable other sibling activity on the page
	[self disableSiblingActivity:num];

	/*
	// disable the paging ability and hide the page control	
	//[scrollView setContentSize:CGSizeMake(wholeWindowMain.size.width, [scrollView bounds].size.height)];
	[scrollView setPagingEnabled:NO];
	if([self pageTTNum] > 1)
		[[self pageControl] setHidden:YES];	
	// enable the zooming ability
	[scrollView setMinimumZoomScale:ZOOM_RATE_MIN];
	[scrollView setMaximumZoomScale:ZOOM_RATE_MAX];
	[scrollView setDelegate:self];
	*/
	
	focalView = [viewportArray objectAtIndex:num-1];
	/*
	[scrollView setPagingEnabled:NO];
	UIScrollView *vpBase = [focalView baseScrollView];
	[vpBase setPagingEnabled:NO];
	if([self pageTTNum] > 1)
		[[self pageControl] setHidden:YES];	
	// enable the zooming ability
	[vpBase setMinimumZoomScale:ZOOM_RATE_MIN];
	[vpBase setMaximumZoomScale:ZOOM_RATE_MAX];
	[vpBase setDelegate:focalView];	
	if([self pageTTNum] > 1)
		[[self pageControl] setHidden:YES];	
	*/
	
	// remember the focal view attributes for recovery use later	
	focalViewRecoverData.focalViewportTag = num;
	focalViewRecoverData.zPos = [[focalView layer] zPosition];
	focalViewRecoverData.centerPosInSuper.x = [[focalView layer] position].x;
	focalViewRecoverData.centerPosInSuper.y = [[focalView layer] position].y;
	focalViewRecoverData.frameInSuper = [focalView frame];	
	// prepare the animation items	
	CGRect largeViewR = [scrollView frame];
	
	//NSLog(@"presentFocalView...scrollView...frame: X= %f Y= %f W= %f H= %f", largeViewR.origin.x, largeViewR.origin.y, largeViewR.size.width, largeViewR.size.height);		
	largeViewR.origin.x += MARGIN_BETWEEN_VIEWPORT;
	largeViewR.origin.y += MARGIN_BETWEEN_VIEWPORT;
	largeViewR.size.width -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	largeViewR.size.height -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	CGPoint p;
	p.x = [scrollView bounds].size.width/2.0;
	p.y = [scrollView bounds].size.height/2.0;	
	//NSLog(@"presentFocalView...largeViewR...frame: X= %f Y= %f W= %f H= %f", largeViewR.origin.x, largeViewR.origin.y, largeViewR.size.width, largeViewR.size.height);
	CGRect largeContainerR = [scrollView frame];	
	//NSLog(@"presentFocalView...largeContainerR...frame: X= %f Y= %f W= %f H= %f", largeContainerR.origin.x, largeContainerR.origin.y, largeContainerR.size.width, largeContainerR.size.height);		
	//NSLog(@"presentFocalView...center...position...x: %f...y: %f", p.x, p.y);
		
	// do the animation
	if(focalViewContainer != nil)
		[focalViewContainer release];
	
	CGRect containerR = [focalView frame];
	containerR.origin.x -= MARGIN_BETWEEN_VIEWPORT;
	containerR.origin.y -= MARGIN_BETWEEN_VIEWPORT;
	containerR.size.width += (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	containerR.size.height += (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	focalViewContainer = [[UIScrollView alloc] initWithFrame:containerR];
	// enable the zooming ability
	[focalViewContainer setMinimumZoomScale:ZOOM_RATE_MIN];
	[focalViewContainer setMaximumZoomScale:ZOOM_RATE_MAX];
	[focalViewContainer setDelegate:self];	
	[focalViewContainer setContentSize:CGSizeMake([scrollView bounds].size.width, [scrollView bounds].size.height)];
	// we also enable the paging ability here to prevent the paging notification forwarded to main scrollView
	// since we don't want the focalViewContainer has the paging ability by setting its contentSize
	// as one page width
	[focalViewContainer setPagingEnabled:NO];
	[focalViewContainer setBounces:NO];
	[focalViewContainer setBouncesZoom:NO];
	[focalViewContainer setDelegate:self];		
	[focalViewContainer addSubview:focalView];

	[[self view] performSelectorOnMainThread:@selector(addSubview:)withObject:(id)focalViewContainer waitUntilDone:YES];	
	
	[UIView animateWithDuration:0.5 
						delay:0.0 
						options:UIViewAnimationOptionCurveEaseIn
						animations:^{
							 [(Viewport*)focalView prepareViewportDisplayModeChange];
							 [(Viewport*)focalView setRunMode:RUN_MODE_FOCAL_PORT];
							 [focalView setFrame:largeViewR];
							 [focalView setCenter:p];
							 //[focalView setContentMode:UIViewContentModeScaleAspectFit];
							 [focalViewContainer setFrame:largeContainerR];							 							 
						 }
						 completion:^(BOOL finished){ 
							 [self presentFocalViewDone:num]; 
						 }];
	
	// iOS 4 and above
	/*
	[UIView animateWithDuration:0.5 
						  delay:0.0 
						options:UIViewAnimationOptionCurveEaseIn
					 animations:^{ [(Viewport*)focalView setRunMode:RUN_MODE_FOCAL_PORT];
								   [context setZPosition:Z_POSITION_MAX_ON_PAGE];
								   [context setPosition:p];
								   //[focalView resizeFrame:largeViewR];
								   [focalView setFrame:largeViewR];
								 }
					 completion:^(BOOL finished){ 
								   [self presentFocalViewDone:num]; 
								 }];
	*/
		
	/*
	 // iOS earlier
	 [focalView beginAnimations:nil context:nil];
	 [focalView setAnimationDuration:0.5];
	 [focalView setAnimationDelay:1.0];
	 [focalView setAnimationCurve:UIViewAnimationCurveEaseOut];
	 
	 CALayer *context = [focalView layer];
	 float x, y;
	 
	 CGRect largeViewR = [scrollView frame];
	 largeViewR.origin.x += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.origin.y += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.size.width -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 largeViewR.size.height -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 [focalView setFrame:largeViewR];
	 // get the maximum z-position for this page
	 Viewport *top = [viewportArray objectAtIndex:[viewportArray count]-1];	
	 //int zPos = [[viewportArray objectAtIndex:[viewportArray count]-1] zPosition];
	 CGFloat zPos = [[top layer] zPosition];
	 [context setZPosition:zPos];	
	 
	 x = [scrollView bounds].origin.x+[scrollView bounds].size.width/2;
	 y = [scrollView bounds].origin.y+[scrollView bounds].size.height/2;	
	 CGPoint p;
	 p.x = x; p.y = y;
	 [context setPosition:p];
	 
	 [focalView commitAnimations];
	 */
	
}

-(void)backFromFocalView
{
	// if no focal viewport, do nothing
	if(focalViewRecoverData.focalViewportTag == 0)
		return;
	
	// flush the exit badge
	//[self badgeLayout:YES];
	int num = focalViewRecoverData.focalViewportTag;
	// enable other sibling activity on the page
	[self enableSiblingActivity:num];
	
	Viewport *recoverView = [viewportArray objectAtIndex:num-1];
		
	// set the animation items for the recover	
	CALayer *context = [focalView layer];	
	CGRect smallViewR = focalViewRecoverData.frameInSuper;
	CGPoint p;
	p.x = focalViewRecoverData.centerPosInSuper.x;
	p.y = focalViewRecoverData.centerPosInSuper.y;	
	
	[UIView animateWithDuration:0.5 
							delay:0.0 
						options:UIViewAnimationCurveEaseOut
						animations:^{ 
							 // reset the zooming rate
							 [self resetZoomRate:1.0f];
							 [(Viewport*)focalView prepareViewportDisplayModeChange];
							 [(Viewport*)recoverView setRunMode:RUN_MODE_NON_FOCAL];
							 [context setZPosition:focalViewRecoverData.zPos];
							 [context setPosition:p];
							 [focalView setFrame:smallViewR];
							 //[focalView setContentMode:UIViewContentModeScaleAspectFit];
							 [focalViewContainer setFrame:smallViewR];							
						 }
						completion:^(BOOL finished){ 
							 [self backFromFocalViewDone:num]; 
						 }];	
	
	[focalViewContainer removeFromSuperview];
	focalViewContainer = nil;
	if([self pageTTNum] > 1)
		[[self pageControl] setHidden:NO];
	
	// if the streaming of the focal viewport we just back from is stopped, restart it
	// if the connection broken, we should automatically do the connection retry here
	if(num <= [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		Viewport *vw = [viewportArray objectAtIndex:num-1];
		if([vw streamTerminated] == YES)
			[[vw streaming] play];
	}
	
	
	/*
	[UIView animateWithDuration:0.5 
						  delay:0.0 
						options:UIViewAnimationCurveEaseOut
					 animations:^{ [(Viewport*)focalView setRunMode:RUN_MODE_NON_FOCAL];
						 [context setZPosition:focalViewRecoverData.zPos];
						 [context setPosition:p];
						 //[focalView resizeFrame:smallViewR];
						 [focalView setFrame:smallViewR];
					 }
					 completion:nil];
	*/
		
	
	/*
	 [focalView beginAnimations:nil context:nil];
	 [focalView setAnimationDuration:0.5];
	 [focalView setAnimationDelay:1.0];
	 [focalView setAnimationCurve:UIViewAnimationCurveEaseOut];
	 
	 CALayer *context = [focalView layer];
	 float x, y;
	 
	 CGRect largeViewR = [scrollView frame];
	 largeViewR.origin.x += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.origin.y += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.size.width -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 largeViewR.size.height -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 [focalView setFrame:largeViewR];
	 // get the maximum z-position for this page
	 Viewport *top = [viewportArray objectAtIndex:[viewportArray count]-1];	
	 //int zPos = [[viewportArray objectAtIndex:[viewportArray count]-1] zPosition];
	 CGFloat zPos = [[top layer] zPosition];
	 [context setZPosition:zPos];	
	 
	 x = [scrollView bounds].origin.x+[scrollView bounds].size.width/2;
	 y = [scrollView bounds].origin.y+[scrollView bounds].size.height/2;	
	 CGPoint p;
	 p.x = x; p.y = y;
	 [context setPosition:p];
	 
	 [focalView commitAnimations];
	 */
	
}


-(void)forcedOutFromFocalView
{
	// if no focal viewport, do nothing
	if(focalViewRecoverData.focalViewportTag == 0)
		return;
	
	// flush the exit badge
	//[self badgeLayout:YES];
	int num = focalViewRecoverData.focalViewportTag;
	// shutdown all sibling activity on the page
	[self disableAllSiblingActivity:num];
	
	Viewport *recoverView = [viewportArray objectAtIndex:num-1];
	
	// set the animation items for the recover	
	CALayer *context = [focalView layer];	
	CGRect smallViewR = focalViewRecoverData.frameInSuper;
	CGPoint p;
	p.x = focalViewRecoverData.centerPosInSuper.x;
	p.y = focalViewRecoverData.centerPosInSuper.y;			

	[UIView animateWithDuration:0.5 
							delay:0.0 
						options:UIViewAnimationCurveEaseOut
						animations:^{ 
							 // reset the zooming rate
							 [self resetZoomRate:1.0f];
							 [(Viewport*)focalView prepareViewportDisplayModeChange];
							 [(Viewport*)recoverView setRunMode:RUN_MODE_NON_FOCAL];
							 [context setZPosition:focalViewRecoverData.zPos];
							 [context setPosition:p];
							 [focalView setFrame:smallViewR];
							 [focalViewContainer setFrame:smallViewR];
						 }
						 completion:^(BOOL finished){ 
							 [self backFromFocalViewDone:num]; 
						 }];
	
	[focalViewContainer removeFromSuperview];
	focalViewContainer = nil;
	if([self pageTTNum] > 1)
		[[self pageControl] setHidden:NO];	
	/*
	 [UIView animateWithDuration:0.5 
	 delay:0.0 
	 options:UIViewAnimationCurveEaseOut
	 animations:^{ [(Viewport*)focalView setRunMode:RUN_MODE_NON_FOCAL];
	 [context setZPosition:focalViewRecoverData.zPos];
	 [context setPosition:p];
	 //[focalView resizeFrame:smallViewR];
	 [focalView setFrame:smallViewR];
	 }
	 completion:nil];
	 */
	
	
	/*
	 [focalView beginAnimations:nil context:nil];
	 [focalView setAnimationDuration:0.5];
	 [focalView setAnimationDelay:1.0];
	 [focalView setAnimationCurve:UIViewAnimationCurveEaseOut];
	 
	 CALayer *context = [focalView layer];
	 float x, y;
	 
	 CGRect largeViewR = [scrollView frame];
	 largeViewR.origin.x += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.origin.y += MARGIN_BETWEEN_VIEWPORT;
	 largeViewR.size.width -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 largeViewR.size.height -= (MARGIN_BETWEEN_VIEWPORT+MARGIN_BETWEEN_VIEWPORT);
	 [focalView setFrame:largeViewR];
	 // get the maximum z-position for this page
	 Viewport *top = [viewportArray objectAtIndex:[viewportArray count]-1];	
	 //int zPos = [[viewportArray objectAtIndex:[viewportArray count]-1] zPosition];
	 CGFloat zPos = [[top layer] zPosition];
	 [context setZPosition:zPos];	
	 
	 x = [scrollView bounds].origin.x+[scrollView bounds].size.width/2;
	 y = [scrollView bounds].origin.y+[scrollView bounds].size.height/2;	
	 CGPoint p;
	 p.x = x; p.y = y;
	 [context setPosition:p];
	 
	 [focalView commitAnimations];
	 */
	
}
		 
-(void)addFocalViewAssociatedToolbarButtons
{
	snapshotBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(doSnapshot)];
	[snapshotBtn setStyle:UIBarButtonItemStyleBordered];
	zoomRate = [[UIBarButtonItem alloc] initWithTitle:@"Zoom: 1.00" style:UIBarButtonItemStylePlain target:self action:@selector(displayZoomRate)];
	[zoomRate setEnabled:NO];	
	
	NSMutableArray *array = [[[toolBar items] mutableCopy] autorelease];
	
#ifdef P2P_MODE	
	
	// decide the button number according to the model name
	if(focalViewRecoverData.focalViewportTag)
	{
		DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:focalViewRecoverData.focalViewportTag-1];
		int ability = [dev extensionFeatures];
		if((ability & DEVICE_EXTENSION_LED_W) || (ability & DEVICE_EXTENSION_LED_IR))
		{
			//ledBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(doLedOnOff)];
			ledBtn = [[UIBarButtonItem alloc] initWithTitle:@"LED" style:UIBarButtonSystemItemCamera target:self action:@selector(doLedOnOff)];
			[ledBtn setStyle:UIBarButtonItemStyleBordered];			
			[array insertObject:snapshotBtn atIndex:TOOLBAR_BTN_SNAPSHOT]; 
			[array insertObject:ledBtn atIndex:TOOLBAR_BTN_LED];
			[array insertObject:zoomRate atIndex:TOOLBAR_BTN_ZOOM_RATE+1];			
		}
		else
		{
			[array insertObject:snapshotBtn atIndex:TOOLBAR_BTN_SNAPSHOT]; 
			[array insertObject:zoomRate atIndex:TOOLBAR_BTN_ZOOM_RATE];			
		}
	}
	else
	{
		[array insertObject:snapshotBtn atIndex:TOOLBAR_BTN_SNAPSHOT]; 
		[array insertObject:zoomRate atIndex:TOOLBAR_BTN_ZOOM_RATE];
	}
#else
	[array insertObject:snapshotBtn atIndex:TOOLBAR_BTN_SNAPSHOT]; 
	[array insertObject:zoomRate atIndex:TOOLBAR_BTN_ZOOM_RATE];	
#endif	
	[toolBar setItems:array animated:YES];	 
}
		 
-(void)removeFocalViewAssociatedToolbarButtons
{
	NSMutableArray *array = [[[toolBar items] mutableCopy] autorelease];
#ifdef P2P_MODE
	if(focalViewRecoverData.focalViewportTag)
	{
		DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:focalViewRecoverData.focalViewportTag-1];
		int ability = [dev extensionFeatures];
		if((ability & DEVICE_EXTENSION_LED_W) || (ability & DEVICE_EXTENSION_LED_IR))
			[array removeObjectAtIndex:TOOLBAR_BTN_SNAPSHOT];	// remove led button
	}
	[array removeObjectAtIndex:TOOLBAR_BTN_SNAPSHOT];	// remove snapshot button
	[array removeObjectAtIndex:TOOLBAR_BTN_SNAPSHOT];	// remove zoom button
#else	
	[array removeObjectAtIndex:TOOLBAR_BTN_SNAPSHOT];
	[array removeObjectAtIndex:TOOLBAR_BTN_SNAPSHOT];
#endif
	[toolBar setItems:array animated:YES];			
}		

-(void)notifyViewportTouched:(NSNotification*)aNote
{
	NSMutableDictionary *dictionary=(NSMutableDictionary*)[aNote userInfo];	
	NSNumber *ptw1=[dictionary valueForKey:KNotifyTag];		
	NSLog(@"NotifyViewportTouched Viewport tag: %d",[ptw1 integerValue]);
	
	// if the viewport not configured, do nothing
	if([ptw1 integerValue] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return;
	
	[self presentFocalView:[ptw1 integerValue]];

	
	/*
	if(!focalViewController)
	{
		NSLog(@"LiveImageController...notifyViewportTouched...create focalViewController");
		TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
		if(appDelegate == nil)
			return;			
		int runMode = [[appDelegate dataCenter] getMobileMode];
		focalViewController = [[FocalViewController alloc] init];
		[focalViewController setRunMode:runMode];
	}		
	
	// push the viewport with the desired tag 
	if(focalViewController)
	{
		int index = [ptw1 integerValue];
		[self pushFocalViewWithTag:index];
							
	}
	*/	
	
}

-(void)notifyStreamingOnOff:(NSNotification*)aNote
{
	NSMutableDictionary *dictionary=(NSMutableDictionary*)[aNote userInfo];	
	NSNumber *ptw1=[dictionary valueForKey:KNotifyLiveViewOnOff];
	
	if([ptw1 integerValue] == 1)
		[self loadStreams];
	else if([ptw1 integerValue] == 0)
	{
		[self forcedOutFromFocalView];		
		[self unloadStreams:NO];
	}
}

-(void)notifyPageChanged:(NSNotification*)aNote
{
	NSLog(@"LiveImageController...notifyPageChanged....");
	// unload the streaming on prePage and load the streaming on curPage	
	[self loadStreams];
	[self unloadStreams:YES];	
}

-(void)pushFocalViewWithTag:(NSInteger)index
{
	NSLog(@"pushFocalViewWithTag: %d", index);
	[focalViewController setAssociatedViewTag:index];
	[focalViewController resetZoomRate:1.00f];	
	[[self navigationController] pushViewController:focalViewController animated:YES];	
}

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
     
}

-(void)doTermination
{
	NSLog(@"terminate button pressed.");
	toobarBtnClickedIndex = TOOLBAR_BTN_TERMINATION;
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Terminate The Program" otherButtonTitles:nil];
	//[actionSheet showInView:[self view]];
	[actionSheet showFromBarButtonItem:[[toolBar items] objectAtIndex:0] animated:YES];
	[actionSheet release];	
}

-(void)labelOnOff
{
	labelON = !labelON;
	
	int max = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if(max == 0)
		return;
	
	if(labelON == NO)
	{
		[labelDisplay setTitle:[NSString stringWithFormat:@"Label ON"]];
		NSLog(@"LiveImageController label: 0");
		for(int i=0; i<[viewportArray count]; i++)
		{
			if(i < max)
			{			
				Viewport *vw = [viewportArray objectAtIndex:i];
				[vw labelOnOff:labelON];
			}
		}
	}
	else
	{
		[labelDisplay setTitle:[NSString stringWithFormat:@"Label OFF"]];
		NSLog(@"LiveImageController label: 1");
		for(int i=0; i<[viewportArray count]; i++)
		{
			if(i < max)
			{			
				Viewport *vw = [viewportArray objectAtIndex:i];
				[vw labelOnOff:labelON];
			}
		}				
	}
}

-(void)scrollViewDidScroll:(UIScrollView*)sender
{
	//NSLog(@"LiveImageController...scrollViewDidScroll...");
	if(focalViewRecoverData.focalViewportTag > 0)
		return;
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1;
	if(page >= [self pageTTNum])
	{
		if(pageControl.currentPage == ([self pageTTNum]-1))
		{
			[self setPageOutOfBound:YES];
			return;
		}
		else
			page = [self pageTTNum]-1;
	}
	
	if(page < 0)
	{
		if(pageControl.currentPage == 0)
		{
			[self setPageOutOfBound:YES];
			return;
		}
		else
			page = 0;
	}
	
	if(pageControl.currentPage == page)
		return;
	
	[self setPageOutOfBound:NO];
	NSLog(@"page number:%d", page);
	[self setPrePage:pageControl.currentPage];
	// update the page control's currentPage here to avoid the page indicator change(the white dot) lag 
	pageControl.currentPage = page;	
	
}

-(void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
	NSLog(@"LiveImageController...scrollViewDidEndDecelerating...");
	NSLog(@"prepage: %d curPage: %d...", [self prePage], [self curPage]);
	if(focalViewRecoverData.focalViewportTag > 0)
		return;
		
	if([self pageOutOfBound] == YES)
		return;	
	
	if(([self prePage] != pageControl.currentPage) && ([self curPage] != pageControl.currentPage))
	{		
		AudioServicesPlaySystemSound(soundFileObject);
		[self setCurPage:pageControl.currentPage]; 
		NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
		NSNumber *ptw = [[NSNumber alloc] initWithInt:0];		
		[notifyDictionary setObject: ptw forKey: KNotifyLiveViewPageChanged];
		[ptw release];		
		[note postNotificationName:NOTIFICATION_LIVEVIEW_PAGE_CHANGED object:self userInfo:notifyDictionary];
	}	
}

-(UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView
{
	NSLog(@"Enter viewForZoomingInScrollView()....");
	Viewport *vw = [viewportArray objectAtIndex:focalViewRecoverData.focalViewportTag-1];
	return vw;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	[self showZoomingScale:scale];
}

-(void)displayZoomRate
{
	
}

-(void)resetZoomRate:(float)rate
{
	//Viewport *vw = [viewportArray objectAtIndex:focalViewRecoverData.focalViewportTag-1];
	[focalViewContainer setZoomScale:rate];
	// update the toolbar
	[self showZoomingScale:rate];
}

-(void)showZoomingScale:(float)scale
{
	//if([self toolBar] == nil)
	//	return;
	
	NSLog(@"zooming scale: %f", scale);
	[zoomRate setTitle:[NSString stringWithFormat:@"Zoom: %2.2F", scale]]; 
}

-(void)doSnapshot
{
	NSLog(@"snapshot button pressed.");
	toobarBtnClickedIndex = TOOLBAR_BTN_SNAPSHOT;
	if(focalViewRecoverData.focalViewportTag == 0)
		return;	
	
	Viewport *vw = [viewportArray objectAtIndex:focalViewRecoverData.focalViewportTag-1];
	// if no streaming on going, do nothing
	if([[vw streaming] opStatus] != DEVICE_STATUS_ONLINE)
	{
		NSLog(@"no streaming...do nothing...just return...");
		return;
	}
	
	toobarBtnClickedIndex = TOOLBAR_BTN_SNAPSHOT;
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Snapshot To Album" otherButtonTitles:nil];
	[actionSheet showFromBarButtonItem:[[toolBar items] objectAtIndex:1] animated:YES];
	[actionSheet release];		
	
}

-(void)doLedOnOff
{
	NSLog(@"LED button pressed.");
	if(focalViewRecoverData.focalViewportTag == 0)
		return;	
	
#ifdef P2P_MODE
	int vwID = focalViewRecoverData.focalViewportTag;	
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:vwID-1];
	int ability = [dev extensionFeatures];
	if(!(ability & DEVICE_EXTENSION_LED_W) && !(ability & DEVICE_EXTENSION_LED_IR))
		return;
	
	BOOL typeWhiteLight = ability & DEVICE_EXTENSION_LED_W;			
	NSString *camCommand;
	if(typeWhiteLight)
	{
		if([self ledAction] == 0)
		{
			camCommand = @"/io/wlledctrl.cgi?action=1";
			[self setLedAction:1];
		}
		else
		{
			camCommand = @"/io/wlledctrl.cgi?action=0";
			[self setLedAction:0];		
		}
	}
	else
	{
		if([self ledAction] == 0)
		{
			camCommand = @"/io/irledctrl.cgi?action=1";
			[self setLedAction:1];
		}
		else
		{
			camCommand = @"/io/irledctrl.cgi?action=0";
			[self setLedAction:0];		
		}			
	}
	NSLog(@"LED command: %@", camCommand);
		
	// retrieve the required url/cgi info from the associated DeviceData object
	NSString *serverIP, *actionURL; int serverPort = 80; 	 
	/*if([self serverMode] == RUN_SERVER_MODE) 
	{ 	
		//serverIP = [NSString stringWithString:[[appDelegate dataCenter] GetServerIP]]; 
		serverIP = [NSString stringWithString:[[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] relayIP]];
		serverPort = [[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] relayPort];
		NSString *strBeacon = [NSString stringWithString:[[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] authenticationToken]];					
		NSData *data = [camCommand dataUsingEncoding:NSUTF8StringEncoding];	
		NSString *base64EncodedCmd = Base64Encoder(data);		
		actionURL = [NSString stringWithFormat:@"http://%@:%d/cgi/cmd_relay.php?beacon=%@&cmd=%@", 
						serverIP, 
						serverPort, 
						strBeacon, 
						base64EncodedCmd];
		NSLog(@"PT...tag: %d, direction: %d, beacon=%@", [self tag], ptDirection, strBeacon);
	}
	else
	{*/
		serverIP = [NSString stringWithString:[[[DeviceCache sharedDeviceCache] deviceAtIndex:vwID-1] IP]];
		serverPort = [[[DeviceCache sharedDeviceCache] deviceAtIndex:vwID-1] portNum];
		actionURL = [NSString stringWithFormat:@"http://%@:%@@%@:%d%@",
						[[[DeviceCache sharedDeviceCache] deviceAtIndex:vwID-1] authenticationName],
						[[[DeviceCache sharedDeviceCache] deviceAtIndex:vwID-1] authenticationPassword],
						serverIP, 
						serverPort, 
						camCommand];
	//}
	
	Viewport *vw = [viewportArray objectAtIndex:vwID-1];
	[vw asyncHttpsRequest:actionURL];					
#endif	
}


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		if(toobarBtnClickedIndex == TOOLBAR_BTN_TERMINATION)
			[[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
		else if(toobarBtnClickedIndex == TOOLBAR_BTN_SNAPSHOT)
		{
			NSLog(@"doSnapshot...");
			Viewport *vw = [viewportArray objectAtIndex:focalViewRecoverData.focalViewportTag-1];
			[[vw streaming] doSnapshot:YES];		
		}
	}
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if(toobarBtnClickedIndex == TOOLBAR_BTN_TERMINATION)
		NSLog(@"terminate program dialog cancel button pressed.");
	else if(toobarBtnClickedIndex == TOOLBAR_BTN_SNAPSHOT)
		NSLog(@"snapshot dialog cancel button pressed.");
}

#pragma mark embedded HomeControl page associated methods
#ifdef SERVER_MODE
-(void)embeddedHCTableLoadingData
{
	[hcTableContainer loadingData];				
}

-(void)pushThermostateControllerWithHomeObj:(homeCtrlObject*)hmgObj
{
	NSLog(@"pushThermostate controller...");
	
	if(thermostatViewer == nil)
	{
		thermostatController *viewer = [[thermostatController alloc] initWithNibName:@"thermostatController"
																			  bundle:nil
																			  object:hmgObj];
		self.thermostatViewer = viewer;
	}
	[self.thermostatViewer setHomeControlObj:hmgObj];
	[[self navigationController] pushViewController:thermostatViewer animated:YES];	
}
#endif


- (void)dealloc 
{	
	[deviceListController release];
	[focalViewController release];
	
	[viewportArray release];
	[pageArray release];	
	[notifyDictionary release];
    AudioServicesDisposeSystemSoundID(soundFileObject);
    CFRelease (soundFileURLRef);
	
	[hcTable release];
	[hcTableContainer release];
	if(roundExitBadge != nil)
		[roundExitBadge release];
	if(focalViewContainer != nil)
		[focalViewContainer release];
	
	if(leftBarButtonItem != nil)
		[leftBarButtonItem release];
		
    [super dealloc];
}


@end
