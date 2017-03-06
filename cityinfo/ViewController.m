//
//  ViewController.m
//  cityinfo
//
//  Created by Georgy Solovei on 3/1/17.
//  Copyright © 2017 Georgy Solovei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray     *citiesInfo;
@property (nonatomic, strong) NSMutableArray     *weatherURLs;
@property (nonatomic, strong) NSLayoutConstraint *smallConstraint;
@property (nonatomic, strong) NSLayoutConstraint *largeConstraint;

@end


@implementation ViewController

// designated initializer
//------------------------------------------------------------------------------------------------------------------------------------------
- (instancetype)init {
    if (!self) {
        self = [super init];
    }
    return self;
}

// user interface setup
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    citiesTableView     = [UITableView new];
    descriptionTextView = [UITextView  new];
    weatherTextView     = [UITextView  new];
    
    [self.view addSubview:citiesTableView];
    [self.view addSubview:descriptionTextView];
    [self.view addSubview:weatherTextView];
    
    weatherTextView.backgroundColor = [UIColor lightGrayColor];
    
    // implement autolayout
    [self setUpConstraints];
    
    citiesTableView.delegate   = self;
    citiesTableView.dataSource = self;

    // adjust weather label
    weatherTextView.editable = NO;
    weatherTextView.userInteractionEnabled = NO;
    
    // adjust description text view
    descriptionTextView.editable = NO;
    descriptionTextView.scrollEnabled = NO;
    descriptionTextView.userInteractionEnabled = YES;
    descriptionTextView.textAlignment = NSTextAlignmentJustified;
    const CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UIBezierPath *weatherTextViewPath = [UIBezierPath bezierPathWithRect:CGRectMake(weatherTextView.frame.origin.x,   weatherTextView.frame.origin.y - statusBarHeight,
                                                                                    weatherTextView.frame.size.width, weatherTextView.frame.size.height - statusBarHeight/2)];
    descriptionTextView.textContainer.exclusionPaths = @[weatherTextViewPath];   // embed weatherTextView in descriptionTextView for proper text layout

    // attach gesture recognizer to the text views
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSingleTap:)];
    [descriptionTextView addGestureRecognizer:singleFingerTap];
    
    // first default programmatic 'tap' on the first row of the table
    [citiesTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                 animated:NO
                           scrollPosition:UITableViewScrollPositionNone];
    
    // fill descriptionTextView and weatherTextView
    NSString *textForDescription = [self.citiesInfo[[NSIndexPath indexPathForRow:0 inSection:0].row] objectForKey:@"description"];
    descriptionTextView.text = textForDescription;
    [self requestServerForWeather];
    [self reloadweatherTextView];
}

// gesture handling method
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    
    [UIView animateWithDuration:0.5
                     animations: ^{
                         // turn on/off constraints to animate descriptionTextView size change
                         if (descriptionTextView.frame.size.height > self.view.frame.size.height / 2) {
                             self.largeConstraint.active = NO;
                             self.smallConstraint.active = YES;
                         }
                         else {
                             self.smallConstraint.active = NO;
                             self.largeConstraint.active = YES;
                         }
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                     }];
}

