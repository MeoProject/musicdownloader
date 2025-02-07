import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String announcement = '加载中...';
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchAnnouncement();
  }

  Future<void> fetchAnnouncement() async {
    try {
      final response = await dio
          .get('https://api.v2.sukimon.me:19742/musicdownloader/getNotice');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        setState(() {
          announcement = response.data['data']['raw'].toString() +
              response.data['data']['ext'].toString();
        });
      }
    } catch (e) {
      setState(() {
        announcement = '获取公告失败: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音乐下载器')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('公告',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text(announcement),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
