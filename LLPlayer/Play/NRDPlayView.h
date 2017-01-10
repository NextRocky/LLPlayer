//
//  NRDPlayView.h
//  NRDPlay
//
//  Created by 罗李 on 16/10/26.
//  Copyright © 2016年 罗李. All rights reserved.
//

#import <UIKit/UIKit.h>

//  //@"http://101.44.1.121/mp4files/310000000356077D/clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";(可用webURL)
//  适配比例  self.view.frame.size.width / 16 * 9  + 40
@interface NRDPlayView : UIView

+ (instancetype)sharedPlayer;

- (void)playerMovieWithURL:(NSURL *)url;
@end
