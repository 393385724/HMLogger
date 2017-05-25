# DDLogger
a log redirect to file ，采用<a href="https://github.com/CocoaLumberjack/CocoaLumberjack">CocoaLumberjack</a>与<a href="https://github.com/Tencent/mars">Xlog</a>的简单封装，在这里感谢两个开源框架

工程中有解码脚本使用方法如下：
python  脚本路径/decode_mars_log_file.py 日志路径/日志名字.xlog

将NSLog替换为DDLog或者重新定义NSLog参见DDLog的定义可以在release模式下重向log到预先定义的日志目录
使用方法：
前提使用的cocopods
pod 'HMLogger', '~> 2.0.1'

##开始收集log
>- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                           encrypt:(BOOL)encrypt;
>
> >@code
> >
> >- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
> >
> >    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
> >    NSString *docDir = [paths objectAtIndex:0];
> >    [[HMLogger Logger] startLogWithCacheDirectory:docDir nameprefix:@"hm" encrypt:NO];
> >
> >    return YES;
> >
> >}
> >
> >@endcode
> >

##当前是否显示logView
>- (BOOL)isShowLogView;

## 显示logView
>- (void)showLogView;

##隐藏logView
>- (void)hidenLogView;


##查看本地存在的log日志
>
>  @param viewController 当前的Viewontroller
>
>  @param handler        选取回调结果
>
>- (void)pikerLogWithViewController:(UIViewController *)viewController eventHandler:(DDPikerLogEventHandler)handler;