// implement autolayout
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)setUpConstraints {
    
    const CGFloat statusBarHeight        = [UIApplication sharedApplication].statusBarFrame.size.height;
    const CGFloat mainViewHeight         = self.view.frame.size.height - statusBarHeight;
    const CGFloat descriptionHeight      = mainViewHeight / 3;
    const CGFloat largeDescriptionHeight = mainViewHeight * 0.6;
    const CGFloat weatherTextViewWidth   = 110;
    const CGFloat weatherTextViewHeight  = 150;
    
    for (id view in @[descriptionTextView, citiesTableView, weatherTextView] ) {
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    // consrtaints for descriptionTextView
    [descriptionTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [descriptionTextView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor].active  = YES;
    [descriptionTextView.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:statusBarHeight].active = YES;

    self.smallConstraint = [descriptionTextView.heightAnchor constraintEqualToConstant:descriptionHeight];
    self.largeConstraint = [descriptionTextView.heightAnchor constraintEqualToConstant:largeDescriptionHeight];
    self.smallConstraint.active = YES;

    // consrtaints for citiesTableView
    [citiesTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [citiesTableView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor].active  = YES;
    [citiesTableView.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor].active   = YES;
    [citiesTableView.topAnchor      constraintLessThanOrEqualToAnchor:descriptionTextView.bottomAnchor].active = YES;
  
    [weatherTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // consrtaints for weatherTextView
    [weatherTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [weatherTextView.topAnchor      constraintEqualToAnchor:descriptionTextView.topAnchor].active = YES;
    [weatherTextView.heightAnchor   constraintGreaterThanOrEqualToConstant:weatherTextViewWidth].active  = YES;
    [weatherTextView.widthAnchor    constraintGreaterThanOrEqualToConstant:weatherTextViewHeight].active = YES;

    [self.view layoutIfNeeded];
}

// fetching weather data from api.openweathermap.org
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)requestServerForWeather {
    
    // asynchronously request the server and process the received weather data
    for (NSURL *weatherURL in self.weatherURLs) {

        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:weatherURL
                                                             completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      if (data) {
                                          [self.citiesWeather replaceObjectAtIndex:[self.weatherURLs indexOfObject:weatherURL]
                                                                        withObject:[NSJSONSerialization JSONObjectWithData:data
                                                                                                                   options:kNilOptions
                                                                                                                     error:&error]];
                                          // when finished reload weather label
                                            if ([self.weatherURLs indexOfObject:weatherURL] == (self.weatherURLs.count - 1)) {
                                             
                                                // UI stuff is always performed on the main thread
                                                dispatch_async (dispatch_get_main_queue(), ^{
                                                    
                                                    [self reloadweatherTextView];  // refresh weatherTextView with new data
                                                    self.lastRequestTime = nil;
                                                    self.lastRequestTime = [NSDate date];
                                                });
                                            }
                                      }
                                      else {
                                          NSLog(@"Failed to fetch %@: %@", weatherURL, error);
                                      }
                                  }];
        [task resume];
    }
}

// actions when a row is selected
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)reloadweatherTextView {
   
    const float absoluteZero = -273.15;
    
    NSInteger rowSelected = citiesTableView.indexPathForSelectedRow.row;
    
    // values to display in weatherTextView
    NSString *temperature   = [self.citiesWeather[rowSelected] valueForKeyPath:@"main.temp"];
    NSString *maxTemp       = [self.citiesWeather[rowSelected] valueForKeyPath:@"main.temp_max"];
    NSString *minTemp       = [self.citiesWeather[rowSelected] valueForKeyPath:@"main.temp_min"];
    NSString *humidity      = [self.citiesWeather[rowSelected] valueForKeyPath:@"main.humidity"];
    NSString *windDirection = [self windDirectionFromDegrees:[[self.citiesWeather[rowSelected] valueForKeyPath:@"wind.deg"] floatValue]];
    NSNumber *windSpeed     = [NSNumber numberWithInt:(int)roundf([[self.citiesWeather[rowSelected] valueForKeyPath:@"wind.speed"] floatValue])];
    NSString *sky           = [[[[self.citiesWeather[rowSelected] valueForKey:@"weather"] allObjects] objectAtIndex:0] valueForKey:@"description"];
    
    NSMutableArray *temperatureArray = [NSMutableArray arrayWithArray:@[temperature, maxTemp, minTemp]];

    if (![temperature isKindOfClass:[NSString class]]) {
        // converting Kelvin temperature to Celsius
        for (int i = 0; i < temperatureArray.count; i++) {
            int temp = (int)roundf([temperatureArray[i] floatValue] + absoluteZero);
            [temperatureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:temp]];
        }
    }
    
    // full string to display in weatherTextView
    NSMutableAttributedString *textForweatherTextView = [[NSMutableAttributedString alloc] initWithString:
                                                         [NSString stringWithFormat:@"   %@%@   \n%@%@ / %@%@\n%@\nhumidity: %@ %%\n      wind: %@ m/s %@ ", temperatureArray[0],@"\u00B0", temperatureArray[1],@"\u00B0", temperatureArray[2], @"\u00B0", sky, humidity, windSpeed, windDirection]];
    
    // adding an attribute of bigger font size for the first string with the temperature
    [textForweatherTextView addAttribute:NSFontAttributeName
                                   value:[UIFont systemFontOfSize:35.0]
                                   range:NSMakeRange(0, 7)];

    weatherTextView.attributedText = textForweatherTextView;
}

