//
//  ContactPickerTextView.m
//  ContactPicker
//
//  Created by Tristan Himmelman on 11/2/12.
//  Copyright (c) 2012 Tristan Himmelman. All rights reserved.
//

#import "THContactPickerView.h"
#import "THContactBubble.h"
#import "PhoneUtils.h"
#import "ChikkaAlertView.h"

@interface THContactPickerView (){
    BOOL _shouldSelectTextView;
}

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, strong) MyTextField *textField;
@property (nonatomic, strong) THBubbleColor *bubbleColor;
@property (nonatomic, strong) THBubbleColor *bubbleSelectedColor;

@end

@implementation THContactPickerView

#define kViewPadding 5 // the amount of padding on top and bottom of the view
#define kHorizontalPadding 4 // the amount of padding to the left and right of each contact bubble
#define kVerticalPadding 5 // amount of padding above and below each contact bubble
#define kTextViewMinWidth 130
//#define kContactButtonWidth 45.0f

#define IS_PORTRAIT     UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])
#define IS_LANDSCAPE    UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code        
        [self setup];
    }
    return self;
}

-(void) dealloc{
    NSLog(@"dealloc in thcontactpickerview");
    
    self.delegate = nil;
    self.textField.delegate = nil;
}

- (void)setup {
    
    //[self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    //[self setAutoresizesSubviews:NO];
    
    self.viewPadding = kViewPadding;
    
    self.contacts = [NSMutableDictionary dictionary];
    self.contactKeys = [NSMutableArray array];
    
    // Create a contact bubble to determine the height of a line
    THContactBubble *contactBubble = [[THContactBubble alloc] initWithName:@"Sample" photoUrl:nil];
    self.lineHeight = contactBubble.frame.size.height + 2 * kVerticalPadding;
 
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    // Create TextView
    // It would make more sense to use a UITextField (because it doesnt wrap text), however, there is no easy way to detect the "delete" key press using a UITextField when there is no 
    self.textField = [[MyTextField alloc] init];
    self.textField.delegate = self;
    self.textField.myDelegate = self;
    self.textField.font = contactBubble.label.font;
    self.textField.backgroundColor = [UIColor clearColor];
//    self.textView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
//    self.textView.scrollEnabled = NO;
//    self.textView.scrollsToTop = NO;
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    //JJRG: will only become first responder if tapped. By default, To is not the first responder
    //[self.textField becomeFirstResponder];
    
    // Add shadow to bottom border
    self.backgroundColor = [UIColor whiteColor];
    CALayer *layer = [self layer];
    [layer setShadowColor:[[UIColor colorWithRed:225.0/255.0 green:226.0/255.0 blue:228.0/255.0 alpha:1] CGColor]];
    [layer setShadowOffset:CGSizeMake(0, 2)];
    [layer setShadowOpacity:1];
    [layer setShadowRadius:1.0f];
    
    // Add placeholder label
    self.placeholderLabel = [[UILabel alloc] init];
    [self.placeholderLabel setText:@"To:"];
    [self.placeholderLabel sizeToFit];
    CGRect frame = self.placeholderLabel.frame;
    frame.origin.x = kViewPadding;
    frame.origin.y = kViewPadding * 2 + 1;
    self.placeholderLabel.frame = frame;
    self.placeholderLabel.font = contactBubble.label.font;
    self.placeholderLabel.textColor = [UIColor grayColor];
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.placeholderLabel];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - Public functions

- (void)disableDropShadow {
    CALayer *layer = [self layer];
    [layer setShadowRadius:0];
    [layer setShadowOpacity:0];
}

- (void)setFont:(UIFont *)font {
    _font = font;
    // Create a contact bubble to determine the height of a line
    THContactBubble *contactBubble = [[THContactBubble alloc] initWithName:@"Sample" photoUrl:nil];
    [contactBubble setFont:font];
    self.lineHeight = contactBubble.frame.size.height + 2 * kVerticalPadding;
    
    self.textField.font = font;
    [self.textField sizeToFit];
    
    self.placeholderLabel.font = font;
    self.placeholderLabel.frame = CGRectMake(2*kViewPadding, self.viewPadding, self.frame.size.width, self.lineHeight);
}

