//
//  getViewController.m
//  get
//
//  Created by takuti on 9/12/13.
//  Copyright (c) 2013 takuti. All rights reserved.
//

#import "getViewController.h"
#import "PostViewController.h"
#import "PostCell.h"
#import "GTMNSString+HTML.h"
#import "SIAlertView.h"
#import "Toast+UIView.h"

@interface getViewController ()
{
    NSMutableArray *_posts;
    NSTimer *_timer;
    NSString *_area;
    double _lat;
    double _latTmp;
    double _lng;
    double _lngTmp;
    int _id;
    BOOL _isShowingActivity;
    BOOL _isLocationServiceAvailable;
    
    // 更新中を表示するViwe
	EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL _reloading;
    
//    UIColor *_cellFrameColor;
}
@end

@implementation getViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // テーブルビューの位置変更と、カスタムセルの設定
    _postTableView.frame = CGRectMake(0, 48, 320, self.view.bounds.size.height-44);
    [self.postTableView registerNib:[UINib nibWithNibName:@"PostCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    // プルリフレッシュの準備
    if (_refreshHeaderView == nil) {
		EGORefreshTableHeaderView *view =
        [[EGORefreshTableHeaderView alloc] initWithFrame:
         CGRectMake(
                    0.0f,
                    0.0f - self.postTableView.bounds.size.height,
                    self.view.frame.size.width,
                    self.postTableView.bounds.size.height
                    )];
		view.delegate = self;
		[self.postTableView addSubview:view];
		_refreshHeaderView = view;
	}
    // 最終更新日付を記録
	[_refreshHeaderView refreshLastUpdatedDate];
    
    _area = nil;
    // ヘッダーに現在のエリアを表示する
    CGRect rect = CGRectMake(75, 0, 170, 45);
    areaLabel = [[UILabel alloc] initWithFrame:rect];
    areaLabel.font = [UIFont boldSystemFontOfSize:17];
    areaLabel.numberOfLines = 1;
    areaLabel.textAlignment = NSTextAlignmentCenter;
    areaLabel.textColor = [UIColor whiteColor];
    areaLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    areaLabel.text = _area;
    [self.view addSubview:areaLabel];
    
    _id = -1;
    
    _posts = [[NSMutableArray alloc] init];
    
    // デフォルトの通知センターを取得する
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(controlActivityIndicator:) name:@"ActivityIndicator" object:nil];
    [nc addObserver:self selector:@selector(completePost:) name:@"Post" object:nil];
    
    [self startLocationService];
}

// アクティビティインジケータ管理用通知センターのセレクタ
-(void) controlActivityIndicator:(NSNotification *)notification
{
    NSString *action = [[notification userInfo] objectForKey:@"action"];
    
    if([action isEqualToString:@"START"]){
        [self.view makeToastActivity];
        _isShowingActivity = YES;
    } else {
        [self.view hideToastActivity];
        _isShowingActivity = NO;
    }
}

// 投稿画面で投稿ボタンを押した時に通知を受け取る
-(void) completePost:(NSNotification *)notification
{
    NSString *status = [[notification userInfo] objectForKey:@"status"];
    NSString *message = [[notification userInfo] objectForKey:@"message"];
    
    if([status isEqualToString:@"SUCCESS"]){
        [self.view makeToast:message duration:2.0f position:@"bottom"];
        [self getPosts];
    }
    else if([status isEqualToString:@"FAILD"]){
        [self.view makeToast:message duration:2.0f position:@"center"];
    }
}


