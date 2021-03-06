//
//  PWViewController.h
//  iS Pictures
//
//  Created by Virinchi Balabhadrapatruni on 1/9/14.
//  Copyright (c) 2014 ECG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iSENSE_API/API.h>
#import <iSENSE_API/ISKeys.h>
#import "RNGridMenu.h"
#import <DataSaver.h>
#import <Waffle.h>
#import <StringGrabber.h>
#import "AboutViewController.h"
#import <QueueUploaderView.h>
#import "PWAppDelegate.h"
#import "Constants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ProjectBrowserViewController.h"
#import "CredentialManager.h"
#import "ImageManipulator.h"
#import <DLAVAlertViewController.h>

@interface PWViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, RNGridMenuDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ZBarReaderDelegate, ProjectBrowserDelegate, CredentialManagerDelegate>

@property(nonatomic) IBOutlet UITextField *groupNameField;
@property(nonatomic) IBOutlet UILabel *projectIDLbl, *picCntLbl;
@property(nonatomic) IBOutlet UIButton *takeButton;
@property(nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property(nonatomic) IBOutlet UIButton *selectButton;

@property(nonatomic) UIAlertView *project, *loginalert;
@property(nonatomic, retain) UIAlertView *proj_num;
@property(nonatomic, retain) UIAlertView *saveMode;
@property(nonatomic) NSString *userName, *passWord;
@property(nonatomic) API *api;
@property(nonatomic) DataSaver *dataSaver;
@property(nonatomic) int projID;
@property (nonatomic, strong) UIPopoverController *popOver;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) DLAVAlertView *alert;
@property (strong, nonatomic) CredentialManager *mngr;

@property (nonatomic) BOOL useDev;
@property (nonatomic) BOOL setupDone;

- (void) callMenu;
- (IBAction)takePicture:(id)sender;
- (IBAction)selectPhoto:(id)sender;

@end