- (void)addContact:(NSString *)contact withName:(NSString *)name andPhotoUrl:(NSString *)photoUrl; {
   // id contactKey = [NSValue valueWithNonretainedObject:contact];
    
 //   NSLog(@"contact to be added: %@ with contactKey: %@", name, contactKey);
    
    if ([self.contactKeys containsObject:contact] || [self.contactKeys count]>self.maximumRecipients){
        //NSLog(@"Cannot add the same object twice to ContactPickerView");
        self.textField.text = @"";
        return;
    }
 
    //check if name is a number, and if so, append "+" if not ctm id
    //if ([name isEqualToString:contact] && ![contact hasPrefix:@"08"]){
    if ([name isEqualToString:contact] && ![PhoneUtils isChikkaNumber:contact]){
        name = [NSString stringWithFormat:@"+%@", name];
    }
    else {
    }
    
    self.textField.text = @"";
    
    //NSLog(@"self.contacts: %@", self.contacts);
    //NSLog(@"self.contactKeys: %@", self.contactKeys);
    
    THContactBubble *contactBubble = [[THContactBubble alloc] initWithName:name
                                                                  photoUrl:photoUrl
                                                                     color:self.bubbleColor
                                                             selectedColor:self.bubbleSelectedColor];
    if (self.font != nil){
        [contactBubble setFont:self.font];
    }
    contactBubble.delegate = self;
    [self.contacts setObject:contactBubble forKey:contact];
    [self.contactKeys addObject:contact];
    
    // update layout
    [self layoutView];
    
    // scroll to bottom
    _shouldSelectTextView = YES;
    [self scrollToBottomWithAnimation:YES];
    // after scroll animation [self selectTextView] will be called
}

- (void)selectTextView {
    self.textField.hidden = NO;
    //[self.textField becomeFirstResponder];
}

- (void)removeAllContacts
{
    for(id contact in [self.contacts allKeys]){
      THContactBubble *contactBubble = [self.contacts objectForKey:contact];
      [contactBubble removeFromSuperview];
    }
    [self.contacts removeAllObjects];
    [self.contactKeys removeAllObjects];
  
    // update layout
    [self layoutView];
  
    self.textField.hidden = NO;
    self.textField.text = @"";
  
}

- (void)removeContact:(id)contact {
    [self removeContactByKey:contact];
//    id contactKey = [NSValue valueWithNonretainedObject:contact];
//    
//    NSLog(@"contactKey: %@", contactKey);
//    
//    // Remove contactBubble from view
//    THContactBubble *contactBubble = [self.contacts objectForKey:contactKey];
//    [contactBubble removeFromSuperview];
//    
//    // Remove contact from memory
//    [self.contacts removeObjectForKey:contactKey];
//    [self.contactKeys removeObject:contactKey];
//    
//    // update layout
//    [self layoutView];
//
//    [self.textField becomeFirstResponder];
//    self.textField.hidden = NO;
//
//    
//    [self scrollToBottomWithAnimation:NO];
}

- (void)setPlaceholderString:(NSString *)placeholderString {
    self.placeholderLabel.text = placeholderString;

    [self layoutView];
}

- (void)resignKeyboard {
    [self.textField resignFirstResponder];
}

- (void)setViewPadding:(CGFloat)viewPadding {
    _viewPadding = viewPadding;

    [self layoutView];
}

- (void)setBubbleColor:(THBubbleColor *)color selectedColor:(THBubbleColor *)selectedColor {
    self.bubbleColor = color;
    self.bubbleSelectedColor = selectedColor;

    for (id contactKey in self.contactKeys){
        THContactBubble *contactBubble = (THContactBubble *)[self.contacts objectForKey:contactKey];

        contactBubble.color = color;
        contactBubble.selectedColor = selectedColor;

        // thid stuff reloads bubble
        if (contactBubble.isSelected)
            [contactBubble select];
        else
            [contactBubble unSelect];
    }
}

#pragma mark - Private functions

- (void)scrollToBottomWithAnimation:(BOOL)animated {
    if (animated){
        CGSize size = self.scrollView.contentSize;
        CGRect frame = CGRectMake(0, size.height - self.scrollView.frame.size.height, size.width, self.scrollView.frame.size.height);
        
        [self.scrollView scrollRectToVisible:frame animated:animated];
    } else {
        // this block is here because scrollRectToVisible with animated NO causes crashes on iOS 5 when the user tries to delete many contacts really quickly
        CGPoint offset = self.scrollView.contentOffset;
        offset.y = self.scrollView.contentSize.height - self.scrollView.frame.size.height;
        self.scrollView.contentOffset = offset;
    }
}

