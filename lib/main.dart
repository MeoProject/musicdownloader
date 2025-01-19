import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  await requestNotificationPermission();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Settings()),
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    await Provider.of<Settings>(context, listen: false).loadDownloadPath();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      notifier: Provider.of<AppState>(context),
      child: MaterialApp(
        title: '音乐下载器',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MainPage(),
        routes: {
          '/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
