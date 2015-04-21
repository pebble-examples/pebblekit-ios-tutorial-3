//
//  ViewController.m
//  PebbleKit-iOS-Tutorial-3
//
//  Created by Chris Lewis on 1/13/15.
//  Copyright (c) 2015 Pebble. All rights reserved.
//

#import "ViewController.h"
#import "PebbleKit/PebbleKit.h"

#define KEY_CHOICE 0
#define CHOICE_ROCK 0
#define CHOICE_PAPER 1
#define CHOICE_SCISSORS 2
#define CHOICE_WAITING 3

#define KEY_RESULT 1
#define RESULT_LOSE 0
#define RESULT_WIN 1
#define RESULT_TIE 2

@interface ViewController () <PBPebbleCentralDelegate>

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *rockButton;
@property (weak, nonatomic) IBOutlet UIButton *paperButton;
@property (weak, nonatomic) IBOutlet UIButton *scissorsButton;

@property PBWatch *watch;

@end

@implementation ViewController

// State variables
int localChoice = CHOICE_WAITING;
int remoteChoice = CHOICE_WAITING;
int gameCounter, winCounter;

- (IBAction)onRockPressed:(id)sender {
    localChoice = CHOICE_ROCK;
    [self updateUI];
}

- (IBAction)onPaperPressed:(id)sender {
    localChoice = CHOICE_PAPER;
    [self updateUI];
}

- (IBAction)onScissorsPressed:(id)sender {
    localChoice = CHOICE_SCISSORS;
    [self updateUI];
}

- (void)setImage:(NSString*) name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    [self.imageView setImage:img];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup delegate
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // UUID of watchapp starter project: af17efe7-2141-4eb2-b62a-19fc1b595595
    uint8_t bytes[] = {0xaf, 0x17, 0xef, 0xe7, 0x21, 0x41, 0x4e, 0xb2, 0xb6, 0x2a, 0x19, 0xfc, 0x1b, 0x59, 0x55, 0x95};
    NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [[PBPebbleCentral defaultCentral] setAppUUID:uuid];
    
    // Get watch reference
    self.watch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    if(self.watch) {
        // Watch connected!
        [self.outputLabel setText:@"Choose a weapon..."];
        
        // Register for AppMessage delivery
        [self.watch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
            // A new message has been received in 'update'
            if([update objectForKey:@(KEY_CHOICE)]) {
                // The KEY_CHOICE key is in the message!
                remoteChoice = [[update objectForKey:@(KEY_CHOICE)] intValue];
                
                // Has the iOS player chosen already?
                if(localChoice != CHOICE_WAITING) {
                    [self doMatch];
                }
            }
            
            return YES;
        }];
    } else {
        // Watch not connected!
        [self.outputLabel setText:@"Watch NOT connected!"];
    }
    
    // Set initial image
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated {
    localChoice = CHOICE_WAITING;
    winCounter = 0;
    gameCounter = 0;
    
    [self updateUI];
}

- (void)updateUI {
    if(localChoice == CHOICE_WAITING) {
        [self.outputLabel setText:@"Choose your weapon..."];
        [self.rockButton setEnabled:YES];
        [self.paperButton setEnabled:YES];
        [self.scissorsButton setEnabled:YES];
        
        [self setImage:@"unknown"];
    } else {
        // A choice has been made
        [self.rockButton setEnabled:NO];
        [self.paperButton setEnabled:NO];
        [self.scissorsButton setEnabled:NO];
        [self.outputLabel setText:@"Waiting for opponent..."];

        switch(localChoice) {
            case CHOICE_ROCK:
                [self setImage:@"rock"];
                break;
            case CHOICE_PAPER:
                [self setImage:@"paper"];
                break;
            case CHOICE_SCISSORS:
                [self setImage:@"scissors"];
                break;
        }
    }
    
    // Check Pebble player response has arrived first
    if(localChoice != CHOICE_WAITING && remoteChoice != CHOICE_WAITING) {
        [self doMatch];
    }
}

/**
 * Compare choices and declare a winner
 * R = R
 * R < P
 * R > S
 *
 * P > R
 * P = P
 * P < S
 *
 * S < R
 * S > P
 * S = S
 */
- (void)doMatch {
    // Remember how many games in this session
    gameCounter++;
    
    // Prepare message for Pebble app
    NSMutableDictionary *outgoing = [NSMutableDictionary new];
    
    switch (localChoice) {
        case CHOICE_ROCK:
            switch(remoteChoice) {
                case CHOICE_ROCK:
                    [self.outputLabel setText:@"It's a tie!"];
                    [outgoing setObject:@(RESULT_TIE) forKey:@(KEY_RESULT)];
                    break;
                case CHOICE_PAPER:
                    [self.outputLabel setText:@"You lose!"];
                    [outgoing setObject:@(RESULT_WIN) forKey:@(KEY_RESULT)];
                    break;
                case CHOICE_SCISSORS:
                    winCounter++;
                    [self.outputLabel setText:[NSString stringWithFormat:@"You win! (%d of %d)", winCounter, gameCounter]];
                    [outgoing setObject:@(RESULT_LOSE) forKey:@(KEY_RESULT)];
                    break;
            }
            break;
        case CHOICE_PAPER:
            switch(remoteChoice) {
                case CHOICE_ROCK:
                    winCounter++;
                    [self.outputLabel setText:[NSString stringWithFormat:@"You win! (%d of %d)", winCounter, gameCounter]];
                    break;
                case CHOICE_PAPER:
                    [self.outputLabel setText:@"It's a tie!"];
                    [outgoing setObject:@(RESULT_TIE) forKey:@(KEY_RESULT)];
                    break;
                case CHOICE_SCISSORS:
                    [self.outputLabel setText:@"You lose!"];
                    [outgoing setObject:@(RESULT_WIN) forKey:@(KEY_RESULT)];
                    break;
            }
            break;
        case CHOICE_SCISSORS:
            switch(remoteChoice) {
                case CHOICE_ROCK:
                    [self.outputLabel setText:@"You lose!"];
                    [outgoing setObject:@(RESULT_WIN) forKey:@(KEY_RESULT)];
                    break;
                case CHOICE_PAPER:
                    winCounter++;
                    [self.outputLabel setText:[NSString stringWithFormat:@"You win! (%d of %d)", winCounter, gameCounter]];
                    [outgoing setObject:@(RESULT_LOSE) forKey:@(KEY_RESULT)];
                    break;
                case CHOICE_SCISSORS:
                    [self.outputLabel setText:@"It's a tie!"];
                    [outgoing setObject:@(RESULT_TIE) forKey:@(KEY_RESULT)];
                    break;
            }
            break;
    }
    
    // Send message to Pebble player
    [self.watch appMessagesPushUpdate:outgoing onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        // Successful?
        if(error) {
            NSLog(@"Error sending update: %@", error);
        }
    }];
    
    // Finally reset both
    localChoice = CHOICE_WAITING;
    remoteChoice = CHOICE_WAITING;
    
    // Leave announcement for 5 seconds
    dispatch_time_t t = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    dispatch_after(t, dispatch_get_main_queue(), ^(void){
        [self updateUI];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
