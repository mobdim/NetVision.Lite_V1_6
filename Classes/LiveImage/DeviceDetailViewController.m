//
//  DeviceDetailViewController.m
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/13.
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

#import "DeviceEditTableViewCell.h"
#import "DeviceDetailViewController.h"
#import "DeviceData.h"
#import "DeviceCache.h"

@implementation DeviceDetailViewController

@synthesize editingPossession;
@synthesize temp;
@synthesize sectionTitleArray,cellTitleArray;
@synthesize confirmed;
@synthesize focalRow;
@synthesize numberKeyPadON;
@synthesize doneButton;

#pragma mark -
#pragma mark View lifecycle


-(id)init
{	
	[super initWithStyle:UITableViewStyleGrouped];
	
	return self;
}

- (void)viewDidLoad 
{
	NSLog(@"DeviceDetailViewController...viewDidLoad");
    [super viewDidLoad];
	
	// prepare the required navigationItem stuff
	// right bar item button
	UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
	[[self navigationItem] setRightBarButtonItem:rightBarButtonItem];		
	[rightBarButtonItem release];	
	
	temp = [[DeviceData alloc] init];
	[temp setIP:[editingPossession IP]];
	[temp setPortNum:[editingPossession portNum]];
	[temp setTitle:[editingPossession title]];
	[temp setAuthenticationName:[editingPossession authenticationName]];
	[temp setAuthenticationPassword:[editingPossession authenticationPassword]];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	//set the title of each section
	[self setSectionTitleArray:[[NSArray alloc] initWithObjects:@"Basic Infomation", nil]];	
	[self setCellTitleArray:[[NSArray alloc] initWithObjects:@"Device Name", @"IP Address", @"Port Number", @"User Name", @"Password", nil]];
	
	[self setNumberKeyPadON:NO];
	doneButton = nil;
}

- (void)viewWillAppear:(BOOL)animated 
{
	NSLog(@"DeviceDetailViewController...viewWillAppear");
    [super viewWillAppear:animated];
	[self setConfirmed:NO];
	// title view
	NSString *str = [editingPossession title];
	[[self navigationItem] setTitle:str];
	
	[temp setIP:[editingPossession IP]];
	[temp setPortNum:[editingPossession portNum]];
	[temp setTitle:[editingPossession title]];
	NSLog(@"DeviceDetailViewController...viewWillAppear...deviceName: %@", [temp title]);
	[temp setAuthenticationName:[editingPossession authenticationName]];
	[temp setAuthenticationPassword:[editingPossession authenticationPassword]];
	
	// to be an observer for keyboard will show notification/
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardDidShow:) 
												 name:UIKeyboardDidShowNotification 
											   object:nil];	
    //[[NSNotificationCenter defaultCenter] addObserver:self 
	//										 selector:@selector(keyboardWillShow:) 
	//											 name:UIKeyboardWillShowNotification 
	//										   object:nil];	
	
	[[self tableView] reloadData];
}


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated 
{
    [super viewWillDisappear:animated];
	
	// if dirty flag set, remember to notify the tableViewCell to refresh the content
    static NSString *CellIdentifier = @"DeviceEditTableView";    
    DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"DeviceEditTableViewCell" owner:nil options:nil];
		for ( id currentObj in nibObjs)
		{
			if ([currentObj isKindOfClass:[DeviceEditTableViewCell class]]) 
			{
				cell = (DeviceEditTableViewCell *)currentObj;
			}
		}
    } 
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[cell value] resignFirstResponder];
	
	if([self confirmed] == YES)
	{				
		// refresh the table view cell via issuing notification
		NSNotification *note = [NSNotification notificationWithName:@"CheckNewItemCreatedNotification" object:self userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotification:note];
	}
	else 
	{
		// delete the undesired object created in possessions(data source)
		NSNotification *note = [NSNotification notificationWithName:@"CheckDummyDataSourceItemCreatedNotification" object:self userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotification:note];						
	}		
}

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


// if not the portNum cell's text field clicked, we will bypass this notification
-(void)keyboardDidShow:(NSNotification *)notification 
//-(void)keyboardWillShow:(NSNotification *)notification 
{
	if([self focalRow] != 2)
		return;
	
	NSLog(@"enter keyboardWillShow notification...");
	[self addDoneButtonOnNumberKeyPad];
}

