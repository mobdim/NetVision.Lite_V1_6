//
//  TerraUIAppDelegate.m
//  TerraUI
//
//  Created by Shell on 2011/1/6.
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

#import "TerraUIAppDelegate.h"
// Jonathan added
#import "ConstantDef.h"
#import "LiveImageController.h"
#import "FocalViewController.h"
#import "DeviceDetailViewController.h"
#import "DeviceListController.h"
#import "Viewport.h"
#import "Streaming.h"

@implementation TerraUIAppDelegate 

@synthesize window;
@synthesize logoView;
@synthesize tabBarController;
@synthesize playbackNAVController,liveviewController,eventController,P2PconfigureController;
//@synthesize playbackNAVController,LiveImageController,eventController,P2PconfigureController;
@synthesize loginViewer;
@synthesize demoUIMode;
@synthesize dataCenter;
// Jonathan added
@synthesize liveViewON;
@synthesize notifyDictionary;
@synthesize LiveVw;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
	[application setIdleTimerDisabled:NO];
	//Sever Information and User Account:initialize defaults
	NSString *dateKey = @"dateKey";
	NSDate *lastRead = (NSDate*)[[NSUserDefaults standardUserDefaults] objectForKey:dateKey];
	if (lastRead == nil) 
	{
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], dateKey ,nil];
		//set a default value
		[[NSUserDefaults standardUserDefaults] setObject:@"demo" forKey:@"UserName"];
		[[NSUserDefaults standardUserDefaults] setObject:@"demo" forKey:@"Password"];
		[[NSUserDefaults standardUserDefaults] setObject:@"portal.sercomm.com" forKey:@"ServerIP"];
		[[NSUserDefaults standardUserDefaults] setInteger:80 forKey:@"Port"];
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"Protocol"];//0:HTTP 1:HTTPS
		//P2P MODE configuration
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"UserDeviceList"];
		//sync the defaults to disk
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:dateKey];
	
	//setting datacenter 
	self.dataCenter = [[DataCenter alloc] init];
	[self.dataCenter Initialization];
	
	//add logo view 
	/*
	[self.window addSubview:self.logoView];		
	[NSTimer scheduledTimerWithTimeInterval:1
									 target:self 
								   selector:@selector(switchtoP2P) 
								   userInfo:nil 
									repeats:NO];
	*/
	
    [self.window makeKeyAndVisible];
	[self switchtoP2P];

	// Jonathan added	
	[self setLiveViewON:0];
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	[self setNotifyDictionary:dictionary];
	[dictionary release];	
	
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	// Jonathan added
	NSLog(@"applicationDidEnterBackground...");
	
	// if we are in live view page, let's terminate the streaming
	if([self liveViewON] > 0)
	{
		NSNumber *ptw = [[NSNumber alloc] initWithInt:0];		
		[notifyDictionary setObject: ptw forKey: KNotifyLiveViewOnOff];
		[ptw release];		
		NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
		[note postNotificationName:NOTIFICATION_LIVEVIEW_ON_OFF object:self userInfo:notifyDictionary];	
	}		
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	// Jonathan added
	NSLog(@"applicationDidBecomeActive...");
	
	// if we are previously in live view page, let's start the streaming
	if([self liveViewON] > 0)
	{
		NSLog(@"issue liveView should ON notification: %d", 1);			
		NSNumber *ptw = [[NSNumber alloc] initWithInt:1];		
		[notifyDictionary setObject: ptw forKey: KNotifyLiveViewOnOff];
		[ptw release];		
		NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
		[note postNotificationName:NOTIFICATION_LIVEVIEW_ON_OFF object:self userInfo:notifyDictionary];				
	}		
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	// Jonathan added
	// if we are in live view page, let's terminate the streaming
	if([self liveViewON] > 0)
	{
		NSNumber *ptw = [[NSNumber alloc] initWithInt:0];		
		[notifyDictionary setObject: ptw forKey: KNotifyLiveViewOnOff];
		[ptw release];		
		NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
		[note postNotificationName:NOTIFICATION_LIVEVIEW_ON_OFF object:self userInfo:notifyDictionary];	
	}	
	exit(0);	
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods


// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)_tabBarController didSelectViewController:(UIViewController *)viewController 
{
	NSInteger indexofTab = [_tabBarController.viewControllers indexOfObject:viewController];
	if (indexofTab >= 4) 
	{
		[_tabBarController.moreNavigationController popToRootViewControllerAnimated:NO];
	}
	if ([viewController isKindOfClass:[UINavigationController class]]) 
	{
		// make sure this is not a subview of LiveImageController
		UIViewController *vw = [(UINavigationController*)viewController topViewController];
		if([vw isKindOfClass:[LiveImageController class]]
		   || [vw isKindOfClass:[FocalViewController class]] 
		   || [vw isKindOfClass:[DeviceListController class]]
		   || [vw isKindOfClass:[DeviceDetailViewController class]])
			return;
		
		// if not the subview of LiveImageController, pop the root view controller				
		[(UINavigationController*)viewController popToRootViewControllerAnimated:NO];
	}
}

