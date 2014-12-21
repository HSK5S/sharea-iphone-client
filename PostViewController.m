//
//  ViewController.m
//  HSK5Spost
//
//  Created by yukihara on 2013/09/12.
//  Copyright (c) 2013年 edu.self. All rights reserved.
//

#import "PostViewController.h"
#import "SIAlertView.h"


@interface PostViewController ()

@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    // 入力文字数カウント用ラベル
    CGRect rect = CGRectMake(75, 0, 170, 45);
    inputCountLabel = [[UILabel alloc] initWithFrame:rect];
    inputCountLabel.font = [UIFont boldSystemFontOfSize:17];
    inputCountLabel.numberOfLines = 1;
    inputCountLabel.textAlignment = NSTextAlignmentCenter;
    inputCountLabel.textColor = [UIColor whiteColor];
    inputCountLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    inputCountLabel.text = @"99";
    [self.view addSubview:inputCountLabel];
    
    // 戻るボタン
    UIButton *returnbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    returnbtn.frame = CGRectMake(10, 10, 50, 30);
    [returnbtn setTitle:@"" forState:UIControlStateNormal];
    [returnbtn addTarget:self action:@selector(returnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:returnbtn];
    
    // 投稿テキスト入力フィールド
    rect = CGRectMake(10, 60, 300, 170);
    inputTextView = [[UITextView alloc] initWithFrame:rect];
    inputTextView.font = [UIFont fontWithName:@"Helvetica" size:14];
    inputTextView.keyboardType = UIKeyboardTypeDefault;
    inputTextView.returnKeyType = UIReturnKeyDefault;
    inputTextView.delegate = self;
    [self.view addSubview:inputTextView];
    
    if([inputTextView canBecomeFirstResponder]){
        [inputTextView becomeFirstResponder];
    }
    
    // 投稿ボタン
    submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    submitBtn.frame = CGRectMake(270, 10, 50, 30);
    [submitBtn setTitle:@"" forState:UIControlStateNormal];
    [submitBtn addTarget:self action:@selector(postAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitBtn];
    
}

// テキスト文字数制限
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    int maxInputLength = 99;
    
    // 入力済みのテキストを取得
    NSMutableString *str = [textView.text mutableCopy];
    int count = maxInputLength - ((str.length - range.length) + text.length); // 重要
    if(count < 0){ count=0; }
    inputCountLabel.text = [NSString stringWithFormat:@"%d",count];
    
    // 入力済みのテキストと入力が行われたテキストを結合
    [str replaceCharactersInRange:range withString:text];
    
    if ([str length] > maxInputLength) {
        return NO;
    }
    
    return YES;
}

// 戻るボタン押す
- (void)returnAction
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// 投稿ボタン押す
- (void)postAction
{
    // アニメーション
    NSString *message = inputTextView.text;
    // 入力の最後の文字〜末尾までの余計な改行は消す
    int i;
    for(i=[message length]-1; i>=0; i--){
        if(!([message characterAtIndex:i] == '\n')){
            break;
        }
    }
    message = [message substringToIndex:i+1];
    if([message length] > 0){
        submitBtn.enabled = NO;
        [UIView animateWithDuration:1.0f
                              delay:0.1f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             //                             inputTextView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                             [inputTextView setFrame:CGRectMake(110,-100,100,85)];
                             [inputTextView setAlpha:0.0];
                         } completion:^(BOOL finished) {
                             [self dismissViewControllerAnimated:YES completion:NULL];
                             // POST通信リクエスト
                             NSURL* url = [NSURL URLWithString:@"http://210.149.64.198/post.php"];
                             NSMutableURLRequest* request = [[NSMutableURLRequest alloc]initWithURL:url];
                             [request setHTTPMethod:@"POST"];
                             
                             // 送信するもの
                             NSString *escapedMessage = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                                              kCFAllocatorDefault,
                                                                                                                              (CFStringRef)message,
                                                                                                                              NULL,
                                                                                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                                              kCFStringEncodingUTF8));
                             
                             NSDate *date = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone] secondsFromGMT]];
                             NSString* body = [NSString stringWithFormat:@"message=%@&lat=%F&lng=%F&date=%@", escapedMessage, _latitude, _longitude, date];
                             
                             [request setHTTPBody: [body dataUsingEncoding:NSUTF8StringEncoding]];
                             
                             NSNotification *n = [NSNotification notificationWithName:@"ActivityIndicator" object:self userInfo:@{@"action":@"START"}];
                             [[NSNotificationCenter defaultCenter] postNotification:n];
                             
                             [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *result, NSError *error) {
                                 
                                 // 通信失敗した場合
                                 if(error){
                                     SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"投稿エラー" andMessage:@"サーバーとの通信に失敗しました"];
                                     [alertView addButtonWithTitle:@"OK"
                                                              type:SIAlertViewButtonTypeDestructive
                                                           handler:nil];
                                     [alertView show];
                                 }
                                 
                                 
                                 NSDictionary *statusDic = [[NSDictionary alloc] init];
                                 
                                 NSString* resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                 if ([resultString isEqualToString:@"Success."]) {
                                     // 成功通知
                                     statusDic = @{@"status":@"SUCCESS", @"message":@"投稿しました"};
                                     NSNotification *n = [NSNotification notificationWithName:@"Post" object:self userInfo:statusDic];
                                     [[NSNotificationCenter defaultCenter] postNotification:n];
                                 } else {
                                     // 失敗通知
                                     statusDic = @{@"status":@"FAILD", @"message":@"投稿に失敗しました"};
                                     NSNotification *n = [NSNotification notificationWithName:@"Post" object:self userInfo:statusDic];
                                     [[NSNotificationCenter defaultCenter] postNotification:n];
                                 }
                                 NSNotification *n = [NSNotification notificationWithName:@"ActivityIndicator" object:self userInfo:@{@"action":@"STOP"}];
                                 [[NSNotificationCenter defaultCenter] postNotification:n];
                             }];
                         }];
        
    } else {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:nil andMessage:@"メッセージは1文字以上\n99文字以下で入力して下さい"];
        [alertView addButtonWithTitle:@"確認"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:nil];
        [alertView show];
    }
}

// ボタンを押したらキーボードを閉じる
-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
