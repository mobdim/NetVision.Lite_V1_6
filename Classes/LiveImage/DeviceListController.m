//
//  DeviceListController.m
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/12.
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

#import "DeviceListController.h"
#import "DeviceDetailViewController.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ImageCache.h"
#import "ConstantDef.h"
#import "checkData.h"
#import "UserDefDevList.h"
#import "TerraUIAppDelegate.h"
#import "ModelNames.h"

@implementation DeviceListController

@synthesize newItemFlag;
@synthesize focalRow;
@synthesize runMode;


-(id)init
{
	// Call the superclass's designated initializer
	//[super initWithNibName:nil bundle:nil];
	//NSLog(@"enter DeviceListController init...\r\n");	
	
	[super initWithStyle:UITableViewStyleGrouped];
	
	// create row item(data source)
	
	// prepare the required navigationItem stuff
	// right bar item button
	//[[self navigationItem] setRightBarButtonItem:[self editButtonItem]];	
	// title view
	[[self navigationItem] setTitle:@"Device List"];
	detailViewController = nil;
	[self setFocalRow:0];
	// default in server mode
	[self setRunMode:RUN_SERVER_MODE];

	return self;
}

-(id)initWithMode:(int)mode
{
	[self init];
	// since we don't allow editing(except mapping) in devicelist, don't care the input
	// run mode setting. Always set the run mode as RUN_SERVER_MODE
	[self setRunMode:RUN_SERVER_MODE];
	//if((mode != RUN_SERVER_MODE) && (mode != RUN_P2P_MODE))
	//	mode = RUN_SERVER_MODE;
	//[self setRunMode:mode];		
	
	return self;
}

/*
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	
	// self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	// if (self) {
	// // Custom initialization.
	// [self init];
	// }
	// return self;
	 
	
	return [self init];
}

-(id)initWithStyle:(UITableViewStyle)style
{
	return [self init];
}
*/


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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	NSLog(@"DeviceListController...viewDidLoad...");
    [super viewDidLoad];
	
	if(!detailViewController)
		detailViewController = [[DeviceDetailViewController alloc] init];
	
	// register myself as an observer for new item delete/insert notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(checkAddNewItemNotification:)
												 name:@"CheckNewItemCreatedNotification"
											   object:detailViewController];	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(checkDummyDataSourceCreatedNotification:)
												 name:@"CheckDummyDataSourceItemCreatedNotification"
											   object:detailViewController];
	
	[self setNewItemFlag:NO];
	
}

-(void)checkAddNewItemNotification:(NSNotification*)note
{
	// if we do have a new item created due to inserting indicator cell pressed, insert the new table view cell
	// otherwise, do nothing(we just highligh an existing table view cell and do some modification)
	if([self newItemFlag] == NO)
		return;	
	
	if(detailViewController == (DeviceDetailViewController*)[note object])
	{
		// if OK, insert a new table view cell row
		int row = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
		NSLog(@"insert a row: %d", row);
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(row-1) inSection:0];
		NSArray *paths = [NSArray arrayWithObject:indexPath];		
		[[self tableView] insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationLeft];
	}
	[self setNewItemFlag:NO];
	
}

-(void)checkDummyDataSourceCreatedNotification:(NSNotification*)note
{
	// check to see if we had created a dummy data source item for new table view cell preparation.
	// if not, do nothing
	if([self newItemFlag] == NO)
		return;	
	
	// we did created a dummy data source item for new table view cell preparation, but user
	// give up the createion. So, we need to remove that dummy data source item.
	if(detailViewController == (DeviceDetailViewController*)[note object])
	{	
		int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
		// remove the item before the inserting indicator row
		NSLog(@"remove object at: %d", (count-1));
		NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:count-1];
		[[DeviceCache sharedDeviceCache] deleteDeviceForKey:key];
	}
	[self setNewItemFlag:NO];
	
}

