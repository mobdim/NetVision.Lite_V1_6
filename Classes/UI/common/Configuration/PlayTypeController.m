//
//  PlayTypeController.m
//  NetVision Lite
//
//  Created by ISBU on 公元2011/12/12.
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

#import "PlayTypeController.h"
#import "checkData.h"
#import "selectionCell.h"
#import "P2PaddCam.h"
#import "ConstantDef.h"
#import "Modelnames.h"

@implementation PlayTypeController

@synthesize saveBtn;
@synthesize deviceData;
@synthesize delegate;
@synthesize modelID;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = @"Stream Type";

	//[[self navigationItem] setRightBarButtonItem:saveBtn];
	self.navigationItem.leftBarButtonItem = self.saveBtn;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
	// the number of stream type depends on the selected device model number
	switch([self modelID])
	{
	case MODEL_NAME_RC4021:
	case MODEL_NAME_RC8021:
	case MODEL_NAME_RC8061:
	case MODEL_NAME_DC402:
	case MODEL_NAME_NV412A:
		return 2;
	case MODEL_NAME_OC810:
	case MODEL_NAME_RC8120:		
	case MODEL_NAME_RC8221:
	case MODEL_NAME_OC821:
	case MODEL_NAME_DC421:
	case MODEL_NAME_iCam:
	case MODEL_NAME_NV812D:
		return 3;
	case MODEL_NAME_NV842:
		return 4;
	default:
		return 3;
	}	

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
	
	int type;
	if([p2p deviceData] == nil)
	{
		NSLog(@"playType...null.....: %d", [p2p playType]);
		type = [p2p playType];		
	}
	else 
	{
		type = [[p2p deviceData] playType];
	}

	
	if (section == 0)
	{
		switch([self modelID])
		{
		case MODEL_NAME_RC4021:
		case MODEL_NAME_RC8021:
		case MODEL_NAME_RC8061:
		case MODEL_NAME_DC402:
		case MODEL_NAME_NV412A:										
			if (row == 0) //mjpeg
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Motion JPEG"];
				if(type == IMAGE_CODEC_MJPEG)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else if((type != IMAGE_CODEC_MJPEG) && (type != IMAGE_CODEC_MPEG4))
				{
					[[((selectionCell*)cell) checkMark] setHidden:NO];
					if([p2p deviceData] == nil)
						[p2p setPlayType:IMAGE_CODEC_MJPEG];
					else 
						[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];					
				}
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 1)// mp4
			{
				[[((selectionCell*)cell) titleLabel] setText:@"MPEG-4"];
				if(type == IMAGE_CODEC_MPEG4)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			break;
		case MODEL_NAME_RC8120:		
		case MODEL_NAME_OC810:				
		case MODEL_NAME_RC8221:
		case MODEL_NAME_OC821:
		case MODEL_NAME_DC421:
		case MODEL_NAME_iCam:
		case MODEL_NAME_NV812D:
			if (row == 0) //mjpeg
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Motion JPEG"];
				if(type == IMAGE_CODEC_MJPEG)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else if((type != IMAGE_CODEC_MJPEG) && (type != IMAGE_CODEC_MPEG4) && (type != IMAGE_CODEC_H264))					
				{
					[[((selectionCell*)cell) checkMark] setHidden:NO];
					if([p2p deviceData] == nil)
						[p2p setPlayType:IMAGE_CODEC_MJPEG];
					else 
						[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];					
				}
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 1)// mp4
			{
				[[((selectionCell*)cell) titleLabel] setText:@"MPEG-4"];
				if(type == IMAGE_CODEC_MPEG4)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 2)// h.264
			{
				[[((selectionCell*)cell) titleLabel] setText:@"H.264"];
				if(type == IMAGE_CODEC_H264)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}				
			break;				
		case MODEL_NAME_NV842:	
			if (row == 0) // channel 1
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Cnannel 1"];
				if(type == IMAGE_CODEC_CH1)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else if((type != IMAGE_CODEC_CH1) && (type != IMAGE_CODEC_CH2) && (type != IMAGE_CODEC_CH3) & (type != IMAGE_CODEC_CH4))					
				{
					[[((selectionCell*)cell) checkMark] setHidden:NO];
					if([p2p deviceData] == nil)
						[p2p setPlayType:IMAGE_CODEC_CH1];
					else 
						[[p2p deviceData] setPlayType:IMAGE_CODEC_CH1];				
					
				}
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 1)	// channel 2
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Channel 2"];
				if(type == IMAGE_CODEC_CH2)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 2)// channel 3
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Channel 3"];
				if(type == IMAGE_CODEC_CH3)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 3)// channel 4
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Channel 4"];
				if(type == IMAGE_CODEC_CH4)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}					
			break;
		default:		
			if (row == 0) //mjpeg
			{
				[[((selectionCell*)cell) titleLabel] setText:@"Motion JPEG"]; 
				if(type == IMAGE_CODEC_MJPEG)
					[[((selectionCell*)cell) checkMark] setHidden:NO];
				else if((type != IMAGE_CODEC_MJPEG) && (type != IMAGE_CODEC_MPEG4) && (type != IMAGE_CODEC_H264))
				{	
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
					if([p2p deviceData] == nil)
						[p2p setPlayType:IMAGE_CODEC_MJPEG];
					else 
						[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];						
				}
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 1)// mp4
			{
				[[((selectionCell*)cell) titleLabel] setText:@"MPEG-4"];
				if(type == IMAGE_CODEC_MPEG4)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}
			else if(row == 2)// h.264
			{
				[[((selectionCell*)cell) titleLabel] setText:@"H.264"];
				if(type == IMAGE_CODEC_H264)
					[[((selectionCell*)cell) checkMark] setHidden:NO];	
				else
					[[((selectionCell*)cell) checkMark] setHidden:YES];
			}					
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
		
	if (section == 0)
	{
		switch([self modelID])
		{
		case MODEL_NAME_RC4021:
		case MODEL_NAME_RC8021:
		case MODEL_NAME_RC8061:
		case MODEL_NAME_DC402:
		case MODEL_NAME_NV412A:			
			if (row == 0) //mjpeg
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MJPEG];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];
			}
			else if(row == 1)// mp4
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MPEG4];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MPEG4];
			}
			break;
		case MODEL_NAME_RC8120:		
		case MODEL_NAME_OC810:				
		case MODEL_NAME_RC8221:
		case MODEL_NAME_OC821:
		case MODEL_NAME_DC421:
		case MODEL_NAME_iCam:
		case MODEL_NAME_NV812D:				
			if (row == 0) //mjpeg
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MJPEG];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];
			}
			else if(row == 1)// mp4
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MPEG4];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MPEG4];
			}
			else if(row == 2)// h.264
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_H264];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_H264];
			}				
			break;					
		case MODEL_NAME_NV842:	
			if (row == 0) // channel 1
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_CH1];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_CH1];
			}
			else if(row == 1)// channel 2
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_CH2];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_CH2];
			}
			else if(row == 2)// channel 3
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_CH3];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_CH3];
			}
			else if(row == 3)// channel 4
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_CH4];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_CH4];
			}				
			break;
		default:
			if (row == 0) //mjpeg
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MJPEG];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MJPEG];
			}
			else if(row == 1)// mp4
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_MPEG4];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_MPEG4];
			}
			else if(row == 2)// h.264
			{
				if([p2p deviceData] == nil)
					[p2p setPlayType:IMAGE_CODEC_H264];
				else 
					[[p2p deviceData] setPlayType:IMAGE_CODEC_H264];
			}					
			break;				
		}
	}
	
	[self.tableView reloadData];
	
	
}

#pragma mark ibaction
- (IBAction)saveButton:(id)sender
{
	P2PaddCam *p2p = (P2PaddCam*)delegate;
	
	if(p2p)
	{
		[p2p setBackFromPlayType:YES];
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

