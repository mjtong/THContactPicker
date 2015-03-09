//
//  THContactBubble.m
//  ContactPicker
//
//  Created by Tristan Himmelman on 11/2/12.
//  Copyright (c) 2012 Tristan Himmelman. All rights reserved.
//

#import "THContactBubble.h"
//#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+WebCache.h"
#import "ChikkaRadius.h"

@implementation THContactBubble

#define kHorizontalPadding 10
#define kVerticalPadding 2

#define kColorGradientTop [UIColor colorWithRed:219.0/255.0 green:229.0/255.0 blue:249.0/255.0 alpha:1.0]
#define kColorGradientBottom [UIColor colorWithRed:188.0/255.0 green:205.0/255.0 blue:242.0/255.0 alpha:1.0]
#define kColorBorder [UIColor colorWithRed:127.0/255.0 green:127.0/255.0 blue:218.0/255.0 alpha:1.0]

#define kColorSelectedGradientTop [UIColor colorWithRed:79.0/255.0 green:132.0/255.0 blue:255.0/255.0 alpha:1.0]
#define kColorSelectedGradientBottom [UIColor colorWithRed:73.0/255.0 green:58.0/255.0 blue:242.0/255.0 alpha:1.0]
#define kColorSelectedBorder [UIColor colorWithRed:56.0/255.0 green:0/255.0 blue:233.0/255.0 alpha:1.0]


#define kColorDefault [UIColor colorWithRed:71.0/255.0 green:71.0/255.0 blue:71.0/255.0 alpha:1.0]

#define maxBubbleWidth 180.0f

- (id)initWithName:(NSString *)name photoUrl:(NSString *)photoUrl {
    if ([self initWithName:name photoUrl:photoUrl color:nil selectedColor:nil]) {

    }
    return self;
}

- (id)initWithName:(NSString *)name
          photoUrl:(NSString *)photoUrl
             color:(THBubbleColor *)color
     selectedColor:(THBubbleColor *)selectedColor {
    self = [super init];
    if (self){
        self.name = name;
        self.photoUrl = photoUrl;
        self.isSelected = NO;

        if (! color)
            color = [[THBubbleColor alloc] initWithGradientTop:kColorDefault
                                                gradientBottom:kColorDefault
                                                        border:kColorDefault];

        if (! selectedColor)
            selectedColor = [[THBubbleColor alloc] initWithGradientTop:kColorDefault
                                                        gradientBottom:kColorDefault
                                                                border:kColorDefault];
        
        self.color = color;
        self.selectedColor = selectedColor;

        
        [self setupView];
    }
    return self;
}

-(void) dealloc{
    NSLog(@"dealloc111");
    
    self.textView.delegate = nil;
}

- (void)setupView {
    //create contact photo

    self.contactPhoto = [[UIImageView alloc] init];
    //[self.contactPhoto setImageWithURL:[NSURL URLWithString:self.photoUrl] placeholderImage:[UIImage imageNamed:@"img_contact.png"] options:0];
#if CTM_OLD
    [self.contactPhoto setImageWithURL:[NSURL URLWithString:self.photoUrl] placeholderImage:[UIImage imageNamed:@"profile-pic.png"] options:SDWebImageRefreshCached];
#else
    [self.contactPhoto sd_setImageWithURL:[NSURL URLWithString:self.photoUrl] placeholderImage:[UIImage imageNamed:@"profile-pic.png"] options:SDWebImageRefreshCached];
#endif

    [self addSubview:self.contactPhoto];


    // Create Label
    self.label = [[UILabel alloc] init];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.text = self.name;
    
    [self addSubview:self.label];
    
    self.textView = [[UITextView alloc] init];
    self.textView.delegate = self;
    self.textView.hidden = YES;
    [self addSubview:self.textView];
    
    // Create a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapGesture];
    
    [self adjustSize];
    
    [self unSelect];
}

