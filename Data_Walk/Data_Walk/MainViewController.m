//
//  DWMasterViewController.m
//  Data_Walk
//
//  Created by Michael Stowell on 8/22/13.
//  Copyright (c) 2013 iSENSE. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "AboutViewController.h"

@implementation MainViewController

// Menu properties
@synthesize reset, about;
// UI properties
@synthesize latitudeLabel, longitudeLabel, recordData, recordingIntervalButton, nameTextField, loggedInAs, upload, selectProject, gpsLock, topBar;
// Other properties
@synthesize locationManager, activeField, passwordField;

// Displays the correct xib based on orientation and device type - called automatically upon view controller entry
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        // iPad Landscape
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            [[NSBundle mainBundle] loadNibNamed:@"MainLayout-landscape~ipad"
                                          owner:self
                                        options:nil];
            [self viewDidLoad];
        // iPad Portrait
        } else {
            [[NSBundle mainBundle] loadNibNamed:@"MainLayout~ipad"
                                          owner:self
                                        options:nil];
            [self viewDidLoad];
        }
    } else {
        // iPhone Landscape
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            [[NSBundle mainBundle] loadNibNamed:@"MainLayout-landscape~iphone"
                                          owner:self
                                        options:nil];
            [self viewDidLoad];
        // iPhone Portrait
        } else {
            [[NSBundle mainBundle] loadNibNamed:@"MainLayout~iphone"
                                          owner:self
                                        options:nil];
            [self viewDidLoad];
        }
    }
    
}

// Called every time the main UI is loaded, or when the device is rotated
- (void)viewDidLoad {
    // Initial super call
    [super viewDidLoad];
    
    // Set up iSENSE settings and API
    api = [API getInstance];
    
    // Set up the menu bar
	reset = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(onResetClick:)];
    about = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStyleBordered target:self action:@selector(onAboutClick:)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:reset, about, nil];
    self.navigationItem.title = @"iSENSE Data Walk";
    
    // Tag the UI objects
    latitudeLabel.tag           = kTAG_LABEL_LATITUDE;
    longitudeLabel.tag          = kTAG_LABEL_LONGITUDE;
    recordData.tag              = kTAG_BUTTON_RECORD;
    recordingIntervalButton.tag = kTAG_BUTTON_INTERVAL;
    nameTextField.tag           = kTAG_TEXTFIELD_NAME;
    loggedInAs.tag              = kTAG_BUTTON_LOGGED_IN;
    upload.tag                  = kTAG_BUTTON_UPLOAD;
    selectProject.tag           = kTAG_BUTTON_PROJECT;
    
    // Set up text field delegate to catch editing actions and return key type to end editing
    nameTextField.delegate = self;
    [nameTextField setReturnKeyType:UIReturnKeyDone];
    
    // Add a long press gesture listener to the record data button
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                       initWithTarget:self
                                                       action:@selector(onRecordDataLongClick:)];
    [longPressGesture setMinimumPressDuration:0.5];
    [recordData addGestureRecognizer:longPressGesture];
    
    // Initialize other variables
    isRecording = NO;
    isShowingPickerView = NO;
    
    // Set up properties dependent on NSUserDefaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int recInt = [prefs integerForKey:[StringGrabber grabString:@"recording_interval"]];
    if (recInt == 0) {
        recInt = kDEFAULT_REC_INTERVAL;
        [prefs setInteger:recInt forKey:[StringGrabber grabString:@"recording_interval"]];
    }
    recordingInterval = recInt;
    switch (recordingInterval) {
        case 1:
            [recordingIntervalButton setTitle:@"1 second" forState:UIControlStateNormal];
            break;
        case 2:
            [recordingIntervalButton setTitle:@"2 seconds" forState:UIControlStateNormal];
            break;
        case 5:
            [recordingIntervalButton setTitle:@"5 seconds" forState:UIControlStateNormal];
            break;
        case 10:
            [recordingIntervalButton setTitle:@"10 seconds" forState:UIControlStateNormal];
            break;
        case 30:
            [recordingIntervalButton setTitle:@"30 seconds" forState:UIControlStateNormal];
            break;
        case 60:
            [recordingIntervalButton setTitle:@"60 seconds" forState:UIControlStateNormal];
            break;
    }
    
    name = [prefs stringForKey:[StringGrabber grabString:@"first_name"]];
    [nameTextField setText:name];
    
    int proj = [prefs integerForKey:[StringGrabber grabString:@"project_id"]];
    if (proj == 0)
        projectID = kDEFAULT_PROJECT;
    else
        projectID = proj;
    [selectProject setTitle:[NSString stringWithFormat:@"to project %d", projectID] forState:UIControlStateNormal];
    
    // Set up location stuff
    [self resetGeospatialLabels];
    [self initLocations];
}

