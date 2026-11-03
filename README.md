# FilzaWallpaper

给 Filza 文件管理器加自定义背景图的 tweak。

## 效果
- 文件列表背景变成你指定的壁纸
- 浅色/深色模式可分别用不同壁纸
- 文件夹图标、字体设置不受影响

## 壁纸放置路径
用 Filza 把图片放到：
```
/var/mobile/Documents/FilzaWallpaper.jpg        ← 浅色/默认模式
/var/mobile/Documents/FilzaWallpaper_dark.jpg   ← 深色模式（可选）
```
也支持 .png 格式。

## 安装方式

### 方式一：越狱环境（推荐）
1. 把这个项目 push 到你的 GitHub 仓库
2. Actions 会自动编译出 .deb
3. 下载 deb 用 Filza 安装，重启 Filza 即可

### 方式二：注入 IPA（无越狱）
1. GitHub Actions 编译出 `libFilzaWallpaper.dylib`
2. 用 `insert_dylib` 把 dylib 注入 Filza 二进制
3. 把壁纸图片放进 `Payload/Filza.app/FilzaWallpaper.jpg`
4. 重新签名 IPA

## 开关
- 默认开启
- 想关掉：把 `FilzaWallpaper.jpg` 改名或删掉就行

## 注意
- 壁纸建议用竖屏手机壁纸尺寸（1170×2532 或以上）
- 图片太大可能影响流畅度，建议压缩到 2MB 以内
