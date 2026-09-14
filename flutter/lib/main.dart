import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PC-TVBox",
      theme: ThemeData.dark(useMaterial3: true).copyWith(primaryColor: Colors.blueAccent),
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Process? _javaProcess;
  bool sideBarOpen = true;
  bool logPanelOpen = false;
  List<String> logList = [];
  Socket? socket;
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    startCatVodService();
  }

  Future<void> startCatVodService() async {
    try {
      String javaPath = "jre/bin/java.exe";
      _javaProcess = await Process.start(
        javaPath,
        ["-jar", "catvod-server.jar"],
        workingDirectory: Directory.current.path,
        creationFlags: 0x08000000,
      );
      addLog("✅ 爬虫后台服务启动成功，等待连接...");
      await Future.delayed(const Duration(seconds: 2));
      connectSocket();
    } catch (e) {
      addLog("❌ 启动爬虫失败：$e");
    }
  }

  Future<void> connectSocket() async {
    try {
      socket = await Socket.connect("127.0.0.1", 18088);
      addLog("✅ Socket连接爬虫服务成功");
      socket!.listen((data) {
        String res = utf8.decode(data);
        addLog("📥收到数据: $res");
      });
    } catch (e) {
      addLog("❌ Socket连接失败：$e");
    }
  }

  Future<void> sendSocketMsg(Map<String, dynamic> msg) async {
    if(socket == null) return;
    String jsonStr = jsonEncode(msg) + "\n";
    socket!.write(jsonStr);
    addLog("📤发送指令：$jsonStr");
  }

  void addLog(String msg) {
    setState(() {
      logList.add("${DateTime.now()} $msg");
    });
  }

  @override
  void dispose() {
    if (_javaProcess != null) {
      _javaProcess!.kill();
      addLog("✅ 关闭爬虫后台进程");
    }
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (sideBarOpen)
            SizedBox(
              width: 220,
              child: Container(
                color: const Color(0xFF1A1A2E),
                child: ListView(
                  children: const [
                    ListTile(title: Text("站点列表")),
                    ListTile(title: Text("分类")),
                    ListTile(title: Text("我的收藏")),
                    ListTile(title: Text("观看历史")),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  color: const Color(0xFF16213E),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Text("PC-TVBox", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      TextButton(onPressed: () => setState(()=>currentPageIndex=0), child: const Text("首页")),
                      TextButton(onPressed: () => setState(()=>currentPageIndex=1), child: const Text("站点管理")),
                      TextButton(onPressed: () => setState(()=>currentPageIndex=2), child: const Text("搜索")),
                      TextButton(onPressed: () => setState(()=>currentPageIndex=3), child: const Text("设置")),
                      const Spacer(),
                      ElevatedButton(onPressed: ()=>setState(()=>logPanelOpen = !logPanelOpen), child: const Text("调试日志")),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: buildContentPage()),
                      if(logPanelOpen)
                        SizedBox(
                          width:340,
                          child: Container(
                            color: Colors.black87,
                            child: ListView.builder(
                              itemCount: logList.length,
                              itemBuilder: (ctx,i)=>Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(logList[i], style: const TextStyle(fontSize:11,color: Colors.greenAccent)),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContentPage(){
    switch(currentPageIndex){
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("首页影视大厅区域（后续添加Banner、影片卡片网格）"),
              SizedBox(height:20),
              ElevatedButton(onPressed: ()=>sendSocketMsg({"action":"home"}), child: Text("拉取首页数据"))
            ],
          ),
        );
      case 1:
        return const Center(child: Text("站点管理，粘贴/导入TVBox json配置"));
      case 2:
        return const Center(child: Text("搜索页面"));
      case 3:
        return const Center(child: Text("设置页面"));
      default:
        return const SizedBox();
    }
  }
}

class PlayerPage extends StatefulWidget {
  final String url;
  const PlayerPage({super.key, required this.url});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late Player player;
  late VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Video(controller: controller),
    );
  }
}
