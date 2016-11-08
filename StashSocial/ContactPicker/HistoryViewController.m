//
//  ContactPickerViewController.m
//  StashSocial
//
//  Created by Rahul Sarna on 11/7/16.
//  Copyright © 2016 AutoKrat Labs. All rights reserved.
//

#import "HistoryViewController.h"
#import "StashRecord+CoreDataProperties.h"
#import "CoreDataHelper.h"
#import "AppDelegate.h"

@interface HistoryViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSManagedObjectContext *localContext;
@property (nonatomic, strong) NSArray *recordsArray;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _recordsArray = [CoreDataHelper getObjectsForEntity:@"StashRecord" withSortKey:nil andSortAscending:YES andContext:[self getLocalContext]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _recordsArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    StashRecord *record = [self.recordsArray objectAtIndex:indexPath.row];
    
    NSString *recipientText = [NSString stringWithFormat:@"%@ (%@)", record.recipientName, record.recipientEmail !=nil ? record.recipientEmail : record.recipientPhoneNumber];

    NSString *placeText = [NSString stringWithFormat:@"%@ (%@)", record.placeName, record.placeAddress];
    
    cell.textLabel.text = recipientText;
    cell.detailTextLabel.text = placeText;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    StashRecord *record = [self.recordsArray objectAtIndex:indexPath.row];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openPlaceId" object:nil userInfo:@{@"placeId": record.placeId}];
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSManagedObjectContext *) getLocalContext{
    if(_localContext != nil){
        return _localContext;
    }
    
    NSManagedObjectContext *mainContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    _localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_localContext setParentContext:mainContext];
    
    return _localContext;
}

@end