// 更新処理
- (void)getPosts
{
    [self.view makeToastActivity];
    _isShowingActivity = YES;
    self.getLocationButton.enabled = NO;
    
    NSDateComponents *dateCmp = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    if(dateCmp.hour >= 5 && dateCmp.hour <= 11){
        self.headerImage.image = [UIImage imageNamed:@"header_green@2x.png"];
    } else if(dateCmp.hour >= 12 && dateCmp.hour <= 16){
        self.headerImage.image = [UIImage imageNamed:@"header_yellow@2x.png"];
    } else if(dateCmp.hour >= 17 && dateCmp.hour <= 19){
        self.headerImage.image = [UIImage imageNamed:@"header_blue@2x.png"];
    } else {
        self.headerImage.image = [UIImage imageNamed:@"header_red@2x.png"];
    }
    
    NSString *url = [NSString stringWithFormat:@"http://210.149.64.198/return_json.php?lat=%f&lng=%f&id=%d",_lat,_lng,_id];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        // 通信失敗した場合
        if(error){
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"エラー" andMessage:@"サーバーとの通信に失敗しました"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:nil];
            [alertView show];
        }
        
        // 返ってくるJSONは表示すべき投稿たちの名前と本文、そのエリア
        NSData *json_data = data;
        
        NSError *get_error = nil;
        NSDictionary *json_dict = [NSJSONSerialization JSONObjectWithData:json_data options:NSJSONReadingAllowFragments error:&get_error];
        if(get_error){
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"エラー" andMessage:@"投稿の取得に失敗しました"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:nil];
            [alertView show];
        }
        
        
        if((_area != nil) && ![_area isEqualToString:json_dict[@"area"]]){
            NSString *alertMessage = [NSString stringWithFormat:@"エリアが%@から%@へ移りました。", _area, json_dict[@"area"]];
            SIAlertView *areaAlert = [[SIAlertView alloc] initWithTitle:@"エリア変更通知" andMessage:alertMessage];
            [areaAlert addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:^(SIAlertView *alert) {
                                      [_posts removeAllObjects];
                                      _id = -1;
                                      
                                      [self getPosts];
                                  }];
            [areaAlert show];
        }
        
        _area = json_dict[@"area"];
        areaLabel.text = _area;
        
        if([json_dict[@"post"] count]!=0){
            for(NSDictionary *obj in json_dict[@"post"]){
                NSDictionary *dic = @{@"name":obj[@"name"], @"message":obj[@"message"], @"date":obj[@"date"]};
                [_posts insertObject:dic atIndex:0];
                _id = [obj[@"id"] integerValue];
            }
            
            // 50件以上はとらない
            if([_posts count] > 50){
                [_posts removeObjectsInRange:NSMakeRange(50, [_posts count]-50)];
            }
            [self.postTableView reloadData];
        }
        
        self.getLocationButton.enabled = YES;
        _isShowingActivity = NO;
        [self.view hideToastActivity];
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.nameLabel.text = [NSString stringWithFormat:@"%@",[[[_posts objectAtIndex:indexPath.row] objectForKey:@"name"] gtm_stringByUnescapingFromHTML]];
    
    NSMutableString *message = [[NSMutableString alloc]initWithString:[[[_posts objectAtIndex:indexPath.row] objectForKey:@"message"] gtm_stringByUnescapingFromHTML]];
    int i;
    for(i=0; i<[message length]; i++){
        if([message characterAtIndex:i] == '\n'){
            [message replaceCharactersInRange:NSMakeRange(i, 1) withString:@" "];
        }
    }
    
    cell.messageLabel.text = [NSString stringWithFormat:@"%@",message];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d HH:mm:ss"]; //2012-04-14 00:00:01
    NSDate *postDate = [formatter dateFromString:[[_posts objectAtIndex:indexPath.row] objectForKey:@"date"]];
    
	[formatter setDateFormat:@"MM/dd HH:mm"];
    cell.postDateLabel.text = [formatter stringFromDate:postDate];
    
    CALayer *leftBorder = [CALayer layer];
    leftBorder.borderColor = [UIColor lightGrayColor].CGColor;
//    leftBorder.borderColor = _cellFrameColor.CGColor;
    leftBorder.borderWidth = 2;
    leftBorder.frame = CGRectMake(0, 0, 2, cell.frame.size.height);
    [cell.layer addSublayer:leftBorder];
    
    CALayer *rightBorder = [CALayer layer];
    rightBorder.borderColor = [UIColor lightGrayColor].CGColor;
//    rightBorder.borderColor = _cellFrameColor.CGColor;
    rightBorder.borderWidth = 2;
    rightBorder.frame = CGRectMake(cell.frame.size.width-2, 0, 2, cell.frame.size.height);
    [cell.layer addSublayer:rightBorder];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.borderColor = [UIColor lightGrayColor].CGColor;
    topBorder.borderWidth = 2;
    topBorder.frame = CGRectMake(0, 0, cell.frame.size.width, 2);
    [cell.layer addSublayer:topBorder];
    
    [cell.messageLabel sizeToFit];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [NSString stringWithFormat:@"%@",[[_posts objectAtIndex:indexPath.row] objectForKey:@"name"]];
    
    NSMutableString *message = [[NSMutableString alloc]initWithString:[[[_posts objectAtIndex:indexPath.row] objectForKey:@"message"] gtm_stringByUnescapingFromHTML]];
    int i;
    for(i=0; i<[message length]; i++){
        if([message characterAtIndex:i] == '\n'){
            [message replaceCharactersInRange:NSMakeRange(i, 1) withString:@" "];
        }
    }
    
    CGSize nameSize = [name sizeWithFont:[UIFont systemFontOfSize:11]
                             constrainedToSize:CGSizeMake(280, 5000)
                                 lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize messageSize = [message sizeWithFont:[UIFont systemFontOfSize:15.0]
                             constrainedToSize:CGSizeMake(280, 5000)
                                 lineBreakMode:NSLineBreakByWordWrapping];
     
    CGFloat cellHeight = messageSize.height + nameSize.height + 45;
    
     
    return cellHeight;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier] isEqualToString:@"showPostView"]){
        [[segue destinationViewController] setLatitude:_lat];
        [[segue destinationViewController] setLongitude:_lng];
    }
}

