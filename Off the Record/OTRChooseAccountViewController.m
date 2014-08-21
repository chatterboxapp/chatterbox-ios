//
//  OTRChooseAccountViewController.m
//  Off the Record
//
//  Created by David on 3/7/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRChooseAccountViewController.h"
#import "OTRManagedAccount.h"
#import "OTRNewBuddyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Strings.h"
#import "OTRAccountsManager.h"

@interface OTRChooseAccountViewController ()

@end

@implementation OTRChooseAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = ACCOUNT_STRING;
	
    tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.scrollEnabled =  [self tableView:tableView numberOfRowsInSection:0] * 50.0 > tableView.frame.size.height;
    
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    
    [self.view addSubview: tableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self onlineAccounts] count];
}

-(UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"cell";
    UITableViewCell * cell = [tView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRManagedAccount * account = [[self onlineAccounts] objectAtIndex:indexPath.row];
    OTRNewBuddyViewController * buddyViewController = [[OTRNewBuddyViewController alloc] initWithAccountObjectID:account.objectID];
    [self.navigationController pushViewController:buddyViewController animated:YES];
    
    
    [tView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSFetchedResultsController *)accountsFetchedResultsController
{
    if(_accountsFetchedResultsController)
    {
        return _accountsFetchedResultsController;
    }
    
    _accountsFetchedResultsController = [OTRManagedAccount MR_fetchAllSortedBy:OTRManagedAccountAttributes.username ascending:YES withPredicate:nil groupBy:nil delegate:self];
    
    return _accountsFetchedResultsController;
    
}

-(NSArray *)onlineAccounts
{
    return [OTRAccountsManager allAccountsAbleToAddBuddies];
}

/*
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}
*/
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [tableView reloadData];
    tableView.scrollEnabled =  [self tableView:tableView numberOfRowsInSection:0] * 50.0 > tableView.frame.size.height;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    tableView.scrollEnabled =  [self tableView:tableView numberOfRowsInSection:0] * 50.0 > tableView.frame.size.height;
}

-(void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OTRManagedAccount *account = [[self onlineAccounts] objectAtIndex:indexPath.row];
    cell.textLabel.text = account.username;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = [UIImage imageNamed:account.imageName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if( account.accountType == OTRAccountTypeFacebook)
    {
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
    }
}

-(void)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
