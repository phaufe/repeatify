//
//  RPGeneralMenuDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 1/6/12.
//  Copyright (c) 2012 Longyi Qi. All rights reserved.
//

#import "RPGeneralMenuDelegate.h"
#import "repeatifyAppDelegate.h"

@interface RPGeneralMenuDelegate()

- (void)updateNowPlayingTrackInformation:(id)sender;
- (void)updateAlbumCoverImage:(id)sender;

- (void)switchToRepeatOneMode;
- (void)switchToRepeatAllMode;
- (void)switchToRepeatShuffleMode;
- (void)togglePlayNext:(id)sender;
- (void)togglePlayPrevious:(id)sender;
- (void)togglePlayController:(id)sender;
- (void)showLoginDialog;
- (void)logoutUser;
- (void)showAboutPanel;
- (void)quitRepeatify;

@end

@implementation RPGeneralMenuDelegate

@synthesize delegate;

- (void)updateMenu:(NSMenu *)menu {
    [NSException raise:@"AbstractMethodException" format:@"Please override this method in subclasses"];
}

- (void)updateAlbumCoverImage:(id)sender {
    [self.delegate updateAlbumCoverImage:sender];
}

- (void)updateNowPlayingTrackInformation:(id)sender {
    SPTrack *track = self.delegate.playbackManager.currentTrack;
    [self.delegate.nowPlayingArtistNameLabel setStringValue:((SPArtist *)[track.artists objectAtIndex:0]).name];
    [self.delegate.nowPlayingTrackNameLabel setStringValue:track.name];
    SPImage *cover = track.album.cover;
    if (cover.isLoaded) {
        NSImage *coverImage = cover.image;
        if (coverImage != nil) {
            [self.delegate.nowPlayingAlbumCoverImageView setImage:coverImage];
        }
    }
    else {
        [self.delegate.nowPlayingAlbumCoverImageView setImage:[NSImage imageNamed:@"album-placeholder"]];
        [cover beginLoading];
        [self performSelector:@selector(updateAlbumCoverImage:) withObject:track afterDelay:0.5];
    }
    
    [self.delegate updateIsPlayingStatus:self];
}

- (void)handleAboutMenuItems:(NSMenu *)menu {
    if (self.delegate.loginStatus != RPLoginStatusNoUser) {
        [menu addItem:[NSMenuItem separatorItem]];
    }
    SPUser *user = [[SPSession sharedSession] user];
    if (user == nil) {
        [menu addItemWithTitle:@"Login" action:@selector(showLoginDialog) keyEquivalent:@""];
    }
    else {
        [menu addItemWithTitle:[NSString stringWithFormat:@"Log Out %@", user.displayName] action:@selector(logoutUser) keyEquivalent:@""];
    }
    [menu addItemWithTitle:@"About Repeatify" action:@selector(showAboutPanel) keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(quitRepeatify) keyEquivalent:@""];
}