// スクロールされたことをライブラリに伝える
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    if([_refreshHeaderView getState]==0 || [_refreshHeaderView getState]==2){
        self.getLocationButton.enabled = NO;
    } else {
        self.getLocationButton.enabled = YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}
// テーブルを下に引っ張ったら、ここが呼ばれる。テーブルデータをリロードして3秒後にdoneLoadingTableViewDataを呼んでいる
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
//	_reloading = YES;
    // 非同期処理
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        if(!_isShowingActivity){ // アクティビティインジケータ回転中は更新処理を無効化する
            self.getLocationButton.enabled = NO;
            // 更新処理など重い処理を書く
            // 今回は3秒待つ
            [NSThread sleepForTimeInterval:2];
            [self getPosts];
            self.getLocationButton.enabled = YES;
        }
        // メインスレッドで更新完了処理
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self doneLoadingTableViewData];
        }];
    }];
}

// 更新終了
- (void)doneLoadingTableViewData{
	// 更新終了をライブラリに通知
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.postTableView];
}
// 更新状態を返す
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return _reloading;
}
// 最終更新日を更新する際の日付の設定
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date];
}


// 位置情報更新ボタンを押した時
- (IBAction)changeLocation:(id)sender
{
    SIAlertView *alertView;
    if(_isLocationServiceAvailable) {
        alertView = [[SIAlertView alloc] initWithTitle:@"位置情報の更新" andMessage:@"現在位置を読み込みます"];
        [alertView addButtonWithTitle:@"キャンセル"
                             type:SIAlertViewButtonTypeCancel
                          handler:nil];
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:^(SIAlertView *alert) {
                                  
                                  _lat = _latTmp;
                                  _lng = _lngTmp;
                              
                                  // sample lat,lng
//                                  _lat = 35.674624;
//                                  _lng = 139.735785;
                              
                              
                                  [_posts removeAllObjects];
                                  _id = -1;
                              
                                  [self getPosts];
                              
                                  [self.view makeToast:@"現在位置を再取得しました" duration:2.0f position:@"bottom"];
                                  
                                  
                              }];
    } else if(!_isLocationServiceAvailable) {
        alertView = [[SIAlertView alloc] initWithTitle:@"エラー" andMessage:@"位置情報の設定を確認して下さい"];
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:nil];
    }
    [alertView show];
}

- (void)startLocationService
{
    // 現在地取得の準備
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    [_locationManager startUpdatingLocation]; // 位置情報サービスの開始
}

- (void)stopLocationService
{
    // 位置情報サービスを停止する
    _lat = 0;
    _lng = 0;
    _latTmp = 0;
    _lngTmp = 0;
    [_locationManager stopUpdatingLocation];
    _locationManager.delegate = nil;
    _locationManager = nil;
}

//　位置情報取得成功時
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // 初回は自動で現在位置から投稿を取得したいので
    if(_lat==0 && _lng==0 ){
        _lng = newLocation.coordinate.longitude;
        _lat = newLocation.coordinate.latitude;
        
        // sample lat,lng
//        _lat = 35.6641222;
//        _lng = 139.729426;
        
        [self getPosts];
    } else {
        _lngTmp = newLocation.coordinate.longitude;
        _latTmp = newLocation.coordinate.latitude;
    }
}

// 位置情報取得失敗時
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    /*
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"エラー" andMessage:@"位置情報の取得に失敗しました"];
    [alertView addButtonWithTitle:@"OK"
                                type:SIAlertViewButtonTypeDestructive
                            handler:nil];
    [alertView show];
     */
}

// 位置情報サービスの設定が変更された場合にこのデリゲートメソッドが呼ばれる
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusRestricted: // 設定 > 一般 > 機能制限で利用が制限されている
        case kCLAuthorizationStatusDenied: // ユーザーがこのアプリでの位置情報サービスへのアクセスを許可していない
        {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"エラー" andMessage:@"位置情報の設定を確認して下さい\nとりあえず海へ行きます"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:^(SIAlertView *alert) {
                                      _lat = 0;
                                      _lng = 0;
                                      _latTmp = 0;
                                      _lngTmp = 0;
                                      [self getPosts];
                                  }];
            [alertView show];
            _isLocationServiceAvailable = NO;
        }
            break;
            
        default:
        {
            _isLocationServiceAvailable = YES;
        }
            break;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
