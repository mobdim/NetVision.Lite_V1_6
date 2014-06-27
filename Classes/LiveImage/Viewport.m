//
//  Viewport.m
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/13.
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

#import "QuartzCore/QuartzCore.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#import <netinet/in.h>
#import <CFNetwork/CFNetwork.h>

#import "Viewport.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ImageCache.h"
#import "ConstantDef.h"
#import "Base64.h"
#import "TerraUIAppDelegate.h"
#import "NSInvocation+.h"
#import "ModelNames.h"
#import "LiveImageController.h"

@implementation Viewport

@synthesize titleView;
@synthesize title;
@synthesize snapshot;
@synthesize imageRect;
@synthesize titleBarPosition;
@synthesize status;
@synthesize statusView;
@synthesize pantiltView;
@synthesize panTiltTouchedDirection;
@synthesize ptIconONTimeRef;
@synthesize watchdogTimerPTIconOFF;
@synthesize initialLayoutDone;
@synthesize notifyDictionary;
@synthesize runMode;
@synthesize serverMode;
@synthesize slideThumbnailUp;
@synthesize preImageSavingTime;
@synthesize actionIndicator;
@synthesize indicatorCount;
@synthesize streaming;
@synthesize controlLabelsOnOff;
@synthesize streamTerminated;

+(id)viewportCreationWithLocation:(CGRect)location inLabel:(NSString*)title assignedIndex:(NSInteger)index associatedServer:(int)server
{	
	Viewport *newViewport = [[self alloc] initWithFrame:location];
	if(newViewport == nil)
		return nil;
	
	// background color
	[newViewport setBackgroundColor:[UIColor whiteColor]];
	// title
	[newViewport setTitle:title];
	[newViewport setTag:index];
	[newViewport setTitleView:nil];
	// status
	[newViewport setStatusView:nil];	
	[newViewport setStatus:0];
	// pan/tilt array (order:left->top->right->down)
	NSMutableArray* arry = [[NSMutableArray alloc] init];
	[newViewport setPantiltView:arry];
	[arry release];
	
	/*
	for(int i=0; i<PAN_TILT_BUTTON_NUM; i++)
	{
		UIImage *ptImage; UIImageView *view;
		switch(i+1)
		{
			case PAN_TILT_LEFT:
				ptImage = [UIImage imageNamed:@"leftpush.png"];
				break;
			case PAN_TILT_UP:
				ptImage = [UIImage imageNamed:@"uppush.png"];
				break;	
			case PAN_TILT_RIGHT:
				ptImage = [UIImage imageNamed:@"rightpush.png"];
				break;				
			case PAN_TILT_DOWN:
				ptImage = [UIImage imageNamed:@"downpush.png"];
				break;
		}
		
		view = [[UIImageView alloc] initWithImage: ptImage];
		[view setAlpha:0.0f];
		[[newViewport pantiltView] addObject:view];				
		[view release];
		// the [UIImage imageNamed..] had done the autorelease job, thus we don't need
		// to do the release here
		//nash [ptImage release];
		
	}
	*/
	[newViewport setPtIconONTimeRef:0.0f];
	[newViewport setWatchdogTimerPTIconOFF:nil];	
	
	[newViewport setInitialLayoutDone:NO];
	// notification dictionary
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	[newViewport setNotifyDictionary:dictionary];
	[dictionary release];
	// ddefault run mode
	[newViewport setRunMode:RUN_MODE_NON_FOCAL];
	
	// register as an observer for "NotifyViewportPanTilt" notification
	[[NSNotificationCenter defaultCenter] addObserver:newViewport
											 selector:@selector(notifyViewportPanTilt:)
												 name:NOTIFICATION_VIEWPORT_PAN_TILT
											   object:newViewport];	
	[newViewport setSlideThumbnailUp:NO];
	[newViewport setServerMode:server];
	//[newViewport setStreaming:[Streaming initWithTag:[newViewport tag] withMode:server]];
	NSLog(@"nash.............number = %d\n",[[DeviceCache sharedDeviceCache] totalDeviceNumber]);
	
	if([newViewport tag]-1 < [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[newViewport tag]-1]; //nash
		[newViewport setStreaming:[Streaming initWithTag:[newViewport tag] withMode:server withType:[dev playType]]];
	}
	else
		[newViewport setStreaming:[Streaming initWithTag:[newViewport tag] withMode:server withType:0]];
	
	[[newViewport streaming] setDelegate:self];
	// due to viewport's background color, we shouldn't choose white for indicator
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[indicator setHidesWhenStopped:YES];
	[newViewport setActionIndicator:indicator];	
	[indicator release];
	[newViewport setIndicatorCount:0];
	[newViewport setPreImageSavingTime:0];
	
	[newViewport setControlLabelsOnOff:0];
	[newViewport setStreamTerminated:YES];
	//[newViewport setContentMode:UIViewContentModeScaleAspectFit];
	
	return [newViewport autorelease];		
}


