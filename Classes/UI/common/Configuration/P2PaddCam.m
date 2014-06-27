//
//  P2PaddCam.m
//  TerraUI
//
//  Created by Shell on 2011/4/26.
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

#import "P2PaddCam.h"
#import "checkData.h"
#import "selectionCell.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ModelNames.h"
#import "ConstantDef.h"

@implementation P2PaddCam
@synthesize sectionTitleArray,settingItemTitle;
@synthesize deviceData,saveBtn,cancelBtn;
@synthesize indexofDevList,UserdevList;
@synthesize panTiltAbility;
@synthesize ledAbility;
@synthesize playTypeCon;
@synthesize playType;
@synthesize backFromPlayType;
@synthesize modelNameController;
@synthesize modelID;
@synthesize backFromModelNameSelection;

#pragma mark -
#pragma mark View lifecycle
//data: -1 ->add new data 
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setDeviceDataIndex:(NSInteger)index
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
	{
		
		//set navigation title
		self.title = @"Setting";
		//set section Title and row title
		//sectionTitleArray = [[NSArray alloc] initWithObjects:@"Camera Basic Information",nil];
		//settingItemTitle = [[NSArray alloc] initWithObjects:@"Camera Name",@"IP Address",@"Port",@"User Name",@"Password",@"Confirm",nil];
	
		sectionTitleArray = [[NSArray alloc] initWithObjects:@"Camera Basic Information",@"Stream Type Information",nil];
		settingItemTitle = [[NSArray alloc] initWithObjects:@"Model Name",@"Camera Name",@"IP Address",@"Port",@"User Name",@"Password",@"Confirm",nil];

	}
    return self;
}


