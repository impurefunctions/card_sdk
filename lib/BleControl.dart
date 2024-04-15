// ignore_for_file: unnecessary_null_comparison

import 'package:flutter_blue/flutter_blue.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'dart:async';
import 'BleBean.dart';

class TLV {
  String? tag;
  int? length;
  String? value;
  @override
  String toString() {
    return 'tag:${this.tag},length:${this.length},value:${this.value}';
  }
}

//获取设备信息回调
typedef GetTerminalInfoCallback = void Function(
    TerminalInfo? terminalInfo, int status);
//请求数据加密回调
typedef RequestDataEncryptCallback = void Function(
    String? encryptedData, int status);
//计算MAC回调
typedef CalculateMacCallback = void Function(String? mac, int status);
//下载工作密钥
typedef DownloadWorkKeyCallback = void Function(int status);
//pin加密
typedef PINEntryCallback = void Function(String? pin, int status);

//刷卡
//等待刷卡
typedef WaitingcardCallback = void Function();
//卡片已插入
typedef ICCardInsertionCallback = void Function();
//NFC已刷
typedef NFCCardDetectionCallback = void Function();
//返回卡片信息
typedef ReadCardCallback = void Function(CardInfo? cardInfo, int status);

//回写
typedef SendOnlineProcessCallback = void Function(
    int onlineResult, String? scriptResult, String? data, int status);

//开始NFC/IC
typedef PowerOnAPDUCallback = void Function(int type, String data, int status);
//结束NFC/IC
typedef PowerOffAPDUCallback = void Function(int status);
//NFC/IC apdu
typedef SendApduCallback = void Function(List<String> data, int status);

//自动关机时间
typedef SetAutomaticShutdownCallback = void Function(int status);

//退出
typedef StopTradeCallback = void Function(int status);

//
typedef DownloadTerminalInfoCallback = void Function(int status);

typedef DownloadAIDParametersCallback = void Function(int status);

typedef ClearAIDParametersCallback = void Function(int status);

typedef DownloadPublicKeyCallback = void Function(int status);

typedef ClearPublicKeyCallback = void Function(int status);

typedef SetTerminalDateTimeCallback = void Function(int status);

typedef GetTerminalDateTimeCallback = void Function(String time, int status);

typedef GetBatteryPowerCallback = void Function(String power, int status);

typedef FirmwareUpdateRequest = void Function(int status);

typedef FirmwareUpdateRequestProgress = void Function(int progress);

class BleControl {
  factory BleControl() => _shareInstance()!;
  static BleControl? _instance;

  BleControl._() {
    _flutterBlue = FlutterBlue.instance;
  }
  static BleControl? _shareInstance() {
    if (null == _instance) {
      _instance = BleControl._();
    }
    return _instance;
  }

  //属性
  late FlutterBlue _flutterBlue;
  List<BluetoothDevice> _blueList = [];
  //正在连接的设备
  late BluetoothDevice _connectBleDevice;
  /*
  //电子烟服务id
  static String m6pService = '0000FFD0-BB29-456D-989D-C44D07F6F6A6';
  //m6p通知特征
  static String m6pNotiChar = '0000FFD2-BB29-456D-989D-C44D07F6F6A6';
  //m6p写数据特征
  static String m6pWriteChar = '0000FFD1-BB29-456D-989D-C44D07F6F6A6';
  */

  //m6p服务id
  static String _m6pService = '49535343-FE7D-4AE5-8FA9-9FAFD205E455';
  //m6p通知特征
  static String _m6pNotiChar = '49535343-1E4D-4BD9-BA61-23C647249616';
  //m6p写数据特征
  static String _m6pWriteChar = '49535343-8841-43F4-A8D4-ECBE34729BB3';

  var _notifySubscription;
  //BluetoothCharacteristic _m6pNotiChar1;
  late BluetoothCharacteristic _m6pWriteChar1;
  //蓝牙发送包长
  static int _bluetoothNumber = 120;

  bool _accepting = false;
  String? _acceptData = '';
  int _acceptDatalen = 0;
  int _acceptDataSumLen = 0;

  //远程下载偏移量
  int _offest = 0;
  //远程下载数据
  List<int> _downloadData = [];
  //远程下载类型，00为app，01为kernel
  String _downloadType = '';
  //远程下载单包包长
  static int _DOWNLOAD_PAGENUM = 1024;

  //判断是更新AID还是RID，1为更新AID，2为清除AID，3为更新RID，4为清除RID
  int? _aidOrRid;
  //tlv
  List<TLV> _getTLVArr(String hexStr) {
    List<TLV> arr = [];
    if (hexStr.length % 2 != 0) {
      return arr;
    }
    hexStr = hexStr.toUpperCase();
    int index = 0;
    while (index < hexStr.length) {
      String tag = _getTag(hexStr, index);
      index = index + tag.length;
      String len = _getLength(hexStr, index);
      index = index + len.length;
      int valueLen = 0;
      if (len.length == 2) {
        valueLen = _hexToInt(len);
      } else {
        valueLen = _hexToInt(len.substring(2, len.length));
      }
      if (valueLen * 2 > hexStr.length - index) {
        return [];
      }
      var value2 = hexStr.substring(index, index + valueLen * 2);
      index = index + value2.length;
      TLV tlv = TLV();
      tlv.tag = tag;
      tlv.length = valueLen;
      tlv.value = value2;
      arr.add(tlv);
    }
    return arr;
  }

  String _getTag(String hexStr, int index) {
    int tag1 = _hexToInt(hexStr.substring(index, index + 2));
    if ((tag1 & 0x1f) == 0x1f) {
      return hexStr.substring(index, index + 4);
    } else {
      return hexStr.substring(index, index + 2);
    }
  }

  String _getLength(String hexStr, int index) {
    int len1 = _hexToInt(hexStr.substring(index, index + 2));
    if ((len1 & 0x80) == 0) {
      return hexStr.substring(index, index + 2);
    } else {
      var len2 = len1 & 0x7f;
      return hexStr.substring(index, index + 2 * (len2 + 1));
    }
  }

  String _getTLVStr(String tag, String value) {
    String len = '';
    String str = '';
    if (value.length / 2 <= 127) {
      len = _intToHex(value.length ~/ 2);
    }
    if (value.length / 2 > 127 && value.length / 2 <= 255) {
      len = '81' + _intToHex(value.length ~/ 2);
    }
    if (value.length / 2 > 255 && value.length / 2 <= 0xffff) {
      len = '82' +
          _intToHex((value.length ~/ 2) ~/ 256) +
          _intToHex((value.length ~/ 2) % 256);
    }
    str = (tag + len + value).toUpperCase();
    return str;
  }

