//
//  Data_CollectorAppDelegate.m
//  iOS Data Collector
//
//  Created by Mike Stowell on 12/28/12.
//  Copyright 2013 iSENSE Development Team. All rights reserved.
//  Engaging Computing Lab, Advisor: Fred Martin
//

#import "Data_CollectorAppDelegate.h"

@implementation Data_CollectorAppDelegate

@synthesize window, navControl, about, guide, managedObjectContext, managedObjectModel, persistentStoreCoordinator, dataSaver;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.    
    self.window.rootViewController = self.navControl;
	[self.window makeKeyAndVisible];
        
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}


- (void)applicationWillTerminate:(UIApplication *)application {
    
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    [self fetchDataSets];

    return managedObjectContext;
}


/**
  * Returns the managed object model for the application.
  *If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
  */
- (NSManagedObjectModel *)managedObjectModel {
    if (!managedObjectModel) {

        NSString *staticLibraryBundlePath = [[NSBundle mainBundle] pathForResource:@"iSENSE_API_Bundle" ofType:@"bundle"];
        NSURL *staticLibraryMOMURL = [[NSBundle bundleWithPath:staticLibraryBundlePath] URLForResource:@"DataSetModel" withExtension:@"momd"];
        managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:staticLibraryMOMURL] retain];
        //NSLog(@"%@", managedObjectModel.entities.description);
        if (!managedObjectModel) {
            NSLog(@"Problem");
            abort();
        }
    }
    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"DataCollector.sqlite"]];
	
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }
	
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}


- (void)dealloc {
    [managedObjectModel release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    
    [window release];
	[navControl release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom Functions

- (IBAction) showAbout:(id)sender {
	AboutView *aboutView = [[AboutView alloc] init];
	aboutView.title = @"About";
	[self.navControl pushViewController:aboutView animated:YES];
	[aboutView release];
}

- (IBAction) showGuide:(id)sender {
	GuideView *guideView = [[GuideView alloc] init];
	guideView.title = @"Guide";
	[self.navControl pushViewController:guideView animated:YES];
	[guideView release];
}

// Get the dataSets from the queue :D
- (void) fetchDataSets {
    
    // Fetch the old DataSets
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *dataSetEntity = [[NSEntityDescription entityForName:@"DataSet" inManagedObjectContext:managedObjectContext] retain];
    if (dataSetEntity) {
        [request setEntity:dataSetEntity];
        
        // Actually make the request
        NSError *error = nil;
        NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
        if (mutableFetchResults == nil) {
            // dats a problem
        } else {
            NSLog(@"Description: %@, %d", mutableFetchResults.description, mutableFetchResults.count);
        }
        
        dataSaver = [[DataSaver alloc] initWithContext:managedObjectContext];
        
        // fill dataSaver's DataSet Queue
        for (int i = 0; i < mutableFetchResults.count; i++) {
            [dataSaver addDataSetFromCoreData:mutableFetchResults[i]];
        }
        
        // release the fetched objects
        [dataSetEntity release];
        [mutableFetchResults release];
        [request release];
    }
}


@end