- (void)handleNowPlayingView:(NSMenu *)menu {
    if (self.delegate.playbackManager.currentTrack != nil) {
        [self updateNowPlayingTrackInformation:self];
        NSMenuItem *nowPlayingMenuItem = [[NSMenuItem alloc] init];
        nowPlayingMenuItem.view = self.delegate.nowPlayingView;
        [menu addItem:nowPlayingMenuItem];
        [nowPlayingMenuItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
}

- (void)handlePlaybackMenuItem:(NSMenu *)menu {
    if (self.delegate.playbackManager.currentTrack != nil) {
        NSMenuItem *playbackMenuItem = [[NSMenuItem alloc] initWithTitle:@"Playback" action:nil keyEquivalent:@""];
        NSMenu *playbackControlMenu = [[NSMenu alloc] init];
        
        NSMenuItem *playQueueMenuItem = [[NSMenuItem alloc] init];
        [playQueueMenuItem setTitle:@"Play Queue"];
        [self addTracks:[self.delegate.playbackManager getCurrentPlayQueue] toMenuItem:playQueueMenuItem];
        [playbackControlMenu addItem:playQueueMenuItem];
        [playQueueMenuItem release];
        
        [playbackControlMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
        [playbackControlMenu addItemWithTitle:@"Play/Pause" action:@selector(togglePlayController:) keyEquivalent:@""];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        [playbackControlMenu addItemWithTitle:@"Next" action:@selector(togglePlayNext:) keyEquivalent:@""];
        [playbackControlMenu addItemWithTitle:@"Previous" action:@selector(togglePlayPrevious:) keyEquivalent:@""];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *repeatOneMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat One" action:@selector(switchToRepeatOneMode) keyEquivalent:@""];
        NSMenuItem *repeatAllMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat All" action:@selector(switchToRepeatAllMode) keyEquivalent:@""];
        NSMenuItem *repeatShuffleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Repeat Shuffle" action:@selector(switchToRepeatShuffleMode) keyEquivalent:@""];
        
        switch ([self.delegate.playbackManager getCurrentRepeatMode]) {
            case RPRepeatOne:
                [repeatOneMenuItem setState:NSOnState];
                break;
            case RPRepeatAll:
                [repeatAllMenuItem setState:NSOnState];
                break;
            case RPRepeatShuffle:
                [repeatShuffleMenuItem setState:NSOnState];
                break;
            default:
                break;
        }
        
        [playbackControlMenu addItem:repeatOneMenuItem];
        [playbackControlMenu addItem:repeatAllMenuItem];
        [playbackControlMenu addItem:repeatShuffleMenuItem];
        [repeatOneMenuItem release];
        [repeatAllMenuItem release];
        [repeatShuffleMenuItem release];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *volumeControlMenuItem = [[NSMenuItem alloc] init];
        volumeControlMenuItem.view = self.delegate.volumeControlView;
        [playbackControlMenu addItem:volumeControlMenuItem];
        [volumeControlMenuItem release];
        [playbackControlMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *showGrowlNotificationMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Notification" action:@selector(toggleShowGrowlNotification) keyEquivalent:@""];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RPGrowlNotification"]) {
            [showGrowlNotificationMenuItem setState:NSOnState];
        }
        [playbackControlMenu addItem:showGrowlNotificationMenuItem];
        [showGrowlNotificationMenuItem release];
        
        [playbackMenuItem setSubmenu:playbackControlMenu];
        [menu addItem:playbackMenuItem];
        
        [playbackControlMenu release];
        [playbackMenuItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
}

- (void)addTracks:(NSArray *)tracks toMenuItem:(NSMenuItem *)menuItem {
    NSMenu *innerMenu = [[NSMenu alloc] init];
    [tracks each:^(SPTrack *track) {
        if (track != nil) {
            NSMenuItem *innerMenuItem;
            if (track.name == nil) {
                innerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Loading Track..." action:nil keyEquivalent:@""];
            }
            else {
                if (track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
                    innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:@selector(clickTrackMenuItem:) keyEquivalent:@""];
                    
                    if ([track isEqualTo:self.delegate.playbackManager.currentTrack]) {
                        [innerMenuItem setState:NSOnState];
                    }
                    else {
                        [innerMenuItem setState:NSOffState];
                    }
                }
                else {
                    innerMenuItem = [[NSMenuItem alloc] initWithTitle:track.name action:nil keyEquivalent:@""];
                }
            }
            [innerMenuItem setRepresentedObject:[NSArray arrayWithObjects:track, tracks, nil]];
            [innerMenu addItem:innerMenuItem];
            [innerMenuItem release];
        }
    }];
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

- (void)handlePlaylistFolder:(SPPlaylistFolder *)folder menuItem:(NSMenuItem *)menuItem {
    [menuItem setTitle:folder.name];
    NSMenu *innerMenu = [[NSMenu alloc] init];
    [folder.playlists each:^(id playlist) {
        NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
        
        if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
            [self handlePlaylistFolder:playlist menuItem:innerMenuItem];
        }
        else if ([playlist isKindOfClass:[SPPlaylist class]]) {
            [self handlePlaylist:playlist menuItem:innerMenuItem];
        }
        
        [innerMenu addItem:innerMenuItem];
        [innerMenuItem release];
    }];
    
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

- (void)handlePlaylist:(SPPlaylist *)list menuItem:(NSMenuItem *)menuItem {
    [menuItem setTitle:list.name];
    [self addTracks:[self getTracksFromPlaylistItems:list.items] toMenuItem:menuItem];
}

- (NSArray *)getTracksFromPlaylistItems:(NSArray *)playlistItems {
    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    [playlistItems each:^(id item) {
        SPTrack *track = nil;
        if ([item isKindOfClass:[SPPlaylistItem class]]) {
            SPPlaylistItem *playlistItem = (SPPlaylistItem *)item;
            if ([playlistItem.item isKindOfClass:[SPTrack class]]) {
                track = (SPTrack *)playlistItem.item;
            }
        }
        if ([item isKindOfClass:[SPTrack class]]) {
            track = (SPTrack *)item;
        }
        if (track != nil) {
            [tracks addObject:track];
        }
    }];
    return [tracks autorelease];
}

#pragma mark -
#pragma mark NSMenuDelegate Methods

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self updateMenu:menu];
}

#pragma mark - 
#pragma mark RPAppDelegate Methods

- (void)switchToRepeatOneMode {
    [self.delegate switchToRepeatOneMode];
}

- (void)switchToRepeatAllMode {
    [self.delegate switchToRepeatAllMode];
}

- (void)switchToRepeatShuffleMode {
    [self.delegate switchToRepeatShuffleMode];
}

- (void)togglePlayNext:(id)sender {
    [self.delegate togglePlayNext:sender];
}

- (void)togglePlayPrevious:(id)sender {
    [self.delegate togglePlayPrevious:sender];
}

- (void)togglePlayController:(id)sender {
    [self.delegate togglePlayController:sender];
}

- (void)showLoginDialog {
    [self.delegate showLoginDialog];
}

- (void)logoutUser {
    [self.delegate logoutUser];
}

- (void)showAboutPanel {
    [self.delegate showAboutPanel];
}

- (void)quitRepeatify {
    [self.delegate quitRepeatify];
}

@end