  _receiveData1(String str) {
    print('receiceData:');
    print(str);
    List<int> resultBuf = _strToIntArr(str);
    int resCode1 = resultBuf[4];
    int resCode2 = resultBuf[5];
    int res = resultBuf[6];
    int resLength = resultBuf[7] * 256 + resultBuf[8];
    String dataStr = str.substring(18, 18 + resLength * 2).toUpperCase();
    //获取设备类型
    if (resCode1 == 0x09 && resCode2 == 0x1b) {
      TerminalInfo terminalInfo = TerminalInfo();
      if (res != 0) {
        _getTerminalInfoCallback1(null, res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        for (TLV tlv in arr) {
          //tusn
          if (tlv.tag == '1F80') {
            terminalInfo.tusn = _ascToHex(tlv.value!);
          }
          //mac
          if (tlv.tag == '1F81') {
            terminalInfo.bluetoothMAC = _ascToHex(tlv.value!);
          }
          //蓝牙版本
          if (tlv.tag == '1F82') {
            terminalInfo.bluetoothVersion = tlv.value;
          }
          //蓝牙名称
          if (tlv.tag == '1F83') {
            terminalInfo.bluetoothName = _ascToHex(tlv.value!);
          }
          //App版本
          if (tlv.tag == '1F84') {
            terminalInfo.appVersion = tlv.value;
          }
          //App版本日期
          if (tlv.tag == '1F85') {
            terminalInfo.appVersionDate = tlv.value;
          }
          //Kernel版本
          if (tlv.tag == '1F86') {
            terminalInfo.kernelVersion = tlv.value;
          }
          //Kernel版本日期
          if (tlv.tag == '1F87') {
            terminalInfo.kernelVersionDate = tlv.value;
          }
          //HW版本
          if (tlv.tag == '1F88') {
            terminalInfo.hardwareVersion = tlv.value;
          }
          //SW版本
          if (tlv.tag == '1F89') {
            terminalInfo.softVersion = tlv.value;
          }
          //终端ID
          if (tlv.tag == '1F44') {
            terminalInfo.sn = tlv.value;
          }
        }
        _getTerminalInfoCallback1(terminalInfo, res);
      }
    }
    //请求数据加密
    if (resCode1 == 0x02 && resCode2 == 0x04) {
      if (res != 0) {
        _requestDataEncryptCallback1('', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? str = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F51') {
            str = tlv.value;
          }
        }
        _requestDataEncryptCallback1(str, res);
      }
    }
    //计算mac
    if (resCode1 == 0x02 && resCode2 == 0x06) {
      if (res != 0) {
        _calculateMacCallback1('', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? str = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F4C') {
            str = tlv.value;
          }
        }
        _calculateMacCallback1(str, res);
      }
    }
    //更新工作密钥
    if (resCode1 == 0x02 && resCode2 == 0x10) {
      _downloadWorkKeyCallback1(res);
    }
    //pin加密
    if (resCode1 == 0x02 && resCode2 == 0x20) {
      if (res != 0) {
        _pinEntryCallback1('', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? str = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F47') {
            str = tlv.value;
          }
        }
        _pinEntryCallback1(str, res);
      }
    }
    //刷卡
    if (resCode1 == 0x02 && resCode2 == 0xa0) {
      if (res == 1) {
        _readCardCallback1(null, res);
        return;
      }
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
      }
      if (res == 0x89) {
        return;
      }
      if ((res == 0x84) || (res == 0x8a)) {
        if (res == 0x84) {
          _icCardInsertionCallback1();
        }
        if (res == 0x8a) {
          _nfcCardDetectionCallback1();
        }
        return;
      }
      if (res == 0x00) {
        _analyzM6(str);
      } else {
        CardInfo cardInfo = CardInfo();
        if (str.length > 18) {
          int failLength = resultBuf[7] * 256 + resultBuf[8];
          cardInfo.swipeFailMessage = str.substring(18, 18 + failLength * 2);
        }
        _readCardCallback1(cardInfo, res);
      }
    }
    //回写IC卡
    if (resCode1 == 0x02 && resCode2 == 0xa1) {
      if (res != 0) {
        _sendOnlineProcessCallback1(0, '', '', res);
      } else {
        int onlineProcessResult = 0;
        String? scriptResult = '';
        String? data1 = '';
        List<TLV> arr = _getTLVArr(dataStr);
        for (TLV tlv in arr) {
          if (tlv.tag == '1F70') {
            onlineProcessResult = _hexToInt(tlv.value!);
          }
          if (tlv.tag == '1F71') {
            scriptResult = tlv.value;
          }
          if (tlv.tag == '1F72') {
            data1 = tlv.value;
          }
        }
        _sendOnlineProcessCallback1(
            onlineProcessResult, scriptResult, data1, res);
      }
    }
    //开始透传
    if (resCode1 == 0x02 && resCode2 == 0xe0) {
      if (res != 0) {
        _powerOnAPDUCallback1(0, '', res);
      } else {
        int type = resultBuf[9];
        int len = resultBuf[8];
        String cardData = str.substring(20, 20 + 2 * (len - 1));
        _powerOnAPDUCallback1(type, cardData, res);
      }
    }
    //关闭NFC
    if (resCode1 == 0x02 && resCode2 == 0xe1) {
      _powerOffAPDUCallback1(res);
    }
    //NFC透传
    if (resCode1 == 0x02 && resCode2 == 0xe2) {
      if (res == 0) {
        int apduNumber = resultBuf[9];
        int len1 = 10;
        List<String> apduMarr = [];
        for (int i = 0; i < apduNumber; i++) {
          String apduNFC_ICDataStr = str.substring(
              2 * (len1 + 1), 2 * (len1 + 1) + resultBuf[len1] * 2);
          apduMarr.add(apduNFC_ICDataStr);
          len1 = len1 + resultBuf[len1] + 1;
        }
        _sendApduCallback1(apduMarr, res);
        return;
      }
      if (res == 0x86) {
        int len = resultBuf[7] * 256 + resultBuf[8];
        List<String> apduMarr = [];
        String apduNFC_ICDataStr = str.substring(18, 18 + len * 2);
        apduMarr.add(apduNFC_ICDataStr);
        _sendApduCallback1(apduMarr, res);
        return;
      }
      _sendApduCallback1([], res);
    }
    //设置自动关机时间
    if (resCode1 == 0x09 && resCode2 == 0x08) {
      _setAutomaticShutdownCallback1(res);
    }
    //停止
    if (resCode1 == 0x09 && resCode2 == 0x07) {
      _stopTradeCallback1(res);
    }
    //终端信息下载
    if (resCode1 == 0x09 && resCode2 == 0x20) {
      _downloadTerminalInfoCallback1(res);
    }
    //AID或RID
    if (resCode1 == 0x09 && resCode2 == 0x22) {
      if (_aidOrRid == 1) {
        _downloadAIDParametersCallback1(res);
      }
      if (_aidOrRid == 2) {
        _clearAIDParametersCallback1(res);
      }
      if (_aidOrRid == 3) {
        _downloadPublicKeyCallback1(res);
      }
      if (_aidOrRid == 4) {
        _clearPublicKeyCallback1(res);
      }
    }
    //同步时间
    if (resCode1 == 0x09 && resCode2 == 0x31) {
      _setTerminalDateTimeCallback1(res);
    }
    //获取时间
    if (resCode1 == 0x09 && resCode2 == 0x32) {
      if (res != 0) {
        _getTerminalDateTimeCallback1('', res);
      } else {
        String timeStr = '';
        int getTimeLen = resultBuf[7] * 256 + resultBuf[8];
        if (getTimeLen != 0) {
          timeStr = str.substring(18, 18 + getTimeLen * 2);
        }
        _getTerminalDateTimeCallback1(timeStr, res);
      }
    }
    //获取电量
    if (resCode1 == 0x09 && resCode2 == 0x13) {
      if (res != 0) {
        _getBatteryPowerCallback1('', res);
      } else {
        int batteryPoewr = 0;
        String power = '%0';
        List<TLV> arr = _getTLVArr(dataStr);
        for (TLV tlv in arr) {
          if (tlv.tag == '1F8A') {
            batteryPoewr = _hexToInt(tlv.value!);
            if (batteryPoewr >= 3900) {
              //100%
              power = '%100';
            } else if ((batteryPoewr < 3900) && (batteryPoewr >= 3700)) {
              //75%
              power = '%75';
            } else if ((batteryPoewr < 3700) && (batteryPoewr >= 3500)) {
              // 50
              power = '%50';
            } else if ((batteryPoewr < 3500) && (batteryPoewr >= 3200)) {
              // 25%
              power = '%25';
            } else if (batteryPoewr < 3200) {
              //5%
              power = '%5';
            }
          }
        }
        _getBatteryPowerCallback1(power, res);
      }
    }
    //m6plus下载
    if (resCode1 == 0x05 && resCode2 == 0x06) {
      if (res != 0) {
        _firmwareUpdateRequest1(res);
      } else {
        _offest = _offest + _DOWNLOAD_PAGENUM;
        //更新成功，查询结果
        if (_offest >= _downloadData.length) {
          _querryUpDate();
        }
        //继续更新
        else {
          int progress = (_offest * 100) ~/ _downloadData.length;
          _firmwareUpdateRequestProgress1(progress);
          _requestDataPage(_offest);
        }
      }
    }
    //m6plus更新查询结果
    if (resCode1 == 0x05 && resCode2 == 0x07) {
      _firmwareUpdateRequest1(res);
    }
  }

  _analyzM6(String str) {
    List<int> resultBuf = _strToIntArr(str);
    int resLength = resultBuf[7] * 256 + resultBuf[8];
    String dataStr = str.substring(18, 18 + resLength * 2).toUpperCase();
    List<TLV> arr = _getTLVArr(dataStr);
    CardInfo cardInfo = CardInfo();
    for (TLV tlv in arr) {
      //磁道明文
      if (tlv.tag == '1F40') {
        cardInfo.tracks = tlv.value;
      }
      //卡类型
      if (tlv.tag == '1F41') {
        print('1F41 ' + tlv.value.toString());
        cardInfo.cardType = _hexToInt(tlv.value!.substring(0, 2));
        if (cardInfo.cardType == 3) {
          cardInfo.nfcCompany =
              _nfcCompay(_hexToInt(tlv.value!.substring(2, 4)));
        }
        cardInfo.tradeChannel = _hexToInt(tlv.value!.substring(4, 6));
      }
      //回送的控制模式
      if (tlv.tag == '1F42') {
        cardInfo.controlModel = tlv.value;
      }
      //psam卡号
      if (tlv.tag == '1F43') {
        cardInfo.psamNo = tlv.value;
      }
      //终端ID
      if (tlv.tag == '1F44') {
        cardInfo.tsn = tlv.value;
      }
      //TUSN
      if (tlv.tag == '1F45') {
        cardInfo.tsn = tlv.value;
      }
      //交易结果
      if (tlv.tag == '1F46') {
        cardInfo.result = tlv.value;
      }
      //磁道密文
      if (tlv.tag == '1F47') {
        cardInfo.encryTrack = tlv.value;
      }
      //55域
      if (tlv.tag == '1F48') {
        cardInfo.icdata = tlv.value;
      }
      //密码
      if (tlv.tag == '1F49') {
        cardInfo.pin = tlv.value;
      }
      //随机数
      if (tlv.tag == '1F4A') {
        cardInfo.random = tlv.value;
      }
      //mac
      if (tlv.tag == '1F4C') {
        cardInfo.mac = tlv.value;
      }
      //pan
      if (tlv.tag == '1F4D') {
        cardInfo.pan = tlv.value;
      }
      //有效期
      if (tlv.tag == '1F4E') {
        cardInfo.cardexpiryDate = _ascToHex(tlv.value!);
      }
      //磁道密文长度
      if (tlv.tag == '1F4F') {
        cardInfo.encryTrackLen = tlv.value;
      }
      //磁道明文长度
      if (tlv.tag == '1F50') {
        cardInfo.trackLen = tlv.value;
      }
      //卡号
      if (tlv.tag == '1F51') {
        cardInfo.cardNo = _ascToHex(tlv.value!);
      }
      //IC卡序列号
      if (tlv.tag == '1F52') {
        cardInfo.cardSerial = tlv.value;
      }
      //cvm
      if (tlv.tag == '1F53') {
        cardInfo.cvm = tlv.value;
      }
      //拒绝原因
      if (tlv.tag == '1F54') {
        cardInfo.deninalReason = tlv.value;
      }
      //持卡人姓名
      if (tlv.tag == '1F55') {
        cardInfo.cardName = _removeSpace(_ascToHex(tlv.value!));
      }
      //ksn
      if (tlv.tag == '1F56') {
        cardInfo.ksn = tlv.value;
      }
      //Kernel Type
      if (tlv.tag == '1F61') {
        cardInfo.kernelType = tlv.value;
      }
      //Outcome Parameter Set
      if (tlv.tag == '1F62') {
        cardInfo.outcomeParameterSet = tlv.value;
      }
      //User Interface Request Data
      if (tlv.tag == '1F63') {
        cardInfo.userInterfaceRequestData = tlv.value;
      }
      //Error Indication
      if (tlv.tag == '1F64') {
        cardInfo.errorIndication = tlv.value;
      }
    }
    _readCardCallback1(cardInfo, 0);
  }

  //去掉字符串后面的空格
  String _removeSpace(String str) {
    if (str.length == 0) {
      return '';
    }
    int length = str.length;
    for (int i = 0; i < length; i++) {
      String str1 = str.substring(str.length - 1, str.length);
      if (str1 == ' ') {
        str = str.substring(0, str.length - 1);
      } else {
        return str;
      }
    }
    return str;
  }

  _receiveData(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    _notifySubscription = characteristic.value.listen((value) {
      String str = _arrToStr(value);
      if (str.length > 0) {
        if (_accepting) {
          //合并字段
          _acceptData = _acceptData! + str;
          _acceptDatalen = _acceptDatalen + (str.length ~/ 2);
          if ((_acceptDataSumLen + 4) == (_acceptData!.length / 2)) {
            //数据接受完成
            //char * temp = (char *)[acceptData bytes];
            var sum = 0;
            for (var i = 0; i < (_acceptData!.length / 2) - 1; i++) {
              sum = sum ^ _hexToInt(_acceptData!.substring(i * 2, i * 2 + 2));
            }
            if (sum ==
                _hexToInt(_acceptData!.substring((_acceptDataSumLen + 3) * 2,
                    (_acceptDataSumLen + 3) * 2 + 2))) {
              //数据接收成功
              _receiveData1(_acceptData!);
              _acceptData = '';
              _acceptDatalen = 0;
              _acceptDataSumLen = 0;
              _accepting = false;
            } else {
              //print("数据校验失败");
              //[self performSelectorInBackground:@selector(calldelegateBluetoothError:) withObject:@"数据校验失败"];
              _accepting = false;
              _acceptData = '';
              _acceptDatalen = 0;
              _acceptDataSumLen = 0;
            }
          } else if ((_acceptDataSumLen + 4) > (_acceptDatalen)) {
          } else {
            //print("数据长度错误");
            //[self performSelectorInBackground:@selector(calldelegateBluetoothError:) withObject:@"数据长度错误"];
            _acceptData = null;
            _accepting = false;
            _acceptDatalen = 0;
            _acceptDataSumLen = 0;
          }
        } else {
          if (_acceptData!.length > 0) {
          } else {
            _acceptData = '';
          }
          _acceptData = _acceptData! + str;
          if (str.length >= 3) {
            if (_hexToInt(_acceptData!.substring(0, 2)) == 0x6d) {
              _acceptDataSumLen =
                  (_hexToInt(_acceptData!.substring(2, 4)) * 256) +
                      _hexToInt(_acceptData!.substring(4, 6));
              _acceptDatalen = _acceptData!.length ~/ 2;
              //判断长度
              if (_acceptDatalen == (_acceptDataSumLen + 4)) {
                var sum = 0;
                for (var i = 0; i < _acceptDatalen - 1; i++) {
                  sum =
                      sum ^ _hexToInt(_acceptData!.substring(i * 2, i * 2 + 2));
                }
                if (_hexToInt(_acceptData!.substring((_acceptDatalen - 1) * 2,
                        (_acceptDatalen - 1) * 2 + 2)) ==
                    sum) {
                  //数据接收成功
                  _receiveData1(_acceptData!);
                  _acceptData = '';
                  _accepting = false;
                  _acceptDatalen = 0;
                  _acceptDataSumLen = 0;
                } else {
                  //print("数据校验失败");
                  //[self performSelectorInBackground:@selector(calldelegateBluetoothError:) withObject:@"数据校验失败"];
                  _acceptData = '';
                  _accepting = false;
                  _acceptDatalen = 0;
                  _acceptDataSumLen = 0;
                }
              } else if (str.length / 2 < (_acceptDataSumLen + 4)) {
                // 数据长度不够需要再次接受
                _accepting = true;
              } else {
                //[self performSelectorInBackground:@selector(calldelegateBluetoothError:) withObject:@"数据长度错误"];
                _acceptData = '';
                _acceptDatalen = 0;
                _acceptDataSumLen = 0;
                _accepting = false;
              }
            }
          } else {}
        }
      }
    });
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

  List<int> _strToIntArr(String str) {
    List<int> arr = [];
    for (int i = 0; i < str.length / 2; i++) {
      int a = _hexToInt(str.substring(i * 2, i * 2 + 2));
      arr.add(a);
    }
    return arr;
  }

  String _intToHex(int num) {
    String str1 = num.toRadixString(16);
    if (str1.length % 2 != 0) {
      str1 = '0' + str1;
    }
    return str1.toUpperCase();
  }

  String _nfcCompay(int id) {
    if (id == 1) {
      return 'Union Pay';
    } else if (id == 2) {
      return 'VISA';
    } else if (id == 3) {
      return 'Master';
    } else if (id == 4) {
      return 'Discover';
    } else if (id == 5) {
      return 'AE';
    } else if (id == 6) {
      return 'JCB';
    } else {
      return 'Unknown';
    }
  }

  int _hexToInt(String hex) {
    int val = 0;
    int len = hex.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = hex.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new FormatException("Invalid hexadecimal value");
      }
    }
    return val;
  }

  //asc字符串转hex,313233->123
  String _ascToHex(String str) {
    if (str.length % 2 != 0) {
      str = str.substring(0, str.length - 1);
    }
    String str1 = '';
    for (var i = 0; i < str.length / 2; i++) {
      int number = _hexToInt(str.substring(i * 2, i * 2 + 2));
      str1 = str1 + String.fromCharCode(number);
    }
    return str1;
  }

  //hex转asc字符串,123->313233
  String _hexToAsc(String str) {
    List<int> arr = str.codeUnits;
    return _arrToStr(arr);
  }

  _sendComd(String commandStr) async {
    //m6pWriteChar1.write();
    int length1 = (commandStr.length ~/ 2) ~/ 256;
    int length2 = (commandStr.length ~/ 2) % 256;
    List<int> arr = [0x4d, length1, length2];
    arr.addAll(_strToIntArr(commandStr));

    //算异或和
    int xor = 0;
    for (int i = 0; i < arr.length; i++) {
      xor = xor ^ arr[i];
    }
    arr.add(xor);
    print('sendCommand:' + _arrToStr(arr));
    //分包发送
    for (int i = 0; i < arr.length ~/ _bluetoothNumber; i++) {
      List<int> arr1 = arr.sublist(
          i * _bluetoothNumber, i * _bluetoothNumber + _bluetoothNumber);
      await _m6pWriteChar1.write(arr1);
    }
    if (arr.length % _bluetoothNumber != 0) {
      List<int> arr1 = arr.sublist(
          (arr.length ~/ _bluetoothNumber) * _bluetoothNumber,
          (arr.length % _bluetoothNumber) +
              ((arr.length ~/ _bluetoothNumber) * _bluetoothNumber));
      await _m6pWriteChar1.write(arr1);
    }
  }

  //搜索蓝牙
  Stream<BleDevice> startScan() async* {
    await _flutterBlue.stopScan();
    _blueList = [];
    yield* _flutterBlue.scan().transform(
        StreamTransformer<ScanResult, BleDevice>.fromHandlers(
            handleData: (ScanResult data, sink) {
      var device = data.device;
      if (device.name.length > 0) {
        var isExist = false;
        for (var i = 0; i < _blueList.length; i++) {
          var blue1 = _blueList[i];
          if (blue1.name == device.name) {
            isExist = true;
            break;
          }
        }
        if (!isExist) {
          _blueList.add(device);
          BleDevice scanResult1 = BleDevice();
          scanResult1.name = data.device.name;
          scanResult1.UUID = data.device.id.toString();
          scanResult1.rssi = data.rssi;
          sink.add(scanResult1);
          //print(device);
        }
      }
    }));
  }

  //连接蓝牙
  Future<bool> connectDevice(BleDevice device) async {
    await _flutterBlue.stopScan();
    bool isConnect = false;
    bool isConnect1 = false;
    bool isConnect2 = false;
    for (BluetoothDevice bleDevice in _blueList) {
      if (bleDevice.id.toString() == device.UUID) {
        try {
          await bleDevice.connect(
              autoConnect: false, timeout: Duration(seconds: 10));
        } catch (e) {
          print(e.toString());
          return false;
        }
        List<BluetoothService> services = await bleDevice.discoverServices();
        services.forEach((service) {
          if (service.uuid.toString().toUpperCase() == _m6pService) {
            List<BluetoothCharacteristic> characteristics =
                service.characteristics;
            characteristics.forEach((characteristic) {
              if (characteristic.uuid.toString().toUpperCase() ==
                  _m6pNotiChar) {
                _receiveData(characteristic);
                isConnect1 = true;
              }
              if (characteristic.uuid.toString().toUpperCase() ==
                  _m6pWriteChar) {
                _m6pWriteChar1 = characteristic;
                isConnect2 = true;
                print(isConnect2);
              }
            });
          }
        });
        if (isConnect1 && isConnect2) {
          isConnect = true;
          _connectBleDevice = bleDevice;
        } else {
          await bleDevice.disconnect();
        }
      }
    }
    return isConnect;
  }

  //停止搜索蓝牙
  stopScan() async {
    await _flutterBlue.stopScan();
  }

  //断开蓝牙
  disconnect() async {
    await _connectBleDevice.disconnect();
    if (_notifySubscription != null) {
      _notifySubscription.cancel();
    }
  }

  late GetTerminalInfoCallback _getTerminalInfoCallback1;
  //获取设备类型
  getTerminalInfo(
      void Function(TerminalInfo? terminalInfo, int status)
          terminalInfoCallback) {
    _getTerminalInfoCallback1 = terminalInfoCallback;
    _sendComd('00091b100000');
  }

  late RequestDataEncryptCallback _requestDataEncryptCallback1;
  //请求数据加密
  requestDataEncrypt(
      String encryptData,
      String keyType,
      String random,
      void Function(String? encryptedData, int status)
          requestDataEncryptCallback) {
    _requestDataEncryptCallback1 = requestDataEncryptCallback;
    String str = '';
    if ((encryptData != '') && (encryptData != null)) {
      str = str + _getTLVStr('1F0E', encryptData);
    }
    if ((keyType != '') && (keyType != null)) {
      str = str + _getTLVStr('1F04', keyType);
    }
    if ((random != '') && (random != null)) {
      str = str + _getTLVStr('1F07', encryptData);
    }
    String str1 = '00020410' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  late CalculateMacCallback _calculateMacCallback1;
  //计算mac
  calculateMac(String data, String keyType,
      void Function(String? mac, int status) calculateMacCallback) {
    _calculateMacCallback1 = calculateMacCallback;
    String dataStr = _getTLVStr('1F0F', data);
    dataStr = '1F0401' + keyType + dataStr;
    int len = dataStr.length ~/ 2;
    String str =
        '00020610' + _intToHex(len ~/ 256) + _intToHex(len % 256) + dataStr;
    _sendComd(str);
  }

  late DownloadWorkKeyCallback _downloadWorkKeyCallback1;
  //下载工作密钥
  downloadWorkKey(String keyType, String pinKey, String macKey, String desKey,
      void Function(int status) downloadWorkKeyCallback) {
    _downloadWorkKeyCallback1 = downloadWorkKeyCallback;
    String str = '1F04' + _intToHex(keyType.length ~/ 2) + keyType;
    int a = 0;
    String str1 = '';
    if ((pinKey != '') && (pinKey != null)) {
      a = a + 1;
      str1 = str1 + _intToHex(pinKey.length ~/ 2) + pinKey;
    }
    if ((macKey != '') && (macKey != null)) {
      a = a + 1;
      str1 = str1 + _intToHex(macKey.length ~/ 2) + macKey;
    }
    if ((desKey != '') && (desKey != null)) {
      a = a + 1;
      str1 = str1 + _intToHex(desKey.length ~/ 2) + desKey;
    }
    str = str + _getTLVStr('1F10', _intToHex(a) + str1);
    str = '00021010' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str);
  }

  late PINEntryCallback _pinEntryCallback1;
  //pin加密
  pinEntry(String pin, String keyType,
      void Function(String? pin, int status) pinEntryCallback) {
    _pinEntryCallback1 = pinEntryCallback;
    pin = _hexToAsc(pin);
    String data = '1F0E' + _intToHex(pin.length ~/ 2) + pin;
    data = '1F0401' + keyType + data;
    int len = data.length ~/ 2;
    String str =
        '00022010' + _intToHex(len ~/ 256) + _intToHex(len % 256) + data;
    _sendComd(str);
  }

  late WaitingcardCallback _waitingcardCallback1;
  late ICCardInsertionCallback _icCardInsertionCallback1;
  late NFCCardDetectionCallback _nfcCardDetectionCallback1;
  late ReadCardCallback _readCardCallback1;
  //刷卡
  startEmvProcess(
      int timeout,
      TradeData tradeData,
      void Function() waitingcardCallback,
      void Function() icCardInsertionCallback,
      void Function() nfcCardDetectionCallback,
      void Function(CardInfo? cardInfo, int status) readCardCallback) {
    _waitingcardCallback1 = waitingcardCallback;
    _icCardInsertionCallback1 = icCardInsertionCallback;
    _nfcCardDetectionCallback1 = nfcCardDetectionCallback;
    _readCardCallback1 = readCardCallback;
    int len = 0;
    String str = '';
    //刷卡模式
    String str1 = _getTLVStr('1F01', tradeData.swipeMode);
    str = str + str1;
    len = len + str1.length ~/ 2;
    //控制标志
    str1 = _getTLVStr('1F02', tradeData.sign);
    str = str + str1;
    len = len + str1.length ~/ 2;
    //系统时间
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString();
    if (month.length != 2) {
      month = '0' + month;
    }
    String day = now.day.toString();
    if (day.length != 2) {
      day = '0' + day;
    }
    String hour = now.hour.toString();
    if (hour.length != 2) {
      hour = '0' + hour;
    }
    String minute = now.minute.toString();
    if (minute.length != 2) {
      minute = '0' + minute;
    }
    String second = now.second.toString();
    if (second.length != 2) {
      second = '0' + second;
    }
    String time = year + month + day + hour + minute + second;
    String str2 = _getTLVStr('1F03', time);
    str = str + str2;
    len = len + str2.length ~/ 2;
    //加密算法
    if (tradeData.encryptionAlg != null) {
      String str1 = _getTLVStr('1F04', tradeData.encryptionAlg!);
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //随机数
    str1 = _getTLVStr('1F07', tradeData.random);
    str = str + str1;
    len = len + str1.length ~/ 2;
    //交易金额
    if (tradeData.cash != null) {
      String str1 = _getTLVStr('1F08', _hexToAsc(tradeData.cash!));
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //附加交易信息
    if (tradeData.transactionInfo != null) {
      String dateTime = _getTLVStr('9A', time.substring(0, 6));
      String dateTime2 = _getTLVStr('9F21', time.substring(6));
      String currencyCode =
          _getTLVStr('5F2A', tradeData.transactionInfo!.currencyCode);
      String type = _getTLVStr('9C', tradeData.transactionInfo!.type);
      String str1 =
          _getTLVStr('1F09', dateTime + dateTime2 + currencyCode + type);
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //回显数据
    if (tradeData.displayData != null) {
      String str1 = _getTLVStr('1F0B', tradeData.displayData!);
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //刷卡标题
    if (tradeData.swipeTitle != null) {
      String str1 =
          _getTLVStr('1F0C', _arrToStr(gbk.encode(tradeData.swipeTitle!)));
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //密码输入标题
    if (tradeData.pinTitle != null) {
      String str1 =
          _getTLVStr('1F0D', _arrToStr(gbk.encode(tradeData.pinTitle!)));
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    String sendStr = '0002A0' +
        _intToHex(timeout) +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        str;
    _sendComd(sendStr);
  }

  late SendOnlineProcessCallback _sendOnlineProcessCallback1;
  //回写
  sendOnlineProcessResult(
      String data,
      void Function(
              int onlineResult, String? scriptResult, String? data, int status)
          sendOnlineProcessCallback) {
    _sendOnlineProcessCallback1 = sendOnlineProcessCallback;
    int len = data.length ~/ 2;
    String str =
        '0002A110' + _intToHex(len ~/ 256) + _intToHex(len % 256) + data;
    _sendComd(str);
  }

  late PowerOnAPDUCallback _powerOnAPDUCallback1;
  //开始NFC/IC
  powerOnAPDU(int type, int timeout,
      void Function(int type, String data, int status) powerOnAPDUCallback) {
    _powerOnAPDUCallback1 = powerOnAPDUCallback;
    String str = '0002E0' + _intToHex(timeout) + '0001' + _intToHex(type);
    _sendComd(str);
  }

  late PowerOffAPDUCallback _powerOffAPDUCallback1;
  //结束NFC/IC
  powerOffAPDU(void Function(int status) powerOffAPDUCallback) {
    _powerOffAPDUCallback1 = powerOffAPDUCallback;
    _sendComd('0002E1100000');
  }

  late SendApduCallback _sendApduCallback1;
  //透传
  sendApdu(int type, List<String> apduData, int timeout,
      void Function(List<String> data, int status) sendApduCallback) {
    _sendApduCallback1 = sendApduCallback;
    String str = '';
    for (String str1 in apduData) {
      str = str + _intToHex(str1.length ~/ 2 + 1) + '30' + str1;
    }
    int len = 2 + str.length ~/ 2;
    String str2 = '0002E2' +
        _intToHex(timeout) +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        _intToHex(type) +
        _intToHex(apduData.length) +
        str;
    _sendComd(str2);
  }

  late SetAutomaticShutdownCallback _setAutomaticShutdownCallback1;
  //设置自动关机时间
  setAutomaticShutdown(
      int time, void Function(int status) setAutomaticShutdownCallback) {
    _setAutomaticShutdownCallback1 = setAutomaticShutdownCallback;
    String str = '000908100001' + _intToHex(time);
    _sendComd(str);
  }

  late StopTradeCallback _stopTradeCallback1;
  //退出
  stopTrade(void Function(int status) stopTradeCallback) {
    _stopTradeCallback1 = stopTradeCallback;
    _sendComd("000907100000");
  }

  late DownloadTerminalInfoCallback _downloadTerminalInfoCallback1;
  //终端信息下载
  downloadTerminalInfo(String tusn, String bluetoothMac,
      void Function(int status) downloadTerminalInfoCallback) {
    _downloadTerminalInfoCallback1 = downloadTerminalInfoCallback;
    String str = '';
    if ((tusn != '') && (tusn != null)) {
      str = str + _getTLVStr('1F80', tusn);
    }
    if ((bluetoothMac != '') && (bluetoothMac != null)) {
      str = str + _getTLVStr('1F81', bluetoothMac);
    }
    String str1 = '00092010' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  late DownloadAIDParametersCallback _downloadAIDParametersCallback1;
  //更新AID
  downloadAIDParameters(AIDParameters aidParameters,
      void Function(int status) downloadAIDParametersCallback) {
    _downloadAIDParametersCallback1 = downloadAIDParametersCallback;
    _aidOrRid = 1;
    String str = '31';
    if ((aidParameters.aid != null) && (aidParameters.aid != '')) {
      str = str +
          '9F06' +
          _intToHex(aidParameters.aid!.length ~/ 2) +
          aidParameters.aid!;
    }
    str = str +
        'DF01' +
        _intToHex(_intToHex(aidParameters.asi).length ~/ 2) +
        _intToHex(aidParameters.asi);
    if ((aidParameters.appVerNum != null) && (aidParameters.appVerNum != '')) {
      str = str +
          '9F09' +
          _intToHex(aidParameters.appVerNum!.length ~/ 2) +
          aidParameters.appVerNum!;
    }
    if ((aidParameters.tacDefault != null) &&
        (aidParameters.tacDefault != '')) {
      str = str +
          'DF11' +
          _intToHex(aidParameters.tacDefault!.length ~/ 2) +
          aidParameters.tacDefault!;
    }
    if ((aidParameters.tacOnline != null) && (aidParameters.tacOnline != '')) {
      str = str +
          'DF12' +
          _intToHex(aidParameters.tacOnline!.length ~/ 2) +
          aidParameters.tacOnline!;
    }
    if ((aidParameters.tacDecline != null) &&
        (aidParameters.tacDecline != '')) {
      str = str +
          'DF13' +
          _intToHex(aidParameters.tacDecline!.length ~/ 2) +
          aidParameters.tacDecline!;
    }
    if ((aidParameters.floorLimit != null) &&
        (aidParameters.floorLimit != '')) {
      str = str +
          '9F1B' +
          _intToHex(aidParameters.floorLimit!.length ~/ 2) +
          aidParameters.floorLimit!;
    }
    if ((aidParameters.threshold != null) && (aidParameters.threshold != '')) {
      str = str +
          'DF15' +
          _intToHex(aidParameters.threshold!.length ~/ 2) +
          aidParameters.threshold!;
    }
    str = str +
        'DF16' +
        _intToHex(_intToHex(aidParameters.maxTargetPercent).length ~/ 2) +
        _intToHex(aidParameters.maxTargetPercent);
    str = str +
        'DF17' +
        _intToHex(_intToHex(aidParameters.targetPercent).length ~/ 2) +
        _intToHex(aidParameters.targetPercent);
    if ((aidParameters.termDDOL != null) && (aidParameters.termDDOL != '')) {
      str = str +
          'DF14' +
          _intToHex(aidParameters.termDDOL!.length ~/ 2) +
          aidParameters.termDDOL!;
    }
    if ((aidParameters.vlptranslimit != null) &&
        (aidParameters.vlptranslimit != '')) {
      str = str +
          'DF20' +
          _intToHex(aidParameters.vlptranslimit!.length ~/ 2) +
          aidParameters.vlptranslimit!;
    }
    if ((aidParameters.termcvmlimit != null) &&
        (aidParameters.termcvmlimit != '')) {
      str = str +
          'DF21' +
          _intToHex(aidParameters.termcvmlimit!.length ~/ 2) +
          aidParameters.termcvmlimit!;
    }
    if ((aidParameters.clessofflinelimitamt != null) &&
        (aidParameters.clessofflinelimitamt != '')) {
      str = str +
          'DF19' +
          _intToHex(aidParameters.clessofflinelimitamt!.length ~/ 2) +
          aidParameters.clessofflinelimitamt!;
    }
    if ((aidParameters.otherTLV != null) && (aidParameters.otherTLV != '')) {
      str = str + aidParameters.otherTLV!;
    }
    int len = 2 + str.length ~/ 2;
    String str1 = '00092210' +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        '0101' +
        str;
    _sendComd(str1);
  }

  late ClearAIDParametersCallback _clearAIDParametersCallback1;
  //删除AID
  clearAIDParameters(void Function(int status) clearAIDParametersCallback) {
    _clearAIDParametersCallback1 = clearAIDParametersCallback;
    _aidOrRid = 2;
    _sendComd(
        '0009221000720100319F0607A0000000031010DF0101009F08020030DF1105D84000A800DF1205D84004F800DF130500100000009F1B0400002710DF150400000000DF160100DF170100DF14039F3704DF1801019F7B06000000080000DF1906000000050000DF2006000000100000DF2106000000010000');
  }

  late DownloadPublicKeyCallback _downloadPublicKeyCallback1;
  //更新RID
  downloadPublicKey(CAPublicKey caPublicKey,
      void Function(int status) downloadPublicKeyCallback) {
    _downloadPublicKeyCallback1 = downloadPublicKeyCallback;
    _aidOrRid = 3;
    String str = '31';
    if ((caPublicKey.rid != null) && (caPublicKey.rid != '')) {
      str = str +
          '9F06' +
          _intToHex(caPublicKey.rid!.length ~/ 2) +
          caPublicKey.rid!;
    }
    str = str +
        '9F22' +
        _intToHex(_intToHex(caPublicKey.capki).length ~/ 2) +
        _intToHex(caPublicKey.capki);
    str = str +
        'DF07' +
        _intToHex(_intToHex(caPublicKey.hashInd).length ~/ 2) +
        _intToHex(caPublicKey.hashInd);
    if ((caPublicKey.expireDate != null) && (caPublicKey.expireDate != '')) {
      str = str +
          'DF05' +
          _intToHex(caPublicKey.expireDate!.length ~/ 2) +
          caPublicKey.expireDate!;
    }
    str = str +
        'DF06' +
        _intToHex(_intToHex(caPublicKey.arithInd).length ~/ 2) +
        _intToHex(caPublicKey.arithInd);
    if ((caPublicKey.modul != null) && (caPublicKey.modul != '')) {
      str = str +
          'DF0281' +
          _intToHex(caPublicKey.modul!.length ~/ 2) +
          caPublicKey.modul!;
    }
    if ((caPublicKey.exponent != null) && (caPublicKey.exponent != '')) {
      str = str +
          'DF04' +
          _intToHex(caPublicKey.exponent!.length ~/ 2) +
          caPublicKey.exponent!;
    }
    if ((caPublicKey.checkSum != null) && (caPublicKey.checkSum != '')) {
      str = str +
          'DF03' +
          _intToHex(caPublicKey.checkSum!.length ~/ 2) +
          caPublicKey.checkSum!;
    }
    int len = 2 + str.length ~/ 2;
    String str1 = '00092210' +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        '0001' +
        str;
    _sendComd(str1);
  }

  late ClearPublicKeyCallback _clearPublicKeyCallback1;
  //删除RID
  clearPublicKey(void Function(int status) clearPublicKeyCallback) {
    _clearPublicKeyCallback1 = clearPublicKeyCallback;
    _aidOrRid = 4;
    _sendComd(
        '0009221000ED0000319F0605A0000003339F220103DF050420241231DF060101DF070101DF0281B0B0627DEE87864F9C18C13B9A1F025448BF13C58380C91F4CEBA9F9BCB214FF8414E9B59D6ABA10F941C7331768F47B2127907D857FA39AAF8CE02045DD01619D689EE731C551159BE7EB2D51A372FF56B556E5CB2FDE36E23073A44CA215D6C26CA68847B388E39520E0026E62294B557D6470440CA0AEFC9438C923AEC9B2098D6D3A1AF5E8B1DE36F4B53040109D89B77CAFAF70C26C601ABDF59EEC0FDC8A99089140CD2E817E335175B03B7AA33DDF040103DF031487F0CD7C0E86F38F89A66F8C47071A8B88586F26');
  }

  late SetTerminalDateTimeCallback _setTerminalDateTimeCallback1;
  //设置终端时间，格式yyyyMMddHHmmss  20190807144120
  setTerminalDateTime(
      String datetime, void Function(int status) setTerminalDateTimeCallback) {
    _setTerminalDateTimeCallback1 = setTerminalDateTimeCallback;
    String str = '0009311000' + _intToHex(datetime.length ~/ 2) + datetime;
    _sendComd(str);
  }

  late GetTerminalDateTimeCallback _getTerminalDateTimeCallback1;
  //获取终端时间
  getTerminalDateTime(
      void Function(String time, int status) getTerminalDateTimeCallback) {
    _getTerminalDateTimeCallback1 = getTerminalDateTimeCallback;
    _sendComd('000932100000');
  }

  late GetBatteryPowerCallback _getBatteryPowerCallback1;
  //获取电量
  getBatteryPower(
      void Function(String power, int status) getBatteryPowerCallback) {
    _getBatteryPowerCallback1 = getBatteryPowerCallback;
    _sendComd('000913100000');
  }

  //关机
  shutDown() {
    _sendComd('000980100000');
  }

  late FirmwareUpdateRequest _firmwareUpdateRequest1;
  late FirmwareUpdateRequestProgress _firmwareUpdateRequestProgress1;
  //固件升级
  firmwareUpdateRequest(
      String type,
      List<int> data,
      void Function(int progress) firmwareUpdateRequestProgress,
      void Function(int status) firmwareUpdateRequest) {
    _firmwareUpdateRequest1 = firmwareUpdateRequest;
    _firmwareUpdateRequestProgress1 = firmwareUpdateRequestProgress;
    _downloadType = type;
    _downloadData = data;
    _offest = 0;
    _requestDataPage(0);
  }

  //查询m6下载是否成功
  _querryUpDate() {
    String str = '0005071000045F0101' + _downloadType;
    _sendComd(str);
  }

  _requestDataPage(int offest1) {
    List<int> data1 = [];
    if (_downloadData.length > (_offest + _DOWNLOAD_PAGENUM)) {
      data1 = _downloadData.sublist(_offest, _offest + _DOWNLOAD_PAGENUM);
    } else {
      data1 = _downloadData.sublist(_offest, _downloadData.length);
    }
    int length = _downloadData.length;
    String str = '5F0101' +
        _downloadType +
        _getTLVStr('5F02', _hexToAsc(length.toString())) +
        _getTLVStr('5F03', _crc32(_downloadData)) +
        _getTLVStr('5F04', _hexToAsc(_offest.toString())) +
        _getTLVStr('5F06', _arrToStr(data1));
    int length1 = str.length ~/ 2;
    str =
        '00050610' + _intToHex(length1 ~/ 256) + _intToHex(length1 % 256) + str;
    _sendComd(str);
  }

  String _crc32(List<int> str) {
    String table =
        "00000000 77073096 EE0E612C 990951BA 076DC419 706AF48F E963A535 9E6495A3 0EDB8832 79DCB8A4 E0D5E91E 97D2D988 09B64C2B 7EB17CBD E7B82D07 90BF1D91 1DB71064 6AB020F2 F3B97148 84BE41DE 1ADAD47D 6DDDE4EB F4D4B551 83D385C7 136C9856 646BA8C0 FD62F97A 8A65C9EC 14015C4F 63066CD9 FA0F3D63 8D080DF5 3B6E20C8 4C69105E D56041E4 A2677172 3C03E4D1 4B04D447 D20D85FD A50AB56B 35B5A8FA 42B2986C DBBBC9D6 ACBCF940 32D86CE3 45DF5C75 DCD60DCF ABD13D59 26D930AC 51DE003A C8D75180 BFD06116 21B4F4B5 56B3C423 CFBA9599 B8BDA50F 2802B89E 5F058808 C60CD9B2 B10BE924 2F6F7C87 58684C11 C1611DAB B6662D3D 76DC4190 01DB7106 98D220BC EFD5102A 71B18589 06B6B51F 9FBFE4A5 E8B8D433 7807C9A2 0F00F934 9609A88E E10E9818 7F6A0DBB 086D3D2D 91646C97 E6635C01 6B6B51F4 1C6C6162 856530D8 F262004E 6C0695ED 1B01A57B 8208F4C1 F50FC457 65B0D9C6 12B7E950 8BBEB8EA FCB9887C 62DD1DDF 15DA2D49 8CD37CF3 FBD44C65 4DB26158 3AB551CE A3BC0074 D4BB30E2 4ADFA541 3DD895D7 A4D1C46D D3D6F4FB 4369E96A 346ED9FC AD678846 DA60B8D0 44042D73 33031DE5 AA0A4C5F DD0D7CC9 5005713C 270241AA BE0B1010 C90C2086 5768B525 206F85B3 B966D409 CE61E49F 5EDEF90E 29D9C998 B0D09822 C7D7A8B4 59B33D17 2EB40D81 B7BD5C3B C0BA6CAD EDB88320 9ABFB3B6 03B6E20C 74B1D29A EAD54739 9DD277AF 04DB2615 73DC1683 E3630B12 94643B84 0D6D6A3E 7A6A5AA8 E40ECF0B 9309FF9D 0A00AE27 7D079EB1 F00F9344 8708A3D2 1E01F268 6906C2FE F762575D 806567CB 196C3671 6E6B06E7 FED41B76 89D32BE0 10DA7A5A 67DD4ACC F9B9DF6F 8EBEEFF9 17B7BE43 60B08ED5 D6D6A3E8 A1D1937E 38D8C2C4 4FDFF252 D1BB67F1 A6BC5767 3FB506DD 48B2364B D80D2BDA AF0A1B4C 36034AF6 41047A60 DF60EFC3 A867DF55 316E8EEF 4669BE79 CB61B38C BC66831A 256FD2A0 5268E236 CC0C7795 BB0B4703 220216B9 5505262F C5BA3BBE B2BD0B28 2BB45A92 5CB36A04 C2D7FFA7 B5D0CF31 2CD99E8B 5BDEAE1D 9B64C2B0 EC63F226 756AA39C 026D930A 9C0906A9 EB0E363F 72076785 05005713 95BF4A82 E2B87A14 7BB12BAE 0CB61B38 92D28E9B E5D5BE0D 7CDCEFB7 0BDBDF21 86D3D2D4 F1D4E242 68DDB3F8 1FDA836E 81BE16CD F6B9265B 6FB077E1 18B74777 88085AE6 FF0F6A70 66063BCA 11010B5C 8F659EFF F862AE69 616BFFD3 166CCF45 A00AE278 D70DD2EE 4E048354 3903B3C2 A7672661 D06016F7 4969474D 3E6E77DB AED16A4A D9D65ADC 40DF0B66 37D83BF0 A9BCAE53 DEBB9EC5 47B2CF7F 30B5FFE9 BDBDF21C CABAC28A 53B39330 24B4A3A6 BAD03605 CDD70693 54DE5729 23D967BF B3667A2E C4614AB8 5D681B02 2A6F2B94 B40BBE37 C30C8EA1 5A05DF1B 2D02EF8D";
    int n = 0; //a number between 0 and 255
    int x = 0; //an hex number
    int crc = 0;
    crc = crc ^ (-1);
    //List<int> str = _strToIntArr(data);
    for (int i = 0, iTop = str.length; i < iTop; i++) {
      n = (crc ^ str[i]) & 0xFF;
      x = _hexToInt(table.substring(n * 9, n * 9 + 8));
      crc = (crc.toUnsigned(32) >> 8) ^ x;
    }
    return (crc ^ (-1)).toUnsigned(32).toRadixString(16).toUpperCase();
  }
}