-(id)initWithFrame:(CGRect)frame 
{    
    self = [super initWithFrame:frame];
    if (self) 
	{
        // Initialization code.
		[self setTitle:@"Camera"];
		[self setTag:0];
		//[self labelLayout:VIEW_TITLE_BAR_POSITION_BOTTOM];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/


-(void)setNeedsLayout
{
	//if(!initialLayoutDone)
	//{
		[self labelLayout:[self titleBarPosition]];
		[self statusLayout];
		[self pantiltLayout];
		[self indicatorLayout];
	//}	
}


-(void)doInternalLayout:(NSInteger)mode
{
	[self setTitleBarPosition:mode];
	[self setNeedsLayout];
	/*
	if(!initialLayoutDone)
	{
		[self labelLayout:mode];
		[self statusLayout];
		[self pantiltLayout];
	}
	*/
	// enable myself as an touch event observer
	[self setUserInteractionEnabled:YES];
}

-(void)labelLayout:(NSInteger)mode
{
	// place the label on the desired position
	NSLog(@"enter labelLayout...");
	//NSLog(@"Title: %@", title);
	// create the label view object
	if(titleView)
		[titleView removeFromSuperview];
	[self setTitleView:[[UILabel alloc] init]];
	[self setTitleBarPosition:mode];
	CGRect labelR; 
	CGRect location = [self bounds];	
	//NSLog(@"Viewport...bound: X= %f Y= %f W= %f H= %f", location.origin.x, location.origin.y, location.size.width, location.size.height);
	if([self titleBarPosition] == VIEW_TITLE_BAR_POSITION_BOTTOM)
	{
		labelR = CGRectMake(location.origin.x+LABEL_MARGIN,
							location.origin.y+location.size.height-LABEL_HEIGHT,
							location.size.width-LABEL_MARGIN*2, 
							LABEL_HEIGHT);
		[self setImageRect:CGRectMake(location.origin.x+LABEL_MARGIN,
									  location.origin.y,
									  location.size.width-LABEL_MARGIN*2, 
									  location.size.height-LABEL_HEIGHT)];
	}
	else if([self titleBarPosition] == VIEW_TITLE_BAR_POSITION_TOP)
	{
		labelR = CGRectMake(location.origin.x+LABEL_MARGIN,
							location.origin.y+LABEL_MARGIN,
							location.size.width-LABEL_MARGIN*2, 
							LABEL_HEIGHT);
		[self setImageRect:CGRectMake(location.origin.x+LABEL_MARGIN,
									  location.origin.y+LABEL_HEIGHT,
									  location.size.width-LABEL_MARGIN*2, 
									  location.size.height-LABEL_HEIGHT)];		
	}
	else if([self titleBarPosition] == VIEW_TITLE_BAR_POSITION_NONE)
	{
		labelR = CGRectMake(0, 0, 0, 0);
		
	}
	//nash
	else {
		labelR = CGRectMake(0, 0, 0, 0);
			
	}

	//label = [[UILabel alloc] initWithFrame:labelR];	
	[[self titleView] setFrame:labelR];
	//NSLog(@"Label...bound: X= %f Y= %f W= %f H= %f", lR.origin.x, lR.origin.y, lR.size.width, lR.size.height);
	[titleView setText:title];
	[titleView setTextAlignment:UITextAlignmentCenter];
	[titleView setTextColor:[UIColor blackColor]];
	[titleView setBackgroundColor:[UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha: 0.5f]];
		
	if([self tag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		[titleView setHidden:NO];
	else
	{
		if(controlLabelsOnOff & CONTROL_LABEL_VIEWPORT_TITLE)
			[titleView setHidden:NO];
		else
			[titleView setHidden:YES];		
	}
	
	[self addSubview:titleView];
	//[titleView release];
}

-(void)labelOnOff:(BOOL)on
{
	if(on == YES)
	{
		[titleView setHidden:NO];
		controlLabelsOnOff |= CONTROL_LABEL_VIEWPORT_TITLE;
		NSLog(@"viewport label: 1");
	}
	else
	{
		[titleView setHidden:YES];
		controlLabelsOnOff &= ~(CONTROL_LABEL_VIEWPORT_TITLE);
		NSLog(@"viewport label: 0");
	}
	
	
	if([self tag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		[titleView setHidden:NO];	
}

-(void)statusLayout
{
	NSLog(@"enter statusLayout...");
	if(statusView)
		[statusView removeFromSuperview];
	
	CGRect statusR; //UILabel *label;
	CGRect location = [self bounds];	
	
	int h = location.size.height;
	int deltaY = h/STATUS_POSITION_PORTION - STATUS_HEIGHT/2;
	statusR = CGRectMake(location.origin.x+LABEL_MARGIN,
						location.origin.y+deltaY,
						location.size.width-LABEL_MARGIN*2, 
						STATUS_HEIGHT);	
	
	[self setStatusView:[[UILabel alloc] init]];
	[[self statusView] setFrame:statusR];
	[statusView setTextAlignment:UITextAlignmentCenter];
	[statusView setTextColor:[UIColor grayColor]];	
	[statusView setBackgroundColor:[UIColor lightGrayColor]];
	[self showStatus];
	/*
	if(controlLabelsOnOff & CONTROL_LABEL_VIEWPORT_STATUS)
	{
		//[statusView setAlpha:0.7f];
		//nash ui
		NSLog(@"Nash+++++++++++++++++++++++show statusView\n");
		[[NSInvocation invocationWithTarget:statusView selector:@selector(setAlpha:) retainArguments:NO,0.7f] 
		 invokeOnMainThreadWaitUntilDone:YES];
	}
	else
	
		//[statusView setAlpha:0.0f];
	{	//nash ui
	
		NSLog(@"Nash+++++++++++++++++++++++no show statusView\n");
		[[NSInvocation invocationWithTarget:statusView  selector:@selector(setAlpha:) retainArguments:NO,0.0f] 
		 invokeOnMainThreadWaitUntilDone:YES];
	 }
	 */
	controlLabelsOnOff &= ~(CONTROL_LABEL_VIEWPORT_STATUS);
	[self addSubview:statusView];
	//[statusView release];	
}

-(void)pantiltLayout
{
	NSLog(@"enter pantiltLayout...");
	UIImageView *view;	
	// remove old icon views
	if([pantiltView count])
	{
		for(int i=0; i<[pantiltView count]; i++)
		{
			view = [pantiltView objectAtIndex:i];
			[view removeFromSuperview];
		}
		[pantiltView removeAllObjects];
	}
	NSLog(@"enter remove old pantilt viewsdone...");
	// create pan/tilt icon view object
	// pan/tilt array (order:left->top->right->down)
	for(int i=0; i<PAN_TILT_BUTTON_NUM; i++)
	{
		UIImage *ptImage; UIImageView *view;
		switch(i+1)
		{
			case PAN_TILT_LEFT:
				ptImage = [UIImage imageNamed:@"leftpush.png"];
				break;
			case PAN_TILT_UP:
				ptImage = [UIImage imageNamed:@"uppush.png"];
				break;	
			case PAN_TILT_RIGHT:
				ptImage = [UIImage imageNamed:@"rightpush.png"];
				break;				
			case PAN_TILT_DOWN:
				ptImage = [UIImage imageNamed:@"downpush.png"];
				break;
			case PAN_TILT_HOME:
				ptImage = [UIImage imageNamed:@"homepush.png"];				
				break;
		}
		
		view = [[UIImageView alloc] initWithImage: ptImage];
		[view setAlpha:0.0f];
		[[self pantiltView] addObject:view];				
		[view release];
	}	
	
	CGRect location = [self bounds];
	int deltaY = location.size.height/2 - PAN_TILT_BTN_SIDE/2;
	int deltaX = location.size.width/2 - PAN_TILT_BTN_SIDE/2;
	CGRect imageR;
	// left
	imageR = CGRectMake(location.origin.x+PAN_TILT_MARGIN,
						location.origin.y+deltaY,
						PAN_TILT_BTN_SIDE, 
						PAN_TILT_BTN_SIDE);	
	view = [pantiltView objectAtIndex:0];
	[view setFrame:imageR];
	//NSLog(@"pantiltLayout...1...bound: X= %f Y= %f W= %f H= %f", imageR.origin.x, imageR.origin.y, imageR.size.width, imageR.size.height);
	//up
	imageR = CGRectMake(location.origin.x+deltaX,
						location.origin.y+PAN_TILT_MARGIN,
						PAN_TILT_BTN_SIDE, 
						PAN_TILT_BTN_SIDE);	
	view = [pantiltView objectAtIndex:1];
	[view setFrame:imageR];
	//NSLog(@"pantiltLayout...2...bound: X= %f Y= %f W= %f H= %f", imageR.origin.x, imageR.origin.y, imageR.size.width, imageR.size.height);
	
	// right
	imageR = CGRectMake(location.size.width-PAN_TILT_MARGIN-PAN_TILT_BTN_SIDE,
						location.origin.y+deltaY,
						PAN_TILT_BTN_SIDE, 
						PAN_TILT_BTN_SIDE);
	view = [pantiltView objectAtIndex:2];
	[view setFrame:imageR];	
	//NSLog(@"pantiltLayout...3...bound: X= %f Y= %f W= %f H= %f", imageR.origin.x, imageR.origin.y, imageR.size.width, imageR.size.height);
	
	// down
	imageR = CGRectMake(location.origin.x+deltaX,
						location.size.height-PAN_TILT_MARGIN-PAN_TILT_BTN_SIDE,
						PAN_TILT_BTN_SIDE, 
						PAN_TILT_BTN_SIDE);
	view = [pantiltView objectAtIndex:3];
	[view setFrame:imageR];
	//NSLog(@"pantiltLayout...4...bound: X= %f Y= %f W= %f H= %f", imageR.origin.x, imageR.origin.y, imageR.size.width, imageR.size.height);	

	// home
	imageR = CGRectMake(location.origin.x+deltaX,
						location.origin.y+deltaY,
						PAN_TILT_BTN_SIDE, 
						PAN_TILT_BTN_SIDE);
	view = [pantiltView objectAtIndex:4];
	[view setFrame:imageR];
	//NSLog(@"pantiltLayout...5...bound: X= %f Y= %f W= %f H= %f", imageR.origin.x, imageR.origin.y, imageR.size.width, imageR.size.height);	
	
	
	// add the pan/tilt buttons to the the imageView
	for(int i=0; i<PAN_TILT_BUTTON_NUM; i++)
	{
		view = [[self pantiltView] objectAtIndex:i];
		[self addSubview:view];
		//[view release];
	}
	// clear the array
	//[pantiltView removeAllObjects];
}

-(void)indicatorLayout
{
	NSLog(@"enter indicatorLayout...");
	CGRect location = [self bounds];
	int deltaY = location.size.height/2 - INDICATOR_SIDE_WIDTH/2;
	int deltaX = location.size.width/2 - INDICATOR_SIDE_WIDTH/2;
	CGRect indicatorR;;

	indicatorR = CGRectMake(location.origin.x+deltaX,
						location.origin.y+deltaY,
						INDICATOR_SIDE_WIDTH, 
						INDICATOR_SIDE_WIDTH);	
	
	[[self actionIndicator] setFrame:indicatorR];
}


-(void)prepareViewportDisplayModeChange
{
	//[titleView setHidden:YES];
	//[statusView setAlpha:0.0f];
	//nash ui
	[[NSInvocation invocationWithTarget:titleView selector:@selector(setHidden:) retainArguments:NO,YES] 
	 invokeOnMainThreadWaitUntilDone:YES];

	[[NSInvocation invocationWithTarget:statusView selector:@selector(setAlpha:) retainArguments:NO,0.0f] 
	 invokeOnMainThreadWaitUntilDone:YES];

}

-(void)resetStreamingStatus
{
	if([self tag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		[self setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
		[self showStatus];
	}
	else 
	{
		//[self setStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
		//[[self streaming] setOpStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
		[self setStatus:DEVICE_STATUS_STOPPED];
		[[self streaming] setOpStatus:DEVICE_STATUS_STOPPED];		
		[[[self streaming] ffmpeg] setStreamingStatus:STREAM_SESSION_STATUS_STOP];
		[[[self streaming] mjpeg] setStreamingStatus:STREAM_SESSION_STATUS_STOP];
		[self showStatus];
	}	
}

-(BOOL)DeviceReachabilityCheck
{
	int ttNum = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if([self tag] > ttNum)
		return NO;	
	
	NSLog(@"Viewport tag: %d enter DeviceReachabilityCheck...", [[self streaming] opTag]);
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1];
	NSString *ip = [NSString stringWithString:[dev IP]];
	const char *ipChar = [ip UTF8String];
	
	struct sockaddr_in targetAddr;
	bzero(&targetAddr, sizeof(targetAddr));
	targetAddr.sin_len = sizeof(targetAddr);
	targetAddr.sin_family = AF_INET;
	NSLog(@"Viewport tag: %d targetAddr.sin_addr.s_addr 1 ...", [[self streaming] opTag]);
	inet_aton(ipChar, &targetAddr.sin_addr.s_addr);
	NSLog(@"Viewport tag: %d targetAddr.sin_addr.s_addr 2 ...", [[self streaming] opTag]);	
	targetAddr.sin_port = [dev portNum];
	
	
	SCNetworkReachabilityRef val = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *) &targetAddr);
	
	SCNetworkReachabilityFlags reachability;
	SCNetworkReachabilityGetFlags(val, &reachability);
	
	CFRelease(val);
	
	if(reachability & kSCNetworkReachabilityFlagsReachable)
		return YES;
	
	// issue notification of network broken
	[self setStatus:DEVICE_STATUS_DEVICE_NOT_FOUND];
	[self showStatus];
	
	
	return NO;
}

-(void)showActivityIndicator
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	
	NSLog(@"Viewport tag: %d  enter showStatus...", [[self streaming] opTag]);		
	
	//[[self statusView] setAlpha:0.0f];
	// nash ui
	[[NSInvocation invocationWithTarget:[self statusView] selector:@selector(setAlpha:) retainArguments:NO,0.0f] 
	 invokeOnMainThreadWaitUntilDone:YES]; 
	
	// retrieve the status from streaming object
	//NSLog(@"Viewport: get status code: %d...", [self status]);
	//NSLog(@"Viewport: associated streaming opTag: %d...", [[self streaming] opTag]);
	// filter the error message
	NSString *message;
	if(([self status] == DEVICE_STATUS_ONLINE) 
	   || ([self status] == DEVICE_STATUS_NO_DEVICE_ASSOCIATED)	   
	   || ([self status] == DEVICE_STATUS_PREPARE_FOR_ONLINE)
	   || [[self streaming] opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{
		
		controlLabelsOnOff &= ~(CONTROL_LABEL_VIEWPORT_STATUS);
		
		if([[self streaming] opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			[self stopIndicator];
			[[self streaming] setContinuousRetryErrorCount:0];
			return;
		}
		
		if(([self status] == DEVICE_STATUS_PREPARE_FOR_ONLINE) 
		   && (([[[self streaming] mjpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)|| 
		       ([[[self streaming] ffmpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)))//([[[self streaming] ffmpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)) - nash
		{
			NSLog(@"start indicator animating...tag: %d", [[self streaming] opTag]);
			[self startIndicator];
			[self setStreamTerminated:NO];					
		}
		//if([[[self streaming] ffmpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY) - nash
		if([[[self streaming] mjpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY || 
		   [[[self streaming] ffmpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY) 
		{
			//NSLog(@"stop indicator animating...tag: %d", [[self streaming] opTag]);
			[self stopIndicator];
			[[self streaming] setContinuousRetryErrorCount:0];
			[self setStreamTerminated:NO];
		}
		
		goto showActivityIndicator_exit;
	}
	
	if([self status] == DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP)
	{		
		if([[self streaming] continuousRetryErrorCount] > CONNECTION_RETRY_COUNT_MAX)
			[self setStatus:DEVICE_STATUS_STOPPED];
		else
		{
			[self stopIndicator];
			[[self streaming] doStreamingRetry];
			[self setStreamTerminated:NO];
			
			goto showActivityIndicator_exit;
		}
	}
	
	// any abnormal streaming condition will come to this block
	switch([self status])
	{
		case DEVICE_STATUS_OFFLINE:	
		case DEVICE_STATUS_DEVICE_NOT_FOUND:
			message = @"Device not found";
			break;
		case DEVICE_STATUS_AUTHENTICATION_ERROR:
			message = @"Authentication error";
			break;
		case DEVICE_STATUS_SESSION_NOT_AVAILABLE:
			message = @"Device busy";
			break;
		case DEVICE_STATUS_SESSION_FAILURE:			
			message = @"Session error";
			break;			
		case DEVICE_STATUS_BAD_REQUEST:
			message = @"Bad request";
			break;			
		case DEVICE_STATUS_REQUEST_FORBIDDEN:
			message = @"Request forbidden";
			break;			
		case DEVICE_STATUS_SERVER_NO_SERVICE:			
		case DEVICE_STATUS_SERVICE_NOT_FOUND:
			message = @"Service not found";
			break;			
		case DEVICE_STATUS_REQUEST_FORMAT_ERROR:
			message = @"Request syntax error";
			break;			
		case DEVICE_STATUS_REQUEST_TIMEOUT:
		case DEVICE_STATUS_SERVICE_TIMEOUT:
			message = @"Time out";
			break;				
		case DEVICE_STATUS_INTERNAL_SERVER_ERROR:
			message = @"Server error";
			break;				
		case DEVICE_STATUS_HTTP_VERSION_ERROR:			
			message = @"HTTP version error";
			break;			
		case DEVICE_STATUS_POOR_NETWORK_CONDITION:
			message = @"Poor network condition";
			break;
		case DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION:
			message = @"Invalid data";
			break;
		case DEVICE_STATUS_PAUSED:
			message = @"Session paused";
			break;			
		case DEVICE_STATUS_STOPPED:
			message = @"Session teardown";
			break;			
		case DEVICE_STATUS_SOCKET_FAILURE:
			message = @"Socket failure";
			break;
		case DEVICE_STATUS_DEVICE_RESPONSE_ERROR:
			message = @"unrecognizable response";
			break;						
		default:
			message = @"Session failure";
			break;			
	}
	
	//[[self statusView] setText:message];
	//[[self statusView] setAlpha:0.7f];
	// nash ui
	[[self statusView] performSelectorOnMainThread:@selector(setText:)withObject:(id)message waitUntilDone:YES];
	[[NSInvocation invocationWithTarget:[self statusView] selector:@selector(setAlpha:) retainArguments:NO,0.7f] 
	 invokeOnMainThreadWaitUntilDone:YES]; 
	
	controlLabelsOnOff |= CONTROL_LABEL_VIEWPORT_STATUS;
	
	//NSLog(@"stop indicator animating...tag: %d", [[self streaming] opTag]);
	[self stopIndicator];
	[self setStreamTerminated:YES];
	
	
 showActivityIndicator_exit:	
	[pool release];
	
	return;	
}

-(void)showStatus
{
	// test start
	//[NSThread detachNewThreadSelector:@selector(showActivityIndicator) toTarget:self withObject:nil];
	// start end	
	
	NSLog(@"Viewport tag: %d  enter showStatus...", [[self streaming] opTag]);		
	
	//[[self statusView] setAlpha:0.0f];
	// nash ui
	[[NSInvocation invocationWithTarget:[self statusView] selector:@selector(setAlpha:) retainArguments:NO,0.0f] 
	invokeOnMainThreadWaitUntilDone:YES]; 
	
	// retrieve the status from streaming object
	//NSLog(@"Viewport: get status code: %d...", [self status]);
	//NSLog(@"Viewport: associated streaming opTag: %d...", [[self streaming] opTag]);
	// filter the error message
	NSString *message;
	if(([self status] == DEVICE_STATUS_ONLINE) 
	   || ([self status] == DEVICE_STATUS_NO_DEVICE_ASSOCIATED)	   
	   || ([self status] == DEVICE_STATUS_PREPARE_FOR_ONLINE)
	   || [[self streaming] opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
	{

		controlLabelsOnOff &= ~(CONTROL_LABEL_VIEWPORT_STATUS);
		
		if([[self streaming] opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			[self stopIndicator];
			[[self streaming] setContinuousRetryErrorCount:0];
			return;
		}

		if(([self status] == DEVICE_STATUS_PREPARE_FOR_ONLINE) 
		   && (([[[self streaming] mjpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)|| 
		       ([[[self streaming] ffmpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)))//([[[self streaming] ffmpeg] streamingStatus] != STREAM_SESSION_STATUS_PLAY)) - nash
		{
			//NSLog(@"start indicator animating...tag: %d", [[self streaming] opTag]);
			[self startIndicator];
			[self setStreamTerminated:NO];					
		}
		//if([[[self streaming] ffmpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY) - nash
		if([[[self streaming] mjpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY || 
		   [[[self streaming] ffmpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY) 
		{
			//NSLog(@"stop indicator animating...tag: %d", [[self streaming] opTag]);
			[self stopIndicator];
			[[self streaming] setContinuousRetryErrorCount:0];
			[self setStreamTerminated:NO];
		}
		
		return;
	}
	
	if([self status] == DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP)
	{		
		if([[self streaming] continuousRetryErrorCount] > CONNECTION_RETRY_COUNT_MAX)
			[self setStatus:DEVICE_STATUS_STOPPED];
		else
		{
			[self stopIndicator];
			[[self streaming] doStreamingRetry];
			[self setStreamTerminated:NO];
			
			return;
		}
	}
	
	// any abnormal streaming condition will come to this block
	switch([self status])
	{
		case DEVICE_STATUS_OFFLINE:			
			message = @"Device not found";
			break;
		case DEVICE_STATUS_AUTHENTICATION_ERROR:
			message = @"Authentication error";
			break;
		case DEVICE_STATUS_SESSION_NOT_AVAILABLE:
			message = @"Device busy";
			break;
		case DEVICE_STATUS_SESSION_FAILURE:			
			message = @"Session error";
			break;			
		case DEVICE_STATUS_BAD_REQUEST:
			message = @"Bad request";
			break;			
		case DEVICE_STATUS_REQUEST_FORBIDDEN:
			message = @"Request forbidden";
			break;			
		case DEVICE_STATUS_SERVER_NO_SERVICE:			
		case DEVICE_STATUS_SERVICE_NOT_FOUND:
			message = @"Service not found";
			break;			
		case DEVICE_STATUS_REQUEST_FORMAT_ERROR:
			message = @"Request syntax error";
			break;			
		case DEVICE_STATUS_REQUEST_TIMEOUT:
		case DEVICE_STATUS_SERVICE_TIMEOUT:
			message = @"Time out";
			break;				
		case DEVICE_STATUS_INTERNAL_SERVER_ERROR:
			message = @"Server error";
			break;				
		case DEVICE_STATUS_HTTP_VERSION_ERROR:			
			message = @"HTTP version error";
			break;			
		case DEVICE_STATUS_POOR_NETWORK_CONDITION:
			message = @"Poor network condition";
			break;
		case DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION:
			message = @"Invalid data";
			break;
		case DEVICE_STATUS_PAUSED:
			message = @"Session paused";
			break;			
		case DEVICE_STATUS_STOPPED:
			message = @"Session teardown";
			break;			
		case DEVICE_STATUS_SOCKET_FAILURE:
			message = @"Socket failure";
			break;
		case DEVICE_STATUS_DEVICE_RESPONSE_ERROR:
			message = @"unrecognizable response";
			break;					
		default:
			message = @"Session failure.";
			break;			
	}
	
	//[[self statusView] setText:message];
	//[[self statusView] setAlpha:0.7f];
	// nash ui
	[[self statusView] performSelectorOnMainThread:@selector(setText:)withObject:(id)message waitUntilDone:YES];
	[[NSInvocation invocationWithTarget:[self statusView] selector:@selector(setAlpha:) retainArguments:NO,0.7f] 
	 invokeOnMainThreadWaitUntilDone:YES]; 
	
	controlLabelsOnOff |= CONTROL_LABEL_VIEWPORT_STATUS;
	
	//NSLog(@"stop indicator animating...tag: %d", [[self streaming] opTag]);
	[self stopIndicator];
	[self setStreamTerminated:YES];

}

-(void)startIndicator
{
	[self addSubview:[self actionIndicator]];
	//NSLog(@"really start indicator...tag: %d", [[self streaming] opTag]);
	//[[self actionIndicator] startAnimating];
	[[self actionIndicator] performSelectorOnMainThread:@selector(startAnimating)withObject:nil waitUntilDone:YES];
	indicatorCount++;
}

-(void)stopIndicator
{
	if(indicatorCount > 0)
	{
		//[[self actionIndicator] stopAnimating];
		//[[self actionIndicator] removeFromSuperview];
		[[self actionIndicator] performSelectorOnMainThread:@selector(stopAnimating)withObject:nil waitUntilDone:YES];
		[[self actionIndicator] performSelectorOnMainThread:@selector(removeFromSuperview)withObject:nil waitUntilDone:YES];
		indicatorCount--;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"Viewport...touchBegin...");	
	
	if([self runMode] == RUN_MODE_NON_FOCAL)
	{
		;
	}
	else if([self runMode] == RUN_MODE_FOCAL_PORT)
	{
		NSSet *allTouches = [event allTouches];
		DeviceData *dev;
		switch ([allTouches count]) 
		{
			case 1: 
			{ //Single touch
				
				//Get the first touch.
				UITouch *touch = [[allTouches allObjects] objectAtIndex:0];				
				switch ([touch tapCount])
				{												
					case 1: //Single Tap.
					{
						// if the device has no PT, do nothing
						dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1];
						if(!([dev extensionFeatures] & DEVICE_EXTENSION_PT) && !([dev extensionFeatures] & DEVICE_EXTENSION_RS485))
							goto ViewportTouchedNoPanTiltButtonTapped;
						
						CGPoint location = [touch locationInView:self];
						int i =0;
						for(i; i<PAN_TILT_BUTTON_NUM; i++)
						{
							//NSLog(@"viewport...pt: %d", i+1);
							UIImageView *ptView = [[self pantiltView] objectAtIndex:i];
							CGRect rect = [ptView frame];
							//NSLog(@"PT...%d bound: X= %f Y= %f W= %f H= %f", i+1, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
							if(CGRectContainsPoint(rect, location)) 
							{
								NSLog(@"viewport...pt: %d", i+1);
								[self setPanTiltTouchedDirection:(i+1)];
								[[pantiltView objectAtIndex:i] setAlpha:0.25f];
								[self createIconOffTimer];
								goto touchBeginExit;
							}
						}
						
					ViewportTouchedNoPanTiltButtonTapped:	
						// no pan/tilt button tapped
						[self setPanTiltTouchedDirection:0];
						// call up the slide thumbnail
						[self setSlideThumbnailUp:![self slideThumbnailUp]];
					} 
						break;
					case 2: 
					{//Double tap. 
						
						//Track the initial distance between two fingers.
						if([allTouches count]>=2)
						{
							;
							//UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
							//UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
							
							//int initialDistance = [self distanceBetweenTwoPoints:[touch1 locationInView:self] 
							//										 toPoint:[touch2 locationInView:self]];
						}
					}
						break;
				}
			} 
				break;
			case 2: 
			{ //Double Touch
				
			} 
				break;
			default:
				break;
		}																									
	}
	
  touchBeginExit:
	return;
	
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self runMode] == RUN_MODE_NON_FOCAL)
	{
		NSLog(@"Viewport withtag: %d touched.", [self tag]);
		NSNumber *pInx = [[NSNumber alloc] initWithInt:[self tag]];		
		[notifyDictionary setObject: pInx forKey: KNotifyTag];
		[pInx release];
		
		NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
		[note postNotificationName:NOTIFICATION_VIEWPORT_TOUCHED object:self userInfo:notifyDictionary];
	}		
	else if([self runMode] == RUN_MODE_FOCAL_PORT)
	{
		// issue the pan/tilt notification if necessary
		if([self panTiltTouchedDirection] > 0)
		{
			if([self panTiltTouchedDirection] > PAN_TILT_HOME)
				return;
			
			NSLog(@"issue pan/tile notification: %d", [self panTiltTouchedDirection]);			
			NSNumber *ptw = [[NSNumber alloc] initWithInt:[self panTiltTouchedDirection]];		
			[notifyDictionary setObject: ptw forKey: KNotifyPanTilt];
			[ptw release];		
			NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
			[note postNotificationName:NOTIFICATION_VIEWPORT_PAN_TILT object:self userInfo:notifyDictionary];		
		}
		else	// do the sliding thumbnail array rising/sinking treatment
		{
			int num;
			if([self slideThumbnailUp] == YES)
				num = 1;
			else
				num = 0;
			
			//NSLog(@"issue slide thumbnail treatment notification: %d", num);						
			NSNumber *ptw = [[NSNumber alloc] initWithInt:num];		
			[notifyDictionary setObject: ptw forKey: KNotifySlideThumbnailTreatment];
			[ptw release];		
			NSNotificationCenter *note = [NSNotificationCenter defaultCenter];
			[note postNotificationName:NOTIFICATION_SLIDE_THUMBNAIL_TREATMENT object:self userInfo:notifyDictionary];		
		}
	}
	
}

-(void)asyncHttpsRequest:(NSString *)inUrl 
{

	NSLog(@"asyncHttpsRequest : %@",inUrl);
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	
	if(appDelegate == nil)
		return;	
	

	NSURL *url = [NSURL URLWithString:inUrl];	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];	
	if(request == nil)
		return;
	
	[request setTimeoutInterval:PROTOCOL_REQUEST_TIMEOUT];	// timeout: 20 sec. the iOS default is 60 sec.
	[request setURL:url];
	
	//NSLog(@"user name:%@ user token:%@",[appDelegate.dataCenter m_userName],[appDelegate.dataCenter m_userToken]);
	NSString *strCookie = [NSString stringWithFormat:@"user_name=%@; user_token=%@;", 
						   [appDelegate.dataCenter m_userName],
						   [appDelegate.dataCenter m_userToken]];	
	[request setValue:strCookie forHTTPHeaderField:@"Cookie"];
	NSLog(@"Cookie : %@",strCookie);
		
	NSURLConnection *tmpCon = [NSURLConnection connectionWithRequest:request delegate:nil];
	if(tmpCon == nil)
		return;
	
	[tmpCon start];

}


-(void)notifyViewportPanTilt:(NSNotification*)aNote
{
	// if the notification not comes from myself, do nothing
	if(self != [aNote object])
		return;
	
	NSMutableDictionary *dictionary=(NSMutableDictionary*)[aNote userInfo];	
	NSNumber *ptw1=[dictionary valueForKey:KNotifyPanTilt];
	int ptDirection = [ptw1 integerValue];
	NSLog(@"NotifyViewportPanTilt direction: %d",ptDirection);	
	
	// if no reachable device, do nothing
	if([self tag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		return;	
	
	// do the pan/tilt
	BOOL ptModels = YES;
#ifdef P2P_MODE
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1];
	int ext = [dev extensionFeatures];
	ptModels = ext & DEVICE_EXTENSION_PT;
#endif	
	NSString *camCommand;
	switch(ptDirection)
	{
		case PAN_TILT_LEFT:
			if(ptModels)
				camCommand = @"/pt/ptctrl.cgi?mv=L,10";
			else
				camCommand = @"/pt/ptctrl.cgi?cmd=L,10";
			break;
		case PAN_TILT_UP:
			if(ptModels)
				camCommand = @"/pt/ptctrl.cgi?mv=U,10";
			else
				camCommand = @"/pt/ptctrl.cgi?cmd=U,10";
			break;
		case PAN_TILT_RIGHT:
			if(ptModels)
				camCommand = @"/pt/ptctrl.cgi?mv=R,10";
			else
				camCommand = @"/pt/ptctrl.cgi?cmd=R,10";
			break;	
		case PAN_TILT_DOWN:
			if(ptModels)
				camCommand = @"/pt/ptctrl.cgi?mv=D,10";
			else
				camCommand = @"/pt/ptctrl.cgi?cmd=D,10";
			break;	
		case PAN_TILT_HOME:
			if(ptModels)
				camCommand = @"/pt/ptctrl.cgi?preset=move,103";	
			else
				camCommand = @"/pt/ptctrl.cgi?cmd=set_home";
			break;			
	}
	
	NSLog(@"P/T command: %@", camCommand);
	
	// retrieve the required url/cgi info from the associated DeviceData object
	NSString *serverIP, *actionURL; int serverPort = 80; 	 
	if([self serverMode] == RUN_SERVER_MODE) 
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
	{
		serverIP = [NSString stringWithString:[[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] IP]];
		serverPort = [[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] portNum];
		actionURL = [NSString stringWithFormat:@"http://%@:%@@%@:%d%@",
												[[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] authenticationName],
												[[[DeviceCache sharedDeviceCache] deviceAtIndex:[self tag]-1] authenticationPassword],
												serverIP, 
												serverPort, 
												camCommand];
	}
	[self asyncHttpsRequest:actionURL];		

}

-(void)createIconOffTimer
{
	// if timer not created, create it
	if([self watchdogTimerPTIconOFF] == nil)
	{
		
		watchdogTimerPTIconOFF = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(ptIconMonitor:) userInfo:nil repeats:YES];	
		if(watchdogTimerPTIconOFF)
		{
			[self setPtIconONTimeRef:CACurrentMediaTime()];
			NSLog(@"start watchDogTimerForPTIconMonitor...");
			//[self setPtIconONTimeRef:av_gettime()];
			//[self showCurrentTime:@"start watchDogTimerForPTIconMonitor..."];
		}		
	}
	// otherwise, refresh the reference time
	else
		[self setPtIconONTimeRef:CACurrentMediaTime()];		
}

-(void)ptIconMonitor:(NSTimer*)timer
{ 
	if(CACurrentMediaTime()-[self ptIconONTimeRef] >= TIME_PERIOD_MAX_PT_ICON_ON)
	{
		for(int i=0;i<PAN_TILT_BUTTON_NUM; i++)
			[[pantiltView objectAtIndex:i] setAlpha:0.0f];
		
		[[self watchdogTimerPTIconOFF] invalidate];
		[self setWatchdogTimerPTIconOFF:nil];
		NSLog(@"kill watchDogTimerForPTIconMonitor...");
	}
}

-(void)updateViewportSnapshot:(UIImage*)img
{
	// if we keep to update the image in ImageCache, do it.
	// check if timer up to update the image. If yes, update the image
	// for the associated image cache object;otherwise, do nothing
	if(img == nil)
		return;
	
	//NSLog(@"enter updateViewportSnapshot...");
	[img retain];
	double t = CACurrentMediaTime();
	if(t-[self preImageSavingTime] >= TIME_PERIOD_IMAGE_SAVING)
	{
		//NSLog(@"enter updateViewportSnapshot...");
		NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[self tag]-1];  
		[[ImageCache sharedImageCache] setImage:img forKey:key];
		[self setPreImageSavingTime:t];
	}
	
	[img release];
}

-(void)clean
{
	[[self layer] performSelectorOnMainThread:@selector(setContents:) withObject:nil waitUntilDone:NO];
	[self setStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
	[self showStatus];
	[self setTitle:@""];
	[[self titleView] setText:title];
	[[self titleView] setHidden:YES];
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_VIEWPORT_PAN_TILT object:self];	
	
	[titleView release];
	[statusView release];
	if([pantiltView count])
		[pantiltView removeAllObjects];
	[pantiltView release];
	[notifyDictionary release];
	[streaming release];
	[actionIndicator release];
	
    [super dealloc];
}


#pragma mark StreamingProtocol methods
-(void)feedNewImage:(Streaming*)streamingObj newImage:(UIImage*)img
{
	if(streamingObj != [self streaming])
		return;	
	
	// we had better retain the image since we don't know how the streaming object
	// will treat the image after the passing
	//NSLog(@"Viewport: feedNewImage...");
	// nash
	//[img retain];
	//[self setImage:img];
	
	if(img != nil)
	{
		//NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
		[[self layer] performSelectorOnMainThread:@selector(setContents:) withObject:(id)img.CGImage waitUntilDone:NO];
		//double t = CACurrentMediaTime();
		//if(t-[self preImageSavingTime] >= TIME_PERIOD_IMAGE_SAVING)
		//{
		//	NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[self tag]-1];  
		//	[[ImageCache sharedImageCache] setImage:img forKey:key];
		//	[self setPreImageSavingTime:t];
		//}		
		//[apool release];
	}
	
	// if we keep to update the image in ImageCache, do it.
	// check if timer up to update the image. If yes, update the image
	// for the associated image cache object;otherwise, do nothing
	//double t = CACurrentMediaTime();
	//if(t-[self preImageSavingTime] >= TIME_PERIOD_IMAGE_SAVING)
	//{
	//	NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[self tag]-1];  
	//	[[ImageCache sharedImageCache] setImage:img forKey:key];
	//	[self setPreImageSavingTime:t];
	//}	 
}

-(BOOL)isFocalMode:(Streaming*)streamingObj
{
	if(streamingObj != [self streaming])
		return NO;	
	
	return [self runMode] == RUN_MODE_FOCAL_PORT;	
}

-(void)streamingStatusChanged:(Streaming*)streamingObj code:(int)code
{
	//NSLog(@"Viewport: enter streamingStatusChanged...");
	if(streamingObj != [self streaming])
		return;
	
	//NSLog(@"Viewport: set status code from streaming object...code: %d", code);
	[self setStatus:code];
	[self showStatus];
}

@end
