//
//  MWButtonGroup.m
//  MWButtonGroup-Example
//
//  Created by martin on 17/05/14.
//  Copyright (c) 2014 Martin Wilz. All rights reserved.
//

#import "MWButtonGroup.h"

@interface MWButtonGroup()

// views used for separator lines, these are all one pixel wide
@property (strong, nonatomic) NSArray *lineViews;



@end

@implementation MWButtonGroup

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupDefaults];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _setupDefaults];
    }
    
    return self;
}


- (void)_setupDefaults
{
    _buttons = @[];
    
    _font = nil;
    _borderColor = nil;
    _borderWidth = 1;
    
    _textColor = [UIColor whiteColor];
    _buttonBackgroundColor = [UIColor blackColor];
    _selectedIndexSet = [NSMutableIndexSet new];
    
    self.clipsToBounds = YES;
    
    //    self.layer.cornerRadius = 8;
    self.layer.borderColor = self.textColor.CGColor;
    self.layer.borderWidth = _borderWidth;
}

- (void)createButtonsForTitles:(NSArray *)titles
{
    NSMutableArray *buttons = [NSMutableArray new];
    NSMutableArray *lineViews = [NSMutableArray new];
    
    for (NSString *title in titles) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:self.textColor forState:UIControlStateNormal];
        
        if (_font) {
            button.titleLabel.font = _font;
        }
        
        [button addTarget:self
                   action:@selector(buttonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:button];
        [self addSubview:button];
        
        UIView *lineView = [UIView new];
        lineView.backgroundColor = (_borderColor) ? _borderColor : _textColor;
        [lineViews addObject:lineView];
        [self addSubview:lineView];
    }
    
    _selectedIndexSet = [NSMutableIndexSet new];
    _lineViews = [NSArray arrayWithArray:lineViews];
    _buttons = [NSArray arrayWithArray:buttons];
}


// internal method used, when deselection occurs triggered by user interaction
- (void)_notifyDeselection:(NSIndexSet *)indexSet
{
    if (self.delegate) {
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
            
            if ([self.delegate respondsToSelector:@selector(buttonGroup:didDeselectButtonAtIndex:)]) {
                [self.delegate buttonGroup:self didDeselectButtonAtIndex:index];
            }
            if ([self.delegate respondsToSelector:@selector(buttonGroup:didDeselectButton:)]) {
                [self.delegate buttonGroup:self didDeselectButton:_buttons[index]];
            }
        }];
    }
}


// internal method used, when selection occurs triggered by user interaction
- (void)_notifySelection:(NSUInteger)index
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(buttonGroup:didSelectButtonAtIndex:)]) {
            [self.delegate buttonGroup:self didSelectButtonAtIndex:index];
        }
        if ([self.delegate respondsToSelector:@selector(buttonGroup:didSelectButton:)]) {
            [self.delegate buttonGroup:self didSelectButton:_buttons[index]];
        }
    }
}


- (IBAction)buttonPressed:(id)sender
{
    NSInteger index = [_buttons indexOfObject:sender];
    
    if (index != NSNotFound) {
        if (self.multiSelectAllowed) {
            
            if (![_selectedIndexSet containsIndex:index]) {
                [self selectButtonAtIndex:index clock:NO];
                [self _notifySelection:index];
            }
            else {
                [self deselectButtonAtIndex:index];
                [self _notifyDeselection:[NSIndexSet indexSetWithIndex:index]];
            }
            
            return;
        }
        
        
        if (_clock) {
            NSMutableIndexSet *copy =  [self.selectedIndexSet mutableCopy];
            [copy removeIndex:index];
            
            [self selectButtonAtIndex:index clock:NO];
            [self _notifyDeselection:copy];
            [self _notifySelection:index];
        }
        if (![_selectedIndexSet containsIndex:index]) {
            NSMutableIndexSet *copy =  [self.selectedIndexSet mutableCopy];
            [copy removeIndex:index];
            
            [self selectButtonAtIndex:index clock:NO];
            [self _notifyDeselection:copy];
            [self _notifySelection:index];
        }
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect buttonFrame = self.bounds;
    buttonFrame.size.width = ((self.frame.size.width - _borderWidth) / self.buttons.count) - _borderWidth;
    
    CGRect lineFrame = self.bounds;
    lineFrame.size.width = _borderWidth;
    
    CGFloat x = _borderWidth;
    
    for (NSUInteger i = 0; i < _buttons.count; i++) {
        UIButton *button = _buttons[i];
        buttonFrame.origin.x = x;
        button.frame = buttonFrame;
        
        if (i < _buttons.count) {
            UIView *lineView = _lineViews[i];
            lineFrame.origin.x = x - _borderWidth;
            lineView.frame = lineFrame;
        }
        
        x += buttonFrame.size.width + _borderWidth;
    }
}


- (void)selectButtonAtIndex:(NSUInteger)index clock:(BOOL)clock;
{
    _clock = clock;
    if (index > _buttons.count) return;
    
    if (!self.multiSelectAllowed) {
        [_selectedIndexSet removeAllIndexes];
    }
    
    [_selectedIndexSet addIndex:index];
    
    [self updateButtons];
}


- (void)deselectButtonAtIndex:(NSUInteger)index
{
    if (index > self.buttons.count) return;
    
    [_selectedIndexSet removeIndex:index];
    [self setNeedsLayout];
    
    UIButton *button = _buttons[index];
    button.backgroundColor = self.buttonBackgroundColor;
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
}


- (void)updateButtons
{
    for (NSUInteger i = 0; i < _buttons.count; i++) {
        UIButton *button = _buttons[i];
        if ([_selectedIndexSet containsIndex:i]) {
            if (_clock) {
                button.backgroundColor = self.buttonBackgroundColor;
                [button setTitleColor:self.textColor forState:UIControlStateNormal];
            }else{
                button.backgroundColor = self.textColor;
                [button setTitleColor:[UIColor colorWithRed:0.16 green:0.18 blue:0.22 alpha:1] forState:UIControlStateNormal];
            }
        }
        else {
            button.backgroundColor = self.buttonBackgroundColor;
            [button setTitleColor:self.textColor forState:UIControlStateNormal];
        }
    }
}

#pragma mark Setters

- (void)setButtonBackgroundColor:(UIColor *)buttonBackgroundColor
{
    _buttonBackgroundColor = buttonBackgroundColor;
    [self updateButtons];
}


- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.layer.borderColor = (_borderColor) ? _borderColor.CGColor : _textColor.CGColor;
    
    if (!_borderColor) {
        for (UIView *view in _lineViews) {
            view.backgroundColor = self.textColor;
        }
    }
    
    [self setNeedsDisplay];
    [self updateButtons];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    
    for (UIButton *button in _buttons) {
        button.titleLabel.font = font;
    }
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.layer.borderWidth = _borderWidth;
    [self setNeedsLayout];
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.layer.borderColor = _borderColor.CGColor;
    
    for (UIView *view in _lineViews) {
        view.backgroundColor = _borderColor;
    }
}

@end
