//
//  loginView.m
//  TerraUI
//
//  Created by Shell on 2011/1/21.
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

#import "loginView.h"


@implementation loginView

@synthesize accountField;
@synthesize passwordField;
@synthesize ipField;
@synthesize portField;
@synthesize cancelBtn;
@synthesize connectBtn;

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.accountField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"UserName"]];
	[self.passwordField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"Password"]];
	[self.ipField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"ServerIP"]];
	[self.portField setText:[NSString stringWithFormat:@"%d",[[NSUserDefaults standardUserDefaults] integerForKey:@"Port"]]];
	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/
#pragma mark -
#pragma mark textField protocol
- (void) textFieldDidBeginEditing:(UITextField*) textField
{
	CGRect textFieldRect = [textField frame];//textfield rect
	CGRect viewRect = [self.view frame];//view rect
	CGFloat textFieldY = (viewRect.size.height - 216)-textFieldRect.size.height - 5;
	if ( (textFieldRect.origin.y+textFieldRect.size.height) > (viewRect.size.height -216)) 
	{
		
		CGFloat distance  = textFieldRect.origin.y -textFieldY;
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.3];
		[self.view setFrame:CGRectMake(0, 0-distance, viewRect.size.width, viewRect.size.height)];
		[UIView commitAnimations];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	CGRect viewFrame = [self.view frame];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view setFrame:CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height)];
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark buttonAction
- (IBAction)cancel:(id)object
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	[appDelegate switchtoTabView:YES//UI mode
						 account:@""
						password:@""
							  IP:@""
							port:@""];
	
}

- (IBAction)connect:(id)object
{
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	[appDelegate switchtoTabView:NO //ui mode
						 account:[self.accountField text] 
						password:[self.passwordField text]
							  IP:[self.ipField text]
							port:[self.portField text]];
}
#pragma mark -
#pragma mark dealloc

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
	[accountField release];
	[passwordField release];
	[ipField release];
	[portField release];
	[cancelBtn release];
	[connectBtn release];
    [super dealloc];
}


@end
