//
//  OTRJabberLoginViewController.h
//  Off the Record
//
//  Created by David on 10/20/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginViewController.h"

@interface OTRJabberLoginViewController : OTRXMPPLoginViewController
{
    UITableViewCell * selectedCell;
}

@property (nonatomic, strong) UITextField *domainTextField;
@property (nonatomic, strong) UITextField *portTextField;

@end
