//
//  deviceListTableView.m
//  TerraUI
//
//  Created by Shell on 2011/1/12.
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

#import "deviceListTableView.h"


@implementation deviceListTableView

@synthesize deviceListArray;
@synthesize delegate;
@synthesize singleMode;
@synthesize loadingView,errorDataNumber;

@class deviceProperties;
#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil singleMode:(BOOL)mode
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		self.singleMode = mode;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	//produce device info
	
	self.deviceListArray = [NSMutableArray array];
}
//transfrom selectDeviceList into deviceListArray data
- (void)setSelectedDeviceList:(NSMutableArray*)selectedDeviceListName
{
	for (id currentObjs in self.deviceListArray) 
		for (id object in selectedDeviceListName)
		{
			Boolean status = [[currentObjs Name] isEqual:[object Name]];
			[currentObjs setSelectStatus:status];
			if (status)
				break;
		}
	[self.tableView reloadData];
}
//end of setSelectedDeviceList


- (void)viewWillAppear:(BOOL)animated 
{	
	[self.tableView setContentOffset:CGPointMake(0, 0)] ;//scroll to top
	self.loadingView = [[loading alloc] initWithNibName:@"loading" bundle:nil];
	[self.loadingView showLoadingView:self.navigationController];
	self.tableView.scrollEnabled = NO;
	
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	//clear device List before
	[self.deviceListArray removeAllObjects];
	//query device list
	self.deviceListArray = [self queryDeviceList];
	[self.tableView reloadData];
	//remove loadView
	[self.loadingView.view removeFromSuperview];
	
    [super viewDidAppear:animated];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
#pragma mark - Query
- (NSMutableArray*)queryDeviceList
{
	NSMutableArray *devArray = [NSMutableArray array];
	// 1. dummy count
	// 2. return real count
	int count = 0;
	NSMutableArray *deviceArray ;//= [[NSMutableArray alloc] init];
	
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	//connect to server
	[appDelegate.dataCenter ConnecttoServer];
	deviceArray = [[appDelegate dataCenter] GetDeviceList:0 
								withSubType:1 
						withRetrievingCount:count];
	
	checkData *check = [[checkData alloc] init];
	for (int i = 0 ; i<[deviceArray count]; i++) 	
	{
		DeviceInfo *device_info = [deviceArray objectAtIndex:i];
		
		//check ip address and return number of wrong data
		NSArray *ipAddressArray = [[device_info internal] componentsSeparatedByString:@":"];//get ip address
		if ([check checkIPAddress:[ipAddressArray objectAtIndex:0]] == NO)
		{
			//NSLog(@"IP Address Error");
			continue;
		}
		
		deviceProperties *deviceData = [[deviceProperties alloc] initWithDeviceName:[device_info name] 
																		   DeviceIP:[ipAddressArray objectAtIndex:0] 
																			   Type:1
																			  devID:[device_info ID]];
		[devArray addObject:deviceData];
		[deviceData release];
	}

	//compute error number
	self.errorDataNumber = [deviceArray count]-[devArray count];
	//[deviceArray release];
	
	[check release];
	return devArray;
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.deviceListArray count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"deviceListCell";
    
    deviceListCellStyle *cell = (deviceListCellStyle*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"deviceListCellStyle" owner:nil options:nil];
		for ( id currentObj in nibObjs)
		{
			if ([currentObj isKindOfClass:[deviceListCellStyle class]]) 
			{
				cell = (deviceListCellStyle *)currentObj;
			}
		}
    }
    
    // Configure the cell...
	NSInteger row = [indexPath row];//get row number
	deviceProperties *currentDevice = [self.deviceListArray objectAtIndex:row];
	[[cell deviceName] setText:[currentDevice Name]];
	[[cell deviceIP] setText:[currentDevice ip]];
	//NSString *imageName = [NSString stringWithFormat:@"device0%d.png",[currentDevice deviceType] ];
	NSString *imageName = [NSString stringWithFormat:@"device0%d.png",1 ];
	[[cell deviceImage] setImage:[UIImage imageNamed:imageName]];
	[[cell deviceCheck] setHidden:![currentDevice selectStatus]];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSInteger row = [indexPath row];
	deviceProperties *deviceObj = [self.deviceListArray objectAtIndex:row];
	if (self.singleMode == NO) 
		[deviceObj setSelectStatus:![deviceObj selectStatus]];
	else 
	{
		for (deviceProperties *currentObj in self.deviceListArray)
			[currentObj setSelectStatus:NO];
		[deviceObj setSelectStatus:YES];
	}

	[self.tableView reloadData];
	
	NSMutableArray *selectedListArray = [NSMutableArray array];
	for (id currenrObj in self.deviceListArray) 
	{
		if ([currenrObj selectStatus] == YES) 
		{
			[selectedListArray addObject:currenrObj];
		}
	}
	[self.delegate setSelectedDevice:selectedListArray];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