- (void)viewDidLoad 
{
    [super viewDidLoad];
	//set navigation bar button item
	[[self navigationItem] setRightBarButtonItem:saveBtn];
	[[self navigationItem] setLeftBarButtonItem:cancelBtn];
	backFromPlayType = NO;
	backFromModelNameSelection = NO;
	modelNameController = nil;
}



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	//NSLog(@"P2PaddCam...viewWillAppear...");
	if(!backFromPlayType && !backFromModelNameSelection)
	{
		//get delegate
		TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
		//get userdeflistfrom server
	
		if(UserdevList)
			[UserdevList release];
	
		UserdevList = [[[appDelegate dataCenter] getUserDeviceList] mutableCopy];
	
		//set devicedata
		cameraName = nil;
		IPAddr     = nil;
		UserName   = nil;
		Password   = nil;
		PortNum	   = nil;
		ConfirmPw  = nil;
	    if (indexofDevList == -1 || indexofDevList > [UserdevList count] )
	    {
			deviceData = nil; 
			cameraName = [[NSString alloc] initWithString:@""];
			IPAddr     = [[NSString alloc] initWithString:@""];
			UserName   = [[NSString alloc] initWithString:@""];
			Password   = [[NSString alloc] initWithString:@""];
			PortNum	   = [[NSString alloc] initWithString:@""];
			ConfirmPw  = [[NSString alloc] initWithString:@""];
		
			panTiltAbility = YES;
			ledAbility = NO;
			playType   = 0;
			
		}
		else
		{
			deviceData = [UserdevList objectAtIndex:indexofDevList];
			//playType = [deviceData playType];
		}
	}
	
	//NSLog(@"P2PaddCam...back from modelNameController...modelID: %d", [deviceData modelNameID]);
	[[self tableView] reloadData];
	backFromPlayType = NO;
	backFromModelNameSelection = NO;
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if(section == 0)
		return 7;
	if(section == 1)
		return 1;
	
	return 6;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"configSetting";
	static NSString *CellIdentifier1 = @"cellSelect";
	    
	id cell;
	if([indexPath section] == 0)
	{
		//NSLog(@"P2PaddCam...cellForRowAtIndexPath...row: %d", [indexPath row]);		
		if([indexPath row]>0)
		{
			cell = (configureSetting*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) 
			{
				NSArray *nibObjs = [[NSBundle mainBundle] loadNibNamed:@"configureSetting" owner:nil options:nil];
				for ( id currentObj in nibObjs)
				{
					if ([currentObj isKindOfClass:[configureSetting class]]) 
					{
						cell = (configureSetting *)currentObj;
					}
				}
			}
		}
		else 
		{
			cell = (selectionCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
			if (cell == nil) 
			{
				NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"selectionCell" owner:nil options:nil];
				
				for( id currentObject in nibObjects)
				{
					if ([currentObject isKindOfClass:[selectionCell class]])
					{
						cell = (selectionCell *)currentObject;
					}
				}
			}						
		}
	}

	else 
	{
		cell = (selectionCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		if (cell == nil) 
		{
			NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"selectionCell" owner:nil options:nil];
			
			for( id currentObject in nibObjects)
			{
				if ([currentObject isKindOfClass:[selectionCell class]])
				{
					cell = (selectionCell *)currentObject;
				}
			}
		}
	}

    // Configure the cell...		
    int section = [indexPath section];
	int row = [indexPath row];
	
	if(section == 0)
	{
		if(row == 0)
		{
			[[((selectionCell*)cell) titleLabel] setText:[self retrieveModelName]];			
		}
		else
		{
			[((configureSetting*)cell).value setDelegate:self];
			[((configureSetting*)cell).value setTag:row];
			[((configureSetting*)cell).value setSecureTextEntry:NO];
		}
	}
	
	//set a title to each row
	if(deviceData == nil) {
		if (section == 0)
		{
			if(row == 0)
			{
				[[((selectionCell*)cell) titleLabel] setText:[self retrieveModelName]];
				[[((selectionCell*)cell) checkMark] setHidden:YES];
				((selectionCell*)cell).accessoryType = UITableViewCellAccessoryDisclosureIndicator;				
				
			}
			else
			{
				if (row == 1) //camera name
				{
					[((configureSetting*)cell).value setText:cameraName];
				}
				else if(row == 2)// ip address
				{
					[((configureSetting*)cell).value setText:IPAddr];
				}
				else if(row == 3)//portNum
				{
					[((configureSetting*)cell).value setText:PortNum];
				}		
				else if(row == 4)//user name
				{
					[((configureSetting*)cell).value setText:UserName];
				}
				else if (row == 5)//password
				{
					[((configureSetting*)cell).value setSecureTextEntry:YES];
					[((configureSetting*)cell).value setText:Password];
				}
				else if (row == 6)//password
				{
					[((configureSetting*)cell).value setSecureTextEntry:YES];
					[((configureSetting*)cell).value setText:ConfirmPw];
				}
								
				[((configureSetting*)cell).title setText:[self.settingItemTitle objectAtIndex:row]];
			}
		}

		else if(section == 1)
		{
			if (row == 0)//play type
			{
				switch([self modelID])
				{
				case MODEL_NAME_NV842:
					switch([self playType])
					{
						case IMAGE_CODEC_CH1:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 1"];
							break;							
						case IMAGE_CODEC_CH2:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 2"];
							break;
						case IMAGE_CODEC_CH3:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 3"];	
							break;
						case IMAGE_CODEC_CH4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 4"];	
							break;							
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 1"];
							[self setPlayType:IMAGE_CODEC_CH1];
					}
					break;
				case MODEL_NAME_RC4021:
				case MODEL_NAME_RC8021:
				case MODEL_NAME_RC8061:
				case MODEL_NAME_DC402:
				case MODEL_NAME_NV412A:
					switch([self playType])
					{						
						case IMAGE_CODEC_MPEG4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: MPEG-4 "];
							break;
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: Motion JPEG "];
							[self setPlayType:IMAGE_CODEC_MJPEG];
					}
					break;	
				default:		
					switch([self playType])
					{
						case IMAGE_CODEC_MPEG4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: MPEG-4 "];
							break;
						case IMAGE_CODEC_H264:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: H.264 "];	
							break;
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: Motion JPEG "];
							[self setPlayType:IMAGE_CODEC_MJPEG];
					}
					break;
				}
				
				[[((selectionCell*)cell) checkMark] setHidden:YES];
				((selectionCell*)cell).accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			
		}

	}
	else {
		if (section == 0)
		{
			if(row == 0)
			{
				modelID = [self.deviceData modelNameID];				
				[[((selectionCell*)cell) titleLabel] setText:[self retrieveModelName]];
				[[((selectionCell*)cell) checkMark] setHidden:YES];
				((selectionCell*)cell).accessoryType = UITableViewCellAccessoryDisclosureIndicator;					
			}
			else
			{
				if (row == 1) //camera name
				{
					[((configureSetting*)cell).value setText:[self.deviceData cameraName]];
				}
				else if(row == 2)// ip address
				{
					[((configureSetting*)cell).value setText:[self.deviceData IPAddr]];
				}
				else if(row == 3)//portNum
				{
					[((configureSetting*)cell).value setText:[self.deviceData PortNum]];
				}		
				else if(row == 4)//user name
				{
					[((configureSetting*)cell).value setText:[self.deviceData UserName]];
				}
				else if (row == 5)//password
				{
					[((configureSetting*)cell).value setSecureTextEntry:YES];
					[((configureSetting*)cell).value setText:[self.deviceData Password]];
				}
				else if (row == 6)//password
				{
					[((configureSetting*)cell).value setSecureTextEntry:YES];
					[((configureSetting*)cell).value setText:[self.deviceData Password]];
					ConfirmPw  = [[NSString alloc ] initWithString:[self.deviceData Password]];
				}
			
				[((configureSetting*)cell).title setText:[self.settingItemTitle objectAtIndex:row]];
			}
		}

		else if(section == 1)
		{
			if (row == 0)//play type
			{
				switch([self modelID])
				{
					case MODEL_NAME_NV842:
						switch([deviceData playType])
						{
						case IMAGE_CODEC_CH1:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 1"];
							break;							
						case IMAGE_CODEC_CH2:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 2"];
							break;
						case IMAGE_CODEC_CH3:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 3"];	
							break;
						case IMAGE_CODEC_CH4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 4"];	
							break;							
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: channel 1"];
							[deviceData setPlayType:IMAGE_CODEC_CH1];
						}
						break;	
					case MODEL_NAME_RC4021:
					case MODEL_NAME_RC8021:
					case MODEL_NAME_RC8061:
					case MODEL_NAME_DC402:
					case MODEL_NAME_NV412A:
						switch([deviceData playType])
						{		
						NSLog(@"P2PaddCam...cellForRowAtIndexPath...streamType: %d", [self playType]);
						case IMAGE_CODEC_MPEG4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: MPEG-4 "];
							break;
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: Motion JPEG "];
							[deviceData setPlayType:IMAGE_CODEC_MJPEG];
						}
						break;						
					default:		
						switch([deviceData playType])
						{
						case IMAGE_CODEC_MPEG4:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: MPEG-4 "];
							break;
						case IMAGE_CODEC_H264:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: H.264 "];	
							break;
						default:
							[[((selectionCell*)cell) titleLabel] setText:@"Play Type: Motion JPEG "];
							[deviceData setPlayType:IMAGE_CODEC_MJPEG];
						}
						break;
				}
				
				[[((selectionCell*)cell) checkMark] setHidden:YES];
				((selectionCell*)cell).accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}			
		}
	}
    return (UITableViewCell*)cell;
}

