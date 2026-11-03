#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//
// FilzaWallpaper — 给 Filza 文件列表加自定义背景图
//
// 壁纸放置路径：
//   /var/mobile/Documents/FilzaWallpaper.jpg      （浅色/默认）
//   /var/mobile/Documents/FilzaWallpaper_dark.jpg （深色模式，可选）
//
// 开关：
//   改文件名任意加/删 .dark 后缀来开关，或用 NSUserDefaults:
//   [FGCFUtilities setBool:YES forKey:@"FWEnabled"]
//

static NSString *const kWallpaperBase  = @"/var/mobile/Documents/FilzaWallpaper.jpg";
static NSString *const kWallpaperDark  = @"/var/mobile/Documents/FilzaWallpaper_dark.jpg";
static NSString *const kWallpaperBasePng  = @"/var/mobile/Documents/FilzaWallpaper.png";
static NSString *const kWallpaperDarkPng  = @"/var/mobile/Documents/FilzaWallpaper_dark.png";

static UIImageView *bgImageView = nil;
static BOOL fwEnabled = YES;

static UIImage *LoadWallpaper(BOOL isDark) {
    NSString *path;
    if (isDark) {
        path = [[NSFileManager defaultManager] fileExistsAtPath:kWallpaperDark] ? kWallpaperDark
             : ([[NSFileManager defaultManager] fileExistsAtPath:kWallpaperDarkPng] ? kWallpaperDarkPng : nil);
    } else {
        path = [[NSFileManager defaultManager] fileExistsAtPath:kWallpaperBase] ? kWallpaperBase
             : ([[NSFileManager defaultManager] fileExistsAtPath:kWallpaperBasePng] ? kWallpaperBasePng : nil);
    }
    if (!path) return nil;
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    return img;
}

static UIView *FindTableViewInView(UIView *view) {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:[UITableView class]] ||
            [sub isKindOfClass:[UICollectionView class]]) {
            return sub;
        }
    }
    // 递归找一层
    for (UIView *sub in view.subviews) {
        UIView *found = FindTableViewInView(sub);
        if (found) return found;
    }
    return nil;
}

static void SetupBackground(UIViewController *vc) {
    if (!fwEnabled) return;
    if (!vc || !vc.view) return;

    BOOL isDark = NO;
    Class themeMgr = NSClassFromString(@"ThemeManager");
    if (themeMgr) {
        id shared = [themeMgr performSelector:@selector(sharedInstance)];
        if ([shared respondsToSelector:@selector(isBlackTheme)]) {
            isDark = [[shared performSelector:@selector(isBlackTheme)] boolValue];
        }
    }

    UIImage *wallpaper = LoadWallpaper:isDark;
    if (!wallpaper) return;

    // 如果已经有 bgImageView 了，只换图
    if (bgImageView) {
        bgImageView.image = wallpaper;
        return;
    }

    bgImageView = [[UIImageView alloc] initWithImage:wallpaper];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    bgImageView.clipsToBounds = YES;
    bgImageView.tag = 98765;

    // 插到最底层
    [vc.view insertSubview:bgImageView atIndex:0];

    // AutoLayout 全屏
    bgImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [bgImageView.topAnchor constraintEqualToAnchor:vc.view.topAnchor],
        [bgImageView.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor],
        [bgImageView.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],
        [bgImageView.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor],
    ]];

    // 把 tableView / collectionView 背景设透明
    UIView *tableView = FindTableViewInView(vc.view);
    if (tableView) {
        tableView.backgroundColor = [UIColor clearColor];
        if ([tableView isKindOfClass:[UITableView class]]) {
            ((UITableView *)tableView).backgroundView = nil;
        }
    }
    vc.view.backgroundColor = [UIColor clearColor];
}

static void RefreshBackground(UIViewController *vc) {
    if (!bgImageView) { SetupBackground(vc); return; }
    BOOL isDark = NO;
    Class themeMgr = NSClassFromString(@"ThemeManager");
    if (themeMgr) {
        id shared = [themeMgr performSelector:@selector(sharedInstance)];
        if ([shared respondsToSelector:@selector(isBlackTheme)]) {
            isDark = [[shared performSelector:@selector(isBlackTheme)] boolValue];
        }
    }
    bgImageView.image = LoadWallpaper:isDark;
}

%hook ThemeManager

// 让主背景变透明，露出壁纸
- (UIColor *)background {
    if (!fwEnabled) return %orig;
    return [UIColor clearColor];
}

// 让 cell 背景也透明
- (UIColor *)selected {
    if (!fwEnabled) return %orig;
    UIColor *orig = %orig;
    return [orig colorWithAlphaComponent:0.85];
}

%new
- (void)fw_refreshWallpaper {
    // 通知刷新
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FWRefreshWallpaper" object:nil];
}

%end

%hook TGFileSystemListViewController

- (void)viewDidLoad {
    %orig;
    SetupBackground(self);
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    RefreshBackground(self);
    // 再次确保 tableView 透明
    UIView *tableView = FindTableViewInView(self.view);
    if (tableView) {
        tableView.backgroundColor = [UIColor clearColor];
        if ([tableView isKindOfClass:[UITableView class]]) {
            ((UITableView *)tableView).backgroundView = nil;
        }
    }
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (bgImageView) {
        bgImageView.frame = self.view.bounds;
    }
}

%end

// 主题切换时刷新壁纸
%hook TGMainView

- (void)themeUpdate {
    %orig;
    RefreshBackground(nil);
}

%end

%ctor {
    // 读开关
    fwEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FWEnabled"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"FWEnabled"] == nil) {
        fwEnabled = YES; // 默认开启
    }

    // 监听刷新通知
    [[NSNotificationCenter defaultCenter] addObserverForName:@"FWRefreshWallpaper"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        RefreshBackground(nil);
    }];
}
