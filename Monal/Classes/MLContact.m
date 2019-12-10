//
//  MLContact.m
//  Monal
//
//  Created by Anurodh Pokharel on 11/27/19.
//  Copyright © 2019 Monal.im. All rights reserved.
//

#import "MLContact.h"

@implementation MLContact

-(NSString *) contactDisplayName
{
    if(self.nickName) return self.nickName;
    if (self.fullName) return self.fullName;
    
    return self.contactJid;
}

+(MLContact *) contactFromDictionary:(NSDictionary *) dic
{
    MLContact *contact =[[MLContact alloc] init];
    contact.contactJid=[dic objectForKey:@"buddy_name"];
    contact.nickName=[dic objectForKey:@"nick"];
    contact.fullName=[dic objectForKey:@"full_name"];
    contact.imageFile=[dic objectForKey:@"filename"];
    
    contact.accountId=[NSString stringWithFormat:@"%@", [dic objectForKey:@"account_id"]];
    
    contact.isGroup=[[dic objectForKey:@"muc"] boolValue];
    contact.groupSubject=[dic objectForKey:@"muc_subject"];
    contact.accountNickInGroup=[dic objectForKey:@"muc_nick"];
    
    contact.statusMessage=[dic objectForKey:@"status"];
    contact.state=[dic objectForKey:@"state"];
    
    contact.unreadCount=[[dic objectForKey:@"count"] integerValue];
    
    return contact;
}

+(MLContact *) contactFromDictionary:(NSDictionary *) dic withDateFormatter:(NSDateFormatter *) formatter
{
    MLContact *contact = [MLContact contactFromDictionary:dic];
    contact.lastMessageTime = [formatter dateFromString:[dic objectForKey:@"lastMessageTime"]]; 
    return contact;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.contactJid forKey:@"contactJid"];
    [coder encodeObject:self.nickName forKey:@"nickName"];
    [coder encodeObject:self.fullName forKey:@"fullName"];
    [coder encodeObject:self.imageFile forKey:@"imageFile"];
    [coder encodeObject:self.accountId forKey:@"accountId"];
    [coder encodeBool:self.isGroup forKey:@"isGroup"];
    [coder encodeObject:self.groupSubject forKey:@"groupSubject"];
    [coder encodeObject:self.statusMessage forKey:@"statusMessage"];
    [coder encodeObject:self.state forKey:@"state"];
    [coder encodeInteger:self.unreadCount forKey:@"unreadCount"];
    
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self=[super init];
    
    self.contactJid=[coder decodeObjectForKey:@"contactJid"];
    self.nickName=[coder decodeObjectForKey:@"nickName"];
    self.fullName=[coder decodeObjectForKey:@"fullName"];
    self.imageFile=[coder decodeObjectForKey:@"imageFile"];
    
    self.accountId=[coder decodeObjectForKey:@"accountId"];
    
    self.isGroup=[coder decodeBoolForKey:@"isGroup"];
    self.groupSubject=[coder decodeObjectForKey:@"groupSubject"];
    self.accountNickInGroup=[coder decodeObjectForKey:@"accountNickInGroup"];
    
    self.statusMessage=[coder decodeObjectForKey:@"status"];
    self.state=[coder decodeObjectForKey:@"state"];
    
    self.unreadCount=[coder decodeIntegerForKey:@"unreadCount"] ;
    
    return self; 
}


@end