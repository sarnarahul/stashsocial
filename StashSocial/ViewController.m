//
//  ViewController.m
//  StashSocial
//
//  Created by Rahul Sarna on 11/3/16.
//  Copyright © 2016 AutoKrat Labs. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "HistoryViewController.h"
#import "StashRecord+CoreDataProperties.h"
@import CoreData;
@import GoogleMaps;
@import GooglePlaces;
@import Contacts;
@import ContactsUI;

typedef enum {
    EMAIL = 1,
    MESSAGE,
    OTHERS
} ShareOption;

@interface ViewController () <UITextFieldDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, CNContactPickerDelegate, CNContactViewControllerDelegate, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (nonatomic,retain) CLLocationManager *locationManager;
@property (nonatomic, strong) GMSPlace *selectedPlace;
@property (nonatomic, strong) NSManagedObjectContext *localContext;
@property (nonatomic, strong) CNContact *selectedContact;

@end

@implementation ViewController{
    ShareOption selectedShareOption;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadMapView];
    
    selectedShareOption = EMAIL;
    
    self.searchTextField.delegate = self;
    self.searchTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.searchTextField.leftViewMode = UITextFieldViewModeAlways;
    self.searchTextField.layer.shadowRadius = 2.0;
    self.searchTextField.layer.shadowOpacity = 0.3;
    self.searchTextField.layer.shadowOffset = CGSizeZero;
    self.searchTextField.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.searchTextField.layer.shouldRasterize = YES;
    
    _locationManager = [[CLLocationManager alloc] init];
    
    // Ask for Authorisation from the User.
    [self.locationManager requestAlwaysAuthorization];
    
    // For use in foreground
    [self.locationManager requestWhenInUseAuthorization];
    
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [self.locationManager startUpdatingLocation];
    
    [self.mapView addObserver:self forKeyPath:@"myLocation" options:0 context:nil];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openPlaceIdOnMap:) name:@"openPlaceId" object:nil];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //Appearance
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"myLocation"]) {
        CLLocation *location = [object myLocation];
        CLLocationCoordinate2D target = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        
        [self.mapView animateToLocation:target];
        [self.mapView animateToZoom:17];
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
    }
}

- (void)loadMapView {
    
    self.mapView.delegate = self;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude: self.mapView.myLocation.coordinate.latitude
                                                            longitude: self.mapView.myLocation.coordinate.longitude
                                                                 zoom: 6];
    
    [self.mapView setCamera: camera];
    self.mapView.myLocationEnabled = YES;
    [self.mapView.settings setMyLocationButton:YES];
}

- (void) openPlaceIdOnMap: (NSNotification *) notification{
    
    [[GMSPlacesClient sharedClient] lookUpPlaceID:[notification.userInfo valueForKey:@"placeId"] callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
        if(error == nil){
            // Do something with the selected place.
            GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude: result.coordinate.latitude
                                                                    longitude: result.coordinate.longitude
                                                                         zoom:6];
            
            [self.mapView setCamera: camera];
            
            GMSMarker *marker = [[GMSMarker alloc] init];
            marker.position = CLLocationCoordinate2DMake(result.coordinate.latitude, result.coordinate.longitude);
            marker.title = result.name;
            marker.snippet = @"Tap to share";
            marker.map = self.mapView;
            [self.mapView setSelectedMarker:marker];
            _selectedPlace = result;
        }
    }];
}

#pragma mark - Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    [textField resignFirstResponder];
    [self presentViewController:acController animated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Google Map Delegate Methods

-(void)mapView:(GMSMapView *)mapView didTapPOIWithPlaceID:(NSString *)placeID name:(NSString *)name location:(CLLocationCoordinate2D)location{
    
    [mapView clear];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[GMSPlacesClient sharedClient] lookUpPlaceID:placeID callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil){
                GMSMarker *marker = [[GMSMarker alloc] init];
                marker.position = CLLocationCoordinate2DMake(location.latitude, location.longitude);
                marker.title = result.name;
                marker.snippet = @"Tap to share";
                marker.map = mapView;
                
                [mapView setSelectedMarker:marker];
                self.selectedPlace = result;
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }];
}

#pragma mark - Google Places Delegate Methods

// Handle the user's selection.
- (void)viewController:(GMSAutocompleteViewController *)viewController didAutocompleteWithPlace:(GMSPlace *)place {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Do something with the selected place.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude: place.coordinate.latitude
                                                            longitude: place.coordinate.longitude
                                                                 zoom:6];
    
    [self.mapView setCamera: camera];
    
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(place.coordinate.latitude, place.coordinate.longitude);
    marker.title = place.name;
    marker.snippet = @"Tap to share";
    marker.map = self.mapView;
    
    NSLog(@"Place name %@", place.name);
    NSLog(@"Place address %@", place.formattedAddress);
    NSLog(@"Place attributions %@", place.attributions.string);
    
    _selectedPlace = place;
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    // TODO: handle the error.
    NSLog(@"Error: %@", [error description]);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (IBAction)historyAction:(id)sender {
    
    // This could be done directly through storyboards too! 
    [self performSegueWithIdentifier:@"History" sender:sender];
}


