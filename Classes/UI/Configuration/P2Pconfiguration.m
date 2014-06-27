//
//  P2Pconfiguration.m
//  TerraUI
//
//  Created by Shell on 2011/4/25.
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

#import "ConstantDef.h"
#import "P2Pconfiguration.h"


@implementation P2Pconfiguration

@synthesize UserDefinedDeviceArray;
@synthesize EditBtn,DoneBtn,AddCameraBtn,EndEditBtn;
@synthesize addCameraPage;
@synthesize totalDeviceNum;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	//set navigation title
	self.title = @"Configuration";
	//set navigation button
	self.navigationItem.rightBarButtonItem = self.EditBtn;
	//self.navigationItem.leftBarButtonItem = self.DoneBtn;
	
	
}



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	//get Delegate
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	//get deviceList from data center
	if(UserDefinedDeviceArray)
		[UserDefinedDeviceArray release];
	
	UserDefinedDeviceArray = [[appDelegate.dataCenter getUserDeviceList] mutableCopy];
	NSLog(@"userdefarray count: %d",[UserDefinedDeviceArray count]);
	[self setTotalDeviceNum:[UserDefinedDeviceArray count]];
	
	if([UserDefinedDeviceArray count] > 0)
		[[self tableView] reloadData];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	
	//release owner of userDefDeviceArray
	//[self.UserDefinedDeviceArray release];
	
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	NSLog(@"P2PConfiguration...tableView number of row: %d", [self.UserDefinedDeviceArray count]);
    return [self.UserDefinedDeviceArray count];
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
	UserDefDevice *currentDevice = [UserDefinedDeviceArray objectAtIndex:row];	
	[[cell deviceName] setText:[NSString stringWithString:[currentDevice cameraName]]];
	[[cell deviceIP] setText:[NSString stringWithString:[currentDevice IPAddr]]];
	
	//NSString *imageName = [NSString stringWithFormat:@"device0%d.png",[currentDevice deviceType] ];
	NSString *imageName = [NSString stringWithFormat:@"device0%d.png",1 ];
	[[cell deviceImage] setImage:[UIImage imageNamed:imageName]];
	[[cell deviceCheck] setHidden:YES];	

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
	
	if (self.addCameraPage == nil) 
	{
		self.addCameraPage = [[P2PaddCam alloc] initWithNibName:@"P2PaddCam"
														 bundle:nil 
											 setDeviceDataIndex:[indexPath row]];
	}
	
	
	
	[self.addCameraPage setIndexofDevList:[indexPath row]];

	[self.navigationController pushViewController:self.addCameraPage animated:YES];	
	
}

// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
		//delete
	if(editingStyle == UITableViewCellEditingStyleDelete) 
	{
		
		int index = [indexPath row];
		
		
		[UserDefinedDeviceArray removeObjectAtIndex:index];
		totalDeviceNum--;
		
		//save..
		TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
		[appDelegate.dataCenter setUserDeviceList:self.UserDefinedDeviceArray];
		
		[self.tableView setEditing:YES animated:YES];
		[[self tableView] reloadData];
	}
	
}


#pragma mark -
#pragma mark IBAction
- (IBAction)saveUserDefArray:(id)object
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	[appDelegate.dataCenter setUserDeviceList:self.UserDefinedDeviceArray];
}

- (IBAction)editMode:(id)object
{
	[self.tableView setEditing:YES animated:YES];
	//save navigation button
	self.navigationItem.rightBarButtonItem = self.AddCameraBtn;
	self.navigationItem.leftBarButtonItem = self.EndEditBtn;
	
	
	
}

- (IBAction)endEditMode:(id)object
{
	[self.tableView setEditing:NO animated:YES];
	//save navigation button
	self.navigationItem.rightBarButtonItem = self.EditBtn;
	self.navigationItem.leftBarButtonItem = nil;
	
	
}

- (IBAction)addCamera:(id)object
{
	// check to see if the total camera number reach the maximum allowable value or not
	if([self totalDeviceNum] >= MAXIMUM_ALLOWABLE_DEVICE_NUMBER)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Number Limitation" 
														message:@"The maximum allowable camera devices is 16." 
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];			
		[alert show];
		[alert release];
		
		return;		
		
	}
	
	
	if (self.addCameraPage == nil) 
	{
		self.addCameraPage = [[P2PaddCam alloc] initWithNibName:@"P2PaddCam"
														 bundle:nil 
											 setDeviceDataIndex:-1];
	}
	[self.addCameraPage setIndexofDevList:-1];
	//[userDef release];
	[self.navigationController pushViewController:self.addCameraPage animated:YES];
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
	[addCameraPage release];
	[AddCameraBtn release];
	[EndEditBtn release];
	[DoneBtn release];
	[EditBtn release];
	[UserDefinedDeviceArray release];
    [super dealloc];
}


@end
