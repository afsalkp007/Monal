//
//  MLChatViewController.m
//  Monal
//
//  Created by Anurodh Pokharel on 6/28/15.
//  Copyright (c) 2015 Monal.im. All rights reserved.
//

#import "MLChatViewController.h"
#import "MLConstants.h"
#import "DataLayer.h"
#import "DDLog.h"
#import "MLXMPPManager.h"
#import "MLChatViewCell.h"
//#import "MLNotificaitonCenter.h"

@interface MLChatViewController ()

@property (nonatomic, strong) NSMutableArray *messageList;

@property (nonatomic, strong)  NSDateFormatter* destinationDateFormat;
@property (nonatomic, strong)  NSDateFormatter* sourceDateFormat;
@property (nonatomic, strong)  NSCalendar *gregorian;
@property (nonatomic, assign) NSInteger thisyear;
@property (nonatomic, assign) NSInteger thismonth;
@property (nonatomic, assign) NSInteger thisday;


@property (nonatomic, strong) NSString *accountNo;
@property (nonatomic, strong) NSString *contactName;
@property (nonatomic, strong) NSString *jid;
@property (nonatomic, assign) BOOL isMUC;

@property (nonatomic, assign) BOOL firstmsg;

@end

@implementation MLChatViewController

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleNewMessage:) name:kMonalNewMessageNotice object:nil];
    [nc addObserver:self selector:@selector(handleSendFailedMessage:) name:kMonalSendFailedMessageNotice object:nil];
    [nc addObserver:self selector:@selector(handleSentMessage:) name:kMonalSentMessageNotice object:nil];
    
    [self setupDateObjects];
    
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) showConversationForContact:(NSDictionary *) contact
{
//    [MLNotificationManager sharedInstance].currentAccountNo=self.accountNo;
//    [MLNotificationManager sharedInstance].currentContact=self.contactName;


    
    self.accountNo = [NSString stringWithFormat:@"%@",[contact objectForKey:kAccountID]];
    self.contactName = [contact objectForKey:kContactName];
    
    self.messageList =[[DataLayer sharedInstance] messageHistory:self.contactName forAccount: self.accountNo];

#warning this should be smarter...
    NSArray* accountVals =[[DataLayer sharedInstance] accountVals:self.accountNo];
    if([accountVals count]>0)
    {
        self.jid=[NSString stringWithFormat:@"%@@%@",[[accountVals objectAtIndex:0] objectForKey:kUsername], [[accountVals objectAtIndex:0] objectForKey:kDomain]];
    }
    
    [self.chatTable reloadData];
    [self scrollToBottom];
}


-(void) scrollToBottom
{
    NSInteger bottom = [self.chatTable numberOfRows];
    if(bottom>0)
    {
        [self.chatTable scrollRowToVisible:bottom-1];
    }
}

#pragma mark -- notificaitons
-(void) handleNewMessage:(NSNotification *)notification
{
    DDLogVerbose(@"chat view got new message notice %@", notification.userInfo);
    
    if([[notification.userInfo objectForKey:@"accountNo"] isEqualToString:_accountNo]
       &&( ( [[notification.userInfo objectForKey:@"from"] isEqualToString:_contactName]) || ([[notification.userInfo objectForKey:@"to"] isEqualToString:_contactName] ))
       )
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           NSDictionary* userInfo;
                           if([[notification.userInfo objectForKey:@"to"] isEqualToString:_contactName])
                           {
                               userInfo = @{@"af": [notification.userInfo objectForKey:@"actuallyfrom"],
                                            @"message": [notification.userInfo objectForKey:@"messageText"],
                                            @"thetime": [self currentGMTTime],   @"delivered":@YES};
                               
                           } else  {
                               userInfo = @{@"af": [notification.userInfo objectForKey:@"actuallyfrom"],
                                            @"message": [notification.userInfo objectForKey:@"messageText"],
                                            @"thetime": [self currentGMTTime]
                                            };
                           }
                           
                           [self.messageList addObject:userInfo];
                           [self.chatTable reloadData];
                           
//                           [_messageTable beginUpdates];
//                           NSIndexPath *path1;
//                           NSInteger bottom = [_messageTable numberOfRowsInSection:0];
//                           if(bottom>0) {
//                               path1 = [NSIndexPath indexPathForRow:bottom-1  inSection:0];
//                               [_messageTable insertRowsAtIndexPaths:@[path1]
//                                                    withRowAnimation:UITableViewRowAnimationBottom];
//                           }
//                           
//                           [_messageTable endUpdates];
                           
                           [self scrollToBottom];
                           
                           //mark as read
                           [[DataLayer sharedInstance] markAsReadBuddy:_contactName forAccount:_accountNo];
                       });
    }

    
}