//set section title
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [sectionTitleArray objectAtIndex:section];
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
	
	
	if([indexPath section] == 0 && [indexPath row] == 0)
	{
		if(self.modelNameController == nil)
		{
			modelNameController = [[ModelNameController alloc] initWithNibName:@"ModelNameController" bundle:nil];
			[modelNameController setDelegate:self];
			
		}
			
		[self.navigationController pushViewController:self.modelNameController animated:YES];
	}	
	
	
	//static NSString *CellIdentifier1 = @"cellSelect";
	/*if([indexPath section] == 1 && [indexPath row] == 0)
	{
		BOOL flag = [self panTiltAbility];
		[self setPanTiltAbility:!flag];
		
		if(indexofDevList != -1 && indexofDevList < [UserdevList count])
			[self.deviceData setPanTiltAbility:[self panTiltAbility]];
		
		[self.tableView reloadData];
	}
	else
	*/	
	if([indexPath section] == 1 && [indexPath row] == 0)
	{
		if(self.playTypeCon == nil)
		{
			playTypeCon = [[PlayTypeController alloc] initWithNibName:@"PlayTypeController" bundle:nil];
			//[playTypeCon setDeviceData:deviceData];
			[playTypeCon setDelegate:self];			
		}
		// remember to set the model number here
		[playTypeCon setModelID:[self modelID]];
		// push the stream type selection view controller
		[self.navigationController pushViewController:self.playTypeCon animated:YES];
	}

	
}

