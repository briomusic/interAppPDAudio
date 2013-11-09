//
//  ViewController.h
//  interAppPDAudio
//
//  Created by Brio on 09/11/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdDispatcher.h"

@interface ViewController : UIViewController <PdListener> {
    PdDispatcher *dispatcher;
    void *patch;
}


@end