- (void)removeContactBubble:(THContactBubble *)contactBubble {
      NSLog(@"======> removeContactBubble");
    id contact = [self contactForContactBubble:contactBubble];
    if (contact == nil){
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(contactPickerDidRemoveContact:)]){
        [self.delegate contactPickerDidRemoveContact:contact];
    }
    
    [self removeContactByKey:contact];
}

- (void)removeContactByKey:(id)contactKey {
  
  // Remove contactBubble from view
  THContactBubble *contactBubble = [self.contacts objectForKey:contactKey];
  [contactBubble removeFromSuperview];
  
  // Remove contact from memory
  [self.contacts removeObjectForKey:contactKey];
  [self.contactKeys removeObject:contactKey];
  
  // update layout
  [self layoutView];
  
  [self.textField becomeFirstResponder];
  self.textField.hidden = NO;
  self.textField.text = @"";
  
  [self scrollToBottomWithAnimation:NO];
}

- (id)contactForContactBubble:(THContactBubble *)contactBubble {
    NSArray *keys = [self.contacts allKeys];
    
    for (id contact in keys){
        if ([[self.contacts objectForKey:contact] isEqual:contactBubble]){
            return contact;
        }
    }
    return nil;
}

- (void)layoutView {
    
    NSLog(@"layoutView");
    
    CGRect frameOfLastBubble = CGRectNull;
    int lineCount = 0;
    
    THContactBubble *contactBubble;
    CGRect bubbleFrame;
    CGFloat bubbleWidth = 0.0f;
    // Loop through selectedContacts and position/add them to the view
    
    if ([self.contactKeys count] == 0){
        self.textField.placeholder = @"Enter name or number";
    }else{
        self.textField.placeholder = nil;
    }
    
    for (id contactKey in self.contactKeys){
        contactBubble = (THContactBubble *)[self.contacts objectForKey:contactKey];
        bubbleFrame = contactBubble.frame;

        if (CGRectIsNull(frameOfLastBubble)){ // first line
            //NSLog(@"FIRST LINE");
            bubbleWidth = bubbleFrame.size.width + 2 * kHorizontalPadding;
            if (self.frame.size.width - bubbleWidth - 40 >= 0){
            //NSLog(@"FIRST IF");
                bubbleFrame.origin.x = kViewPadding + kHorizontalPadding + self.placeholderLabel.frame.size.width;
                bubbleFrame.origin.y = kVerticalPadding + self.viewPadding;
            }else{
                lineCount++;
                bubbleFrame.origin.x = kHorizontalPadding;
                bubbleFrame.origin.y = (lineCount * self.lineHeight) + kVerticalPadding + 	self.viewPadding;
            }
        } else {
            //NSLog(@"NEXT LINE");
            // Check if contact bubble will fit on the current line
            bubbleWidth = bubbleFrame.size.width + 2 * kHorizontalPadding;
            if (self.frame.size.width - frameOfLastBubble.origin.x - frameOfLastBubble.size.width - bubbleWidth >= 0){ // add to the same line
                // Place contact bubble just after last bubble on the same line
                bubbleFrame.origin.x = frameOfLastBubble.origin.x + frameOfLastBubble.size.width + kHorizontalPadding;
                bubbleFrame.origin.y = frameOfLastBubble.origin.y;
            } else { // No space on line, jump to next line
                lineCount++;
                //bubbleFrame.origin.x = kHorizontalPadding;
                bubbleFrame.origin.x = kViewPadding;
                bubbleFrame.origin.y = (lineCount * self.lineHeight) + kVerticalPadding + 	self.viewPadding;
            }
        }
        frameOfLastBubble = bubbleFrame;
        contactBubble.frame = bubbleFrame;
        // Add contact bubble if it hasn't been added
        if (contactBubble.superview == nil){
            [self.scrollView addSubview:contactBubble];
        }
    }
    
    // Now add a textView after the comment bubbles
    CGFloat minWidth = kTextViewMinWidth + 2 * kHorizontalPadding;
    CGRect textViewFrame = CGRectMake(0, 0, self.textField.frame.size.width, self.lineHeight-10);

    // Check if we can add the text field on the same line as the last contact bubble
    if (CGRectIsNull(frameOfLastBubble)){ // first line
        textViewFrame.origin.x = kViewPadding + kHorizontalPadding + self.placeholderLabel.frame.size.width;
        textViewFrame.size.width = self.frame.size.width - textViewFrame.origin.x - 20;
        
    } else if (self.frame.size.width - frameOfLastBubble.origin.x - frameOfLastBubble.size.width - minWidth >= 0){ // add to the same line
        textViewFrame.origin.x = frameOfLastBubble.origin.x + frameOfLastBubble.size.width + kHorizontalPadding;
        
        if (lineCount ==0) {
            textViewFrame.size.width = self.frame.size.width - textViewFrame.origin.x - 20;
        }
        else {
            textViewFrame.size.width = self.frame.size.width - textViewFrame.origin.x;
        }
    } else { // place text view on the next line
        lineCount++;
        if (self.contacts.count == 0){
            lineCount = 0;
        }
        
        textViewFrame.origin.x = kHorizontalPadding;
        textViewFrame.size.width = self.frame.size.width - 2 * kHorizontalPadding;
    }
    self.textField.frame = textViewFrame;
    self.textField.center = CGPointMake(self.textField.center.x, lineCount * self.lineHeight + self.lineHeight / 2 + kVerticalPadding);
    
    // Add text view if it hasn't been added 
    if (self.textField.superview == nil){
        [self.scrollView addSubview:self.textField];
    }

//    // Hide the text view if we are limiting number of selected contacts to 1 and a contact has already been added
//    if (self.limitToOne && self.contacts.count >= 1){
//        self.textField.hidden = YES;
//        lineCount = 0;
//    }
    
    // Adjust scroll view content size
    CGRect frame = self.bounds;

    CGFloat maxFrameHeight;
    if (IS_PORTRAIT){
        maxFrameHeight = 2 * self.lineHeight + 2 * self.viewPadding; // limit frame to two lines of content in portrait mode
    }
    else {
        maxFrameHeight = self.lineHeight + self.viewPadding; // limit frame to one line of content in landscape mode
    }
  
    CGFloat newHeight = (lineCount + 1) * self.lineHeight + 2 * self.viewPadding;
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width, newHeight);

    // Adjust frame of view if necessary
    newHeight = (newHeight > maxFrameHeight) ? maxFrameHeight : newHeight;
    if (self.frame.size.height != newHeight){
        // Adjust self height
        CGRect selfFrame = self.frame;
        selfFrame.size.height = newHeight;
        selfFrame.size.width = frame.size.width;
        self.frame = selfFrame;
        
        // Adjust scroll view height
        frame.size.height = newHeight;
        self.scrollView.frame = frame;
        
        if ([self.delegate respondsToSelector:@selector(contactPickerDidResize:)]){
            [self.delegate contactPickerDidResize:self];
        }
    }

}




