//
//  StashRecord+CoreDataProperties.h
//  StashSocial
//
//  Created by Rahul Sarna on 11/8/16.
//  Copyright © 2016 AutoKrat Labs. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "StashRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface StashRecord (CoreDataProperties)

+ (NSFetchRequest<StashRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *recipientPhoneNumber;
@property (nullable, nonatomic, copy) NSString *placeName;
@property (nullable, nonatomic, copy) NSString *placeAddress;
@property (nullable, nonatomic, copy) NSString *recipientEmail;
@property (nonatomic) int64_t recordId;
@property (nullable, nonatomic, copy) NSString *placeId;
@property (nullable, nonatomic, copy) NSString *sender;

@end

NS_ASSUME_NONNULL_END
