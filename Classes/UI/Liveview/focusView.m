//
//  focusView.m
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

#import "focusView.h"


@implementation focusView

@synthesize cameraNameLabel;
@synthesize selectDeviceBtn;
@synthesize deviceListView;
@synthesize deviceObj;
@synthesize delegate;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil deviceObject:(id)obj
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		//set current deviceObj
		self.deviceObj=obj;
    }
    return self;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[[self navigationItem] setTitle:@"LiveView"];
	[[self navigationItem] setRightBarButtonItem:self.selectDeviceBtn];
	[self.cameraNameLabel setText:[self.deviceObj Name]];
    [super viewDidLoad];
	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
#pragma mark -
#pragma mark button action
- (IBAction)selectDeviceBtn:(id)object
{
	if (self.deviceListView == nil) 
	{
		deviceListTableView *deviceListViewer = [[deviceListTableView alloc] initWithNibName:@"deviceListTableView" 
																					  bundle:nil
																				  singleMode:YES ];
		deviceListViewer.delegate =self;
		self.deviceListView = deviceListViewer;
	}
	//set selected device
	NSMutableArray *deviceData = [NSMutableArray array];
	[deviceData addObject:self.deviceObj];
	[[self navigationController] pushViewController:deviceListView animated:YES];
	[self.deviceListView setSelectedDeviceList:deviceData];
}

#pragma mark -
#pragma mark deviceListTableView protocol
- (void)setSelectedDevice:(NSMutableArray*)selectedDevice
{
	self.deviceObj = [selectedDevice objectAtIndex:0];
	//set device name label
	NSString *devName = [self.deviceObj Name];
	[self.cameraNameLabel setText:devName];
	//change liveViewController setting
	[self.delegate setDeviceArray:self.deviceObj];
	
}

#pragma mark -
#pragma mark setting
- (void)changeDevice:(id)obj
{
	[self setDeviceObj:obj];
	[self.cameraNameLabel setText:[self.deviceObj Name]];
}

#pragma mark -
#pragma mark unload
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[cameraNameLabel release];
	[selectDeviceBtn release];
	[deviceListView release];
	[deviceObj release];
    [super dealloc];
}


@end