// actions when a row is selected
//------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    const int oneHourInSeconds = 3600;
    
    // content for city's description
    NSString *textForDescription = [self.citiesInfo[indexPath.row] objectForKey:@"description"];
    descriptionTextView.text     = textForDescription;
    
    [self reloadweatherTextView];
    
    // request the server if one hour has passed
    if (-[self.lastRequestTime timeIntervalSinceNow] > oneHourInSeconds || !self.lastRequestTime) {
        [self requestServerForWeather];
    }
}

// number of rows in the table
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    NSInteger numberOfRows = self.citiesInfo.count;
    return numberOfRows;
}

// setting and populating cells with the content
//------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[UITableViewCell alloc] init];
    NSString *city        = [[self.citiesInfo objectAtIndex:indexPath.row] objectForKey:@"name"];
    NSString *countryCode = [[self.citiesInfo objectAtIndex:indexPath.row] objectForKey:@"countryCode"];
    cell.textLabel.text   = [NSString stringWithFormat:@"%@\t%@", countryCode, city];
    
    return cell;
}

// getter for @property citiesWeather
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSMutableArray *)citiesWeather {
    // default value for weather label fields in case of broken connection or absence of values
    NSString * const noDataValue = @"---";

    if (!_citiesWeather) {
        
        // check NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *locallyFetchedWeatherArray = [defaults objectForKey:@"citiesWeather"];
        
        // if weather array was found in NSUserDefaults, initialize @property citiesWeather with it
        if (locallyFetchedWeatherArray) {
            _citiesWeather = [NSMutableArray arrayWithArray:locallyFetchedWeatherArray];
        }
        // or create from scratch and populate with default values
        else {
            _citiesWeather = [NSMutableArray new];
            for (int i = 0; i < self.citiesInfo.count; i++) {
                NSDictionary *city = @{@"main"    : @{@"temp"     : noDataValue,
                                                      @"temp_max" : noDataValue,
                                                      @"temp_min" : noDataValue,
                                                      @"humidity" : noDataValue},
                                       @"wind"    : @{@"deg"      : noDataValue,
                                                      @"speed"    : noDataValue},
                                       @"weather" : @{@"main"     : noDataValue} };
                [_citiesWeather addObject:city];
            }
        }
    }
    return _citiesWeather;
}

//  conversion of wind direction degrees to cardinal directions
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)windDirectionFromDegrees:(float)degrees {
    
    static NSArray *directions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      
        // initialize array on first call
        directions = @[@"N", @"NNE", @"NE", @"ENE", @"E", @"ESE", @"SE", @"SSE", @"S", @"SSW", @"SW", @"WSW", @"W", @"WNW", @"NW", @"NNW"];
    });
    
    int i = (degrees + 11.25)/22.5;
    return directions[i % 16];
}

// getter for @property citiesInfo
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSMutableArray *)citiesInfo {
    if (!_citiesInfo) {
        
        // parse local JSON containing cities' info
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cities"
                                                             ofType:@"json"
                                                        inDirectory:nil];
        
        NSData *localJSONfile = [NSData dataWithContentsOfFile:filePath];
        
        NSError *error;
        _citiesInfo = [NSJSONSerialization JSONObjectWithData:localJSONfile
                                                      options:kNilOptions
                                                        error:&error];
    }
    return _citiesInfo;
}

// getter for @property weatherURLs
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSMutableArray *)weatherURLs {
    if (!_weatherURLs) {
        
        // create array of cities' weather URLs
        _weatherURLs = [NSMutableArray new];
        for (NSDictionary *city in self.citiesInfo) {
            NSString * URLstring = [NSString stringWithFormat: @"http://api.openweathermap.org/data/2.5/weather?q=%@,%@&APPID=eba47effea88b18d5b67eae531209447",
                                    [city valueForKey: @"name"], [city valueForKey: @"countryCode"]];
            [_weatherURLs addObject:[NSURL URLWithString:URLstring]];
        }
    }
    return _weatherURLs;
}

// getter for @property lastRequestTime
//------------------------------------------------------------------------------------------------------------------------------------------
- (NSDate *) lastRequestTime {
    if (!_lastRequestTime) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSavedRequestTime = [defaults objectForKey:@"lastRequestTime"];
        if (lastSavedRequestTime) {
            _lastRequestTime = lastSavedRequestTime;
        }
        else {
            _lastRequestTime = [NSDate new];
        }
    }
    return _lastRequestTime;
}

@end