// Is called every time MainViewController is about to appear
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

// Is called every time MainViewController appears
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self willRotateToInterfaceOrientation:(self.interfaceOrientation) duration:0];
    
    // Register for keyboard notifications
    [self registerForKeyboardNotifications];
}

// Display a dialog asking user if he/she would like to reset application settings
- (void) onResetClick:(id)sender {
    [self.view makeWaffle:@"Reset clicked" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Reset Settings"
                                                      message:@"Are you sure you would like to reset settings?  These include the project number, recording interval, and username."
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Okay", nil];
    message.tag = kTAG_RESET_ARE_YOU_SURE;
    [message show];
}

// Shows the user information about the application, as well as a generic "Help/How To" guide
- (void) onAboutClick:(id)sender {
    AboutViewController *avc = [[AboutViewController alloc] init];
    avc.title = @"About and Help";
    [self.navigationController pushViewController:avc animated:YES];
}

// Activated when the main application button, the data recording button, is long pressed and it's state is UIGestureRecognizerStateBegan
- (void) onRecordDataLongClick:(UIButton *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (!isRecording) {
            isRecording = true;
            [self setRecordingLayout];
        } else {
            isRecording = false;
            [self setNonRecordingLayout];
        }
    }
}

// Activated when the user wants to change his/her recording interval, measured in seconds
- (IBAction) onRecordingIntervalClick:(id)sender {
    
    if (isShowingPickerView && intervalPickerView != nil) {
        [intervalPickerView removeFromSuperview];
        isShowingPickerView = NO;
        
        // Set button text according to the selected recording interval
        switch (recordingInterval) {
            case 1:
                [recordingIntervalButton setTitle:@"1 second" forState:UIControlStateNormal];
                break;
            case 2:
                [recordingIntervalButton setTitle:@"2 seconds" forState:UIControlStateNormal];
                break;
            case 5:
                [recordingIntervalButton setTitle:@"5 seconds" forState:UIControlStateNormal];
                break;
            case 10:
                [recordingIntervalButton setTitle:@"10 seconds" forState:UIControlStateNormal];
                break;
            case 30:
                [recordingIntervalButton setTitle:@"30 seconds" forState:UIControlStateNormal];
                break;
            case 60:
                [recordingIntervalButton setTitle:@"60 seconds" forState:UIControlStateNormal];
                break;
        }
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:recordingInterval forKey:[StringGrabber grabString:@"recording_interval"]];
        
    } else {
        
        // Display the recording interval selector
        int x = recordingIntervalButton.frame.origin.x;
        int y = recordingIntervalButton.frame.origin.y + recordingIntervalButton.frame.size.height;
        if([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
                x = 0;
        
        [recordingIntervalButton setTitle:@"Done" forState:UIControlStateNormal];
        
        intervalPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(x, y, 320, 200)];
        intervalPickerView.delegate = self;
        intervalPickerView.showsSelectionIndicator = YES;
        
        [self.view addSubview:intervalPickerView];
        isShowingPickerView = YES;
        
    }
}

// Called every time the recording interval selector stops on a new row
- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
    if (row != 0) {
        switch (row) {
            case 1:
                recordingInterval = 1;
                break;
            case 2:
                recordingInterval = 2;
                break;
            case 3:
                recordingInterval = 5;
                break;
            case 4:
                recordingInterval = 10;
                break;
            case 5:
                recordingInterval = 30;
                break;
            case 6:
                recordingInterval = 60;
                break;
        }
    
    } else {
        // If the user selects row 0, reset the recording interval to its previous state
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        recordingInterval = [prefs integerForKey:[StringGrabber grabString:@"recording_interval"]];
    }
   
}

// Tells the picker how many rows are available for a given component - we have 7 recording interval options
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 7;
}

// Tells the picker how many components it will have - 1, since we only want to display a single interval per row
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// Assigns the picker a title for each row - a "Return to previous" selection, and the 6 other intervals
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    switch (row) {
        case 0:
            title = @"Return to previous";
            return title;
        case 1:
            title = @"1 second";
            return title;
        case 2:
            title = @"2 seconds";
            return title;
        case 3:
            title = @"5 seconds";
            return title;
        case 4:
            title = @"10 seconds";
            return title;
        case 5:
            title = @"30 seconds";
            return title;
        case 6:
            title = @"60 seconds";
            return title;
    }
    return title;
}