-(void) handleSendFailedMessage:(NSNotification *)notification
{
    NSDictionary *dic =notification.userInfo;
    [self setMessageId:[dic objectForKey:kMessageId]  delivered:NO];
}

-(void) handleSentMessage:(NSNotification *)notification
{
    NSDictionary *dic =notification.userInfo;
    [self setMessageId:[dic objectForKey:kMessageId]  delivered:YES];
}

#pragma mark - sending

//always messages going out
-(void) addMessageto:(NSString*)to withMessage:(NSString*) message andId:(NSString *) messageId
{
    if(!self.jid || !message)  {
        DDLogError(@" not ready to send messages");
        return;
    }
    
    if([[DataLayer sharedInstance] addMessageHistoryFrom:self.jid to:to forAccount:[NSString stringWithFormat:@"%@",self.accountNo] withMessage:message actuallyFrom:self.jid withId:messageId])
    {
        DDLogVerbose(@"added message %@, %@ %@", message, messageId, [self currentGMTTime]);
        
        NSDictionary* userInfo = @{@"af": self.jid,
                                   @"message": message ,
                                   @"thetime": [self currentGMTTime],
                                   kDelivered:@YES,
                                   kMessageId: messageId
                                   };
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                          
                           [self.messageList addObject:[userInfo mutableCopy]];
                           [self.chatTable reloadData];
                           
                           //                           NSIndexPath *path1;
                           //                           [self.chatTable beginUpdates];
                           //                           NSInteger bottom = [_messageTable numberOfRowsInSection:0];
                           //                           if(bottom>0) {
                           //                               path1 = [NSIndexPath indexPathForRow:bottom  inSection:0];
                           //                               [_messageTable insertRowsAtIndexPaths:@[path1]
                           //                                                    withRowAnimation:UITableViewRowAnimationBottom];
                           //                           }
                           //                           [_messageTable endUpdates];
                           
                           [self scrollToBottom];
                           
                       });
        
    }
    else {
        DDLogVerbose(@"failed to add message");
    }
    
    // make sure its in active
    if(self.firstmsg==YES)
    {
        [[DataLayer sharedInstance] addActiveBuddies:to forAccount:_accountNo];
        self.firstmsg=NO;
    }
    
}

-(void) setMessageId:(NSString *) messageId delivered:(BOOL) delivered
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       
                       [self.chatTable reloadData];
                       
                       //                       int row=0;
                       //                       for(NSMutableDictionary *rowDic in self.messageList)
                       //                       {
                       //                           if([[rowDic objectForKey:kMessageId] isEqualToString:messageId]) {
                       //                               [rowDic setObject:[NSNumber numberWithBool:delivered] forKey:kDelivered];
                       //                               NSIndexPath *indexPath =[NSIndexPath indexPathForRow:row inSection:0];
                       //                               dispatch_async(dispatch_get_main_queue(), ^{
                       //                                   [_messageTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                       //                               });
                       //                               break;
                       //                           }
                       //                           row++;
                       //                       }
                   });
}

-(void) sendMessage:(NSString *) messageText andMessageID:(NSString *)messageID
{
    DDLogVerbose(@"Sending message %@", messageText);
    u_int32_t r = arc4random_uniform(30000000);
    NSString *newMessageID =messageID;
    if(!newMessageID) {
        newMessageID=[NSString stringWithFormat:@"Monal%d", r];
    }
    [[MLXMPPManager sharedInstance] sendMessage:messageText toContact:self.contactName fromAccount:self.accountNo isMUC:self.isMUC messageId:newMessageID
                          withCompletionHandler:nil];
    
    //dont readd it, use the exisitng
    if(!messageID) {
        [self addMessageto:_contactName withMessage:messageText andId:newMessageID];
    }
}