#pragma mark - UITextViewDelegate
- (BOOL)textField:(UITextField *)textView shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    NSLog(@" shouldChangeCharactersInRange:");
    NSLog(@"textview.text: %@", textView.text);
    NSLog(@"replacement string: %@", text);
    
    self.textField.hidden = NO;
    // Capture "delete" key press when cell is empty
    if ([textView.text isEqualToString:@""] && [text isEqualToString:@""] && [self.contactKeys count]>0){
        // If no contacts are selected, select the last contact
//        self.selectedContactBubble = [self.contacts objectForKey:[self.contactKeys lastObject]];
//        [self.selectedContactBubble select];
         return YES;
    }
    
//    if ([self.delegate recordingViewIsShown] && [self.contacts count]>1) {
//        //but this will never happen....
//        return NO;
//    }
    
    if([self.contacts count]>=self.maximumRecipients){
        [ChikkaAlertView showAlertViewWithMessage:ERROR_MAX_NUMBER_OF_RECIPIENTS_REACHED];
        return NO;
    }
    
    
//JJRG: I commented out this function because we are not going to listen to the enter events anymore
//
//    if ( [text isEqualToString:@"\n"] || [text isEqualToString:@";"] || [text isEqualToString:@","] ) { // Return key was pressed, or ; or ,
//        if ([self.delegate respondsToSelector:@selector(contactPickerTextView:enterKeyPressedWithText:)]){
//            [self.delegate contactPickerTextView:textView enterKeyPressedWithText:textView.text];
//        }
//        return NO;
//    }
    
    
     return YES;   
}