-(void)numberPadShouldHide:(id)sender
{
    for(UIWindow *keyboardWindow in [[UIApplication sharedApplication] windows]) 
	{		
        // Now iterating over each subview of the available windows
        for(UIView *keyboard in [keyboardWindow subviews]) 
		{	
			if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) 
			{
				if([[keyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES)
				{
					NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
					DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] cellForRowAtIndexPath:indexPath];					
					[[cell value] resignFirstResponder];
					[self setNumberKeyPadON:NO];
					NSLog(@"keyboard dismissed...1");
				}			
			}
			else
			{
				NSLog(@"check iOS < 3.2");
				if ([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES) 
				{
					NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
					DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] cellForRowAtIndexPath:indexPath];					
					[[cell value] resignFirstResponder];
					[self setNumberKeyPadON:NO];
					NSLog(@"keyboard dismissed...2");				
				}
			}					
		}
	}	
}

-(void)addDoneButtonOnNumberKeyPad
{
    // create custom buttom	
    doneButton = [UIButton buttonWithType:UIButtonTypeCustom];	
    doneButton.frame = CGRectMake(0, 163, 106, 53);
    doneButton.adjustsImageWhenHighlighted = NO;
    [doneButton setImage:[UIImage imageNamed:@"DoneUp.png"] forState:UIControlStateNormal];
    [doneButton setImage:[UIImage imageNamed:@"DoneDown.png"] forState:UIControlStateHighlighted];
    [doneButton addTarget:self action:@selector(numberPadShouldHide:) forControlEvents:UIControlEventTouchUpInside];
	
    // locate keyboard view
    for(UIWindow *keyboardWindow in [[UIApplication sharedApplication] windows]) 
	{		
        // Now iterating over each subview of the available windows
        for(UIView *keyboard in [keyboardWindow subviews]) 
		{	
			if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) 
			{
				NSLog(@"check iOS > 3.2");
				NSLog(@"keyboard description: %@", [keyboard description]);
				if([[keyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES)
				{
					[keyboard addSubview:doneButton];
					[self setNumberKeyPadON:YES];
					NSLog(@"add 'Done' button on keyboard...1");
				}			
			}
			else
			{
				NSLog(@"check iOS < 3.2");
				if ([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES) 
				{
					[keyboard addSubview:doneButton];
					[self setNumberKeyPadON:YES];
					NSLog(@"add 'Done' button on keyboard...2");
				}
			}					
		}
	}	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
	if(section == 0)
		return DEVICE_DETAILED_TABLE_VIEW_TOTAL_CELL;
	else
		return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self sectionTitleArray] objectAtIndex:section];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	//NSLog(@"DeviceDetailViewController...cellForRowAtIndexPath...");
    static NSString *CellIdentifier = @"DeviceEditTableView";
    
    DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"DeviceEditTableViewCell" owner:nil options:nil];
		for ( id currentObj in nibObjs)
		{
			if ([currentObj isKindOfClass:[DeviceEditTableViewCell class]]) 
			{
				cell = (DeviceEditTableViewCell *)currentObj;
			}
		}
    }    
	
    int section = [indexPath section];
	int row = [indexPath row];
	//NSLog(@"DeviceDetailViewController...cellForRowAtIndexPath...section: %d row: %d", section, row);
	//set a title to each row
	if(section == 0)
	{
		[[cell title] setText:[[self cellTitleArray] objectAtIndex:row]];
		[cell.value setDelegate:self];
		//NSLog(@"DeviceDetailViewController...cellForRowAtIndexPath...got cell");
		//NSLog(@"DeviceDetailViewController...cellForRowAtIndexPath...cellTitle: %@", [[cell title] text]);
		NSString *str;
		switch(row)
		{
			case 0:
				NSLog(@"DeviceDetailViewController...cellForRowAtIndexPath...cellValue: %@", [temp title]);
				[[cell value] setText:[temp title]];
				[[cell value] setTag:0];
				break;				
			case 1:
				[[cell value] setText:[temp IP]];
				[[cell value] setTag:1];
				break;
			case 2:	
				str = [NSString stringWithFormat:@"%d", [temp portNum]];
				[[cell value] setText:str];
				[[cell value] setTag:2];
				[[cell value] setKeyboardType:UIKeyboardTypeNumberPad];
				[[cell value] setReturnKeyType:UIReturnKeyDone];								
				break;
			case 3:
				[[cell value] setText:[temp authenticationName]];
				[[cell value] setTag:3];
				break;
			case 4:
				[[cell value] setText:[temp authenticationPassword]];
				[[cell value] setTag:4];
				break;								
		}
	}	

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
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
	//NSLog(@"inside didSelect...row: %d", [indexPath row]);

}

#pragma mark -
#pragma mark textField protocol


