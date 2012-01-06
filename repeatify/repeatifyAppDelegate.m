//
//  repeatifyAppDelegate.m
//  repeatify
//
//  Created by Longyi Qi on 7/25/11.
//  Copyright 2011 Longyi Qi. All rights reserved.
//
/*
 Copyright (c) 2011, Longyi Qi
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of author nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "repeatifyAppDelegate.h"
#import "appkey.h"

@implementation RPApplication
- (void)sendEvent:(NSEvent *)theEvent
{
    // If event tap is not installed, handle events that reach the app instead
    BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];
    
    if(shouldHandleMediaKeyEventLocally && [theEvent type] == NSSystemDefined && [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
        [(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
    }
    [super sendEvent:theEvent];
}
@end

@interface repeatifyAppDelegate()

- (void)toggleShowGrowlNotification;

- (void)afterLoggedIn;
- (void)didLoggedIn;

- (void)updateMenus;

@end

@implementation repeatifyAppDelegate

@synthesize nowPlayingView, nowPlayingAlbumCoverImageView, nowPlayingTrackNameLabel, nowPlayingArtistNameLabel, nowPlayingControllerButton, volumeControlView, volumeControlSlider;
@synthesize loginDialog, usernameField, passwordField, loginProgressIndicator, loginStatusField, saveCredentialsButton;
@synthesize playbackManager, loginStatus, topList;

#pragma mark -
#pragma mark Application Lifecycle

+(void)initialize {
    if([self class] != [repeatifyAppDelegate class]) return;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
                                                             RPRepeatOne, "RPRepeatMode",
                                                             [NSNumber numberWithBool:YES], "RPGrowlNotification",
                                                             nil]];
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size] 
                                               userAgent:@"com.longyiqi.Repeatify"
                                                   error:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([[SPSession sharedSession] attemptLoginWithStoredCredentials:nil]) {
        [self afterLoggedIn];
    }
    else {
        [self showLoginDialog];
        self.loginStatus = RPLoginStatusNoUser;
    }
    
    [[SPSession sharedSession] setDelegate:self];
    
    NSBundle *currentBundle = [NSBundle bundleForClass:[repeatifyAppDelegate class]];
    NSString *growlPath = [[currentBundle privateFrameworksPath]
                           stringByAppendingPathComponent:@"Growl.framework"];
    NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
    if (growlBundle && [growlBundle load]) {
	[GrowlApplicationBridge setGrowlDelegate:self];
    } else {
	NSLog(@"Could not load Growl.framework");
    }

    _playlistMenuDelegate = [RPPlaylistMenuDelegate new];
    _playlistMenuDelegate.delegate = self;
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];
    [_statusMenu setDelegate:_playlistMenuDelegate];
    
    self.playbackManager = [[RPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    self.topList = nil;
    _mediaKeyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    if([SPMediaKeyTap usesGlobalMediaKeyTap]) {
        [_mediaKeyTap startWatchingMediaKeys];
    }  
    else {
        NSLog(@"Media key monitoring disabled");
    }
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
    NSImage *statusBarIcon = [NSImage imageNamed:@"app"];
    [statusBarIcon setSize:NSMakeSize(16, 16)];
    [_statusItem setImage:statusBarIcon];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    [_statusItem setMenu:_statusMenu];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([SPSession sharedSession].connectionState == SP_CONNECTION_STATE_LOGGED_OUT ||
        [SPSession sharedSession].connectionState == SP_CONNECTION_STATE_UNDEFINED) 
        return NSTerminateNow;
    
    [[SPSession sharedSession] logout];
    return NSTerminateLater;
}

- (void)dealloc {
    [_statusMenu release];
    [_statusItem release];
    [_mediaKeyTap release];
    if (self.topList != nil) {
        [self.topList release];
        self.topList = nil;
    }
    [self.playbackManager release];
    
    [super dealloc];
}

- (void)updateMenus {
    [_playlistMenuDelegate updateMenu:_statusMenu];
}


#pragma mark -
#pragma mark System Menu Items

- (void)showAboutPanel {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:nil];
}

- (void)quitRepeatify {
    [NSApp terminate:self];
}

#pragma mark -
#pragma mark Playback

- (void)updateIsPlayingStatus:(id)sender {
    if (self.playbackManager.isPlaying) {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"pause"];
    }
    else {
        self.nowPlayingControllerButton.image = [NSImage imageNamed:@"play"];
    }
}

- (void)clickTrackMenuItem:(id)sender {
    NSMenuItem *clickedMenuItem = (NSMenuItem *)sender;
    
    [self.playbackManager play:[[clickedMenuItem representedObject] objectAtIndex:0]];
    NSArray *filteredPlaylist = [[[clickedMenuItem representedObject] objectAtIndex:1] select:^BOOL(SPTrack *track) {
        return track.availability == SP_TRACK_AVAILABILITY_AVAILABLE;
    }];
    [self.playbackManager setPlaylist:filteredPlaylist];
}

- (void)updateAlbumCoverImage:(id)sender {
    SPTrack *track = (SPTrack *)sender;
    if (track != nil) {
        if (track.isLoaded) {
            SPImage *cover = track.album.cover;
            if (cover.isLoaded) {
                NSImage *coverImage = cover.image;
                if (coverImage != nil) {
                    [self.nowPlayingAlbumCoverImageView setImage:coverImage];
                }
            }
            else {
                [self performSelector:@selector(updateAlbumCoverImage:) withObject:track afterDelay:0.5];
                return;
            }
        }
    }
}

- (IBAction)togglePlayController:(id)sender {
    if (self.playbackManager.currentTrack != nil) {
        self.playbackManager.isPlaying = !self.playbackManager.isPlaying;
        [self updateIsPlayingStatus:self];
    }
}

- (void)togglePlayNext:(id)sender {
    [self.playbackManager next];
    [self updateMenus];
}

- (void)togglePlayPrevious:(id)sender {
    [self.playbackManager previous];
    [self updateMenus];
}

#pragma mark -
#pragma mark Playback Management

- (void)switchToRepeatOneMode {
    [self.playbackManager toggleRepeatOneMode];
}

- (void)switchToRepeatAllMode {
    [self.playbackManager toggleRepeatAllMode];
}

- (void)switchToRepeatShuffleMode {
    [self.playbackManager toggleRepeatShuffleMode];
}

#pragma mark -
#pragma mark Growl Notification Configuration

- (void)toggleShowGrowlNotification {
    BOOL currentState = [[NSUserDefaults standardUserDefaults] boolForKey:@"RPGrowlNotification"];
    [[NSUserDefaults standardUserDefaults] setBool:!currentState forKey:@"RPGrowlNotification"];
}

#pragma mark -
#pragma mark Volume Change Methods

- (IBAction)volumeChanged:(id)sender {
    NSSlider *volumeSlider = (NSSlider *)sender;
    self.playbackManager.volume = volumeSlider.doubleValue;
}

#pragma mark -
#pragma mark Login/Logout methods

- (IBAction)closeLoginDialog:(id)sender {
    [self.loginDialog orderOut:nil];
}

- (IBAction)clickLoginButton:(id)sender {
    if ([self.usernameField.stringValue length] > 0 && [self.passwordField.stringValue length] > 0) {
        [[SPSession sharedSession] attemptLoginWithUserName:self.usernameField.stringValue
                                                   password:self.passwordField.stringValue
                                        rememberCredentials:self.saveCredentialsButton.state];
        [self.loginProgressIndicator setHidden:NO];
        [self.loginProgressIndicator startAnimation:self];
        self.loginStatus = RPLoginStatusLogging;
        [self.loginStatusField setStringValue:@"Logging In..."];
    }
    else {
        NSBeep();
    }
}

- (void)showLoginDialog {
    self.loginStatus = RPLoginStatusNoUser;
    self.usernameField.stringValue = @"";
    self.passwordField.stringValue = @"";
    [self.loginDialog center];
    [self.loginDialog orderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.loginProgressIndicator setHidden:YES];
    [self.loginStatusField setStringValue:@""];
}

- (void)afterLoggedIn {
    self.topList = [[SPToplist alloc] initLocaleToplistWithLocale:nil inSession:[SPSession sharedSession]];
    self.loginStatus = RPLoginStatusLoggedIn;
}

- (void)didLoggedIn {
    [self afterLoggedIn];
    [self closeLoginDialog:nil];
}

- (void)logoutUser {
    self.loginStatus = RPLoginStatusNoUser;
    [self.playbackManager playTrack:nil error:nil];
    [[SPSession sharedSession] forgetStoredCredentials];
    [[SPSession sharedSession] logout];
    [self showLoginDialog];
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession {
    self.loginStatus = RPLoginStatusLoadingPlaylist;
    [self.loginStatusField setStringValue:@"Loading Playlists..."];
    [self performSelector:@selector(didLoggedIn) withObject:nil afterDelay:5.0];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
    self.loginStatus = RPLoginStatusNoUser;
    [self.loginStatusField setStringValue:@""];
    if (error.code == SP_ERROR_USER_NEEDS_PREMIUM) {
        [[NSApplication sharedApplication] presentError:[NSError spotifyErrorWithDescription:@"According to Spotify's terms of use, to run third-party apps, a Premium account is required. Thanks for your interest in Repeatify. Please upgrade to Spotify Premium account."]];
    }
    else {
        [[NSApplication sharedApplication] presentError:error];
    }
    [self.passwordField becomeFirstResponder];
    
    [self.loginProgressIndicator setHidden:YES];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error {
    NSLog(@"did encounter network error: %@", [error localizedDescription]);
}

-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage {
    // NSLog(@"did log message: %@", aMessage);
}

-(void)sessionDidChangeMetadata:(SPSession *)aSession {
    // NSLog(@"did change metadata");
}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
    NSLog(@"a message: %@", aMessage);
}

#pragma mark - 
#pragma mark SPMediaKeyTap Methods
-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {
    NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyIsPressed) {
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                [self togglePlayController:self];
                break;
            case NX_KEYTYPE_FAST:
                [self togglePlayNext:self];
                break;
            case NX_KEYTYPE_REWIND:
                [self togglePlayPrevious:self];
                break;
            default:
                break;
        }
    }
}

@end
