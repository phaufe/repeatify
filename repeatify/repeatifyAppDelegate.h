//
//  repeatifyAppDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 ChaiONE. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface repeatifyAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
}

@property (strong) IBOutlet NSWindow *window;

@end
