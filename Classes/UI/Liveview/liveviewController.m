//
//  liveviewController.m
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

#import "liveviewController.h"


@implementation liveviewController

@synthesize cameraButton1,cameraButton2,cameraButton3,cameraButton4;
@synthesize cameraLabel1,cameraLabel2,cameraLabel3,cameraLabel4;
@synthesize cameraView1,cameraView2,cameraView3,cameraView4;
@synthesize focusViewr;
@synthesize playObjArray,indexNum;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	/*random produce data of play Obj array*/
	self.playObjArray = [NSMutableArray array];
	for (int i=0; i<4; i++) 
	{
		NSString *name = [NSString stringWithFormat:@"Device %d",i+1];
		NSString *ip = [NSString stringWithFormat:@"192.168.10.%d",i+1];
		deviceProperties *obj = [[deviceProperties alloc] initWithDeviceName:name 
																	DeviceIP:ip 
																		Type:i
																	   devID:@"123"];
		[self.playObjArray addObject:obj];
		[obj release];
	}
	/*end of produce*/
	
	//set label title
	[self.cameraLabel1 setText:[[self.playObjArray objectAtIndex:0] Name]];
	[self.cameraLabel2 setText:[[self.playObjArray objectAtIndex:1] Name]];
	[self.cameraLabel3 setText:[[self.playObjArray objectAtIndex:2] Name]];
	[self.cameraLabel4 setText:[[self.playObjArray objectAtIndex:3] Name]];
	self.title = @"Live View";
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark ButtonClick
- (IBAction)liveViewButtonClick:(id)object
{
	deviceProperties *deviceobj;
	
	if (object == self.cameraButton1) 
	{
		deviceobj = [self.playObjArray objectAtIndex:0];
		self.indexNum = 0;
	}
	else if (object == self.cameraButton2) 
	{
		deviceobj = [self.playObjArray objectAtIndex:1];
		self.indexNum = 1;
	}
	else if (object == self.cameraButton3) 
	{
		deviceobj = [self.playObjArray objectAtIndex:2];
		self.indexNum = 2;
	}
	else 
	{
		deviceobj = [self.playObjArray objectAtIndex:3];
		self.indexNum = 3;
	}
	if (self.focusViewr == nil) 
	{
		focusView *focusController = [[focusView alloc] initWithNibName:@"focusView" 
																 bundle:nil
														   deviceObject:deviceobj
																  ];
		focusController.delegate = self;
		self.focusViewr = focusController;
	}
	else 
	{
		[self.focusViewr changeDevice:deviceobj];
	}


	[[self navigationController] pushViewController:self.focusViewr animated:YES];
}
#pragma mark -
#pragma mark potocol

- (void)setDeviceArray:(id)deviceObject
{
	[self.playObjArray replaceObjectAtIndex:self.indexNum withObject:deviceObject];
	
	//reload data form array
	//set label title
	[self.cameraLabel1 setText:[[self.playObjArray objectAtIndex:0] Name]];
	[self.cameraLabel2 setText:[[self.playObjArray objectAtIndex:1] Name]];
	[self.cameraLabel3 setText:[[self.playObjArray objectAtIndex:2] Name]];
	[self.cameraLabel4 setText:[[self.playObjArray objectAtIndex:3] Name]];
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
	[cameraButton1 release];
	[cameraButton2 release];
	[cameraButton3 release];
	[cameraButton4 release];
	[cameraLabel1 release];
	[cameraLabel2 release];
	[cameraLabel3 release];
	[cameraLabel4 release];
	[cameraView1 release];
	[cameraView2 release];
	[cameraView3 release];
	[cameraView4 release];
	[focusViewr release];
	[playObjArray release];
    [super dealloc];
}


@end
