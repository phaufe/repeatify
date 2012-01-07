//
//  RPPlaylistHelper.m
//  repeatify
//
//  Created by Longyi Qi on 1/6/12.
//  Copyright (c) 2012 Longyi Qi. All rights reserved.
//

#import "RPPlaylistHelper.h"

void addTracks(NSArray *tracks, NSMenuItem *menuItem) {
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
                    /* Turn it on when PlaybackManager becomes a singleton pattern
                    if ([track isEqualTo:self.delegate.playbackManager.currentTrack]) {
                        [innerMenuItem setState:NSOnState];
                    }
                    else {
                        [innerMenuItem setState:NSOffState];
                    }
                     */
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

void handlePlaylistFolder(SPPlaylistFolder *folder, NSMenuItem *menuItem) {
    [menuItem setTitle:folder.name];
    NSMenu *innerMenu = [[NSMenu alloc] init];
    [folder.playlists each:^(id playlist) {
        NSMenuItem *innerMenuItem = [[NSMenuItem alloc] init];
        
        if ([playlist isKindOfClass:[SPPlaylistFolder class]]) {
            handlePlaylistFolder(playlist, innerMenuItem);
        }
        else if ([playlist isKindOfClass:[SPPlaylist class]]) {
            handlePlaylist(playlist, innerMenuItem);
        }
        
        [innerMenu addItem:innerMenuItem];
        [innerMenuItem release];
    }];
    
    [menuItem setSubmenu:innerMenu];
    [innerMenu release];
}

void handlePlaylist(SPPlaylist *list, NSMenuItem *menuItem) {
    [menuItem setTitle:list.name];
    addTracks(getTracksFromPlaylistItems(list.items), menuItem);
}

NSArray *getTracksFromPlaylistItems(NSArray *playlistItems) {
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
