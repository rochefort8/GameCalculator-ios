//
//  ViewController.m
//  GameCalculator
//
//  Created by 荻原有二 on 2017/01/21.
//  Copyright © 2017年 Yuji Ogihara. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_0;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_1;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_2;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_3;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_4;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_5;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_separator;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_target;

@property (weak, nonatomic) NSTimer *updateDigitTimer ;

@property (strong, nonatomic) AVAudioPlayer *audioHit ;
@property (strong, nonatomic) AVAudioPlayer *audioNotHit ;
@property (strong, nonatomic) AVAudioPlayer *audioOver ;
@property (strong, nonatomic) AVAudioPlayer *audioUFO,*audioClear ;

@end

@implementation ViewController

typedef NS_ENUM(NSInteger, SegmentDigitType) {
    SEG_DIGIT_NONE = -1,
    SEG_DIGIT_0,SEG_DIGIT_1,SEG_DIGIT_2,SEG_DIGIT_3,SEG_DIGIT_4,
    SEG_DIGIT_5,SEG_DIGIT_6,SEG_DIGIT_7,SEG_DIGIT_8,SEG_DIGIT_9,
    SEG_DIGIT_UFO,
    SEG_DIGIT_MAX
};

NSString *const SegmentDigitNameList[] = {
    @"7seg_0",@"7seg_1",@"7seg_2",@"7seg_3",@"7seg_4",
    @"7seg_5",@"7seg_6",@"7seg_7",@"7seg_8",@"7seg_9",
    @"7seg_ufo"
};

NSString *const Segment7SeparatorNameList[] = {
    @"7seg_sep_3",@"7seg_sep_2",@"7seg_sep_1"
};

#define MAX_SEGMENT_POSITION (6)
#define MAX_REPEAT_COUNT_IN_STAGE (3)
#define MAX_DIGIT_EMERGE_COUNT (16)

int patternNumber ;     /* 1 to 9 */
int partNumber ;        /* 1 or 2 */

int totalScore ;

int repeatCountInStage ;
int targetNumber ;
int segmentDigitNumber[MAX_SEGMENT_POSITION];
int sumOfShootNumber ;
int emergeUFO ;
int shootCount ;
int digitCount ;


UIImageView *SegmentImageList[MAX_SEGMENT_POSITION] ;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SegmentImageList[0] = _segmentImage_0 ;
    SegmentImageList[1] = _segmentImage_1 ;
    SegmentImageList[2] = _segmentImage_2 ;
    SegmentImageList[3] = _segmentImage_3 ;
    SegmentImageList[4] = _segmentImage_4 ;
    SegmentImageList[5] = _segmentImage_5 ;
    
    [self resetPattern];
    
    repeatCountInStage = 0;
    targetNumber = 0;
    totalScore = 0 ;
    
    [self initAudio];
}

- (void)resetPattern {
    patternNumber = 0;
    partNumber = 0 ;
    totalScore = 0;
}

