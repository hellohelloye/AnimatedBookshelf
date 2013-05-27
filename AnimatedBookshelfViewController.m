//
//  AnimatedBookshelfViewController.m
//  AnimatedBookshelf
//
//  Created by Yukui Ye on 5/26/13.
//  Copyright (c) 2013 Yukui Ye. All rights reserved.
//

#import "AnimatedBookshelfViewController.h"
#import "AskerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AnimatedBookshelfViewController ()<UINavigationControllerDelegate,UIPopoverControllerDelegate,UIActionSheetDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *bookshelf;
@property (nonatomic,weak) NSTimer *drainTimer;
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;
@property (weak, nonatomic) UIActionSheet *bookshelfControlActionSheet;

@end

@implementation AnimatedBookshelfViewController


- (IBAction)addBookPhoto:(UIBarButtonItem *)sender {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum sender:sender];
}

- (IBAction)takeBookPhoto:(UIBarButtonItem *)sender {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera sender:sender];
}


// presents a UIImagePickerController which gets an image from the specified sourceType
// on iPad, if sourceType is not Camera, presents in a popover from the given UIBarButtonItem
//   (else modally)

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType sender:(UIBarButtonItem *)sender
{
    if (!self.imagePickerPopover && [UIImagePickerController isSourceTypeAvailable:sourceType]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = sourceType;
            picker.mediaTypes = @[(NSString *)kUTTypeImage];
            picker.allowsEditing = YES;
            picker.delegate = self;
            if ((sourceType != UIImagePickerControllerSourceTypeCamera) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
                self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [self.imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                self.imagePickerPopover.delegate = self;
            } else {
                [self presentViewController:picker animated:YES completion:nil];
            }
        }
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePickerPopover = nil;
}

// UIImagePickerController was canceled, so dismiss it

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#define MAX_IMAGE_WIDTH 200

// called when the user chooses an image in the UIImagePickerController
// limit any image to MAX_IMAGE_WIDTH
// randomly drops it into the kitchen sink
// dismisses the UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGRect frame = imageView.frame;
        if (frame.size.width > MAX_IMAGE_WIDTH) {
            frame.size.height = (frame.size.height / frame.size.width) * MAX_IMAGE_WIDTH;
            frame.size.width = MAX_IMAGE_WIDTH;
        }
        imageView.frame = frame;
        [self setRandomLocationForView:imageView];
        [self.bookshelf addSubview:imageView];
    }
    if (self.imagePickerPopover) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#define SINK_CONTROL_STOP_DRAIN @"Stopper Drain"
#define SINK_CONTROL_UNSTOP_DRAIN @"Unstopper Drain"
#define SINK_CONTROL @"Bookshelf Control"
#define SINK_CONTROL_CANCEL @"Cancel"
#define SINK_CONTROL_EMPTY @"Empty Bookshelf"


- (IBAction)controlBookshelf:(UIBarButtonItem *)sender {
    if (!self.bookshelfControlActionSheet) {
        NSString *drainButton = self.drainTimer ? SINK_CONTROL_STOP_DRAIN : SINK_CONTROL_UNSTOP_DRAIN;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:SINK_CONTROL
                                                                 delegate:self
                                                        cancelButtonTitle:SINK_CONTROL_CANCEL
                                                   destructiveButtonTitle:SINK_CONTROL_EMPTY
                                                        otherButtonTitles:drainButton, nil];
        [actionSheet showFromBarButtonItem:sender animated:YES];
        self.bookshelfControlActionSheet = actionSheet;  // sinkControlActionSheet is weak, but showing gives the popover a strong pointer to it
    }

}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self.bookshelf.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else {
        NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([choice isEqualToString:SINK_CONTROL_STOP_DRAIN]) {
            [self stopDrainTimer];
        } else if ([choice isEqualToString:SINK_CONTROL_UNSTOP_DRAIN]) {
            [self startDrainTimer];
        }
    }
}


#define DRAIN_DURATION 3.0
#define DRAIN_DELAY 1.0

- (void)startDrainTimer
{
    self.drainTimer = [NSTimer scheduledTimerWithTimeInterval:DRAIN_DURATION/3
                                                       target:self
                                                     selector:@selector(drain:)
                                                     userInfo:nil
                                                      repeats:YES];
}
-(void)drain:(NSTimer *)timer
{
    [self drain];
}

