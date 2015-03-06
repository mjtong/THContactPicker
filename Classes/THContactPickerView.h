//
//  ContactPickerTextView.h
//  ContactPicker
//
//  Created by Tristan Himmelman on 11/2/12.
//  Copyright (c) 2012 Tristan Himmelman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THContactBubble.h"
#import "MyTextField.h"

@class THContactPickerView;

@protocol THContactPickerDelegate <NSObject>

- (void)contactPickerTextViewDidChange:(NSString *)textViewText;
- (void)contactPickerDidRemoveContact:(id)contact;
- (void)contactPickerWillAddContact:(NSString*)contact;
- (void)contactPickerDidResize:(THContactPickerView *)contactPickerView;
//- (BOOL)contactPickerTextView:(UITextView *)textView enterKeyPressedWithText:(NSString *)text;
- (BOOL)contactPickerTextView:(UITextField *)textView enterKeyPressedWithText:(NSString *)text;
-(BOOL)recordingViewIsShown;

@end

@interface THContactPickerView : UIView <UITextViewDelegate, THContactBubbleDelegate, UIScrollViewDelegate, UITextFieldDelegate, MyTextFieldDelegate>

@property (nonatomic, strong) THContactBubble *selectedContactBubble;
@property (nonatomic, assign) IBOutlet id <THContactPickerDelegate> delegate;
@property (nonatomic, assign) BOOL limitToOne;
@property (nonatomic, assign) CGFloat viewPadding;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, retain) NSMutableDictionary *contacts;
@property (nonatomic, strong) NSMutableArray *contactKeys; // an ordered set of the keys placed in the contacts dictionary
@property int maximumRecipients;


- (void)addContact:(NSString *)contact withName:(NSString *)name andPhotoUrl:(NSString *)photoUrl;
- (void)removeContact:(NSString *)contact;
- (void)removeAllContacts;
- (void)setPlaceholderString:(NSString *)placeholderString;
- (void)disableDropShadow;
- (void)resignKeyboard;
- (void)setBubbleColor:(THBubbleColor *)color selectedColor:(THBubbleColor *)selectedColor;
- (void)checkIfHasTextInTextViewOnSend;

//added functions
- (void)changeContactPickerFrameTo:(CGRect)newFrame;
@end