- (void)textFieldDidChange:(UITextField *)textView {
    if ([self.delegate respondsToSelector:@selector(contactPickerTextViewDidChange:)]){
        [self.delegate contactPickerTextViewDidChange:textView.text];
    }
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.placeholder = nil;
}

- (void)textFieldDidEndEditing:(UITextField *)textView
{
//    NSString *text = self.textField.text;
//    
//    if ([self.delegate respondsToSelector:@selector(contactPickerWillAddContact:)]){
//        [self.delegate contactPickerWillAddContact:text];
//    }

}

#pragma mark - MyTextFieldDelegate methods

- (void)textFieldDidDeleteWithText:(NSString *)text {
        // DELETE pressed with textfield empty
    
    NSLog(@"=======> textFieldDidDeleteWithText: %@ contactKey: %d", text, [self.contactKeys count]);
    
    if ([text length]==0 && [self.contactKeys count]>0){
        NSLog(@"DELETEEEEE");
        self.selectedContactBubble = [self.contacts objectForKey:[self.contactKeys lastObject]];
        [self.selectedContactBubble select];
    }

}


#pragma mark - THContactBubbleDelegate Functions

- (void)contactBubbleWasSelected:(THContactBubble *)contactBubble {
    @try {
        
        NSLog(@"======> contactBubbleWasSelected select");
        if (self.selectedContactBubble != nil){
            [self.selectedContactBubble unSelect];
        }
        self.selectedContactBubble = contactBubble;
        
        //[self.textField resignFirstResponder];
        self.textField.text = @"";
        self.textField.hidden = YES;

    }	
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
}

- (void)contactBubbleWasUnSelected:(THContactBubble *)contactBubble {
    @try {
        if (self.selectedContactBubble != nil){
            
        }
        [self.textField becomeFirstResponder];
        self.textField.text = @"";
        self.textField.hidden = NO;
    }
    @catch (NSException *exception) {
        NSLog(@"exception =%@", exception);
    }
    @finally {
        
    }
   
}

- (void)contactBubbleShouldBeRemoved:(THContactBubble *)contactBubble {
    NSLog(@"======> THContactBubble contactBubbleShouldBeRemoved");

    [self removeContactBubble:contactBubble];
}

#pragma mark - Gesture Recognizer

- (void)handleTapGesture {
    if (self.limitToOne && self.contactKeys.count == 1){
        return;
    }
    [self scrollToBottomWithAnimation:YES];
    
    // Show textField
    self.textField.hidden = NO;
    [self.textField becomeFirstResponder];
    
    // Unselect contact bubble
    [self.selectedContactBubble unSelect];
    self.selectedContactBubble = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    @try {
        if (_shouldSelectTextView){
            _shouldSelectTextView = NO;
            [self selectTextView];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
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





#pragma mark - Added Functions

- (void)changeContactPickerFrameTo:(CGRect)newFrame{
    self.frame = newFrame;
    self.scrollView.frame = self.frame;
    //self.placeholderLabel.frame = CGRectMake(8, self.viewPadding, self.frame.size.width, self.lineHeight);
    self.textField.frame = CGRectMake(100, 0, self.frame.size.width - self.placeholderLabel.frame.size.width, self.lineHeight + 8);
    
    for(id contact in [self.contacts allKeys]){
        THContactBubble *contactBubble = [self.contacts objectForKey:contact];
        [contactBubble removeFromSuperview];
    }
    [self layoutView];
}


- (void)checkIfHasTextInTextViewOnSend
{
//    if ([self.textField.text length]>0) {
//        [self.delegate contactPickerTextView:self.textField enterKeyPressedWithText:self.textField.text];
//    }
}


-(BOOL) becomeFirstResponder
{
    [super becomeFirstResponder];
    return [self.textField becomeFirstResponder];
}

-(BOOL) resignFirstResponder
{
    [super resignFirstResponder];
    if (self.selectedContactBubble){
        NSLog(@"contact picker has a selected bubble. must unselect!");
        [self.selectedContactBubble unSelect];
    }

    return [self.textField resignFirstResponder];
}

-(BOOL) isFirstResponder
{
    return [self.textField isFirstResponder];
}


@end
