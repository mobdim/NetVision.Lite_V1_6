//
//  FocalViewController.m
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
#import "FocalViewController.h"
#import "Viewport.h"
#import "Streaming.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ImageCache.h"
#import "ConstantDef.h"
#import "UserDefDevList.h"
#import "CheckData.h"
#import "TerraUIAppDelegate.h"

@implementation FocalViewController

@synthesize toolBar;
@synthesize imageView;
@synthesize associatedViewTag;
@synthesize runMode;
@synthesize zoomRate;
@synthesize scrollView;
@synthesize cancelMode;


-(id)init
{
	// Call the superclass's designated initializer
	//[super initWithNibName:@"FocalViewController.xib" bundle:nil];
	[super initWithNibName:nil bundle:nil];
	
	[self setRunMode:RUN_SERVER_MODE];	
	[self setToolBar:nil];
	[self setScrollView:nil];
	[self setImageView:nil];
	[self setCancelMode:NO];
	
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

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(void)viewDidLoad
{
	NSLog(@"focalViewController...viewDidLoad");
	
	// prepare the required navigationItem stuff
	// right bar item button
	UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
	[[self navigationItem] setRightBarButtonItem:rightBarButtonItem];
	[rightBarButtonItem release];	
	// left bar item button(no effect???)
	// create a custom navigation bar button and set it to always say "Back"
	//UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	//temporaryBarButtonItem.title = @"Back";
	//[[self navigationItem] setBackBarButtonItem:temporaryBarButtonItem];
	//[temporaryBarButtonItem release];		
	[[self view] setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];

	CGRect wholeWindow = [[self view] bounds];		
	//CGRect wholeWindow = [[[self parentViewController] view] bounds];
	//NSLog(@"FocalView...bound: X= %f Y= %f W= %f H= %f", wholeWindow.origin.x, wholeWindow.origin.y, wholeWindow.size.width, wholeWindow.size.height);
	//UINavigationBar *navigationBar = [[self navigationController] navigationBar];

	//int navBarHeight = [navigationBar bounds].size.height;
	//NSLog(@"navigationBar height: %d", navBarHeight);	
	wholeWindow.size.height -= NAVIGATION_BAR_HEIGHT;
	//UITabBar *tabBarCtrl = [[self tabBarController] tabBar];
	//int tabBarHeight = [tabBarCtrl bounds].size.height;
	//NSLog(@"tabBar height: %d", tabBarHeight);	
	wholeWindow.size.height -= TAB_BAR_HEIGHT;
	wholeWindow.size.height -= FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
	//wholeWindow.size.width -= (MARGIN_BETWEEN_VIEWPORT*2);
	//wholeWindow.origin.x = MARGIN_BETWEEN_VIEWPORT;
	//wholeWindow.origin.y = MARGIN_BETWEEN_VIEWPORT;
	//NSLog(@"FocalView...scrollView...frame: X= %f Y= %f W= %f H= %f", wholeWindow.origin.x, wholeWindow.origin.y, wholeWindow.size.width, wholeWindow.size.height);
	// arrange the scroll view location
	// let's have w:h = 4:3
	int unit = (wholeWindow.size.width-MARGIN_BETWEEN_VIEWPORT*2)/4;
	int h = unit*3+MARGIN_BETWEEN_VIEWPORT*2;
	int delta = wholeWindow.size.height - h;
	delta /= 2;
	// center the viewport
	wholeWindow.origin.y = delta;
	wholeWindow.size.height = h;
	scrollView = [[UIScrollView alloc] initWithFrame:wholeWindow];
	[scrollView setBackgroundColor:[UIColor lightGrayColor]];
	// enable scroll view's zooming ability
	[scrollView setMinimumZoomScale:ZOOM_RATE_MIN];
	[scrollView setMaximumZoomScale:ZOOM_RATE_MAX];
	[scrollView setDelegate:self];
	
	// we don'tneed following codes since this scroll view doesn't support paging and the
	// the scroll view willtake care the zooming area by itself 
	//CGRect reallyBigRect;
	//reallyBigRect.origin = wholeWindow.origin;	//CGPointZero;
	//reallyBigRect.size.width = wholeWindow.size.width*ZOOM_RATE_MAX;
	//reallyBigRect.size.height = wholeWindow.size.height*ZOOM_RATE_MAX;	
	//[scrollView setContentSize:reallyBigRect.size];

	// create a viewport on the scroll view
	CGRect ttRect = [scrollView bounds];
	ttRect.size.width -= (MARGIN_BETWEEN_VIEWPORT*2);
	ttRect.size.height -= (MARGIN_BETWEEN_VIEWPORT*2);
	ttRect.origin.x = MARGIN_BETWEEN_VIEWPORT;
	ttRect.origin.y = MARGIN_BETWEEN_VIEWPORT;
	//NSLog(@"FocalView...scrollView...bounds: X= %f Y= %f W= %f H= %f", ttRect.origin.x, ttRect.origin.y, ttRect.size.width, ttRect.size.height);
	//NSLog(@"focalViewController create viewport with tag: %d", [self associatedViewTag]);
	imageView = [Viewport viewportCreationWithLocation:ttRect inLabel:@"Device" assignedIndex:[self associatedViewTag] associatedServer:[self runMode]];
	[[imageView streaming] setDelegate:imageView];
	[imageView doInternalLayout:VIEW_TITLE_BAR_POSITION_NONE];
	[imageView setRunMode:RUN_MODE_FOCAL_PORT];

	[scrollView addSubview:imageView];	
	[[self view] addSubview:scrollView];
	
	// toolbar treatment
	CGRect tbRect;
	tbRect.origin.x = 0;
	tbRect.origin.y = [scrollView bounds].size.height+wholeWindow.origin.y*2;
	tbRect.size.width = [[self view] bounds].size.width;
	tbRect.size.height = FOCAL_VIEW_CONTROL_PANEL_HEIGHT;
	toolBar = [[UIToolbar alloc] init];
	[toolBar setFrame:tbRect];	
	
	UIBarButtonItem *snapshot = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(doSnapshot)];
	[snapshot setStyle:UIBarButtonItemStyleBordered];
	// position the zoomrate button for right edge alignment
	UIBarButtonItem *spaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	zoomRate = [[UIBarButtonItem alloc] initWithTitle:@"Zoom Scale: 1.00" style:UIBarButtonItemStylePlain target:self action:@selector(displayZoomRate)];
	[zoomRate setEnabled:NO];
	
	//UISegmentedControl *button = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Zoom Scale: 1.00", nil]] autorelease];
	//button.momentary = YES;
	//button.segmentedControlStyle = UISegmentedControlStylePlain;
	//button.tintColor = [UIColor colorWithRed:125 green:190 blue:255 alpha:0.0f];	
	//zoomRate = [[UIBarButtonItem alloc] initWithCustomView:button];	
	//[zoomRate setEnabled:YES];
	
	NSArray *items = [NSArray arrayWithObjects:snapshot, spaceBtn, zoomRate, nil];
	[snapshot release];	
	[zoomRate release];
	[spaceBtn release];
	[toolBar setItems:items animated:YES];
	[[self view] addSubview:toolBar];
	
	//donot release these object for low memory warning consideration
	//[toolBar release];
	//toolBar = nil;
	//[scrollView release];
	//scrollView = nil;	
	//[imageView release];
	//imageView = nil;	
}

