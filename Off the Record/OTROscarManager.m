//
//  OTROscarManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTROscarManager.h"
#import "OTRProtocolManager.h"
#import "OTRConstants.h"
#import "Strings.h"

@interface OTROscarManager ()

@property (nonatomic, strong) OTRManagedAccount * account;
@property (nonatomic) BOOL isConnected;

@end

@implementation OTROscarManager

@synthesize accountName;
@synthesize aimBuddyList;
@synthesize theSession;
@synthesize login;
@synthesize loginFailed;

BOOL loginFailed;

-(id)initWithAccount:(OTRManagedAccount *)newAccount
{
    self = [super init];
    if(self)
    {
        self.account = newAccount;
        mainThread = [NSThread currentThread];
        self.isConnected = NO;
    }
    return self;
}

- (BOOL)isConnected
{
    return _isConnected;
}

- (OTRManagedAccount *)account
{
    return _account;
}

- (void)blockingCheck {
	static NSDate * lastTime = nil;
	if (!lastTime) {
		lastTime = [NSDate date];
	} else {
		NSDate * newTime = [NSDate date];
		NSTimeInterval ti = [newTime timeIntervalSinceDate:lastTime];
		if (ti > 0.2) {
			//DDLogWarn(@"Main thread blocked for %d milliseconds.", (int)round(ti * 1000.0));
		}
		lastTime = newTime;
	}
	[self performSelector:@selector(blockingCheck) withObject:nil afterDelay:0.05];
}

- (void)checkThreading {
	if ([NSThread currentThread] != mainThread) {
		//DDLogWarn(@"warning: NOT RUNNING ON MAIN THREAD!");
	}
}

-(OTRBuddyStatus)convertAimStatus:(AIMBuddyStatus *)status
{
    OTRBuddyStatus buddyStatus;
    
    switch (status.statusType)
    {
        case AIMBuddyStatusAvailable:
            buddyStatus = OTRBuddyStatusAvailable;
            break;
        case AIMBuddyStatusAway:
            buddyStatus = OTRBuddyStatusAway;
            break;
        default:
            buddyStatus = OTRBuddyStatusOffline;
            break;
    }
    
    return buddyStatus;
}

-(OTRManagedBuddy *)updateManagedBuddyWith:(AIMBlistBuddy *)buddy
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRBuddyStatus buddyStatus = [self convertAimStatus:buddy.status];
    OTRManagedAccount *localAccount = [self.account MR_inContext:context];
    
    OTRManagedBuddy *otrBuddy = [OTRManagedBuddy fetchOrCreateWithName:buddy.username account:self.account inContext:context];
    
    otrBuddy.displayName = buddy.username;
    [otrBuddy newStatusMessage:buddy.status.statusMessage status:buddyStatus incoming:YES inContext:context];
    
    UIImage * photo = [UIImage imageWithData:[buddy.buddyIcon iconData]];
    otrBuddy.photo = photo;
    
    [otrBuddy addToGroup:buddy.group.name inContext:context];
    otrBuddy.account = localAccount;
    
    [context MR_saveToPersistentStoreAndWait];
    return otrBuddy;
}

-(void)updateMangedBuddyWith:(AIMBlistBuddy *)buddy withStatus:(AIMBuddyStatus *)status
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
        OTRBuddyStatus buddyStatus = [self convertAimStatus:status];
        OTRManagedBuddy *otrBuddy = [self updateManagedBuddyWith:buddy];
        [otrBuddy newStatusMessage:status.statusMessage status:buddyStatus incoming:YES inContext:context];
        [context MR_saveToPersistentStoreAndWait];
    });
}


#pragma mark Login Delegate

-(void)authorizer:(id)authorizer didFailWithError:(NSError *)error {
    //DDLogError(@"Authorizer Error: %@",[error description]);
}

- (void)aimLogin:(AIMLogin *)theLogin failedWithError:(NSError *)error {
	[self checkThreading];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginFail object:self];
    //DDLogError(@"login error: %@",[error description]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"AIM login failed. Please check your username and password and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    self.isConnected = NO;
    [alert show];
}

