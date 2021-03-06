//
//  PSCImageOverlayPDFViewController.m
//  PSPDFCatalog
//
//  Copyright (c) 2013 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY AUSTRIAN COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "PSCImageOverlayPDFViewController.h"

@interface PSCAutoResizeButton : UIButton <PSPDFAnnotationViewProtocol>

@property (nonatomic, assign) CGRect targetPDFRect;
@property (nonatomic, strong) PSPDFImageInfo *imageInfo;

@end


@implementation PSCImageOverlayPDFViewController

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFViewController

- (void)commonInitWithDocument:(PSPDFDocument *)document {
    [super commonInitWithDocument:document];
    self.pageTransition = PSPDFPageCurlTransition;
    self.delegate = self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewController:(PSPDFViewController *)pdfController didLoadPageView:(PSPDFPageView *)pageView {
    // Iterate over all images and add button overlays on top.
    // Accessing the text parser will block the thread, so it'll be better to access the in a background thread and than use the result on the main thread (but then you'll have to check if the pageView still points at the same page which would add too much complexity for this simple example.)
    for (PSPDFImageInfo *imageInfo in [pageView.document textParserForPage:pageView.page].images) {
        // Create the view
        PSCAutoResizeButton *resizeButton = [PSCAutoResizeButton new];
        resizeButton.targetPDFRect = [imageInfo boundingBox];
        resizeButton.imageInfo = imageInfo;
        resizeButton.showsTouchWhenHighlighted = YES;
        resizeButton.layer.borderColor = [UIColor redColor].CGColor;
        resizeButton.layer.borderWidth = 2.f;
        resizeButton.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.2f];
        [resizeButton addTarget:self action:@selector(imageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // Add to container view. Only here views will get notified on changes via PSPDFAnnotationViewProtocol.
        // The container view will be purged when the page is prepared for reusage.
        [pageView.annotationContainerView addSubview:resizeButton];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)imageButtonPressed:(PSCAutoResizeButton *)button {
    PSPDFAssert([button isKindOfClass:PSCAutoResizeButton.class]);

    PSPDFImageInfo *imageInfo = button.imageInfo;
    UIImage *image = [imageInfo imageWithError:NULL];
    
    // Show view controller
    if (image) {
        UIViewController *imagePreviewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        imagePreviewController.title = imageInfo.imageID;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imagePreviewController.view = imageView;
        [self presentViewControllerModalOrPopover:imagePreviewController embeddedInNavigationController:YES withCloseButton:YES animated:YES sender:button options:@{PSPDFPresentOptionAlwaysModal : @YES, PSPDFPresentOptionModalPresentationStyle : @(UIModalPresentationFormSheet)}];
    }
}

@end

@implementation PSCAutoResizeButton

// Will resize the view anytime the parent changes.
- (void)didChangePageFrame:(CGRect)frame {
    PSPDFPageView *pageView = (PSPDFPageView *)self.superview.superview;
    self.frame = [pageView convertPDFRectToViewRect:self.targetPDFRect];
}

@end