// Tells the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    int sectionWidth = 300;
    return sectionWidth;
}

// Called when the user clicked on the button displaying his/her login information
- (IBAction) onLoggedInClick:(id)sender {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Login"
                                         message:nil
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                               otherButtonTitles:@"Okay", nil];
    message.tag = kTAG_LOGIN_DIALOG;
    [message setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    
    [message textFieldAtIndex:0].tag = kENTER_USER_TEXTFIELD;
    [message textFieldAtIndex:1].tag = kENTER_PASS_TEXTFIELD;
    [message textFieldAtIndex:0].delegate = self;
    [message textFieldAtIndex:1].delegate = self;
    [message textFieldAtIndex:0].returnKeyType = UIReturnKeyNext;
    [message textFieldAtIndex:1].returnKeyType = UIReturnKeyDone;
    
    passwordField = [message textFieldAtIndex:1];
    [message show];
}

// Called when the user clicked the Upload button
- (IBAction) onUploadClick:(id)sender {
    [self.view makeWaffle:@"Upload clicked" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM];
}

// Called when the user clicked the project selection button
- (IBAction) onSelectProjectClick:(id)sender {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Enter Project #", @"Browse Projects", @"Scan QR Code", nil];
    message.tag = kTAG_PROJECT_SELECTION;
    [message show];
}

// Allows the device to rotate as necessary - overriden to allow any orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (isRecording) ? NO : YES;
}

// iOS6 enable rotation
- (BOOL)shouldAutorotate {
    return (isRecording) ? NO : YES;
}

// iOS6 enable rotation
- (NSUInteger)supportedInterfaceOrientations {
    if (isRecording) {
        if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
            return UIInterfaceOrientationMaskPortrait;
        } else if (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        } else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            return UIInterfaceOrientationMaskLandscapeLeft;
        } else {
            return UIInterfaceOrientationMaskLandscapeRight;
        }
    } else
        return UIInterfaceOrientationMaskAll;
}

// Called when a UIActionSheet or UIAlertView is clicked at a button index
- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // User clicked on the project selection action sheet
    if (actionSheet.tag == kTAG_PROJECT_SELECTION){
        
        // User wants to manually enter a project ID
        if (buttonIndex == kOPTION_ENTER_PROJECT) {
            
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Enter Project #:"
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                                    otherButtonTitles:@"Okay", nil];
            
            message.tag = kOPTION_ENTER_PROJECT;
            [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [message textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
            [message textFieldAtIndex:0].tag = kENTER_PROJ_TEXTFIELD;
            [message textFieldAtIndex:0].delegate = self;
            [message show];
        
        // User wants to browse projects
        } else if (buttonIndex == kOPTION_BROWSE_PROJECTS) {
            
            NSNumber *projNumInteger = [[NSNumber alloc] init];
            
            ProjectBrowseViewController *browseView = [[ProjectBrowseViewController alloc] init];
            browseView.title = @"Browse for Experiments";
            browseView.chosenProject = projNumInteger;
            [self.navigationController pushViewController:browseView animated:YES];
            
            NSLog(@"Project chosen: %@", projNumInteger);

        // User wants to obtain a project number by scanning a QR code
        } else if (buttonIndex == kOPTION_SCAN_PROJECT_QR) {
            [self.view makeWaffle:@"Scan QR Code not currently implemented" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM];
        }
        
    // User is done entering a project # manually
    } else if (actionSheet.tag == kOPTION_ENTER_PROJECT) {
        
        if (buttonIndex != kOPTION_CANCELED) {
            
            NSString *projNum = [[actionSheet textFieldAtIndex:0] text];
            projectID = [projNum intValue];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger:projectID forKey:[StringGrabber grabString:@"project_id"]];
            
            [selectProject setTitle:[NSString stringWithFormat:@"to project %d", projectID] forState:UIControlStateNormal];
        }
        
    // User is done with the login dialog
    } else if (actionSheet.tag == kTAG_LOGIN_DIALOG) {
        
        passwordField = nil;
        
        if (buttonIndex != kOPTION_CANCELED) {
            NSString *usernameInput = [[actionSheet textFieldAtIndex:0] text];
            NSString *passwordInput = [[actionSheet textFieldAtIndex:1] text];
            [self login:usernameInput withPassword:passwordInput];
        }
        
    // User is done with the Reset dialog
    } else if (actionSheet.tag == kTAG_RESET_ARE_YOU_SURE) {
        
        if (buttonIndex != kOPTION_CANCELED) {
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:kDEFAULT_USER forKey:[StringGrabber grabString:@"key_username"]];
            [prefs setObject:kDEFAULT_PASS forKey:[StringGrabber grabString:@"key_password"]];
            [prefs setInteger:kDEFAULT_PROJECT forKey:[StringGrabber grabString:@"project_id"]];
            [prefs setInteger:kDEFAULT_REC_INTERVAL forKey:[StringGrabber grabString:@"recording_interval"]];
            [prefs synchronize];
            
            [loggedInAs setTitle:kDEFAULT_NAME forState:UIControlStateNormal];
            [selectProject setTitle:[NSString stringWithFormat:@"to project %d", kDEFAULT_PROJECT] forState:UIControlStateNormal];
            [recordingIntervalButton setTitle:[NSString stringWithFormat:@"%d seconds", kDEFAULT_REC_INTERVAL] forState:UIControlStateNormal];
            
        }
        
    }
}

