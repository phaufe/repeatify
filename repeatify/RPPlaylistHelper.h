//
//  RPPlaylistHelper.h
//  repeatify
//
//  Created by Longyi Qi on 1/6/12.
//  Copyright (c) 2012 Longyi Qi. All rights reserved.
//

#import <Foundation/Foundation.h>

void addTracks(NSArray *tracks, NSMenuItem *menuItem);
void handlePlaylistFolder(SPPlaylistFolder *folder, NSMenuItem *menuItem);
void handlePlaylist(SPPlaylist *list, NSMenuItem *menuItem);
NSArray *getTracksFromPlaylistItems(NSArray *playlistItems);
