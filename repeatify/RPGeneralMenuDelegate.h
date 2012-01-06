//
//  RPGeneralMenuDelegate.h
//  repeatify
//
//  Created by Longyi Qi on 1/6/12.
//  Copyright (c) 2012 Longyi Qi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class repeatifyAppDelegate;

@interface RPGeneralMenuDelegate : NSObject <NSMenuDelegate>

@property (nonatomic, retain) repeatifyAppDelegate *delegate;

- (void)updateMenu:(NSMenu *)menu;

- (void)addTracks:(NSArray *)tracks toMenuItem:(NSMenuItem *)menuItem;
- (void)handleNowPlayingView:(NSMenu *)menu;
- (void)handlePlaybackMenuItem:(NSMenu *)menu;
- (void)handleAboutMenuItems:(NSMenu *)menu;
- (NSArray *)getTracksFromPlaylistItems:(NSArray *)playlistItems;
- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem;
- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem;

@end