#pragma mark -
#pragma mark textFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void) textFieldDidBeginEditing:(UITextField*) textField
{	
	CGRect rc = [textField bounds];
	rc = [textField convertRect:rc toView:self.tableView];
	rc.origin.x = 0;
	rc.origin.y -= 30;
	rc.size.height = 120;
	[self.tableView scrollRectToVisible:rc animated:YES];
	saveField = textField;
	//[saveBtn setEnabled:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSInteger tag = textField.tag;
	
	if(deviceData == nil)
	{
		NSLog(@"textFieldDidEndEditing..tag: %d", tag);
		switch (tag) 
		{
			case 1: //CAMERA name
				if(cameraName != nil)
					[cameraName release];
				cameraName = [[NSString alloc] initWithString:[textField text]];
				break;
			case 2:	//ip address
				[IPAddr release];
				IPAddr = [[NSString alloc] initWithString:[textField text]];
				break;
			case 3://Port
				[PortNum release];
				PortNum = [[NSString alloc] initWithString:[textField text]];
				break;
			case 4://user name
				[UserName release];
				UserName = [[NSString alloc] initWithString:[textField text]];
				break;
			case 5://password
				[Password release];
				Password = [[NSString alloc] initWithString:[textField text]];
				break;
			case 6:
				[ConfirmPw release];
				ConfirmPw = [[NSString alloc] initWithString:[textField text]];
				break;
			default:
				break;
		}
	}
	else 
	{
		switch (tag) 
		{
			case 1: //CAMERA name
				[deviceData setCameraName:[textField text]];
				break;
			case 2:	//ip address
				[deviceData setIPAddr:[textField text]];
				break;
			case 3://port
				[deviceData setPortNum:[textField text]];
				break;
			case 4://user name
				[deviceData setUserName:[textField text]];
				break;
			case 5: //password 
				[deviceData setPassword:[textField text]];
				break;
			case 6:
				if(ConfirmPw != NULL)
					[ConfirmPw release];
				ConfirmPw = [[NSString alloc] initWithString:[textField text]];;
				break;
			default:
				break;
		}
	}
	//[saveBtn setEnabled:YES];
}

