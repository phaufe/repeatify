//
//  RPPlaylistMenuDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 1/6/12.
//  Copyright (c) 2012 Longyi Qi. All rights reserved.
//

#import "RPPlaylistMenuDelegate.h"
#import "repeatifyAppDelegate.h"
#import "RPPlaylistHelper.h"

@interface RPPlaylistMenuDelegate()

- (void)handleStarredPlaylist:(NSMenu *)menu;
- (void)handleInboxPlaylist:(NSMenu *)menu;
- (void)handleTopList:(NSMenu *)menu;

@end

@implementation RPPlaylistMenuDelegate

- (void)updateMenu:(NSMenu *)menu {
    [menu removeAllItems];
    
    [self handleNowPlayingView:menu];
    [self handlePlaybackMenuItem:menu];
    
    SPPlaylistContainer *container = [[SPSession sharedSession] userPlaylists];
    if (self.delegate.loginStatus == RPLoginStatusLogging) {
        [menu addItemWithTitle:@"Logging In..." action:nil keyEquivalent:@""];
    }
    if (self.delegate.loginStatus == RPLoginStatusLoadingPlaylist) {
        [menu addItemWithTitle:@"Loading Playlist..." action:nil keyEquivalent:@""];
    }
    if (self.delegate.loginStatus == RPLoginStatusLoggedIn && container != nil) {
        NSArray *playlists = container.playlists;
        if ([playlists count] == 0) {
            [menu addItemWithTitle:@"No Playlist Found" action:nil keyEquivalent:@""];
        }
        [playlists each:^(id playlist) {
            NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
            
            if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
                handlePlaylistFolder(playlist, innerMenuItem);
            }
            else if ([playlist isKindOfClass:[SPPlaylist class]]) {
                handlePlaylist(playlist, innerMenuItem);
            }
            
            [menu addItem:innerMenuItem];
            [innerMenuItem release];
        }];
        
        [menu addItem:[NSMenuItem separatorItem]];
        [self handleStarredPlaylist:menu];
        [self handleInboxPlaylist:menu];
        [self handleTopList:menu];
    }
    
    [self handleAboutMenuItems:menu];
}

#pragma mark -
#pragma mark Playlist Menu Items

- (void)handleStarredPlaylist:(NSMenu *)menu {
    NSMenuItem *starredPlaylistItem = [[NSMenuItem alloc] init];
    handlePlaylist([[SPSession sharedSession] starredPlaylist], starredPlaylistItem);
    [starredPlaylistItem setTitle:@"Starred"];
    [menu addItem:starredPlaylistItem];
    [starredPlaylistItem release];    
}

- (void)handleInboxPlaylist:(NSMenu *)menu {
    NSMenuItem *inboxPlaylistItem = [[NSMenuItem alloc] init];
    handlePlaylist([[SPSession sharedSession] inboxPlaylist], inboxPlaylistItem);
    [inboxPlaylistItem setTitle:@"Inbox"];
    [menu addItem:inboxPlaylistItem];
    [inboxPlaylistItem release];
}

- (void)handleTopList:(NSMenu *)menu {
    if (self.delegate.topList.isLoaded) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
        [innerMenuItem setTitle:@"What's Hot"];
        addTracks(self.delegate.topList.tracks, innerMenuItem);
        [menu addItem:innerMenuItem];
        [innerMenuItem release];
    }
}

@end