-(IBAction)send:(id)sender
{
    [self sendMessage:[self.messageBox.string copy] andMessageID:nil];
    self.messageBox.string=@"";
}

#pragma mark -table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self.messageList count];
}

#pragma mark - table view delegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn  row:(NSInteger)row
{
    
    NSDictionary *messageRow = [self.messageList objectAtIndex:row];
    MLChatViewCell *cell;
    
    if([[messageRow objectForKey:@"af"] isEqualToString:self.jid]) {
        cell = [tableView makeViewWithIdentifier:@"OutboundTextCell" owner:self];
        cell.messageText.textColor = [NSColor whiteColor];
        cell.messageText.linkTextAttributes =@{NSForegroundColorAttributeName:[NSColor whiteColor], NSUnderlineStyleAttributeName: @YES};
    }
    else  {
        cell = [tableView makeViewWithIdentifier:@"InboundTextCell" owner:self];
        cell.messageText.linkTextAttributes =@{NSForegroundColorAttributeName:[NSColor blackColor], NSUnderlineStyleAttributeName: @YES};
    }
    
    cell.messageText.editable=YES;
    cell.messageText.string =[messageRow objectForKey:@"message"];
    [cell.messageText checkTextInDocument:nil];
    cell.messageText.editable=NO;
    
    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSDictionary *messageRow = [self.messageList objectAtIndex:row];
    NSString *messageString =[messageRow objectForKey:@"message"];

    NSDictionary *attributes = @{NSFontAttributeName: [NSFont systemFontOfSize:13.0f]};
    NSSize size = NSMakeSize(272, MAXFLOAT);
    CGRect rect = [messageString boundingRectWithSize:size options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:attributes];

   
    if(rect.size.height<25)  {
        return  25.0f;
    }
    else {
       return rect.size.height+5+5;
    
    }
}

#pragma mark date time

-(void) setupDateObjects
{
    self.destinationDateFormat = [[NSDateFormatter alloc] init];
    [self.destinationDateFormat setLocale:[NSLocale currentLocale]];
    [self.destinationDateFormat setDoesRelativeDateFormatting:YES];
    
    self.sourceDateFormat = [[NSDateFormatter alloc] init];
    [self.sourceDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.gregorian = [[NSCalendar alloc]
                      initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate* now =[NSDate date];
    self.thisday =[self.gregorian components:NSDayCalendarUnit fromDate:now].day;
    self.thismonth =[self.gregorian components:NSMonthCalendarUnit fromDate:now].month;
    self.thisyear =[self.gregorian components:NSYearCalendarUnit fromDate:now].year;
    
    
}

-(NSString*) currentGMTTime
{
    NSDate* sourceDate =[NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone systemTimeZone];
    NSTimeZone* destinationTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    
    return [self.sourceDateFormat stringFromDate:destinationDate];
}

-(NSString*) formattedDateWithSource:(NSString*) sourceDateString
{
    NSString* dateString;
    
    if(sourceDateString!=nil)
    {
        
        NSDate* sourceDate=[self.sourceDateFormat dateFromString:sourceDateString];
        
        NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
        NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
        NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
        NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
        NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
        
        NSInteger msgday =[self.gregorian components:NSDayCalendarUnit fromDate:destinationDate].day;
        NSInteger msgmonth=[self.gregorian components:NSMonthCalendarUnit fromDate:destinationDate].month;
        NSInteger msgyear =[self.gregorian components:NSYearCalendarUnit fromDate:destinationDate].year;
        
        if ((self.thisday!=msgday) || (self.thismonth!=msgmonth) || (self.thisyear!=msgyear))
        {
            
            //no more need for seconds
            [self.destinationDateFormat setTimeStyle:NSDateFormatterShortStyle];
            
            // note: if it isnt the same day we want to show the full  day
            [self.destinationDateFormat setDateStyle:NSDateFormatterMediumStyle];
            
            //cache date
            
        }
        else
        {
            //today just show time
            [self.destinationDateFormat setDateStyle:NSDateFormatterNoStyle];
            [self.destinationDateFormat setTimeStyle:NSDateFormatterMediumStyle];
        }
        
        dateString = [ self.destinationDateFormat stringFromDate:destinationDate];
    }
    
    return dateString;
}


@end