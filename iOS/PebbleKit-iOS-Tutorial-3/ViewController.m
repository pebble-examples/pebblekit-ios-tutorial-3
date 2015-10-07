//
//  ViewController.m
//  PebbleKit-iOS-Tutorial-3
//
//  Created by Chris Lewis on 1/13/15.
//  Copyright (c) 2015 Pebble. All rights reserved.
//

#import "ViewController.h"
#import "PebbleKit/PebbleKit.h"

// AppMessage key values
typedef NS_ENUM(NSUInteger, AppMessageKey) {
    KeyChoice = 0,
    KeyResult
};

// Game result values
typedef NS_ENUM(NSUInteger, GameResult) {
    ResultLose = 0,
    ResultWin,
    ResultTie
};

// Game weapon choices
typedef NS_ENUM(NSUInteger, Choice) {
    ChoiceRock = 0,
    ChoicePaper,
    ChoiceScissors,
    ChoiceWaiting
};

@interface ViewController () <PBPebbleCentralDelegate>

@property (weak, nonatomic) PBPebbleCentral *central;
@property (weak, nonatomic) PBWatch *watch;

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *rockButton;
@property (weak, nonatomic) IBOutlet UIButton *paperButton;
@property (weak, nonatomic) IBOutlet UIButton *scissorsButton;

// State variables
@property (nonatomic) Choice localChoice;
@property (nonatomic) Choice remoteChoice;
@property (nonatomic) NSUInteger gameCounter;
@property (nonatomic) NSUInteger winCounter;

@end

@implementation ViewController

- (IBAction)onRockPressed:(id)sender {
    self.localChoice = ChoiceRock;
    [self updateUI];
}

- (IBAction)onPaperPressed:(id)sender {
    self.localChoice = ChoicePaper;
    [self updateUI];
}

- (IBAction)onScissorsPressed:(id)sender {
    self.localChoice = ChoiceScissors;
    [self updateUI];
}

- (void)setImage:(NSString*) name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    self.imageView.image = img;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.localChoice = ChoiceWaiting;
    self.remoteChoice = ChoiceWaiting;
    
    // Setup delegate
    self.central = [PBPebbleCentral defaultCentral];
    self.central.delegate = self;
    
    // UUID of watchapp starter project: af17efe7-2141-4eb2-b62a-19fc1b595595
    self.central.appUUID = [[NSUUID alloc] initWithUUIDString:@"af17efe7-2141-4eb2-b62a-19fc1b595595"];
    
    // Begin connection
    [self.central run];
    
    // Set initial image
    [self updateUI];
}

-(void)pebbleCentral:(PBPebbleCentral *)central watchDidConnect:(PBWatch *)watch isNew:(BOOL)isNew {
    if(self.watch) {
        return;
    }
    self.watch = watch;
}

-(void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
    // Only remove reference if it was the current active watch
    if(self.watch == watch) {
        self.watch = nil;
        self.outputLabel.text = @"Watch disconnected";
    }
}

- (void)updateUI {
    if(self.localChoice == ChoiceWaiting) {
        self.outputLabel.text = @"Choose your weapon...";
        self.rockButton.enabled = YES;
        self.paperButton.enabled = YES;
        self.scissorsButton.enabled = YES;
        
        [self setImage:@"unknown"];
    } else {
        // A choice has been made
        self.rockButton.enabled = NO;
        self.paperButton.enabled = NO;
        self.scissorsButton.enabled = NO;
        self.outputLabel.text = @"Waiting for opponent...";
        
        switch(self.localChoice) {
            case ChoiceRock:
                [self setImage:@"rock"];
                break;
            case ChoicePaper:
                [self setImage:@"paper"];
                break;
            case ChoiceScissors:
                [self setImage:@"scissors"];
                break;
            case ChoiceWaiting: // Handled above
                break;
        }
    }
    
    // Check Pebble player response has arrived first
    if(self.localChoice != ChoiceWaiting && self.remoteChoice != ChoiceWaiting) {
        [self doMatch];
    }
}

-(GameResult)compareChoices {
    if(self.localChoice == self.remoteChoice) {
        // It's a tie!
        return ResultTie;
    } else {
        // The two are different. Which one wins?
        switch (self.localChoice) {
            case ChoiceRock:
                // Beats scissors, loses to paper
                return self.remoteChoice == ChoiceScissors ? ResultWin : ResultLose;
            case ChoicePaper:
                // Beats rock, loses to scissors
                return self.remoteChoice == ChoiceRock ? ResultWin : ResultLose;
            case ChoiceScissors:
                // Beats paper, loses to rock
                return self.remoteChoice == ChoicePaper ? ResultWin : ResultLose;
            case ChoiceWaiting:
            default:
                // (Shouldn't happen)
                return ResultTie;
        }
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
    self.gameCounter++;
    
    GameResult result = [self compareChoices];
    switch(result) {
        case ResultTie:
            self.outputLabel.text = @"It's a tie!";
            break;
        case ResultWin:
            self.winCounter++;
            self.outputLabel.text = [NSString stringWithFormat:@"You win! (%d of %d)", (int)self.winCounter, (int)self.gameCounter];
            break;
        case ResultLose:
            self.outputLabel.text = @"You lose!";
            break;
    }
    
    // Finally reset both
    self.localChoice = ChoiceWaiting;
    self.remoteChoice = ChoiceWaiting;
    
    // Remove result announcement after 5 seconds
    [self performSelector:@selector(updateUI) withObject:nil afterDelay:5];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
