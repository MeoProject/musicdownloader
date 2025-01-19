import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musicdownloader/state/settings.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    await Provider.of<Settings>(context, listen: false).loadDownloadPath();
  }

  Future<void> _selectDirectory() async {
    final settings = Provider.of<Settings>(context, listen: false);
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null && mounted) {
      settings.downloadPath = selectedPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    String downloadPath = Provider.of<Settings>(context).downloadPath;

    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('下载目录'),
            subtitle: Text(downloadPath.isEmpty ? '未设置' : downloadPath),
            leading: Icon(Icons.folder),
            onTap: _selectDirectory,
          ),
          ListTile(
            title: Text('温馨提示'),
            leading: Icon(Icons.info_outline),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TipsPage(),
                ),
              );
            },
          ),
          ListTile(
            title: Text('关于我们'),
            leading: Icon(Icons.group),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutUsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('温馨提示'),
      ),
      body: Markdown(
        data: '''
By: MeoProject
非原版歌词适配

## 协议
### 开头语
本项目基于 MIT 协议发行，以下内容为对该协议的补充，如有冲突，以下方内容为准。

----

### 词语约定
 1.  本协议中的"本项目"指 音乐下载器 项目
 2.  "使用者"指签署本协议的项目使用者
 3.  "版权内容"为本项目中可能引用到的所有包括**但不限于** 姓名、图片、音频 等他人拥有版权的所有数据

----

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
 8.3 本协议可能会发生变更，恕不另行通知，可自行前往查看。协议变更后，如您继续使用本项目，**即默认您接受变更后的新协议内容**如有疑问请联系: 
  ikun@ikunshare.com
  naiy@zcmonety.xyz
        ''',
        selectable: true,
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('关于我们'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('加入QQ群'),
            leading:
                Image.asset('assets/icon/qq_icon.png', width: 24, height: 24),
            onTap: () async {
              final Uri url = Uri.parse("https://qm.qq.com/q/7VaRB0zvFK");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
                Fluttertoast.showToast(msg: "已跳转");
              } else {
                Fluttertoast.showToast(msg: "跳转失败, 请检查是否任意浏览器");
              }
            },
          ),
          ListTile(
            title: Text('加入Telegram群'),
            leading: Icon(Icons.telegram),
            onTap: () async {
              final Uri url = Uri.parse("https://t.me/MusicDownloaderCN");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
                Fluttertoast.showToast(msg: "已跳转");
              } else {
                Fluttertoast.showToast(msg: "跳转失败, 请检查是否安装任意浏览器");
              }
            },
          ),
        ],
      ),
    );
  }
}