-(void)viewWillAppear:(BOOL)animated
{
	NSLog(@"FocalViewController...viewWillAppear");
	[super viewWillAppear:animated];
	
	// set the background color to white
	[[[self imageView] layer] performSelectorOnMainThread:@selector(setContents:) withObject:nil waitUntilDone:NO];
	//Viewport *vw = [[self vArray] objectAtIndex:[[self imageView] tag]-1];
	//CALayer* la = [vw layer]; 
	//id cont = la.contents;
	//[[[self imageView] layer] performSelectorOnMainThread:@selector(setContents:) withObject:(id)cont waitUntilDone:NO];		

	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	/*
	//don't use following codes here, it might shortly block the thread processing
	// no network available, do nothing
	int err = [[appDelegate dataCenter] isConnectToNetworkWithMsg:YES];
	if(err == MB_NETWORK_NONE)
		return;		
	*/
	int serverType = [[appDelegate dataCenter] getMobileMode];	
	if(serverType == RUN_SERVER_MODE)
	{
		if([[appDelegate dataCenter] cfgReload] == NO)
		{
			int ttDevice = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
			NSString *str;
			if([self associatedViewTag] > ttDevice)
				str = @"No Device Configured";
			else
			{
				DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self associatedViewTag]-1];
				str = [dev title];
			}
			
			[[self navigationItem] setTitle:str];
			
			[[self imageView] setTag:associatedViewTag];
			[[[self imageView] streaming] setDelegate:[self imageView]];
			[[[self imageView] streaming] setOpTag:[self associatedViewTag]];	
			[imageView resetStreamingStatus];			
			
			[self loadStream];
			goto FocalViewController_viewWillAppear;
			
		}
		
		// server account changed, we need to reload the device list data
		NSError *err = [[appDelegate dataCenter] ConnecttoServer];
		if([err code] == 3)
			[self setCancelMode:YES];
		else
			[self setCancelMode:NO];
		// if something wrong in server, do not retrieve device list
		if(err != nil)
			goto FocalViewController_viewWillAppear;			
	}	
	
	if([self cancelMode] == YES)
		goto FocalViewController_viewWillAppear;
	
	[[appDelegate dataCenter] setCfgReload:NO];
	[self checkReloadRequirement];

  FocalViewController_viewWillAppear:		
	// register as an observer for "NotifySlideThumbnailTreatment" notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(notifySlideThumbnailArrayTreatment:)
												 name:NOTIFICATION_SLIDE_THUMBNAIL_TREATMENT
											   object:nil];	
	
	// register as an observer for "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(notifyStreamingOnOff:)
												 name:NOTIFICATION_LIVEVIEW_ON_OFF
											   object:nil];	
	// tell application delegate that we are on	
	if(appDelegate != nil)
		appDelegate.liveViewON++;
	
	UIApplication *app =  (UIApplication*)[UIApplication sharedApplication];	
	if(app != nil)	
	{
		if([self associatedViewTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
			[app setIdleTimerDisabled:NO];
		else
			[app setIdleTimerDisabled:YES];
	}	
	
}

-(void)viewWillDisappear:(BOOL)animated
{
	NSLog(@"FocalViewController...viewWillDisappear");
	[super viewWillDisappear:animated];
	[self unloadStream];	
	// unregistry the observer role
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_SLIDE_THUMBNAIL_TREATMENT object:nil];

	// unregistry the observer role "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_ON_OFF object:nil];
	
	// tell application delegate that we are on
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate != nil)
		appDelegate.liveViewON--;
	
	UIApplication *app =  (UIApplication*)[UIApplication sharedApplication];	
	if(app != nil)	
		[app setIdleTimerDisabled:NO];		
}