-(void)viewWillAppear:(BOOL)animated
{
	NSLog(@"DeviceListController...viewWillAppear...");
	[super viewWillAppear:animated];
	// reload the item just modified instead of reloading all the rows since it 
	// might be expensive for latter operation

	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	//if([self focalRow] < count)
	//{
	//	NSLog(@"DeviceListController...viewWillAppear...totalDevice: %d reload row at: %d", count, [self focalRow]);
	//	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self focalRow] inSection:0];
	//	NSArray *paths = [NSArray arrayWithObject:indexPath];	
	//	[[self tableView] reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationLeft];				
	//}
	
	[self checkReloadRequirement];
	[[self tableView] reloadData];
	// to auto enter 'editing'mode
	if(count > 0)
		[self setEditing:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
	NSLog(@"DeviceListController...viewWillDisappear...");	
	[super viewWillDisappear:animated];	
	
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	NSLog(@"DeviceListController...viewWillDisappear...totalDevice: %d reload row at: %d", count, [self focalRow]);
	// to auto leave 'editing' mode
	[self setEditing:NO animated:YES];
}

-(void)runModeChanged:(int)mode
{
	// if unrecognizable mode, do nothing
	if((mode != RUN_SERVER_MODE) && (mode != RUN_P2P_MODE))
		return;
	
	[self setRunMode:mode];	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	int numberOfRows = [[DeviceCache sharedDeviceCache] totalDeviceNumber];;
	
	if([self runMode] == RUN_SERVER_MODE)
	{
		NSLog(@"DeviceListController total row number(serverMode): %d", numberOfRows);
		return numberOfRows;
	}
	
	// in P2Pmode, we can add a new item
	// since we don't let the camera adding ability be done in this mapping page, don't need to count the 'Add' row
	//if([self isEditing])
	//	numberOfRows++;
	
	NSLog(@"DeviceListController total row number(P2PMode): %d", numberOfRows);
	return numberOfRows;
	
}

-(void)pushDeviceEditingView:(NSIndexPath*)indexPath
{
	NSLog(@"enter pushDeviceEditingView....object index: %d", [indexPath row]);
	
	//link the detail view controller with its data source
	NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[indexPath row]];
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceForKey:key];
	[detailViewController setEditingPossession: dev];
	NSLog(@"pushDeviceEditingView....setEditingPossession...");
	NSLog(@"editingPossession...title: %@", [[detailViewController editingPossession] title]);
	[[self navigationController] pushViewController:detailViewController animated:YES];	
}

// for table view cell modification
-(void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if([self runMode] == RUN_SERVER_MODE)
		return;
	
	NSLog(@"enter didSelectRowAtIndexPath....");
	[self setFocalRow:[indexPath row]];
	[self pushDeviceEditingView:indexPath];
	
	//link the detail view controller with its data source
	//[detailViewController setEditingPossession: [possessions objectAtIndex:[indexPath row]]];
	//
	//[[self navigationController] pushViewController:detailViewController animated:YES];	
}


-(void)editingButtonPressed:(id)sender
{
	// if we currently in editing mode
	if([self isEditing])
	{
		// change the text of the button to inform user of state
		[sender setTitle:@"Edit" forState:UIControlStateNormal];
		// turn off editing mode
		[self setEditing:NO animated:YES];
		
	}
	else 
	{
		// change the text of the button to inform user of state
		[sender setTitle:@"Done" forState:UIControlStateNormal];
		// turn off editing mode
		[self setEditing:YES animated:YES];		
	}
	
}

-(void)setEditing:(BOOL)flag animated:(BOOL)animated
{
	// always call super implenentation of this method, it need to do work
	// ie., let super's editing property consistent with the sub-controller
	[super setEditing:flag animated:animated];
	NSLog(@"enter setEditing mode....");
	
	// if need a insert indicator row
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if(flag)
	{
		// in editing mode, we need an inserting indicator row if we are run in P2P mode
		if([self runMode] == RUN_P2P_MODE)
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];
			NSArray *paths = [NSArray arrayWithObject:indexPath];
			
			[[self tableView] insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationLeft];
			NSLog(@"enter setEditing mode....insert add icon row...total device: %d", count);
		}
	}
	else
	{
		// if leaving editing mode, remember to remove the inserting indicator row if we are run in P2P mode
		if([self runMode] == RUN_P2P_MODE)
		{		
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];
			NSArray *paths = [NSArray arrayWithObject:indexPath];
			
			[[self tableView] deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationLeft];
			NSLog(@"enter setEditing mode....delete add icon row...total device: %d", count);
			//NSLog(@"leave editing mode... object count: %d", count);
		}
	}
}