-(void)stopDrainTimer
{
    [self.drainTimer invalidate];
    self.drainTimer = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startDrainTimer];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopDrainTimer];
}

-(void)drain
{
    for (UIView *view in self.bookshelf.subviews) {
        CGAffineTransform transform = view.transform;
        if (CGAffineTransformIsIdentity(transform)) {
            [UIView animateWithDuration:DRAIN_DURATION/3 delay:DRAIN_DELAY options:UIViewAnimationOptionCurveLinear animations:^{
                view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3);
            } completion:^(BOOL finished) {
                if (finished) [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), -2*M_PI/3);
                } completion:^(BOOL finished) {
                    if (finished) [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{  view.transform = CGAffineTransformScale(transform, 0.1, 0.1);
                    } completion:^(BOOL finished) {
//if (finished) [view removeFromSuperview]; //view disappear after animationFinished
                        if(finished) view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99); //view turn to be original size after animationFinished
                    }];
                }];
            }];
        }
    }
}


#define MOVE_DURATION 3.0

- (IBAction)Tap:(UITapGestureRecognizer *)sender
{
    CGPoint tapLocation = [sender locationInView:self.bookshelf];
    for (UIView *view in self.bookshelf.subviews) {
        if (CGRectContainsPoint(view.frame, tapLocation)) {
            [UIView animateWithDuration:MOVE_DURATION delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setRandomLocationForView:view];
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99);
            } completion:^(BOOL finished) {
                if (finished) view.transform = CGAffineTransformIdentity;
            }];
        }
    }
}
/*
#define WHITE_BOOK @"OperatingSystem"
#define YELLOW_BOOK @"Algorithm"
#define RED_BOOK @"ComputerArchitecture"
#define BLUE_BOOK @"ObjectOrientedDesign"
#define ORANGE_BOOK @"IOSDevelopment"
#define BROWN_BOOK @"VideoAndImageProcessing"
#define PURPLE_BOOK @"JavaProgramming"*/  //hardcoding bookInformation

-(void)addBook:(NSString *)book
{
    UILabel *bookLabel = [[UILabel alloc]init];
/*
    static NSDictionary *books = nil;
    if(!books) books = @{ WHITE_BOOK :[UIColor whiteColor],
                          YELLOW_BOOK :[UIColor yellowColor],
                          RED_BOOK :[UIColor redColor],
                          BLUE_BOOK :[UIColor blueColor],
                          ORANGE_BOOK :[UIColor orangeColor],
                          BROWN_BOOK :[UIColor brownColor],
                          PURPLE_BOOK :[UIColor purpleColor]};
    if(![book length]){
        book = [[books allKeys] objectAtIndex:arc4random()%[books count]];
        bookLabel.textColor = [books objectForKey:book];
    }*/
    
    bookLabel.text = book;
    bookLabel.font = [UIFont systemFontOfSize:46];
    bookLabel.backgroundColor = [UIColor clearColor];
    [self setRandomLocationForView:bookLabel];
    [self.bookshelf addSubview:bookLabel];
    [self drain];

    bookLabel.text = book;
    bookLabel.textColor = [UIColor whiteColor];
    bookLabel.font = [UIFont systemFontOfSize:46];
    bookLabel.backgroundColor = [UIColor clearColor];
    [self setRandomLocationForView:bookLabel];
    [self.bookshelf addSubview:bookLabel];
}

-(void)setRandomLocationForView:(UIView *)view
{
    [view sizeToFit];
    CGRect bookshelfBounds = CGRectInset(self.bookshelf.bounds, view.frame.size.width/2, view.frame.size.height/2);
    CGFloat x = arc4random() % (int)bookshelfBounds.size.width + view.frame.size.width/2;
    CGFloat y = arc4random() % (int)bookshelfBounds.size.height + view.frame.size.height/2;
    view.center = CGPointMake(x, y);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Ask"]){
        AskerViewController *asker = segue.destinationViewController;
        asker.question = @"Which book you want to add in bookshelf ?";
    }
}

-(IBAction)cancelAsking:(UIStoryboardSegue *)segue
{
}

-(IBAction)doneAsking:(UIStoryboardSegue *)segue
{
    AskerViewController *asker = segue.sourceViewController;
    [self addBook:asker.answer];
}
@end