-(void)viewDidUnload
{
	NSLog(@"FocalViewController...viewDidUnload");
	[super viewDidUnload];
	
	// unregistry the observer role
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_SLIDE_THUMBNAIL_TREATMENT object:nil];
	
	// unregistry the observer role "NotifyliveViewOnOff" notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_LIVEVIEW_ON_OFF object:nil];
	
	/*if(scrollView != nil)
	 {
	 NSLog(@"FocalViewController...viewDidUnload...release scrollView");
	 [scrollView release];
	 scrollView = nil;
	 }
	 if(imageView != nil)
	 {
	 NSLog(@"FocalViewController...viewDidUnload...release imageView");
	 [imageView release];
	 imageView = nil;
	 }
	 
	 if(toolBar != nil)
	 {
	 NSLog(@"FocalViewController...viewDidUnload...release toolBar");
	 [toolBar release];
	 toolBar = nil;
	 }*/	
}

-(void)checkReloadRequirement
{	
	BOOL dcAttrChanged = NO;	
	
	// if we use our own dataCenter, use following codes
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	
	int err = [[appDelegate dataCenter] isConnectToNetworkWithMsg:YES];
	if(err == MB_NETWORK_NONE)
		return;	
	
	int serverType = [[appDelegate dataCenter] getMobileMode];
	if(serverType == RUN_SERVER_MODE)
	{
		NSError *errE = [[appDelegate dataCenter] ConnecttoServer];
		// something wrong in server
		if(errE != nil)
			return;
	}
		
	NSMutableArray *deviceArray;
	if(serverType == RUN_SERVER_MODE)
	{
		int count = 0;		
		deviceArray = [[appDelegate dataCenter] GetDeviceListWithRefresh:&dcAttrChanged
																			 withDevType:0
																			 withSubType:1
																	 withRetrievingCount:count];
	}
	else
	{
		deviceArray = [[appDelegate dataCenter] getUserDeviceList];
		// check to see if array object changed. If yes, flush and reproduce the DataCache array
		dcAttrChanged = [self deviceAttrChanged:deviceArray];		
	}
	
	if(dcAttrChanged == YES)
	{		
		[self refreshDeviceList:deviceArray];
	}
	
	// title view
	int ttDevice = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	NSString *str;
	if([self associatedViewTag] > ttDevice)
		str = @"No Configured Device";
	else
	{
		DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self associatedViewTag]-1];
		str = [dev title];
		//nash
		imageAttributesDef attr;
		attr = [[[self imageView] streaming] imageAttributes];
		if([dev playType] == 1)
			attr.codec = IMAGE_CODEC_MPEG4;
		else
			attr.codec = IMAGE_CODEC_MJPEG; // default
		
		[[[self imageView] streaming] setImageAttributes:attr];
	}
	
	[[self navigationItem] setTitle:str];	
	[[self imageView] setTag:associatedViewTag];
	[[[self imageView] streaming] setDelegate:[self imageView]];
	[[[self imageView] streaming] setOpTag:[self associatedViewTag]];	
	//[imageView resetStreamingStatus];	-nash	

	// loading the streams
	[self loadStream];	
	
}

