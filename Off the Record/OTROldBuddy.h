//
//  OTRBuddy.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
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

#import <Foundation/Foundation.h>
#import "OTRProtocol.h"
#import "OTRManagedBuddy.h"
#import "OTRKit.h"


#define MESSAGE_PROCESSED_NOTIFICATION @"MessageProcessedNotification"
#define kOTREncryptionStateNotification @"kOTREncryptionStateNotification"


@interface OTRBuddy : NSObject


@property (nonatomic, retain) NSString* displayName;
@property (nonatomic, retain) NSString* accountName;
@property (nonatomic, retain) NSString* groupName;
@property (nonatomic, retain) NSMutableString* chatHistory;
@property (nonatomic, retain) NSString *lastMessage;
@property (nonatomic, strong) NSString * composingMessageString;
@property (nonatomic, retain) id<OTRProtocol> protocol;
@property (nonatomic) BOOL lastMessageDisconnected;
@property (nonatomic) int numberOfMessagesSent;

@property (nonatomic) OTRBuddyStatus status;
@property (nonatomic) OTRKitMessageState encryptionStatus;
@property (nonatomic) OTRChatState chatState;
@property (nonatomic) OTRChatState lastSentChatState;

@property (nonatomic, strong) NSTimer * pausedChatStateTimer;
@property (nonatomic, strong) NSTimer * inactiveChatStateTimer;

-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;
+(OTRBuddy*)buddyWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(id <OTRProtocol>)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName;

-(void)receiveMessage:(NSString *)message;
-(void)receiveChatStateMessage:(OTRChatState) chatState;
-(void)receiveReceiptResonse:(NSString *)responseID;
-(void)sendMessage:(NSString *)message secure:(BOOL)secure;
-(void)sendPausedChatState;
-(void)sendActiveChatState;
-(void)sendInactiveChatState;
-(void)sendComposingChatState;

@end
