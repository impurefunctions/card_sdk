import 'package:card_sdk_example/view/m6plus.dart';
import 'package:flutter/material.dart';
import 'package:card_sdk/M6pBleBean.dart';
import 'package:card_sdk/M6pBleControl.dart';
import 'package:dio/dio.dart';

List<M6pBleDevice> blueList = [];

BleControl bleControl = BleControl();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('m6plus Test'),
        ),
        body: HomeContent(),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => new _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
  }

  _blueConnect(M6pBleDevice device) async {
    //await device.connect();
    bool isConnect = await bleControl.connectDevice(device);

    //List<ItronBleDevice> services = await device.discoverServices();
    if (isConnect) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return M6plusView();
      }));
    }
  }

  Widget buildItem(BuildContext context, int index) {
    return TextButton(
        onPressed: () {
          print(index);
          M6pBleDevice device = blueList[index];
          _blueConnect(device);
        },
        child: Text('${blueList[index].name}\n${blueList[index].UUID}'));
  }

  @override
  Widget build(BuildContext context) {
    /*
    return ListView.builder(
      itemCount: blueList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('${blueList[index]}'),
        );
      },
    );*/

    return Container(
        child: Column(
      children: [
        Expanded(
          //child: Text('123'),
          child: ListView.separated(
            itemCount: blueList.length,
            itemBuilder: buildItem,
            separatorBuilder: (BuildContext context, int index) =>
                new Divider(),
          ),
          flex: 20,
        ),
        Expanded(
          child: Center(
            child: ElevatedButton(
              child: Text('search bluetooth'),
              onPressed: () {
                print('start search bluetooth');
                /*
                itronBle.startScan().listen((event) {
                  //print(event);
                });*/
                //scanBle();
                setState(() {
                  blueList = [];
                });
                bleControl.startScan().listen((device) {
                  setState(() {
                    blueList.add(device);
                  });
                  print(device);
                });
              },
            ),
          ),
          flex: 2,
        ),
        Expanded(
          child: Center(
            child: ElevatedButton(
              child: Text('disconnect bluetooth'),
              onPressed: () {
                bleControl.disconnect();
                // _getHttp();
              },
            ),
          ),
          flex: 2,
        ),
        Expanded(
          child: Center(),
          flex: 1,
        ),
      ],
    ));
  }

  _getHttp() async {
    String url = 'https://wx.itron.com.cn/mp4/M6Pluz_APP_Sign.bin';

    Response response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    print(response.statusCode);
    if (response.statusCode == 200) {
      print('1111');
      //String data = _arrToStr(response.data);
      // List<int> dataa = response.data;
    }
  }

  String _arrToStr(List<int> arr) {
    String str = '';
    for (int i = 0; i < arr.length; i++) {
      String str1 = arr[i].toRadixString(16);
      if (str1.length != 2) {
        str1 = '0' + str1;
      }
      str = str + str1;
    }
    return str.toUpperCase();
  }
}
