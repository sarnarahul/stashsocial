//
//  StashRecord+CoreDataProperties.m
//  StashSocial
//
//  Created by Rahul Sarna on 11/8/16.
//  Copyright © 2016 AutoKrat Labs. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "StashRecord+CoreDataProperties.h"

@implementation StashRecord (CoreDataProperties)

+ (NSFetchRequest<StashRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"StashRecord"];
}

@dynamic recipientPhoneNumber;
@dynamic placeName;
@dynamic placeAddress;
@dynamic recipientEmail;
@dynamic recordId;
@dynamic placeId;
@dynamic sender;

@end
