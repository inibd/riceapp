import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '水稻病害检测系统',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: UploadPage(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class UploadPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  UploadPage({required this.isDarkMode, required this.onToggleTheme});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  String? _resultImageUrl;
  List<dynamic> _detections = [];
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _resultImageUrl = null;
        _detections = [];
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
      _resultImageUrl = null;
      _detections = [];
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://101.201.151.95:5000/api/flutter_detect'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonData = json.decode(respStr);

      setState(() {
        _resultImageUrl = 'http://101.201.151.95:5000' + jsonData['result_image'];
        _detections = jsonData['diseases'];
      });
    } else {
      setState(() {
        _resultImageUrl = null;
        _detections = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败，状态码：${response.statusCode}')),
        );
      });
    }

    setState(() {
      _loading = false;
    });
  }

  void _openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  void _showDiseaseInfoDialog(String className) {
    String title = '';
    String content = '';

    if (className == 'Blast') {
      title = '稻瘟病（Blast）';
      content =
      '（1）选用抗病品种，培育优质秧苗，将优质品种种子使用5000倍液的灵乳油（浓度10%）进行消毒浸润处理，将表面病菌消除干净，浸润时间五天左右，经过浸润的种子直接进入到接下来的催芽处理中，不用再次洗涤。\n'
          '（2）严格控制氮肥在肥料配比中的分量，按照相关施肥技术标准要求，配备适合的基肥。\n'
          '（3）将发生过水稻稻瘟病种植基地的秸秆按照科学方式进行处理，避免病菌源在秸秆上越冬次年继续侵蚀水稻。\n'
          '（4）当切实发现稻瘟病发生时，要正确判断稻瘟病类型，结合病情力求在初期阶段控制病情发展，尽可能阻绝病菌的扩散蔓延。采取富士一号、氯溴异氰尿酸可溶性粉剂（浓度50%）的药物治理策略，控制病情发展，避免造成更大的损害。\n'
          '（5）使用化学药剂控制稻瘟病是最常见和最有效的方式，主要的药剂包括苯菌灵、三环唑、异丙硫脲和抗生素（如杀稻瘟菌素和春雷霉素）。';
    } else if (className == 'Brown_Spot') {
      title = '褐斑病（Brown Spot）';
      content =
      '（1）加强检疫，防止病种调入和调出。\n'
          '（2）选用抗病良种；及时清除田边杂草，处理带菌稻草；浅水灌溉，防止田水串流；采用配方施肥，忌偏施氮肥等。\n'
          '（3）老病区在台风暴雨来临前或过境后，对病田或感病品种立即全面喷药1次，特别是洪涝淹水的田块。用药次数根据病情发展情况和气候条件决定，一般间隔7-10天喷1次，发病早的喷2次，发病迟的喷1次。每亩用10%叶情双可湿性粉剂100克，70%叶枯净（又称杀枯净）胶悬剂100-150克，或25%叶枯宁可湿性粉剂100克，或50%代森铵100克（抽穗后不能用），或25%消菌灵可湿性粉剂40克，或15%消菌灵200克，以上药剂加水50升喷雾。';
    } else if (className == 'Blight') {
      title = '白叶枯病（Bacterial Blight）';
      content =
      '（1）选种：各地应因地制宜地选育和推广抗病耐病的高产品种，这是经济、有效和切实可行的防病措施。\n'
          '（2）实施植物检疫：严格执行检疫制度，认真划定疫区和保护区，调运种子前必须实施产地检疫，保证疫区的病种不调出，保护区不引进病种或带病稻草制品。\n'
          '（3）控制病菌来源：不使用带病种子，禁止带病稻草直接还田、及时彻底处理病谷壳、病米糠等病残组织，以减少菌源，清除田问病草、稻茬及渠边病草，不用病草堵塞涵洞、水口，扎草把或做薄膜固定绳。\n'
          '（4）加强栽培管理：秧田要选择在地势较高、排灌方便、远离病源的无病田或同田，采用旱育秧。必要时秧苗期可喷药两次，以防止或减少秧苗带菌。施肥要注意氮、磷、钾的配合，基肥应以有机肥为主，后期慎用氮肥；绿肥或其他有机肥过多的田，可施用适量石灰和草木灰。要浅水勤灌，适时适度搁田，严防秧苗淹水，铲除田边杂草。这些都有减轻发病的作用。\n'
          '（5）在水稻三叶期和移栽前5天各喷施1次10%三氯异氰脲酸500倍液，预防本田发病。大田施药适期应掌握在零星发病阶段，以消灭发病中心为主，防止扩大蔓延。常用的药剂有35%克壮·叶唑可湿性粉剂1500倍液，或50%氯溴异氰尿酸可湿性粉剂2000-3000倍液，或20%噻菌铜悬浮剂2000倍液，或3%中生菌素可湿性粉剂10000倍液，或15%叶枯唑可湿性粉剂2000倍液，或20%噻菌茂可湿性粉剂1500倍液，或72%硫酸链霉素可溶性粉剂3000倍液，或20%噻森铜悬浮剂2500倍液，或5%菌毒清水剂5000倍液，或45%代森铵水剂2000倍液喷雾。';
    } else {
      title = '未知病害';
      content = '暂无该病害的详细信息。';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('水稻病害检测系统'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettingsPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: _image != null
                  ? Image.file(_image!, height: 200, fit: BoxFit.cover)
                  : Container(
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library),
              label: Text('选择图片'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: Icon(Icons.cloud_upload),
              label: Text('上传并检测'),
            ),
            SizedBox(height: 20),
            if (_loading) Center(child: CircularProgressIndicator()),
            if (_resultImageUrl != null) ...[
              // 检测结果图像标题
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // 改为淡灰色背景
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        '检测结果图像：',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Image.network(_resultImageUrl!),
              ),
            ],
            if (_detections.isNotEmpty) ...[
              SizedBox(height: 20),
              // 识别到的病害标题
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // 淡灰色背景
                    borderRadius: BorderRadius.circular(20), // 圆角
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fact_check, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        '识别到的病害：',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),







              ..._detections.map((d) => Card(
                child: ListTile(
                  leading: Image.asset(
                    'assets/bug.png', // 记得把 bug.png 添加到项目 assets 中
                    width: 40,
                    height: 40,
                  ),
                  title: Text(
                    '${d['class_name']}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('概率：${(d['confidence'] * 100).toStringAsFixed(2)}%'),
                  onTap: () => _showDiseaseInfoDialog(d['class_name']),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  SettingsPage({required this.isDarkMode, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('夜间模式'),
              value: isDarkMode,
              onChanged: onToggleTheme,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('应用说明'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('应用说明'),
                    content: Text(
                      '本系统是基于YOLOv11的水稻病害精准检测系统，'
                          '可以检测白叶枯病、褐斑病以及稻瘟病三种水稻病害。'
                          '用户可以通过选择图片并上传到服务器，由系统检测并返回病害部位及结果。'
                          '用户点击病害结果后可以看见病害的防治方法。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