#pragma mark -
#pragma mark ibaction
- (IBAction)saveButton:(id)sender
{
	//checkData *checked = [checkData new];
	[saveField resignFirstResponder];
	BOOL  isOK = NO;
		
	if (indexofDevList == -1 || indexofDevList >[UserdevList count]) 
	{
		//add new device
		if (UserdevList ==nil) 
		{
			UserdevList =[[NSMutableArray alloc] init];
		}
		if([ConfirmPw isEqualToString:Password] == NO) {
			
			NSLog(@"Confirm:%@\n",ConfirmPw);
			NSLog(@"Password:%@\n",Password);
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Configuration error" 
															message:@"Password not matched." 
														   delegate:nil 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];			
			[alert show];
			[alert release];
			
			return;
			
		}
		
		NSRange range = [IPAddr rangeOfString:@"."];
		if( range.location != NSNotFound) 
		{			
			deviceData = [[UserDefDevice alloc] initWithDeviceName:cameraName
													  DeviceIP:IPAddr
													  UserName:UserName
													  Password:Password
													  PortNum: PortNum
													  PanTilt: panTiltAbility
														  LED:ledAbility
													 PlayType:playType];
			[deviceData setModelNameID:modelID];
			int ability = [UserDefDevice resolveExtensionAbility:[deviceData modelNameID]];
			[deviceData setExtensionAbilities:ability];			
			[UserdevList addObject:deviceData];
			[deviceData release];
			isOK = YES;
		}
	}
	else 
	{
		if([ConfirmPw isEqualToString:[self.deviceData Password] ]== NO) {
			
			NSLog(@"Confirm:%@\n",ConfirmPw);
			NSLog(@"Password:%@\n",Password);
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Configuration error" 
															message:@"Password not matched." 
														   delegate:nil 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];			
			[alert show];
			[alert release];
			
			return;
			
		}
		
		NSRange range = [[self.deviceData IPAddr] rangeOfString:@"."];
		if( range.location != NSNotFound) 
		{
			[deviceData setModelNameID:modelID];
			int ability = [UserDefDevice resolveExtensionAbility:[deviceData modelNameID]];
			[deviceData setExtensionAbilities:ability];
			NSLog(@"P2PaddCam...saveBtn...streamType: %d", [self playType]);
			//[deviceData setPlayType:[self playType]];
			[UserdevList replaceObjectAtIndex:self.indexofDevList
								   withObject:self.deviceData];
			isOK = YES;
		}
	}			
	
	if(!isOK) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Configuration error" 
														message:@"Invalid IP address." 
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];		
		[alert show];
		[alert release];
		
		return;
		
	}
	
	//set new array to device
	//get delegate
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	//get userdeflistfrom server
	[appDelegate.dataCenter setUserDeviceList:self.UserdevList];
	// need to update the device data cache here
	
	[[DeviceCache sharedDeviceCache] setDirtyFlag:YES];
	
	if(sender!=nil)
		[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelButton:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}


-(NSString*)retrieveModelName
{
	switch(modelID)
	{
		case MODEL_NAME_RC4021:	
			return [NSString stringWithString:@"Model Name: RC4021"];	
		case MODEL_NAME_RC8021:	
			return [NSString stringWithString:@"Model Name: RC8021"];			
		case MODEL_NAME_RC8061:	
			return [NSString stringWithString:@"Model Name: RC8061"];
		case MODEL_NAME_RC8120:	
			return [NSString stringWithString:@"Model Name: RC8120"];			
		case MODEL_NAME_RC8221:	
			return [NSString stringWithString:@"Model Name: RC8221"];			
		case MODEL_NAME_OC810:	
			return [NSString stringWithString:@"Model Name: OC810"];	
		case MODEL_NAME_OC821:	
			return [NSString stringWithString:@"Model Name: OC821"];
		case MODEL_NAME_iCam:	
			return [NSString stringWithString:@"Model Name: iCam"];	
		case MODEL_NAME_DC402:	
			return [NSString stringWithString:@"Model Name: DC402"];	
		case MODEL_NAME_DC421:	
			return [NSString stringWithString:@"Model Name: DC421"];
		case MODEL_NAME_NV812D:	
			return [NSString stringWithString:@"Model Name: NV812D"];	
		case MODEL_NAME_NV412A:	
			return [NSString stringWithString:@"Model Name: NV412A"];
		case MODEL_NAME_NV842:	
			return [NSString stringWithString:@"Model Name: NV842"];			
		default:
			return [NSString stringWithString:@"Model Name: neutral"];
	}	
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
	[playTypeCon release];
	[UserdevList release];
	[deviceData release];
	[sectionTitleArray release];
	[settingItemTitle release];
	[modelNameController release];
	
	[cameraName release];
	[IPAddr  release];
	[UserName   release];
	[Password   release];
	[PortNum	release];
	[ConfirmPw  release];
	
	
    [super dealloc];
}


@end

