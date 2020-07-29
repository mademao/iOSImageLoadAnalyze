//
//  KeyboardViewController.m
//  BaseKeyboard
//
//  Created by mademao on 2020/7/21.
//  Copyright © 2020 mademao. All rights reserved.
//

#import "KeyboardViewController.h"
#import "CustomView.h"

@interface KeyboardViewController ()
@property (nonatomic, strong) UIButton *nextKeyboardButton;

@property (nonatomic, strong) CustomView *customView;
@end

@implementation KeyboardViewController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Perform custom UI setup here
    self.nextKeyboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [self.nextKeyboardButton setTitle:NSLocalizedString(@"Next Keyboard", @"Title for 'Next Keyboard' button") forState:UIControlStateNormal];
    [self.nextKeyboardButton sizeToFit];
    self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.nextKeyboardButton addTarget:self action:@selector(handleInputModeListFromView:withEvent:) forControlEvents:UIControlEventAllTouchEvents];
    
    [self.view addSubview:self.nextKeyboardButton];
    
    [self.nextKeyboardButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.nextKeyboardButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    [self.view addSubview:self.customView];
    [self.view sendSubviewToBack:self.customView];
}

- (void)viewWillLayoutSubviews
{
    self.nextKeyboardButton.hidden = !self.needsInputModeSwitchKey;
    [super viewWillLayoutSubviews];
}

- (void)textWillChange:(id<UITextInput>)textInput {
    // The app is about to change the document's contents. Perform any preparation here.
}

- (void)textDidChange:(id<UITextInput>)textInput {
    // The app has just changed the document's contents, the document context has been updated.
    
    UIColor *textColor = nil;
    if (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearanceDark) {
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    [self.nextKeyboardButton setTitleColor:textColor forState:UIControlStateNormal];
}

- (CustomView *)customView
{
    if (_customView == nil) {
        _customView = [[CustomView alloc] initWithFrame:self.view.bounds];
        _customView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _customView;
}

@end