- (void)incrementPattern {
    if (++patternNumber > 9) {
        patternNumber = 1;
        partNumber = (partNumber % 2) + 1 ; /* 1 -> 2 -> 1 -> 2 -> .... */
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onReset:(id)sender {
    [self resetPattern] ;
    [self startPattern];
}

-(void)startPattern {
    
    repeatCountInStage = 0 ;
    shootCount = 0 ;
    emergeUFO = 0 ;
    [self prepareNewPattern];
    [self setNextDigit];
}

- (void)prepareNewPattern {
    
    targetNumber = 0;
    sumOfShootNumber = 0 ;
    digitCount = 0 ;
    
    for (int i = 0;i < MAX_SEGMENT_POSITION;i++) {
        segmentDigitNumber[i] = SEG_DIGIT_NONE ;
    }
    
    [self setDigitImage ];
    [self setSeparatorDigitImage] ;
    [self setTargetDigitImage];
}

- (void)setDigitImage {
    for (int i = 0;i < MAX_SEGMENT_POSITION;i++) {
        int number = segmentDigitNumber[i] ;
        if (number != SEG_DIGIT_NONE){
            SegmentImageList[i].image = [UIImage imageNamed:SegmentDigitNameList[number]] ;
        } else {
            SegmentImageList[i].image = nil ;
        }
    }
}


- (void)setSeparatorDigitImage {
    _segmentImage_separator.image = [UIImage imageNamed:Segment7SeparatorNameList[repeatCountInStage]] ;
}

- (void)setTargetDigitImage {
    _segmentImage_target.image = [UIImage imageNamed:SegmentDigitNameList[targetNumber]] ;
}

- (void)setNextDigit {
    
    if (segmentDigitNumber[MAX_SEGMENT_POSITION-1] != SEG_DIGIT_NONE) {
        NSLog(@"Over") ;
        if (++repeatCountInStage < MAX_REPEAT_COUNT_IN_STAGE) {
            [self prepareNewPattern] ;
            [self.audioOver play] ;

        } else {
            NSLog(@"GAME OVER") ;
            AudioServicesPlaySystemSound(1020);
            return ;
        }
    }
    int digit ;
    
    if (digitCount + shootCount < MAX_DIGIT_EMERGE_COUNT) {
        if (emergeUFO > 0) {
            digit = SEG_DIGIT_UFO ;
            emergeUFO-- ;
        } else {
            digit = (int)(arc4random() % (SEG_DIGIT_9 + 1)) ;
        }
        digitCount++ ;
    } else {
        digit = SEG_DIGIT_NONE ;
    }
    
    for (int i = MAX_SEGMENT_POSITION-1;i > 0 ;i--) {
        segmentDigitNumber[i] = segmentDigitNumber[i-1] ;
    }
    segmentDigitNumber[0] = digit ;
    [self setDigitImage ];

    _updateDigitTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                        target:self
                                            selector:@selector(updateDigitTimerExpired:)
                                            userInfo:nil
                                             repeats:NO];
    
}

-(void)updateDigitTimerExpired:(NSTimer*)timer{
    
    [_updateDigitTimer invalidate] ;
    [self setNextDigit] ;
}

- (IBAction)onIncrement:(id)sender {
    
    targetNumber = (targetNumber + 1) % SEG_DIGIT_MAX ;
    [self setTargetDigitImage] ;
}

- (IBAction)onShoot:(id)sender {
    Boolean found = false ;
    int i ;
    
    for (i = MAX_SEGMENT_POSITION-1;i >=0 ;i--) {
        if (targetNumber == segmentDigitNumber[i]) {
            found = true ;
            break ;
        }
    }
    if (found == true) {
        
        if (targetNumber == SEG_DIGIT_UFO) {
            [self.audioUFO play] ;
        } else {
            [self.audioHit play] ;
        }
        NSLog(@"Hit %d at segment %d.", targetNumber,i);
        
        /* Score */
        int score = 0 ;
        if (targetNumber == SEG_DIGIT_UFO) {
            score = 250 ;
        } else {
            score = 60 - 10*i ; /* 10 20 30 40 50 60 */
        }
        NSLog(@"Score=%d",score) ;
        totalScore += score ;

        NSLog(@"Score=%d",totalScore) ;

        if ((SEG_DIGIT_1 <= targetNumber) && (targetNumber <= SEG_DIGIT_9)) {
            sumOfShootNumber += targetNumber ;
            if ((sumOfShootNumber % 10) == 0){
                emergeUFO++ ;
            }
        }
        for ( ;i < MAX_SEGMENT_POSITION - 1;i++) {
            segmentDigitNumber[i] = segmentDigitNumber[i+1] ;
        }
        segmentDigitNumber[MAX_SEGMENT_POSITION - 1] = SEG_DIGIT_NONE ;
        
        digitCount-- ;
        shootCount++ ;
        [self setDigitImage ];

        if (MAX_DIGIT_EMERGE_COUNT <= shootCount) {
            if (digitCount != 0 ) {
                NSLog(@"digitCount!=0, ==%d",digitCount) ;
            }
            NSLog(@"Clear!!") ;
            [self setScoreImage];
            [self.audioClear play] ;
            
            [_updateDigitTimer invalidate];
         
            _updateDigitTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                 target:self
                                                               selector:@selector(nextStageTimerExpired:)
                                                               userInfo:nil
                                                                repeats:NO];
        }

    } else {
        NSLog(@"No %d found.", targetNumber);
        [self.audioNotHit play] ;
    }
}

- (void)setScoreImage {
    targetNumber = patternNumber ;
    for (int i = 0;i < MAX_SEGMENT_POSITION;i++) {
        segmentDigitNumber[i] = SEG_DIGIT_0 ;
    }
    NSLog (@"Score=%d",totalScore) ;
    
    int _score = totalScore ;
    
    for (int i = 0; i < MAX_SEGMENT_POSITION-1;i++) {
        segmentDigitNumber[i+1] = (_score % 100) / 10;
        _score /= 10 ;
    }
    
    [self setDigitImage ];
    [self setSeparatorDigitImage] ;
    [self setTargetDigitImage];
}

-(void)nextStageTimerExpired:(NSTimer*)timer{
    [_updateDigitTimer invalidate] ;
    
    [self incrementPattern];
    [self startPattern] ;
}

- (void)initAudio
{
    NSError *error ;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Hit" ofType:@"mp3"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioHit = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioHit.numberOfLoops = 0 ;
    if ( error != nil ) {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    [self.audioHit setDelegate:self];

    path = [[NSBundle mainBundle] pathForResource:@"NotHit" ofType:@"mp3"];
    url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioNotHit = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioNotHit.numberOfLoops = 0 ;
    if ( error != nil ) {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    [self.audioNotHit setDelegate:self];

    path = [[NSBundle mainBundle] pathForResource:@"Over" ofType:@"mp3"];
    url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioOver = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioOver.numberOfLoops = 0 ;
    if ( error != nil ) {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    [self.audioOver setDelegate:self];

    path = [[NSBundle mainBundle] pathForResource:@"UFO" ofType:@"mp3"];
    url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioUFO = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioUFO.numberOfLoops = 0 ;
    if ( error != nil ) {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    [self.audioUFO setDelegate:self];

    path = [[NSBundle mainBundle] pathForResource:@"Clear" ofType:@"mp3"];
    url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioClear = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioClear.numberOfLoops = 0 ;
    if ( error != nil ) {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    [self.audioClear setDelegate:self];
}


@end
