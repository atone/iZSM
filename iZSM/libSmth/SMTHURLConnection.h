//
//  SMTHURLConnection.h
//  BBSAdmin
//
//  Created by HE BIAO on 3/7/14.
//  Copyright (c) 2014 newsmth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMTHURLConnection : NSObject

@property(nonatomic, readonly) int net_error;

@property(nonatomic, readonly, nullable) NSString *net_error_desc;

/* must call after [[alloc]init] */
- (void)init_smth;
/* must call before net_query */
- (void)reset_status;
/* cancel operation */
- (void)cancel;

NS_ASSUME_NONNULL_BEGIN

// thread
- (long)net_GetThreadCnt:(NSString *)board_id;
- (NSArray *_Nullable)net_LoadThreadList:(NSString *)board_id :(long)from :(long)size :(int)brcmode;
- (NSArray *_Nullable)net_SearchArticle:(NSString *)board_id :(NSString *_Nullable)title :(NSString *_Nullable)user :(long)from :(long)size;
- (NSArray *_Nullable)net_GetThread:(NSString *)board_id :(long)article_id :(long)from :(long)size :(int)sort;
- (long)net_GetLastThreadCnt;
- (long)net_GetArticleCnt:(NSString *)board_id;
- (NSDictionary *_Nullable)net_GetArticle:(NSString *)board_id :(long)article_id;
- (long)net_PostArticle:(NSString *)board_id :(NSString *)title :(NSString *)content;
- (long)net_ForwardArticle:(NSString *)board_id :(long)article_id :(NSString *)user;
- (long)net_ReplyArticle:(NSString *)board_id :(long)reply_id :(NSString *)title :(NSString *)content;
- (long)net_CrossArticle:(NSString *)board_id :(long)article_id :(NSString *)dest_board;
- (long)net_ModifyArticle:(NSString *)board_id :(long)article_id :(NSString *)title :(NSString *)content;
- (long)net_DeleteArticle:(NSString *)board_id :(long)article_id;
// attachment
- (NSArray *_Nullable)net_GetAttachmentList;
- (NSArray *_Nullable)net_AddAttachment:(NSData *)attachment :(NSString *)name;
- (NSArray *_Nullable)net_DelAttachment:(NSString *)name;
// mail
- (int)net_GetMailCountSent;
- (NSDictionary *_Nullable)net_GetMailCount;
- (NSArray *_Nullable)net_LoadMailSentList:(long)from :(long)size;
- (NSArray *_Nullable)net_LoadMailList:(long)from :(long)size;
- (NSDictionary *_Nullable)net_GetMailSent:(int)position;
- (NSDictionary *_Nullable)net_GetMail:(int)position;
- (int)net_ReplyMail:(int)position :(NSString *)title :(NSString *)content;
- (long)net_ForwardMail:(int)position :(NSString *)receiver;
- (int)net_PostMail:(NSString *)receiver :(NSString *)title :(NSString *)content;
// refer
- (NSDictionary *_Nullable)net_GetReferCount:(int)mode;
- (NSArray *_Nullable)net_LoadRefer:(int)mode :(long)from :(long)size;
- (int)net_SetReferRead:(int)mode :(int)position;
// hot topics
- (NSArray *_Nullable)net_LoadSectionHot:(long)section;
// favorite
- (NSArray *_Nullable)net_LoadFavorites:(long)group;
- (void)net_AddFav:(NSString *)board_id :(long)group;
- (void)net_DelFav:(NSString *)board_id :(long)group;
// board
- (NSArray *_Nullable)net_LoadBoards:(long)group;
- (NSArray *_Nullable)net_QueryBoard:(NSString *)search;
// section
- (NSArray *_Nullable)net_LoadSection;
- (NSArray *_Nullable)net_ReadSection:(long)section :(long)group;
// user
- (NSDictionary *_Nullable)net_QueryUser:(NSString *)userid;
- (NSArray *_Nullable)net_LoadUserAllFriends:(NSString *)userid;
- (long long)net_LoadUserFriendsTS:(NSString *)userid;
- (int)net_AddUserFriend:(NSString *)userid;
- (int)net_DelUserFriend:(NSString *)userid;

- (NSDictionary *_Nullable)net_ModifyUserFace:(NSData *)imageData;
- (NSDictionary *_Nullable)net_modifyFace:(NSString *)face_fname;
// member
- (NSArray *_Nullable)net_LoadMember:(NSString *)userid :(long)from :(long)size;
- (int)net_JoinMember:(NSString *)board_id;
- (int)net_QuitMember:(NSString *)board_id;
// timeline
- (NSArray *_Nullable)net_LoadTimelineList:(int)friends :(int)loadold :(long)oldid :(long)size :(int)order_thread;
// guess
- (NSArray *_Nullable)net_ListGuess;
- (NSArray *_Nullable)net_ListMatch;
- (NSDictionary *_Nullable)net_LoadGuess:(int)guessid;
- (NSArray *_Nullable)net_ListGuessTop:(int)guessid;
- (int)net_RegGuess:(int)guessid :(NSString *)realname :(NSString *)phone;
- (NSDictionary *_Nullable)net_LoadMatch:(int)guessid :(int)matchid;
- (int)net_VoteMatch:(int)guessid :(int)matchid :(int)sel :(int)money;
// login
- (NSDictionary *_Nullable)net_GetVersion;
- (int)net_LoginBBS:(NSString *)usr :(NSString *)pwd;
- (void)net_LogoutBBS;

NS_ASSUME_NONNULL_END

@end