-(BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if([indexPath row] <count)
		return YES;
	
	return NO;
	
}

-(NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath
	 toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath
{
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if([proposedDestinationIndexPath row] < count)
	{
		return proposedDestinationIndexPath;
		
	}
	
	// if we reach here, it mean we cannot move a row beneath the insert indicator row
	NSIndexPath *betterIndexPath = [NSIndexPath indexPathForRow:count-1 inSection:0];
	
	return betterIndexPath;
	
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSLog(@"commitEditingStyle...row: %d", [indexPath row]);
	// if table view is asking to commit a delete command...
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		// remove the data source item corresponding to the proposed to removed row in table view
		NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[indexPath row]];
		[[DeviceCache sharedDeviceCache] deleteDeviceForKey:key];
		
		// Now, remove the table view cell
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
		
	}
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		[self setNewItemFlag:YES];
		// popup the device editing view
		// create a temp new possession object with empty data	
		DeviceData *dev = [DeviceData deviceDataCreationWthAssignedIndex:[indexPath row]];
		[[DeviceCache sharedDeviceCache] setDevice:dev forKey:[dev deviceKey]];
		NSLog(@"insert...temp add one object: %d", [[DeviceCache sharedDeviceCache] totalDeviceNumber]);		
		// clean the posession object's content before push the device editing view
		//DeviceData *object = [possessions objectAtIndex:[possessions count]-1];
		//[object cleanContent];
		[self pushDeviceEditingView:indexPath];	
		/*
		 NSLog(@"\r\nvaccess confirm button value....before");		
		 BOOL confirm = [detailViewController confirmed];
		 NSLog(@"\r\nvaccess confirm button value....after");
		 if(confirm)
		 {
		 // sync the object content
		 //[possessions replaceObjectAtIndex:[indexPath row] withObject:object];
		 // if OK, insert a new table view cell row
		 [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
		 }
		 else
		 {
		 // otherwise, delete the temp possesion object
		 [possessions removeObjectAtIndex:[indexPath row]];
		 }
		 */
	}
}

-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath
	 toIndexPath:(NSIndexPath*)toIndexPath
{
	[[DeviceCache sharedDeviceCache] moveDeviceFromIndex:[fromIndexPath row] toIndex:[toIndexPath row]];
	
	// if we are in P2P mode, we need to set the device list back to data center
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
		
	int serverType = [[appDelegate dataCenter] getMobileMode];
	if(serverType == RUN_P2P_MODE)
	{
		NSMutableArray *array = [[NSMutableArray alloc] init];
		DeviceData *dev;
		UserDefDevice *newObj;
		for(int i=0; i<[[DeviceCache sharedDeviceCache] totalDeviceNumber]; i++)
		{
			dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:i];
			NSString *strT = [NSString stringWithString:[dev title]];
			NSString *strUN = [NSString stringWithString:[dev authenticationName]];
			NSString *strPW = [NSString stringWithString:[dev authenticationPassword]];
			NSString *ip = [NSString stringWithString:[dev IP]];
			NSString *port = [[NSString alloc] initWithFormat:@"%d", [dev portNum]]; //nash
			int features = [dev extensionFeatures];
			
			newObj = [[UserDefDevice alloc] initWithDeviceName:strT
													  DeviceIP:ip
													  UserName:strUN
													  Password:strPW
													   PortNum:port
													   PanTilt:(features&DEVICE_EXTENSION_PT)|(features&DEVICE_EXTENSION_RS485)
														   LED:features&DEVICE_FEATURE_LED
													  PlayType:[dev playType]];	//nash need fix		
			
			[array addObject:newObj];
			[port release]; // nash leak
			[newObj release];
		}
		
		[[appDelegate dataCenter] setUserDeviceList:array];
		
		[array release];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// if necessary, create a new instance of UITableViewCell, with default appearance
	NSLog(@"cellForRowAtIndexPath..row: %d", [indexPath row]);
	/*
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
				NSLog(@"cellForRowAtIndexPath...got the desired cell!");
			}
		}
    }
	*/
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
	if(!cell)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:@"UITableViewCell"] autorelease];
	}
	
	//if(cell)
	//   NSLog(@"cellForRowAtIndexPath...got cell");
	
	// set the text on the cell with the description of the possession
	// that is at the nth index of possessions, where n = row this cell will 
	// appear in on the tableview
	
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	//NSLog(@"cellForRowAtIndexPath...total row: %d", count);
	if([indexPath row] < count)
	{
		
		//NSLog(@"cellForRowAtIndexPath....row: %d", [indexPath row]);		
		NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[indexPath row]];
		//NSLog(@"cellForRowAtIndexPath...row: %d Device key: %@", [indexPath row], key);
		DeviceData *p = [[DeviceCache sharedDeviceCache] deviceForKey:key];	
		//NSLog(@"cellForRowAtIndexPath...deviceTitle: %@", [p title]);
		[[cell textLabel] setText:[p title]];
		[[cell detailTextLabel] setText:[p IP]];
		NSString *imageName = [NSString stringWithFormat:@"device01.png"];
		[[cell imageView] setImage:[UIImage imageNamed:imageName]];				
		
		//[[cell deviceName] setText:[p title]];
		//[[cell deviceIP] setText:[p IP]];
		//NSString *imageName = [NSString stringWithFormat:@"device01.png"];
		//[[cell deviceImage] setImage:[UIImage imageNamed:imageName]];		
		
	}
	else
	{
		if([self runMode] == RUN_P2P_MODE)
			[[cell textLabel] setText:@"Add new item..."];
	}	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	//[sell setShouldIndentWhileEditing:NO];
	// test
	//CGRect fr = [cell frame];
	//NSLog(@"cell before x: %f", fr.origin.x);
	//fr.origin.x -= 15;
	//fr.size.width += 15;
	//[cell setFrame:fr];
	//fr = [cell frame];
	//NSLog(@"cell after x: %f", fr.origin.x);	
	//
	
	return cell;
}