- (void)adjustSize {

    
//    BOOL shouldShowPhoto = [UserDefaultsUtil getBoolValueForKey:kSettingsShowProfilePhoto withDefaultValue:YES];
//    if (shouldShowPhoto){
//        CGRect photoFrame = CGRectMake(0, 0, 25, 25);
//        self.contactPhoto.frame = photoFrame;
//    }
//    else {
        self.contactPhoto.frame = CGRectZero;
//    }
    
    // Adjust the label frames
    [self.label sizeToFit];
    CGRect frame = self.label.frame;
    
    if (frame.size.width > maxBubbleWidth){
        frame.size.width = maxBubbleWidth;
    }

    frame.origin.x = kHorizontalPadding + self.contactPhoto.frame.size.width;
    frame.origin.y = kVerticalPadding;
    self.label.frame = frame;
    
    
    // Adjust view frame
    self.bounds = CGRectMake(0, 0, frame.size.width + 2 * kHorizontalPadding + self.contactPhoto.frame.size.width, frame.size.height + 2 * kVerticalPadding);
    
    
    // Create gradient layer
    if (self.gradientLayer == nil){
        self.gradientLayer = [CAGradientLayer layer];
        [self.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    self.gradientLayer.frame = self.bounds;
    
    
    
    // Round the corners
    CALayer *viewLayer = [self layer];
    //viewLayer.cornerRadius = self.bounds.size.height / 2;
    viewLayer.cornerRadius = [ChikkaRadius mediumRadius];
    viewLayer.borderWidth = 1;
    viewLayer.masksToBounds = YES;
    
}

- (void)setFont:(UIFont *)font {
    self.label.font = font;

    [self adjustSize];
}

- (void)select {
    @try {
        NSLog(@"======> THContactBubble select");
        if ([self.delegate respondsToSelector:@selector(contactBubbleWasSelected:)]){
            [self.delegate contactBubbleWasSelected:self];
        }
        
        CALayer *viewLayer = [self layer];
        viewLayer.borderColor = self.selectedColor.border.CGColor;
        
        self.gradientLayer.colors = [NSArray arrayWithObjects:(id)[self.selectedColor.gradientTop CGColor], (id)[self.selectedColor.gradientBottom CGColor], nil];
        
        //self.label.textColor = [UIColor whiteColor];
        self.label.textColor = [UIColor lightGrayColor];
        
        self.isSelected = YES;
        
        [self.textView becomeFirstResponder];
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
   
}

- (void)unSelect {
    CALayer *viewLayer = [self layer];
    viewLayer.borderColor = self.color.border.CGColor;
    
    self.gradientLayer.colors = [NSArray arrayWithObjects:(id)[self.color.gradientTop CGColor], (id)[self.color.gradientBottom CGColor], nil];
    
    self.label.textColor = [UIColor whiteColor];

    [self setNeedsDisplay];
    self.isSelected = NO;
    
    [self.textView resignFirstResponder];
}

- (void)handleTapGesture {
    if (self.isSelected){
        [self unSelect];
    } else {
        [self select];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    @try {
        NSLog(@"======> THContactBubble shouldChangeTextInRange");
        self.textView.hidden = NO;
        
        if ( [text isEqualToString:@"\n"] ) { // Return key was pressed
            return NO;
        }
        
        // Capture "delete" key press when cell is empty
        if ([textView.text isEqualToString:@""] && [text isEqualToString:@""]){
            if ([self.delegate respondsToSelector:@selector(contactBubbleShouldBeRemoved:)]){
                [self.delegate contactBubbleShouldBeRemoved:self];
            }
        }
        
        if (self.isSelected){
            self.textView.text = @"";
            [self unSelect];
            if ([self.delegate respondsToSelector:@selector(contactBubbleWasUnSelected:)]){
                [self.delegate contactBubbleWasUnSelected:self];
            }
        }
        
        
    }
    @catch (NSException *exception) {
        NSLog(@"====== exception: %@", exception);
    }
    @finally {
        return YES;
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
