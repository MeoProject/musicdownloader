import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String announcement = '加载中...';
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchAnnouncement();
  }

  Future<void> fetchAnnouncement() async {
    try {
      final response = await dio.get('YOUR_API_ENDPOINT');
      if (response.statusCode == 200) {
        setState(() {
          announcement = response.data['announcement'];
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
                Text('公告', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