- (void)aimLogin:(AIMLogin *)theLogin openedSession:(AIMSessionManager *)session {
	[self checkThreading];
	[session setDelegate:self];
	login = nil;
	theSession = session;
    self.isConnected = YES;
    //s_AIMSession = theSession;
	
	/* Set handler delegates */
	session.feedbagHandler.delegate = self;
	session.messageHandler.delegate = self;
	session.statusHandler.delegate = self;
	session.rateHandler.delegate = self;
	session.rendezvousHandler.delegate = self;
	
	[session configureBuddyArt];
	AIMCapability * fileTransfers = [[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer];
	AIMCapability * getFiles = [[AIMCapability alloc] initWithType:AIMCapabilityGetFiles];
	NSArray * caps = [NSArray arrayWithObjects:fileTransfers, getFiles, nil];
	AIMBuddyStatus * newStatus = [[AIMBuddyStatus alloc] initWithMessage:@"Available" type:AIMBuddyStatusAvailable timeIdle:0 caps:caps];
	[session.statusHandler updateStatus:newStatus];
    
	//DDLogInfo(@"Got session: %@", session);
	//DDLogInfo(@"Our status: %@", session.statusHandler.userStatus);
	//DDLogInfo(@"Disconnecting in %d seconds ...", kSignoffTime);
	//[[session session] performSelector:@selector(closeConnection) withObject:nil afterDelay:kSignoffTime];
	
	// uncomment to test rate limit detection.
	// [self sendBogus];
        
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginSuccess
     object:self];
}

#pragma mark Session Delegate

- (void)aimSessionManagerSignedOff:(AIMSessionManager *)sender {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [self.account setAllBuddiesStatuts:OTRBuddyStatusOffline inContext:context];
    
    if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
    {
        [self.account deleteAllAccountMessagesInContext:context];
    }
    
    [context MR_saveToPersistentStoreAndWait];
    
	[self checkThreading];
    self.isConnected = NO;
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    [protocolManager.protocolManagers removeObjectForKey:self.account.uniqueIdentifier];
    aimBuddyList = nil;
	theSession = nil;
    
	///DDLogInfo(@"Session signed off");
    
    
    
}

#pragma mark Buddy List Methods

- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler {
	[self checkThreading];
	//DDLogInfo(@"%@ got the buddy list.", feedbagHandler);
	//DDLogInfo(@"Blist: %@", );
    
    aimBuddyList = [theSession.session buddyList];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        for(AIMBlistGroup *group in aimBuddyList.groups)
        {
            for(AIMBlistBuddy *buddy in group.buddies)
            {
                [self updateManagedBuddyWith:buddy];
            }
        }
    });
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy {
	[self checkThreading];
	//DDLogInfo(@"Buddy added: %@", newBuddy);
    [self updateManagedBuddyWith:newBuddy];
    
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy {
	[self checkThreading];
	//DDLogInfo(@"Buddy removed: %@", oldBuddy);
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    
    OTRManagedBuddy * buddy = [OTRManagedBuddy fetchOrCreateWithName:oldBuddy.username account:self.account inContext:context];
    [buddy MR_deleteInContext:context];
    
    [context MR_saveToPersistentStoreAndWait];
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup {
	[self checkThreading];
	//DDLogInfo(@"Group added: %@", [newGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup {
	[self checkThreading];
	//DDLogInfo(@"Group removed: %@", [oldGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup {
	[self checkThreading];
	//DDLogInfo(@"Group renamed: %@", [theGroup name]);
	//DDLogInfo(@"Blist: %@", theSession.session.buddyList);
    
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDenied:(NSString *)username {
	//DDLogInfo(@"User blocked: %@", username);
    
    
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyPermitted:(NSString *)username {
	//DDLogInfo(@"User permitted: %@", username);
    
    
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUndenied:(NSString *)username {
	//DDLogInfo(@"User un-blocked: %@", username);
    
    
}
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUnpermitted:(NSString *)username {
	//DDLogInfo(@"User un-permitted: %@", username);
    
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender transactionFailed:(id<FeedbagTransaction>)transaction {
	[self checkThreading];
	//DDLogWarn(@"Transaction failed: %@", transaction);
}

#pragma mark Message Handler

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMessage:(AIMMessage *)message {
	[self checkThreading];
	
	NSString * msgTxt = [message plainTextMessage];
	
	//NSString * autoresp = [message isAutoresponse] ? @" (Auto-Response)" : @"";
	//DDLogInfo(@"(%@) %@%@: %@", [NSDate date], [[message buddy] username], autoresp, [message plainTextMessage]);
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    
    OTRManagedBuddy * messageBuddy = [OTRManagedBuddy fetchOrCreateWithName:message.buddy.username account:self.account inContext:context];
    
    OTRManagedMessage *otrMessage = [OTRManagedMessage newMessageFromBuddy:messageBuddy message:msgTxt encrypted:YES delayedDate:nil inContext:context];
    
    [context MR_saveToPersistentStoreAndWait];
    
    [OTRCodec decodeMessage:otrMessage completionBlock:^(OTRManagedMessage *message) {
        [OTRManagedMessage showLocalNotificationForMessage:message];
    }];
    

	NSArray * tokens = [CommandTokenizer tokensOfCommand:msgTxt];
	if ([tokens count] == 1) {
		if ([[tokens objectAtIndex:0] isEqual:@"blist"]) {
			NSString * desc = [[theSession.session buddyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"takeicon"]) {
			NSData * iconData = [[[message buddy] buddyIcon] iconData];
			if (iconData) {
				[theSession.statusHandler updateUserIcon:iconData];
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Icon set requested."]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Couldn't get your icon!"]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"bye"]) {
			[[theSession session] closeConnection];
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * desc = [[[theSession.session buddyList] denyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"permit"]) {
			NSString * desc = [[[theSession.session buddyList] permitList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"pdmode"]) {
			NSString * desc = PD_MODE_TOSTR([theSession.feedbagHandler currentPDMode:NULL]);
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"caps"]) {
			NSString * desc = [[[[message buddy] status] capabilities] description];
			if (desc) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Capabilities unavailable."]];
			}
		}
	} else if ([tokens count] == 2) {
		if ([[tokens objectAtIndex:0] isEqual:@"delbuddy"]) {
			NSString * msg = [self removeBuddy:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"addgroup"]) {
			NSString * msg = [self addGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"delgroup"]) {
			NSString * msg = [self deleteGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"echo"]) {
			NSString * msg = [tokens objectAtIndex:1];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"sendfile"]) {
			NSString * messagestr = [tokens objectAtIndex:1];
			BOOL canTransfer = NO;
			for (AIMCapability * cap in message.buddy.status.capabilities) {
				if ([cap capabilityType] == AIMCapabilityFileTransfer) {
					canTransfer = YES;
				}
			}
			if (canTransfer) {
				NSString * tempPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/%d%ld.txt", arc4random(), time(NULL)];
				[messagestr writeToFile:tempPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
				if (![theSession.rendezvousHandler sendFile:tempPath toUser:message.buddy]) {
					[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: sendfile failed." stringByAddingAOLRTFTags]]];
				} else {
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Sendfile started." stringByAddingAOLRTFTags]]];
				}
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: you can't receive files." stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * msg = [self denyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"undeny"]) {
			NSString * msg = [self undenyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	} else if ([tokens count] == 3) {
		if ([[tokens objectAtIndex:0] isEqual:@"addbuddy"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * buddy = [tokens objectAtIndex:2];
			NSString * msg = [self addBuddy:buddy toGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	}
}

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMissedCall:(AIMMissedCall *)missedCall {
	[self checkThreading];
	//DDLogInfo(@"Missed call from %@", [missedCall buddy]);
}

#pragma mark Status Handler

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status {
	[self checkThreading];
	//DDLogInfo(@"\"%@\"%s%@", theBuddy, ".status = ", status);
    [self updateMangedBuddyWith:theBuddy withStatus:status];
    
}

- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler {
	[self checkThreading];
	//DDLogInfo(@"user.status = %@", [handler userStatus]);
    
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy {
	[self checkThreading];
    
    [self updateManagedBuddyWith:theBuddy];
    
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dirPath = [paths objectAtIndex:0];
    
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		NSString * path = nil;
		AIMBuddyIconFormat fmt = [[theBuddy buddyIcon] iconDataFormat];
		switch (fmt) {
			case AIMBuddyIconBMPFormat:
				path = [dirPath stringByAppendingFormat:@"%@.bmp", [theBuddy username]];
				break;
			case AIMBuddyIconGIFFormat:
				path = [dirPath stringByAppendingFormat:@"%@.gif", [theBuddy username]];
				break;
			case AIMBuddyIconJPEGFormat:
				path = [dirPath stringByAppendingFormat:@"%@.jpg", [theBuddy username]];
				break;
			default:
				break;
		}
		if (path) {
			[[[theBuddy buddyIcon] iconData] writeToFile:path atomically:YES];
		}
	}
    */
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler setIconFailed:(AIMIconUploadErrorType)reason {
	//DDLogWarn(@"Failed to set our buddy icon.");
}

#pragma mark Rate Handlers

- (void)aimRateLimitHandler:(AIMRateLimitHandler *)handler gotRateAlert:(AIMRateNotificationInfo *)info {
	// use this to show the user that they should stop sending messages.
	//DDLogWarn(@"Rate alert");
}

#pragma mark File Transfers

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferRequested:(AIMReceivingFileTransfer *)ft {
	/*DDLogInfo(@"Auto-accepting transfer: %@", ft);
     NSString * path = [NSString stringWithFormat:@"/var/tmp/%@", [ft remoteFileName]];
     [rvHandler acceptFileTransfer:ft saveToPath:path];
     DDLogInfo(@"Save to path: %@", path);*/
    //DDLogInfo(@"File transfer disabled.");
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferCancelled:(AIMFileTransfer *)ft reason:(UInt16)reason {
	//DDLogInfo(@"File transfer cancelled: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferFailed:(AIMFileTransfer *)ft {
	//DDLogInfo(@"File transfer failed: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferStarted:(AIMFileTransfer *)ft {
	//DDLogInfo(@"File transfer started: %@", ft);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferProgressChanged:(AIMFileTransfer *)ft {
	// cancel it a bit of the way through to test that cancelling works.
	// if ([ft progress] > 0.1) [rvHandler cancelFileTransfer:ft];
	// DDLogVerbose(@"%@ progress = %f", ft, [ft progress]);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferDone:(AIMFileTransfer *)ft {
	//DDLogInfo(@"File transfer done: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

#pragma mark Commands

- (NSString *)removeBuddy:(NSString *)username {
	AIMBlistBuddy * buddy = [theSession.session.buddyList buddyWithUsername:username];
	if (buddy && [buddy group]) {
		FTRemoveBuddy * remove = [[FTRemoveBuddy alloc] initWithBuddy:buddy];
		[theSession.feedbagHandler pushTransaction:remove];
		return @"Remove (buddy) request sent.";
	} else {
		return @"Err: buddy not found.";
	}
}
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	AIMBlistBuddy * buddy = [group buddyWithUsername:username];
	if (buddy) {
		return @"Err: buddy exists.";
	}
	FTAddBuddy * addBudd = [[FTAddBuddy alloc] initWithUsername:username group:group];
	[theSession.feedbagHandler pushTransaction:addBudd];
	return @"Add (buddy) request sent.";
}
- (NSString *)deleteGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	FTRemoveGroup * delGrp = [[FTRemoveGroup alloc] initWithGroup:group];
	[theSession.feedbagHandler pushTransaction:delGrp];
	return @"Delete (group) request sent.";
}
- (NSString *)addGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (group) {
		return @"Err: group exists.";
	}
	FTAddGroup * addGrp = [[FTAddGroup alloc] initWithName:groupName];
	[theSession.feedbagHandler pushTransaction:addGrp];
	return @"Add (group) request sent.";
}
- (NSString *)denyUser:(NSString *)username {
	NSString * msg = @"Deny add sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		FTSetPDMode * pdMode = [[FTSetPDMode alloc] initWithPDMode:PD_MODE_DENY_SOME pdFlags:PD_FLAGS_APPLIES_IM];
		[theSession.feedbagHandler pushTransaction:pdMode];
		msg = @"Set PD_MODE and sent add deny";
	}
	FTAddDeny * deny = [[FTAddDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:deny];
	return msg;
}
- (NSString *)undenyUser:(NSString *)username {
	NSString * msg = @"Deny delete sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		msg = @"Warning: Deny delete sent but PD_MODE isn't DENY_SOME";
	}
	FTDelDeny * delDeny = [[FTDelDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:delDeny];
	return msg;
}

/*+(AIMSessionManager*) AIMSession
{
    return s_AIMSession;
}*/

-(void)sendMessage:(OTRManagedMessage *)theMessage
{
    NSString *recipient = theMessage.buddy.accountName;
    NSString *message = theMessage.message;
    dispatch_async(dispatch_get_main_queue(), ^{
        AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:recipient] message:message];
        
        // use delay to prevent OSCAR rate-limiting problem
        //NSDate *future = [NSDate dateWithTimeIntervalSinceNow: delay ];
        //[NSThread sleepUntilDate:future];
        
        [theSession.messageHandler sendMessage:msg];
    });
}

-(void)connectWithPassword:(NSString *)myPassword
{
    // LibOrange has security problems, sorry!
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: AIM_REMOVED_TITLE_STRING,
                               NSLocalizedFailureReasonErrorKey: AIM_REMOVED_MESSAGE_STRING};
    NSError *error = [NSError errorWithDomain:@"com.chatterbox.Chatterbox" code:500 userInfo:userInfo];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginFail object:self userInfo:@{kOTRProtocolLoginFailErrorKey:error}];
    
    /*** WARNING LibOrange has security problems. ***
    self.login = [[AIMLogin alloc] initWithUsername:account.username password:myPassword];
    [self.login setDelegate:self];
    [self.login beginAuthorization];
    */
}
-(void)disconnect
{
    [[self theSession].session closeConnection];
   
    
}

- (void) addBuddy:(OTRManagedBuddy *)newBuddy
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [self undenyUser:newBuddy.accountName];
    AIMBlistGroup * group = [theSession.session.buddyList groupWithName:@"Buddies"];
    if(!group)
    {
        [self addGroup:@"Buddies"];
    }
    [newBuddy addToGroup:@"Buddies" inContext:context];
    
    [context MR_saveToPersistentStoreAndWait];
    [self addBuddy:newBuddy.accountName toGroup:@"Buddies"];
}

-(void)removeBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies)
    {
        [self removeBuddy:buddy.accountName];
    }
        
}
-(void)blockBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        [self denyUser:buddy.accountName];
    }
    
}

@end
