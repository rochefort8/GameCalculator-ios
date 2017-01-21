//
//  ViewController.m
//  GameCalculator
//
//  Created by 荻原有二 on 2017/01/21.
//  Copyright © 2017年 Yuji Ogihara. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_0;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_1;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_2;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_3;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_4;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_5;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_separator;
@property (weak, nonatomic) IBOutlet UIImageView *segmentImage_target;

@property (weak, nonatomic) NSTimer *updateDigitTimer ;

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

int stageNumber ;
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
    stageNumber = 0 ;
    repeatCountInStage = 0;
    targetNumber = 0;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onReset:(id)sender {
    stageNumber = 0 ;
    repeatCountInStage = 0 ;
    shootCount = 0 ;
    [self resetSegment];
    [self setNextDigit];
}

- (void)resetSegment {
    targetNumber = 0;
    sumOfShootNumber = 0 ;
    emergeUFO = 0 ;
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
            [self resetSegment] ;
        } else {
            NSLog(@"GAME OVER") ;
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
    
    NSString *str = [_updateDigitTimer isValid] ? @"yes" : @"no";
    NSLog(@"isValid:%@", str);
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
        NSLog(@"Hit %d at segment %d.", targetNumber,i);
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
            [_updateDigitTimer invalidate];
        }

    } else {
        NSLog(@"No %d found.", targetNumber);
    }
}

@end
