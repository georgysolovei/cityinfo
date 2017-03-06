//
//  ViewController.h
//  cityinfo
//
//  Created by Georgy Solovei on 3/1/17.
//  Copyright © 2017 Georgy Solovei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    UITableView *citiesTableView;
    UITextView  *descriptionTextView;
    UITextView  *weatherTextView;
}

@property (nonatomic, strong) NSMutableArray *citiesWeather;
@property (nonatomic, strong) NSDate *lastRequestTime;

@end