-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
		
	int serverType = [[appDelegate dataCenter] getMobileMode];	
	if(serverType != RUN_P2P_MODE)
		return YES;	// to qaurantee user will update the device list
	
	if([deviceArray count] != [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return YES;
	
	for(int i=0; i<[deviceArray count]; i++)
	{
		UserDefDevice *newObj;
		DeviceData *dev;
		newObj = [deviceArray objectAtIndex:i];
		dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:i];
		
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
			[port release]; // nash leak
			return YES;
		}
		
		[port release];// nash leak

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

-(void)refreshDeviceList:(NSMutableArray*)newDeviceList
{
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
		
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	
	int serverType = [[appDelegate dataCenter] getMobileMode];	
	if(serverType == RUN_P2P_MODE)
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
		
		if(serverType == RUN_SERVER_MODE)
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
		if(serverMode == RUN_SERVER_MODE)
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
		}
		//	
#endif		
		NSString *strIP;
		if(serverType == RUN_SERVER_MODE)
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

-(void)loadStream
{	
	if([self associatedViewTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return;	
	
	// paste the previous imgage(will crash, need to find out the root cause)
	//NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[[self imageView] tag]-1];  
	//UIImage *img = [[ImageCache sharedImageCache] imageForKey:key];
	//[[self imageView] setImage:img];
	// test
	//Viewport *vw = [[self vArray] objectAtIndex:[[self imageView] tag]-1];
	//UIImage *img = [vw image];
	//if(img != nil)
	//	[[self imageView] setImage:img];
	//
	[[imageView streaming] play];
}

-(void)unloadStream
{
	if([self associatedViewTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return;	
	
	[[imageView streaming] stop];
}

// do streaming connection retry if this viewport is in disconnected status
-(void)refresh
{
	if([self cancelMode] == YES)
		[self setCancelMode:NO];
		
	[self checkReloadRequirement];
}
	 
-(void)doSnapshot
{
	NSLog(@"snapshot button pressed.");
	// if no streaming on going, do nothing
	if([[[self imageView] streaming] opStatus] != DEVICE_STATUS_ONLINE)
	{
		NSLog(@"no streaming...do nothing...just return...");
		return;
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Snapshot To Album" otherButtonTitles:nil];
	[actionSheet showFromBarButtonItem:[[toolBar items] objectAtIndex:0] animated:YES];
	[actionSheet release];		
	
}

-(void)displayZoomRate
{
	
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		NSLog(@"FocalViewController: set doSnapshot flag");
		[[[self imageView] streaming] doSnapshot:YES];
	}
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	NSLog(@"snapshot album dialog cancel button pressed.");
}

-(void)showZoomingScale:(float)scale
{
	if([self toolBar] == nil)
		return;
	
	NSLog(@"zooming scale: %f", scale);
	[zoomRate setTitle:[NSString stringWithFormat:@"Zoom Scale: %2.2F", scale]]; 
}

-(void)notifySlideThumbnailArrayTreatment:(NSNotification*)aNote
{
	NSMutableDictionary *dictionary=(NSMutableDictionary*)[aNote userInfo];	
	NSNumber *ptw1=[dictionary valueForKey:KNotifySlideThumbnailTreatment];		
	//NSLog(@"NotifySlideThumbnailTreatment...up(1)...down(0)...: %d",[ptw1 integerValue]);
	
	// sliding thumbnail row treatment 
	if([ptw1 integerValue] == 1)	// show the thumbnail row
	{
		;				
	}
	else	// sink the thumbnail row
	{
		;
	}
}

-(void)notifyStreamingOnOff:(NSNotification*)aNote
{
	NSMutableDictionary *dictionary=(NSMutableDictionary*)[aNote userInfo];	
	NSNumber *ptw1=[dictionary valueForKey:KNotifyLiveViewOnOff];
	
	if([ptw1 integerValue] == 1)
		[self loadStream];
	else if([ptw1 integerValue] == 0)
		[self unloadStream];
}

-(UIView*)viewForZoomingInScrollView:(UIScrollView*)scrollView
{
	//NSLog(@"Enter viewForZoomingInScrollView()...view#: %d...", [[self view] tag]);
	return [self imageView];
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	[self showZoomingScale:scale];
}

-(void)resetZoomRate:(float)rate
{
	[scrollView setZoomScale:rate];
	// update the toolbar
	[self showZoomingScale:rate];
}

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc 
{
	[scrollView release];
	[imageView release];
	//[rightBarButtonItem release];
	//[leftBarButtonItem release];	
	[toolBar release];
	
    [super dealloc];
}


@end
