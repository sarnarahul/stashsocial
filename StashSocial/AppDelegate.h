//
//  AppDelegate.h
//  StashSocial
//
//  Created by Rahul Sarna on 11/3/16.
//  Copyright © 2016 AutoKrat Labs. All rights reserved.
//


// Key: AIzaSyBU2SB6o1jachh9vlYq35Tr6q6emYqsC0E

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@import Contacts;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) CNContactStore *contanctStore;
@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;
- (void) requestForContactsAccessWithCompletionHandler: (void (^)(BOOL granted))completionHandler;

+ (AppDelegate *) getAppDelegate;

@end