#pragma mark - Places Marker

-(void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker{
    
//    [self performSegueWithIdentifier:@"ContactPicker" sender: marker];
    
    CNContactPickerViewController *contactPickerVC = [[CNContactPickerViewController alloc] init];
    contactPickerVC.delegate = self;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Sort Order" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // Cancel button tappped.
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        contactPickerVC.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
        selectedShareOption = EMAIL;
        [self presentViewController:contactPickerVC animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        contactPickerVC.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"phoneNumbers.@count > 0"];
        selectedShareOption = MESSAGE;
        [self presentViewController:contactPickerVC animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Others" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        selectedShareOption = OTHERS;
        NSString *shareText = [self createMessageText];
        UIActivityViewController *atvc = [[UIActivityViewController alloc] initWithActivityItems:@[shareText] applicationActivities:nil];
        atvc.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePrint];
        [self presentViewController:atvc animated:YES completion:nil];
    }]];
    
    [actionSheet setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [actionSheet popoverPresentationController];
    popPresenter.sourceView = marker.iconView;
    
    // Present action sheet.
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Contact Picker Delegates

-(void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact{
    CNContactViewController *cvc = [CNContactViewController viewControllerForContact:contact];
    cvc.delegate = self;
    cvc.allowsActions = NO;
    cvc.allowsEditing = NO;
    cvc.contactStore = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).contanctStore;
    
    switch (selectedShareOption) {
        case EMAIL:
            cvc.displayedPropertyKeys = @[CNContactEmailAddressesKey];
            break;
        case MESSAGE:
            cvc.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
            break;
        default:
            break;
    }
    
    //Appearance
    [self.navigationController.navigationBar setTintColor:nil];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    [self.navigationController pushViewController:cvc animated:YES];
}

-(BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property{
    
    [viewController.navigationController popViewControllerAnimated:YES];
    _selectedContact = property.contact;
    switch (selectedShareOption) {
        case EMAIL:
            [self sendEmailWithEmail: property.contact.emailAddresses[0].value];
            break;
        case MESSAGE:{
                [self sendMessageWithPhoneNumber: [((CNPhoneNumber *)property.contact.phoneNumbers[0].value) valueForKey:@"digits"]];
            }
            break;
        default:
            break;
    }
    
    return NO;
}

#pragma mark - Email and Mail Methods

- (NSString *) createMessageText{
    NSString *link = [NSString stringWithFormat:@"stashsocial://?placeId=%@",self.selectedPlace.placeID];
    NSString *text = [NSString stringWithFormat:@"%@, %@\n%@", self.selectedPlace.name, self.selectedPlace.formattedAddress, link];
    return text;
}

- (void) sendEmailWithEmail:(NSString *) email {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setToRecipients:@[email]];
    [mailComposeViewController setSubject: self.selectedPlace.name];
    
    [mailComposeViewController setMessageBody:[self createMessageText]
                                       isHTML:NO];
    [self.navigationController presentViewController:mailComposeViewController animated:YES completion:nil];
}


-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    
    if(result == MFMailComposeResultSent){
        if(![self saveRecord]){
            NSLog(@"Error saving record"); // TODO Alert
        }
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendMessageWithPhoneNumber:(NSString *) phoneNumber {
    MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
    messageComposeViewController.messageComposeDelegate = self;
    messageComposeViewController.recipients = @[phoneNumber];
    messageComposeViewController.body = [self createMessageText];
    [self.navigationController presentViewController:messageComposeViewController animated:YES completion:nil];
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    
    if(result == MessageComposeResultSent){
        if(![self saveRecord]){
            NSLog(@"Error saving record"); // TODO Alert
        }
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) saveRecord{
    StashRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"StashRecord" inManagedObjectContext:[self getLocalContext]];
    record.recordId = [NSDate timeIntervalSinceReferenceDate]; // TODO: Generate More Unique ID
    record.recipientPhoneNumber = [((CNPhoneNumber *)self.selectedContact.phoneNumbers[0].value) valueForKey:@"digits"];
    record.placeId = self.selectedPlace.placeID;
    record.placeName = self.selectedPlace.name;
    record.placeAddress = self.selectedPlace.formattedAddress;
    record.recipientName = self.selectedContact.givenName;
    
    if(![self saveContext]){
        NSLog(@"Failure Handle this");
        return false;
    }
    return true;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:@"History"]){
        HistoryViewController *cpvc = (HistoryViewController *) segue.destinationViewController;
        cpvc.place = self.selectedPlace;
    }
}

#pragma mark - Core Data Methods

- (NSManagedObjectContext *) getLocalContext{
    if(_localContext != nil){
        return _localContext;
    }
    
    NSManagedObjectContext *mainContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    _localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_localContext setParentContext:mainContext];
    
    return _localContext;
}

- (BOOL) saveContext {
    NSManagedObjectContext *context = [self getLocalContext];
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        return false;
    }
    return true;
}

@end