-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if([self runMode] == RUN_SERVER_MODE)
		return UITableViewCellEditingStyleNone;
	
	int count = [[DeviceCache sharedDeviceCache] totalDeviceNumber];
	if([self isEditing] && [indexPath row] == count)
		return UITableViewCellEditingStyleInsert;
	else 
		return UITableViewCellEditingStyleDelete;	
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

-(void)checkReloadRequirement
{
	BOOL dcAttrChanged = NO;	

	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return;
	
	//int err = [[appDelegate dataCenter] isConnectToNetworkWithMsg:YES];
	//if(err == MB_NETWORK_NONE)
	//	return;	
	
	int serverMode = [[appDelegate dataCenter] getMobileMode];
	if(serverMode == RUN_SERVER_MODE)
	{
		NSError *errE = [[appDelegate dataCenter] ConnecttoServer];
		// something wrong in server
		if(errE != nil)
			return;
	}
	
	int count = 0;	
	NSMutableArray *deviceArray;	
	if(serverMode == RUN_SERVER_MODE)	
		deviceArray = [[appDelegate dataCenter] GetDeviceListWithRefresh:&dcAttrChanged
															 withDevType:0
															 withSubType:1
												     withRetrievingCount:count];
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
}


-(BOOL)deviceAttrChanged:(NSMutableArray*)deviceArray
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return NO;
	
	int serverMode = [[appDelegate dataCenter] getMobileMode];
	if(serverMode != RUN_P2P_MODE)
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
			[port release];
			return YES;
		}
		[port release];
	}
	
	// all the same, return NO
	return NO;
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
	
	int serverMode = [[appDelegate dataCenter] getMobileMode];
	if(serverMode == RUN_P2P_MODE)
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
		
		if(serverMode == RUN_SERVER_MODE)
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
		if(serverMode == RUN_SERVER_MODE)
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


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;

	// if we release the controllers here due to LowMamoryWarning, the program will crash once we
	// go back to device list page
	//if(detailViewController)
	//{
	//	[detailViewController release];
	//	detailViewController = nil;
	//}
	
	detailViewController = nil;
	// unregistry the notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dealloc 
{
	[detailViewController release];
	
    [super dealloc];
}


@end