// Log into iSENSE
- (void) login:(NSString *)usernameInput withPassword:(NSString *)passwordInput {

    // __block BOOL success;
    // __block RPerson *curUser;

    [self showLoadingDialogWithMessage:@"Logging in..."
                andExecuteInBackground:^{}
             finishingOnMainThreadWith:^{
                 BOOL success = [api createSessionWithUsername:usernameInput andPassword:passwordInput];
                 if (success) {
                     [self.view makeWaffle:[NSString stringWithFormat:@"Login as %@ successful", usernameInput]
                                  duration:WAFFLE_LENGTH_SHORT
                                  position:WAFFLE_BOTTOM
                                     image:WAFFLE_CHECKMARK];
                     
                     // save the username and password in prefs
                     NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
                     [prefs setObject:usernameInput forKey:[StringGrabber grabString:@"key_username"]];
                     [prefs setObject:passwordInput forKey:[StringGrabber grabString:@"key_password"]];
                     [prefs synchronize];
                     

                     RPerson *curUser = [api getCurrentUser];
 
                     [loggedInAs setTitle:curUser.name forState:UIControlStateNormal];
                 } else {
                     [self.view makeWaffle:@"Login failed"
                                  duration:WAFFLE_LENGTH_SHORT
                                  position:WAFFLE_BOTTOM
                                     image:WAFFLE_RED_X];
                 }
             }];
    
    
}

// Function template that shows a spinner UIAlertView while executing a background block, then updating the UI with another block
- (void)showLoadingDialogWithMessage:(NSString *)message andExecuteInBackground:(APIBlock)backgroundBlock finishingOnMainThreadWith:(APIBlock)mainBlock {
    UIAlertView *spinnerDialog = [self getDispatchDialogWithMessage:message];
    [spinnerDialog show];
    
    dispatch_queue_t queue = dispatch_queue_create("dispatch_queue_t_dialog", NULL);
    dispatch_async(queue, ^{
        
        backgroundBlock();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            mainBlock();
            [spinnerDialog dismissWithClickedButtonIndex:0 animated:YES];
            
        });
    });
}

// Default dispatch_async dialog with custom spinner
- (UIAlertView *) getDispatchDialogWithMessage:(NSString *)dString {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:dString
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:nil];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(139.5, 75.5);
    [message addSubview:spinner];
    [spinner startAnimating];
    return message;
}

// Initialize the location manager.  If one exist, set it to nil and recreate it
- (void) initLocations {
    if (locationManager) locationManager = nil;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
}

// New location has been found - update the latitude/longitude labels
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"New location = %@", newLocation);
    CLLocationCoordinate2D lc2d = [newLocation coordinate];

    double latitude  = lc2d.latitude;
    double longitude = lc2d.longitude;
    
    if([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        [latitudeLabel setText:[NSString stringWithFormat:@"Latitude: %lf", latitude]];
        [longitudeLabel setText:[NSString stringWithFormat:@"Longitude: %lf", longitude]];
    } else {
        [latitudeLabel setText:[NSString stringWithFormat:@"Lat: %lf", latitude]];
        [longitudeLabel setText:[NSString stringWithFormat:@"Lon: %lf", longitude]];
    }
    
    [gpsLock setImage:[UIImage imageNamed:@"gps_icon.png"]];
}

