//
//  AppDelegate.h
//  App_Mopub
//
//  Created by Jose Portocarrero on 12/6/17.
//  Copyright © 2017 AppMonet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@end

