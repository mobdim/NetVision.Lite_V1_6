//
//  ModelNameController.m
//  NetVision Lite
//
//  Created by Yen Jonathan on 2011/7/11.
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

#import "ModelNameController.h"
#import "checkData.h"
#import "selectionCell.h"
#import "P2PaddCam.h"
#import "ModelNames.h"

@implementation ModelNameController
@synthesize backBtn;
@synthesize deviceData;
@synthesize delegate;
// test
@synthesize mForcedStop;
//

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Model Name";
	
	//[[self navigationItem] setRightBarButtonItem:saveBtn];
	self.navigationItem.leftBarButtonItem = self.backBtn;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	
}



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// test
	[self setMForcedStop:NO];
	//
	
	[self.tableView reloadData];
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return MODEL_NAME_TOTAL;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier1 = @"cellSelect";    
    // Configure the cell...
    
	id cell;
	cell = (selectionCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
	if (cell == nil) {
		NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"selectionCell" owner:nil options:nil];
		
		for( id currentObject in nibObjects)
		{
			if ([currentObject isKindOfClass:[selectionCell class]])
			{
				cell = (selectionCell *)currentObject;
			}
		}
	}
	int section = [indexPath section];
	int row = [indexPath row];
	P2PaddCam *p2p = (P2PaddCam*)delegate;
	
	if(!p2p)
		return nil;
	
	int model;
	if([p2p deviceData] == nil)
	{		
		NSLog(@"modelName...null.....: %d", [p2p modelID]);
		model = [p2p modelID];
		//NSLog(@"ModelNameController.get model ID from p2p dialog: %d", model);
	}
	else 
	{		
		model = [[p2p deviceData] modelNameID];
		//NSLog(@"ModelNameController.get model ID from p2p's contained device: %d", model);
	}		
	
	//row = row%MODEL_NAME_TOTAL;
	if (section == 0)
	{
		switch(row+1)
		{
			case MODEL_NAME_RC4021:
				[[((selectionCell*)cell) titleLabel] setText:@"RC4021"];
				if(model == MODEL_NAME_RC4021)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;
			case MODEL_NAME_RC8021:
				[[((selectionCell*)cell) titleLabel] setText:@"RC8021"];
				if(model == MODEL_NAME_RC8021)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;				
			case MODEL_NAME_RC8061:
				[[((selectionCell*)cell) titleLabel] setText:@"RC8061"];
				if(model == MODEL_NAME_RC8061)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;
			case MODEL_NAME_RC8120:
				[[((selectionCell*)cell) titleLabel] setText:@"RC8120"];
				if(model == MODEL_NAME_RC8120)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_RC8221:
				[[((selectionCell*)cell) titleLabel] setText:@"RC8221"];
				if(model == MODEL_NAME_RC8221)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;				
			case MODEL_NAME_OC810:
				[[((selectionCell*)cell) titleLabel] setText:@"OC810"];
				if(model == MODEL_NAME_OC810)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;				
			case MODEL_NAME_OC821:
				[[((selectionCell*)cell) titleLabel] setText:@"OC821"];
				if(model == MODEL_NAME_OC821)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_iCam:
				[[((selectionCell*)cell) titleLabel] setText:@"iCam"];
				if(model == MODEL_NAME_iCam)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_DC402:
				[[((selectionCell*)cell) titleLabel] setText:@"DC402"];
				if(model == MODEL_NAME_DC402)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;				
			case MODEL_NAME_DC421:
				[[((selectionCell*)cell) titleLabel] setText:@"DC421"];
				if(model == MODEL_NAME_DC421)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_NV812D:
				[[((selectionCell*)cell) titleLabel] setText:@"NV812D"];
				if(model == MODEL_NAME_NV812D)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_NV412A:
				[[((selectionCell*)cell) titleLabel] setText:@"NV412A"];
				if(model == MODEL_NAME_NV412A)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			case MODEL_NAME_NV842:
				[[((selectionCell*)cell) titleLabel] setText:@"NV842"];
				if(model == MODEL_NAME_NV842)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
			default:
				[[((selectionCell*)cell) titleLabel] setText:@"Neutral"];
				if(model == MODEL_NAME_DONTCARE)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
				break;					
		}
	}
	
	/*
	// test
	if(row == 7)
	{
		NSLog(@"row number: 7...");
		
		//if([self mForcedStop] == NO)
		{
			[[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
			[self setMForcedStop:YES];
			// stop scrolling
		}
		//else if([self mForcedStop] == YES)
		//	[self setMForcedStop:NO];
	}
	else
	{
		// enable the scrolling
		
	}
	//
	*/
	
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
	
	int section = [indexPath section];
	int row = [indexPath row];
	P2PaddCam *p2p = (P2PaddCam*)delegate;
	
	if(!p2p)
		return;
	
	//if([p2p deviceData] == nil)
	//	NSLog(@"ModelNameController...didSelectRowAtIndexPath...deviceData nil");
	
	if (section == 0)
	{
		switch(row+1)
		{
			case MODEL_NAME_RC4021:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_RC4021];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_RC4021];				
				break;
			case MODEL_NAME_RC8021:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_RC8021];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_RC8021];				
				break;	
			case MODEL_NAME_RC8120:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_RC8120];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_RC8120];				
				break;				
			case MODEL_NAME_RC8061:
				if([p2p deviceData] == nil)
				{
					[p2p setModelID:MODEL_NAME_RC8061];
					//NSLog(@"ModelNameController...didSelectRowAtIndexPath...R8061..1");
				}
				else 
				{
					[[p2p deviceData] setModelNameID:MODEL_NAME_RC8061];
					//NSLog(@"ModelNameController...didSelectRowAtIndexPath...RC8061..2");
					//NSLog(@"ModelNameController...[[p2p deviceData] setModelNameID]: %d", [[p2p deviceData] modelNameID]);
				}
				break;				
			case MODEL_NAME_OC810:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_OC810];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_OC810];				
				break;					
			case MODEL_NAME_OC821:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_OC821];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_OC821];				
				break;					
			case MODEL_NAME_iCam:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_iCam];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_iCam];				
				break;					
			case MODEL_NAME_DC402:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_DC402];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_DC402];				
				break;					
			case MODEL_NAME_DC421:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_DC421];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_DC421];				
				break;					
			case MODEL_NAME_NV812D:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_NV812D];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_NV812D];				
				break;					
			case MODEL_NAME_NV412A:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_NV412A];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_NV412A];				
				break;						
			case MODEL_NAME_NV842:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_NV842];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_NV842];				
				break;	
			case MODEL_NAME_RC8221:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_RC8221];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_RC8221];				
				break;						
			default:
				if([p2p deviceData] == nil)
					[p2p setModelID:MODEL_NAME_DONTCARE];
				else 
					[[p2p deviceData] setModelNameID:MODEL_NAME_DONTCARE];				
				break;					
		}		
		//NSLog(@"ModelNameController...didSelectRowAtIndexPath...id: %d", row+1);
	}
	
	[self.tableView reloadData];
	
	
}

#pragma mark ibaction
- (IBAction)backButton:(id)sender
{
	P2PaddCam *p2p = (P2PaddCam*)delegate;
	
	if(p2p)
	{
		[p2p setBackFromModelNameSelection:YES];
	}
		
	[self.navigationController popViewControllerAnimated:YES];
	
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
	//[deviceData release];
    [super dealloc];
}


@end