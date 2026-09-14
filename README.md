# PC-TVBox
Windows桌面影视客户端，深色影视大厅UI，基于CatVod爬虫引擎
> 仅支持纯HTTP类型CSP，不支持WebView爬虫

## 目录结构
- jre 精简java运行环境
- catvod-server.jar：后端爬虫服务
- flutter_client.exe 主程序

## 使用
1. 直接双击 flutter_client.exe
2. 程序会后台自动启动java爬虫服务，无黑窗口
3. 在站点管理页面粘贴TVBox的json站点配置
4. 加载站点，浏览影片、播放视频
5. 右上角【调试日志】查看爬虫请求信息

## 注意
- 关闭主窗口，自动停止java爬虫后台
- 只支持本地127.0.0.1通信，不会暴露到外网