static UIViewController *save_viewController;

-(void)waitLive
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(!LiveVw && [[LiveVw viewportArray] count] <= 0)
		goto SwitchTab;
	
	int viewportCountPerPage = LiveVw.viewportPerPage.row*LiveVw.viewportPerPage.column;	
	
	int start = [LiveVw curPage]*viewportCountPerPage;
	int end = ([LiveVw curPage]+1)*viewportCountPerPage;		
	
	
	//safe stop - nash
	int wait = 100;
	[LiveVw unloadStreams:NO];
	[LiveVw resetStreamingStatus];	
	while(wait--)
	{
		int ok = 1;
		for(int i=start; i<end; i++)
		{
			if([[[[[LiveVw viewportArray] objectAtIndex:i] streaming] mjpeg] stream_t] != NULL)
			{
				if(![[[[[[LiveVw viewportArray] objectAtIndex:i] streaming] mjpeg] stream_t] isFinished])
				{
					//NSLog(@"wait close!\n");
					ok = 0;
					break;
				}
			}
			if(!ok)
				break;
			if([[[[[LiveVw viewportArray] objectAtIndex:i] streaming] ffmpeg] stream_t] != NULL)
			{
				if(![[[[[[LiveVw viewportArray] objectAtIndex:i] streaming] ffmpeg] stream_t] isFinished])
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
	
	
SwitchTab:	
	
	[[LiveVw loadingView].view removeFromSuperview];
	[[[LiveVw loadingView] label] setText:@"Loading"];
	self.tabBarController.selectedViewController = save_viewController;
	[pool release];
}

- (BOOL)tabBarController:(UITabBarController *)_tabBarController shouldSelectViewController:(UIViewController *)viewController
{
	UIViewController *select_viewController = [_tabBarController selectedViewController];
	
	if(![select_viewController isKindOfClass:[UINavigationController class]])
		return YES;
	
	UIViewController *vw = [(UINavigationController*)select_viewController topViewController];
	if([vw isKindOfClass:[LiveImageController class]])
	{
		NSLog(@"Out of Live view!\n");
		
		[[[LiveVw loadingView] label] setText:@"Waiting"];
		
		save_viewController = viewController;
		[[LiveVw loadingView] showLoadingView:LiveVw.navigationController];
		[NSThread detachNewThreadSelector:@selector(waitLive) toTarget:self withObject:self];
		return NO;
	}
	return YES;
	
	
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/
#pragma mark -
#pragma mark viewControl

-(void)switchtoLoginView:(NSTimer*)timer
{
	[[self logoView] removeFromSuperview];
	if (self.loginViewer == nil) 
	{
		loginView *viewer = [[loginView alloc] initWithNibName:@"loginView" bundle:nil];
		self.loginViewer = viewer;
		
	}
	[self.window addSubview:self.loginViewer.view];
}

-(void)switchtoP2P {
	//set ui demo mode
	self.demoUIMode = NO;
	//[self.logoView removeFromSuperview];	
	[self.window addSubview:tabBarController.view];
	
	
	/*
	protocolType protocol = HTTP;
	//set server info
	if (!UImode) 
	{
		[self.dataCenter SetCMSServerInfo:ip 
								 withPort:[Port intValue] 
							 withUsername:Account
							 withPassword:Password 
							 withProtocol:protocol];
	}
	*/
	
	
}


-(void)switchtoTabView:(BOOL)UImode account:(NSString*)Account password:(NSString*)Password IP:(NSString*)ip port:(NSString*)Port
{
	//set ui demo mode
	self.demoUIMode = UImode;
	[self.loginViewer.view removeFromSuperview];	
	[self.window addSubview:tabBarController.view];
	
	protocolType protocol = HTTP;
	//set server info
	if (!UImode) 
	{
		[self.dataCenter SetCMSServerInfo:ip 
								 withPort:[Port intValue] 
							 withUsername:Account
							 withPassword:Password 
							 withProtocol:protocol];
	}
	
	
	
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[logoView release];
	[P2PconfigureController release];
	[playbackNAVController release];
	[liveviewController release];
	//[LiveImageController release];
	[eventController release];
    [tabBarController release];
	[dataCenter release];
    [window release];
	// Jonathan added
	[notifyDictionary release];
	
    [super dealloc];
}

@end

