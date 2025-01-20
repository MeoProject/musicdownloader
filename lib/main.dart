import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
  await requestStoragePermission();
  runApp(MyApp(isFirstLaunch: isFirstLaunch));
  if (isFirstLaunch) {
    await prefs.setBool('first_launch', false);
  }
}

Future<void> requestStoragePermission() async {
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => Settings()),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          final defaultLightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          );
          final defaultDarkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );

          final lightColorScheme =
              lightDynamic?.harmonized() ?? defaultLightColorScheme;
          final darkColorScheme =
              darkDynamic?.harmonized() ?? defaultDarkColorScheme;

          return Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context);
              return AppStateProvider(
                notifier: appState,
                child: MaterialApp(
                  title: '音乐下载器',
                  theme: ThemeData(
                    colorScheme: lightColorScheme,
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      backgroundColor: lightColorScheme.primaryContainer,
                      foregroundColor: lightColorScheme.onPrimaryContainer,
                    ),
                    cardTheme: CardTheme(
                      color: lightColorScheme.surfaceContainerHighest,
                    ),
                    bottomNavigationBarTheme: BottomNavigationBarThemeData(
                      selectedItemColor: lightColorScheme.primary,
                      unselectedItemColor: lightColorScheme.onSurfaceVariant,
                    ),
                  ),
                  darkTheme: ThemeData(
                    colorScheme: darkColorScheme,
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      backgroundColor: darkColorScheme.primaryContainer,
                      foregroundColor: darkColorScheme.onPrimaryContainer,
                    ),
                    cardTheme: CardTheme(
                      color: darkColorScheme.surfaceContainerHighest,
                    ),
                    bottomNavigationBarTheme: BottomNavigationBarThemeData(
                      selectedItemColor: darkColorScheme.primary,
                      unselectedItemColor: darkColorScheme.onSurfaceVariant,
                    ),
                  ),
                  home: isFirstLaunch ? const WelcomePage() : const MainPage(),
                  routes: {
                    '/settings': (context) => const SettingsPage(),
                  },
                ),
              );
            },
          );
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

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('欢迎使用')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Markdown(
                data: '''
# 欢迎使用音乐下载器

## 协议
### 开头语
本项目基于 MIT 协议发行，以下内容为对该协议的补充，如有冲突，以下方内容为准。

### 词语约定
1. 本协议中的"本项目"指 音乐下载器 项目
2. "使用者"指签署本协议的项目使用者
3. "版权内容"为本项目中可能引用到的所有包括**但不限于** 姓名、图片、音频 等他人拥有版权的所有数据

### 协议正文
#### 一、数据来源
1.1 本项目从QQ音乐、网易云音乐等 APP 的公开服务器中拉取处理内容后返回，故不对此类数据的准确性、安全性、合法性等负责。
1.2 本项目使用中可能会产生本地内容，本项目不对此类数据的准确性、安全性、合法性等负责

#### 二、版权数据
2.1 本项目在使用中可能会产生版权数据。对于这些版权数据，本项目不拥有其所有权。为了避免侵权，使用者务必在**24小时内**清除使用本项目的过程中所产生的版权数据。

#### 三、本地资源
3.1 本项目中的部分本地内容（包括但不限于 图片、文字 等）来自互联网搜集。如出现侵权请联系删除。

#### 四、免责声明
4.1 由于使用本项目产生的包括由于本协议或由于使用或无法使用本项目而引起的任何性质的任何直接、间接、特殊、偶然或结果性损害（包括但不限于因商誉损失、停工、计算机故障或故障引起的损害赔偿，或任何及所有其他商业损害或损失）由使用者负责。

#### 五、使用限制
5.1 **禁止在违反当地法律法规的情况下使用本项目。** 对于使用者在明知或不知当地法律法规不允许的情况下使用本项目所造成的任何违法违规行为由使用者承担，本项目不承担由此造成的任何直接、间接、特殊、偶然或结果性责任。

#### 六、版权保护
6.1 平台不易，建议支持正版。

#### 七、非商业性质
7.1 本项目开发旨在对于技术可行性的探究，不接受任何商业性行为，使用者也不得使用本项目进行任何商业性行为。

#### 八、协议生效
8.1 如您使用本项目，即代表您接受本协议。
8.2 因违反协议而造成的任何损失，本项目开发者不承担任何包括但不限于道德、法律责任。
8.3 本协议可能会发生变更，恕不另行通知，可自行前往查看。协议变更后，如您继续使用本项目，**即默认您接受变更后的新协议内容**。
''',
                selectable: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainPage()),
                    );
                  },
                  child: const Text('同意并开始使用'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