- (void) textFieldDidBeginEditing:(UITextField*) textField
{	
	/*
	// check previous focal row and resign firstResponsder role if necessary
	if([self numberKeyPadON] == YES)
	{
		if(doneButton)
		{
			NSLog(@"remove the 'DONE' button");
			[doneButton removeFromSuperview];
			[doneButton release];
			doneButton = nil;
			[self setNumberKeyPadON:NO];
		}	
	}
	*/
	if([textField tag] == 2)
		[self addDoneButtonOnNumberKeyPad];
	else 
	{
		if([self numberKeyPadON] == YES)
		{
			if(doneButton)
				[doneButton setHidden:YES];
		}
	}

	
	// remember the current focal row
	[self setFocalRow:[textField tag]];
	NSLog(@"begin editing text field....%d", [self focalRow]);	
	CGRect rc = [textField bounds];
	rc = [textField convertRect:rc toView:self.tableView];
	rc.origin.x = 0;
	rc.origin.y -= 30;
	rc.size.height = 120;
	[self.tableView scrollRectToVisible:rc animated:YES];	

}

-(void)textFieldDidEndEditing:(UITextField *)textField
{		 
	NSLog(@"textFieldDidEndEditing...%d", [textField tag]);
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[textField tag] inSection:0];
	DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] cellForRowAtIndexPath:indexPath];					
	[[cell value] resignFirstResponder];	
}

-(BOOL)textFieldShouldReturn:(UITextField *)tf
{		
	NSLog(@"\r\nKeyboard should resign.");
	/*
    static NSString *CellIdentifier = @"DeviceEditTableView";    
    DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"DeviceEditTableViewCell" owner:nil options:nil];
		for ( id currentObj in nibObjs)
		{
			if ([currentObj isKindOfClass:[DeviceEditTableViewCell class]]) 
			{
				cell = (DeviceEditTableViewCell *)currentObj;
			}
		}
    } 
	*/
	// release first responder role	
	//movieURLText = [self urlField];
	// When the user presses 'Done', take focus away from the text field to dismiss the keyboard.
	//if (tf == [cell value]) 
	//{

		int port; NSString *str;
		switch([tf tag])
		{
			case 0:	
				NSLog(@"value:%@", [tf text]);				
				[temp setTitle:[tf text]];
				break;				
			case 1:	
				NSLog(@"value:%@", [tf text]);	
				[temp setIP:[tf text]];
				break;
			case 2:	
				NSLog(@"value:%@", [tf text]);	
				str = [tf text];
				port = (int)CFStringGetIntValue((CFStringRef)str);
				[temp setPortNum:port];
				break;
			case 3:	
				NSLog(@"value:%@", [tf text]);	
				[temp setAuthenticationName:[tf text]];
				break;
			case 4:	
				[temp setAuthenticationPassword:[tf text]];
				break;			
		}
		NSLog(@"\r\nKeyboard resign due to 'Done' pressed.");
		[tf resignFirstResponder];
	//}		
	
	return YES;
}

-(void)save
{
	// retrieve the value from each TableView cell
	for(int i=0; i<DEVICE_DETAILED_TABLE_VIEW_TOTAL_CELL; i++)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
		DeviceEditTableViewCell *cell = (DeviceEditTableViewCell*)[[self tableView] cellForRowAtIndexPath:indexPath];
		NSString *str; int port;
		switch(i)
		{
			case 0:
				[temp setTitle:[[cell value] text]];
				break;
			case 1:
				[temp setIP:[[cell value] text]];
				break;				
			case 2:
				str = [[cell value] text];
				port = (int)CFStringGetIntValue((CFStringRef)str);
				[temp setPortNum:port];
				break;
			case 3:
				[temp setAuthenticationName:[[cell value] text]];
				break;					
			case 4:
				[temp setAuthenticationPassword:[[cell value] text]];
				break;					
		}
	}
	
	// update to the editingPossesion
	[editingPossession setTitle:[temp title]];	
	[editingPossession setIP:[temp IP]];
	[editingPossession setPortNum:[temp portNum]];
	[editingPossession setAuthenticationName:[temp authenticationName]];
	[editingPossession setAuthenticationPassword:[temp authenticationPassword]];
	// update navigation item title	
	NSString *str = [editingPossession title];
	[[self navigationItem] setTitle:str];
	
	[editingPossession setDirtyFlag:YES];
	[self setConfirmed:YES];
	// update to device cache
	[[DeviceCache sharedDeviceCache] setDevice:editingPossession forKey:[editingPossession deviceKey]];
	
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if(sectionTitleArray)
	{
		[sectionTitleArray release];
		sectionTitleArray = nil;
	}
	if(cellTitleArray)
	{
		[cellTitleArray release];
		cellTitleArray = nil;
	}
	
	if(editingPossession)
	{
		[editingPossession release];
		editingPossession = nil;
	}
	
	if(temp)
	{
		[temp release];
		temp = nil;
	}	
	
}


- (void)dealloc 
{
	[cellTitleArray release];
	[sectionTitleArray release];
	[temp release];
	
    [super dealloc];
}


@end