// Reset the latitude/longiude labels
- (void) resetGeospatialLabels {
    if([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        [latitudeLabel setText:@"Latitude: ..."];
        [longitudeLabel setText:@"Longitude: ..."];
    } else {
        [latitudeLabel setText:@"Lat: ..."];
        [longitudeLabel setText:@"Lon: ..."];
    }
    
    [gpsLock setImage:[UIImage imageNamed:@"gps_icon_no_lock.png"]];
}

// Checks text and returns whether or not the new user character is allowed
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Check if the text field is the project text field.  If so, restrict input to 10 numbers only
    if (textField.tag == kENTER_PROJ_TEXTFIELD) {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        
        if (![self containsAcceptedDigits:string])
            return NO;
        
        return (newLength > 10) ? NO : YES;
    }
    
    // For all other text fields, all characters are accepted
    return YES;
}

// Checks to see if the string contains only digits 0 - 9
- (BOOL) containsAcceptedDigits:(NSString *)mString {
    NSCharacterSet *unwantedCharacters =
    [[NSCharacterSet characterSetWithCharactersInString:
      [StringGrabber grabString:@"accepted_digits"]] invertedSet];
    
    return ([mString rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound) ? YES : NO;
}

// Application received a memory warning - free up what we can
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self unregisterKeyboardNotifications];
}

// Sets up listeners for keyboard
- (void) registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// Unregisters listeners for keyboard
- (void) unregisterKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    if (activeField.tag == kTAG_TEXTFIELD_NAME) {
        
        NSDictionary* info = [aNotification userInfo];
        
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        CGRect aRect = self.view.frame;
        aRect.size.height -= kbSize.height;
        CGPoint origin = activeField.frame.origin;
        
        if (!CGRectContainsPoint(aRect, origin) ) {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
                self.view.frame = CGRectMake(0.0, -(kbSize.height), self.view.frame.size.width, self.view.frame.size.height);
        }
    }
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    
    if (activeField != nil && activeField.tag == kTAG_TEXTFIELD_NAME)
        self.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    
}

// Set the active text field to the text field currently being edited
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeField = textField;
}

// Set the active text field to nil when no text fields are in focus
- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeField = nil;
}

// Determine how text fields should behave when they are no longer in focus
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.tag == kTAG_TEXTFIELD_NAME) {
        name = textField.text;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:name forKey:[StringGrabber grabString:@"first_name"]];
    } else if (textField.tag == kENTER_USER_TEXTFIELD) {
        //[textField resignFirstResponder];
        if (passwordField != nil)
            [passwordField becomeFirstResponder];
    }
    
    return YES;
}

// Called when the text field is done being edited
- (IBAction)textFieldFinished:(id)sender {
}

// Alter the layout for the data recording state
- (void) setRecordingLayout {
    topBar.backgroundColor = UIColorFromHex(0x066126);
    
    [recordData setTitle:@"Hold to Stop Recording" forState:UIControlStateNormal];
    
    [recordingIntervalButton setEnabled:FALSE];
    [recordingIntervalButton setAlpha:0.5f];
    
    [loggedInAs setEnabled:FALSE];
    [loggedInAs setAlpha:0.5f];
    
    [upload setEnabled:FALSE];
    [upload setAlpha:0.5f];
    
    [selectProject setEnabled:FALSE];
    [selectProject setAlpha:0.5f];
    
    [nameTextField setEnabled:FALSE];
    [nameTextField setAlpha:0.5f];
    
    for (UIBarButtonItem *bbi in self.navigationItem.rightBarButtonItems)
        bbi.enabled = FALSE;
}

// Alter the layout for when data is not being recorded
- (void) setNonRecordingLayout {
    topBar.backgroundColor = UIColorFromHex(0x0F0661);
    
    [recordData setTitle:@"Hold to Record Data" forState:UIControlStateNormal];
    
    [recordingIntervalButton setEnabled:TRUE];
    [recordingIntervalButton setAlpha:1.0f];
    
    [loggedInAs setEnabled:TRUE];
    [loggedInAs setAlpha:1.0f];
    
    [upload setEnabled:TRUE];
    [upload setAlpha:1.0f];
    
    [selectProject setEnabled:TRUE];
    [selectProject setAlpha:1.0f];
    
    [nameTextField setEnabled:TRUE];
    [nameTextField setAlpha:1.0f];
    
    for (UIBarButtonItem *bbi in self.navigationItem.rightBarButtonItems)
        bbi.enabled = TRUE;
}


@end