import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'dart:async';
import 'M6pBleBean.dart';

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
    M6pTerminalInfo? terminalInfo, int status);
//请求数据加密回调
typedef RequestDataEncryptCallback = void Function(
    String? encryptedData, String? ksn, int status);
//请求回显回调
typedef RequestDisplayCallback = void Function(int status);
//请求输入回调
typedef RequestInputCallback = void Function(String? input, int status);
//请求输入卡号和有效期回调
typedef RequestInputAndCheckCallback = void Function(
    String? cardNo, String? cardexpiryDate, int status);
//错误回调
typedef RequestErrorCallback = void Function(int errorID, String msg);
//计算MAC回调
typedef CalculateMacCallback = void Function(
    String? mac, String? ksn, int status);
//下载工作密钥
typedef DownloadWorkKeyCallback = void Function(int status);
//pin加密
typedef PINEntryCallback = void Function(String? pin, int status);
// 密钥更新
// 更新KEK密钥
typedef DownloadKEKCallBack = void Function(int status);
// 更新MK DUKPT 密钥
typedef DownloadMKDUKPTCallBack = void Function(int status);
// 更新 SK 密钥
typedef DownloadSKCallBack = void Function(int status);
//获取密钥信息回调
typedef GetSecretKeyInfoCallback = void Function(
    String? keyInfo, String? kcv, String? ksn, int status);

//刷卡
//等待刷卡
typedef WaitingcardCallback = void Function();
//卡片已插入
typedef ICCardInsertionCallback = void Function();
//NFC已刷
typedef NFCCardDetectionCallback = void Function();
//返回卡片信息
typedef ReadCardCallback = void Function(M6pCardInfo? cardInfo, int status);
//读卡错误回调
typedef ReadCardError = void Function(int errorID, String msg);
//读卡错误降级回调
typedef ReadCardDegradeError = void Function(int errorID, String msg, int code);

//回写
typedef SendOnlineProcessCallback = void Function(
    int onlineResult, String? scriptResult, String? data, int status);

//开始NFC/IC
typedef PowerOnAPDUCallback = void Function(
    String type, String uuid, String data, int status);
//结束NFC/IC
typedef PowerOffAPDUCallback = void Function(int status);
//NFC/IC apdu
typedef SendApduCallback = void Function(List<String> data, int status);

// Mifare Card
// Mifare 卡扇区
typedef OperateMifareCallbock = void Function(int status, String msg);
// // Mifare 写数据回调
// typedef WriteMifareCallbock = void Function(int status, String str);

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
//大数据
typedef TestData = void Function(String str, int status);

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
    //大数据
    if (resCode1 == 0x09 && resCode2 == 0xff) {
      if (res != 0) {
        _testDataCallback1('', res);
      } else {
        _testDataCallback1(dataStr, res);
      }
    }
    //获取设备类型
    if (resCode1 == 0x09 && resCode2 == 0x1b) {
      M6pTerminalInfo terminalInfo = M6pTerminalInfo();
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
            terminalInfo.appVersion = _ascToHex(tlv.value!);
          }
          //App版本日期
          if (tlv.tag == '1F85') {
            terminalInfo.appVersionDate = _ascToHex(tlv.value!);
          }
          //Kernel版本
          if (tlv.tag == '1F86') {
            terminalInfo.kernelVersion = _ascToHex(tlv.value!);
          }
          //Kernel版本日期
          if (tlv.tag == '1F87') {
            terminalInfo.kernelVersionDate = _ascToHex(tlv.value!);
          }
          //HW版本
          if (tlv.tag == '1F88') {
            terminalInfo.hardwareVersion = _ascToHex(tlv.value!);
          }
          //SW版本
          if (tlv.tag == '1F89') {
            terminalInfo.softVersion = _ascToHex(tlv.value!);
          }
          //终端ID
          if (tlv.tag == '1F44') {
            terminalInfo.sn = tlv.value;
          }
          //终端模式
          if (tlv.tag == '1F8C') {
            terminalInfo.operationMode = tlv.value;
          }
          //语言
          if (tlv.tag == '1F8A') {
            terminalInfo.language = _ascToHex(tlv.value!);
          }
        }
        _getTerminalInfoCallback1(terminalInfo, res);
        // _queryTMS(
        //     terminalInfo.tusn.toString(),
        //     terminalInfo.appVersion.toString(),
        //     terminalInfo.kernelVersion.toString());
      }
    }
    //请求数据加密
    if (resCode1 == 0x02 && resCode2 == 0x04) {
      if (res != 0) {
        _requestDataEncryptCallback1('', '', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? str = '';
        String? ksn = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F4D') {
            str = tlv.value;
          }
          if (tlv.tag == '1F56') {
            ksn = tlv.value;
          }
        }
        _requestDataEncryptCallback1(str, ksn, res);
      }
    }
    //获取密钥信息
    if (resCode1 == 0x02 && resCode2 == 0x09) {
      if (res != 0) {
        _getSecretKeyInfoCallback1('', '', '', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? keyInfo = '';
        String? kcv = '';
        String? ksn = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F5B') {
            keyInfo = tlv.value;
          }
          if (tlv.tag == '1F5C') {
            kcv = tlv.value;
          }
          if (tlv.tag == '1F56') {
            ksn = tlv.value;
          }
        }
        _getSecretKeyInfoCallback1(keyInfo, kcv, ksn, res);
      }
    }
    //请求回显
    if (resCode1 == 0x02 && resCode2 == 0xAA) {
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
      }
      if (res == 0x0A) {
        _requestErrorCallback1(res, 'user quit');
        return;
      }
      if (res == 0x01) {
        _requestErrorCallback1(res, 'user operation time out');
        return;
      }
      _requestDisplayCallback1(res);
    }
    //请求输入控制
    if (resCode1 == 0x02 && resCode2 == 0xAB) {
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
      }
      if (res == 0x0A) {
        _requestErrorCallback1(res, 'user quit');
        return;
      }
      if (res == 0x01) {
        _requestErrorCallback1(res, 'user operation time out');
        return;
      }
      if (res != 0) {
        _requestInputCallback1('', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? input = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F60') {
            input = tlv.value;
          }
        }
        _requestInputCallback1(_ascToHex(input!), res);
      }
    }
    //输入卡号和有效期回调
    if (resCode1 == 0x02 && resCode2 == 0xAC) {
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
      }
      if (res == 0x0A) {
        _requestErrorCallback1(res, 'user quit');
        return;
      }
      if (res == 0x01) {
        _requestErrorCallback1(res, 'user operation time out');
        return;
      }
      if (res != 0) {
        _requestInputAndCheckCallback1('', '', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? cardNo = '';
        String? cardexpiryDate = '';

        for (TLV tlv in arr) {
          if (tlv.tag == '1F51') {
            cardNo = tlv.value;
          }
          if (tlv.tag == '1F4E') {
            cardexpiryDate = tlv.value;
          }
        }
        _requestInputAndCheckCallback1(
            _ascToHex(cardNo!), _ascToHex(cardexpiryDate!), res);
      }
    }
    //计算mac
    if (resCode1 == 0x02 && resCode2 == 0x06) {
      if (res != 0) {
        _calculateMacCallback1('', '', res);
      } else {
        List<TLV> arr = _getTLVArr(dataStr);
        String? str = '';
        String? ksn = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F4C') {
            str = tlv.value;
          }
          if (tlv.tag == '1F56') {
            ksn = tlv.value;
          }
        }
        _calculateMacCallback1(str, ksn, res);
      }
    }
    //更新工作密钥
    if (resCode1 == 0x02 && resCode2 == 0x10) {
      _downloadWorkKeyCallback1(res);
    }
    //更新KEK密钥
    if (resCode1 == 0x02 && resCode2 == 0x0D) {
      _downloadKEKCallBack(res);
    }
    //更新MK DUKPT密钥
    if (resCode1 == 0x02 && resCode2 == 0x0E) {
      _downloadMKDUKPTCallBack(res);
    }
    //更新 SK 密钥
    if (resCode1 == 0x02 && resCode2 == 0x0F) {
      _downloadSKCallBack(res);
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
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
      }
      if (res == 0x89) {
        return;
      }
      // IC卡读卡失败
      if (res == 0x87) {
        _readCardError(res, 'read card error ' + str);
        return;
      }
      if (res == 0x86) {
        _readCardError(res, 'read card error ' + str);
        return;
      }
      if (res == 0x91) {
        _readCardError(res, 'read card error ' + str);
        return;
      }
      if (res == 0xD4) {
        _readCardError(res, 'read card error ' + str);
        return;
      }
      if (res == 0x01) {
        _readCardError(res, 'user operation time out');
        return;
      }
      if (res == 0x0A) {
        _readCardError(res, 'user quit');
        return;
      }
      if (res == 0x7c) {
        if (str.length > 18) {
          int failLength = resultBuf[7] * 256 + resultBuf[8];
          if (failLength == 4) {
            int value = _hexToInt(str.substring(18, 18 + failLength * 2));
            ByteData byteData = ByteData(4);
            byteData.setUint32(0, value, Endian.host);
            int code = byteData.getInt32(0, Endian.big);
            _readCardDegradeError(
                res, "Waiting for card insertion or swiping", code);
          }
        }
        return;
      }
      if (res == 0x7b) {
        if (str.length > 18) {
          int failLength = resultBuf[7] * 256 + resultBuf[8];
          if (failLength == 4) {
            int value = _hexToInt(str.substring(18, 18 + failLength * 2));
            ByteData byteData = ByteData(4);
            byteData.setUint32(0, value, Endian.host);
            int code = byteData.getInt32(0, Endian.big);
            _readCardDegradeError(res, "Waiting for card swiping", code);
          }
        }
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
        M6pCardInfo cardInfo = M6pCardInfo();
        if (str.length > 18) {
          int failLength = resultBuf[7] * 256 + resultBuf[8];
          cardInfo.swipeFailMessage = str.substring(18, 18 + failLength * 2);
        }
        _readCardCallback1(cardInfo, res);
      }
      return;
    }
    //回写IC卡
    if (resCode1 == 0x02 && resCode2 == 0xa1) {
      if (res != 0) {
        _sendOnlineProcessCallback1(0, '', '', res);
      } else {
        int onlineProcessResult = 0;
        String? scriptResult = '';
        String? data1 = '';
        onlineProcessResult = int.parse(dataStr.substring(0, 2));
        int scriptResultlen = int.parse(dataStr.substring(2, 4));
        if (scriptResultlen > 0) {
          scriptResult = dataStr.substring(4, scriptResultlen);
          print(scriptResult);
        }
        data1 = dataStr.substring(4 + scriptResultlen);
        print(data1);
        _sendOnlineProcessCallback1(
            onlineProcessResult, scriptResult, data1, res);
      }
    }
    //开始透传
    if (resCode1 == 0x02 && resCode2 == 0xe0) {
      if (res == 0x80) {
        _waitingcardCallback1();
        return;
        // }
        // if (res != 0) {
        //   _powerOnAPDUCallback1('0', '', '', res);
      } else {
        // TLV 格式解析
        print("resLength " + resLength.toString() + " str " + str);
        dataStr = str.substring(18, 18 + resLength * 2).toUpperCase();
        print("dataStr: " + dataStr);
        List<TLV> arr = _getTLVArr(dataStr);
        String? type = '';
        String? cardData = '';
        String? uuid = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F65') {
            type = tlv.value;
          }
          if (tlv.tag == '1F66') {
            uuid = tlv.value;
          }
          if (tlv.tag == '1F67') {
            cardData = tlv.value;
          }
        }
        // int type = resultBuf[9];
        // int len = resultBuf[8];
        // String cardData = str.substring(20, 20 + 2 * (len - 1));
        _powerOnAPDUCallback1(type!, uuid!, cardData!, res);
      }
    }
    //关闭NFC
    if (resCode1 == 0x02 && resCode2 == 0xe1) {
      _powerOffAPDUCallback1(res);
    }
    //NFC透传
    if (resCode1 == 0x02 && resCode2 == 0xe2) {
      if (res == 0) {
        dataStr = str.substring(18, 18 + resLength * 2).toUpperCase();
        print("dataStr: " + dataStr);
        List<TLV> arr = _getTLVArr(dataStr);
        String? type = '';
        String? strlist = '';
        for (TLV tlv in arr) {
          if (tlv.tag == '1F65') {
            type = tlv.value;
          }
          if (tlv.tag == '1F68') {
            strlist = tlv.value;
          }
        }
        print("type:" + type!);
        print("strlist:" + strlist!);

        if ((type == '00') || (type == '01')) {
          List<String> apduMarr = _arryAPDURespondData(strlist);
          _sendApduCallback1(apduMarr, res);
        } else if (type == '11') {
          // Mifare classic
          _operateMifareCallbock(0, strlist);
        } else if (type == '21') {
          // Mifare Desfire
          List<String> apduMarr = _arryAPDURespondData(strlist);
          _sendApduCallback1(apduMarr, res);
        }
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
        String power = '0';
        List<TLV> arr = _getTLVArr(dataStr);
        for (TLV tlv in arr) {
          if (tlv.tag == '1F5A') {
            batteryPoewr = _hexToInt(tlv.value!);
            if (batteryPoewr >= 4050) {
              //100%
              power = '100';
            } else if (batteryPoewr >= 3850) {
              //75%
              power = '75';
            } else if (batteryPoewr >= 3750) {
              // 50%
              power = '50';
            } else if (batteryPoewr >= 3600) {
              // 25%
              power = '25';
            } else {
              //10%
              power = '10';
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

  List<String> _arryAPDURespondData(String msg) {
    int cmdnum = _hexToInt(msg.substring(0, 2));
    List<String> cmdrespond = [];
    int cmdlan = 0;
    int index = 2;
    for (int i = 0; i < cmdnum; i++) {
      cmdlan = _hexToInt(msg.substring(index, index + 2));
      index = index + 2;
      String str = msg.substring(index, index + cmdlan * 2);
      index = index + cmdlan * 2;
      cmdrespond.add(str);
    }
    return cmdrespond;
  }

  _analyzM6(String str) {
    List<int> resultBuf = _strToIntArr(str);
    int resLength = resultBuf[7] * 256 + resultBuf[8];
    String dataStr = str.substring(18, 18 + resLength * 2).toUpperCase();
    List<TLV> arr = _getTLVArr(dataStr);
    M6pCardInfo cardInfo = M6pCardInfo();
    for (TLV tlv in arr) {
      //磁道明文
      if (tlv.tag == '1F40') {
        cardInfo.originalTrack = tlv.value;
      }
      //卡类型
      if (tlv.tag == '1F41') {
        print('1F41 ' + tlv.value.toString());
        cardInfo.cardType = _hexToInt(tlv.value!.substring(0, 2));
        if (cardInfo.cardType == 3) {
          cardInfo.nfcCompany =
              _nfcCompay(_hexToInt(tlv.value!.substring(2, 4)));
        }
        print('cardInfo.nfcCompany ' + cardInfo.nfcCompany.toString());
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
      //终端No
      if (tlv.tag == '1F44') {
        cardInfo.terimalNo = tlv.value;
      }
      //TUSN
      if (tlv.tag == '1F45') {
        cardInfo.tusn = _ascToHex(tlv.value!);
      }
      //NFC 交易结果
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
      // PIN 密文
      if (tlv.tag == '1F49') {
        cardInfo.pin = tlv.value;
      }
      //随机数
      if (tlv.tag == '1F4A') {
        cardInfo.random = tlv.value;
      }
      // 电子现金
      if (tlv.tag == '1F4B') {
        cardInfo.electronicCash = tlv.value;
      }
      //mac
      if (tlv.tag == '1F4C') {
        cardInfo.mac = tlv.value;
      }
      //pan
      if (tlv.tag == '1F4D') {
        cardInfo.cardNo = tlv.value;
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
        cardInfo.originalTracklength = tlv.value;
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
      // serviceCode
      if (tlv.tag == '1F57') {
        if (tlv.value != null) {
          cardInfo.serviceCode = _ascToHex(tlv.value!);
        }
      }
      // BatteryLevel
      if (tlv.tag == '1F5A') {
        int batteryPoewr = 0;
        String power = '0';
        batteryPoewr = _hexToInt(tlv.value!);

        if (batteryPoewr >= 4050) {
          //100%
          power = '100';
        } else if (batteryPoewr >= 3850) {
          //75%
          power = '75';
        } else if (batteryPoewr >= 3750) {
          // 50%
          power = '50';
        } else if (batteryPoewr >= 3600) {
          // 25%
          power = '25';
        } else {
          //10%
          power = '10';
        }
        cardInfo.batteryLevel = power;
      }
      //dataKsn
      if (tlv.tag == '1F58') {
        cardInfo.dataKsn = tlv.value;
      }
      //trackKsn
      if (tlv.tag == '1F59') {
        cardInfo.trackKsn = tlv.value;
      }
      //macKsn
      if (tlv.tag == '1F5D') {
        cardInfo.macKsn = tlv.value;
      }
      //emvKsn
      if (tlv.tag == '1F5E') {
        cardInfo.emvKsn = tlv.value;
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
      print('接受数据:' + str);
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

  // //asc字符串转hex,313233->123
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
  Stream<M6pBleDevice> startScan() async* {
    await _flutterBlue.stopScan();
    _blueList = [];
    yield* _flutterBlue.scan().transform(
        StreamTransformer<ScanResult, M6pBleDevice>.fromHandlers(
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
          M6pBleDevice scanResult1 = M6pBleDevice();
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
  Future<bool> connectDevice(M6pBleDevice device) async {
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

        List<BluetoothService> services;
        try {
          services = await bleDevice.discoverServices();
        } catch (e) {
          return false;
        }

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
          print('----------------------------------------');
          try {
            final int mtu1 = await bleDevice.mtu.first;
            print(mtu1);
            await bleDevice.requestMtu(124);
            print('设置正确................................');
          } catch (e) {
            print('设置错误................................');
            //return false;
          }
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
      void Function(M6pTerminalInfo? terminalInfo, int status)
          terminalInfoCallback) {
    _getTerminalInfoCallback1 = terminalInfoCallback;
    _sendComd('00091b100000');
  }

  late RequestDataEncryptCallback _requestDataEncryptCallback1;
  //请求数据加密
  /**
 请求数据加密
 * @param encryptData  encryptData
 * @param entype  1:DUKPT ; 2:MK/SK
 * @param index  index
 * @param random  random
 * @param dukptMode dukptMode 0 automatic addition of 1 , 1 dupkt  No automatic addition of 1
 * @param operationMode operationMode 0 ECB , 1 CBC (IV data is required)
 * @param ivData  ivData
 */
  requestDataEncrypt(
      String encryptData,
      int entype,
      int index,
      String random,
      int dukptMode,
      int operationMode,
      String ivData,
      void Function(String? encryptedData, String? ksn, int status)
          requestDataEncryptCallback) {
    _requestDataEncryptCallback1 = requestDataEncryptCallback;
    String str = '';
    int value = 0;
    value = value | 0;
    // ignore: unnecessary_null_comparison
    if (operationMode == 1 && (ivData != '') && (ivData != null)) {
      value = value | 2;
    }
    if (dukptMode == 1) {
      value = value | 64;
    }
    value = value | 128;
    str = str +
        '1F0406' +
        _intToHex(entype) +
        _intToHex(index) +
        '000000' +
        _intToHex(value);
    // ignore: unnecessary_null_comparison
    if ((random != '') && (random != null)) {
      str = str + _getTLVStr('1F07', random);
    }
    // ignore: unnecessary_null_comparison
    if ((encryptData != '') && (encryptData != null)) {
      str = str + _getTLVStr('1F0E', encryptData);
    }
    // ignore: unnecessary_null_comparison
    if (operationMode == 1 && (ivData != '') && (ivData != null)) {
      str = str + _getTLVStr('1F22', ivData);
    }
    String str1 = '00020410' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  //请求数据解密
  /**
 请求数据解密
 * @param decryptData  decryptData
 * @param entype  1:DUKPT ; 2:MK/SK
 * @param index  index
 * @param random  random
 * @param dukptMode dukptMode 0 automatic addition of 1 , 1 dupkt  No automatic addition of 1
 * @param operationMode operationMode 0 ECB , 1 CBC (IV data is required)
 * @param ivData  ivData
 */
  requestDataDecrypt(
      String decryptData,
      int entype,
      int index,
      String random,
      int dukptMode,
      int operationMode,
      String ivData,
      void Function(String? encryptedData, String? ksn, int status)
          requestDataDecryptCallback) {
    _requestDataEncryptCallback1 = requestDataDecryptCallback;
    String str = '';
    int value = 0;
    value = value | 1;
    // ignore: unnecessary_null_comparison
    if (operationMode == 1 && (ivData != '') && (ivData != null)) {
      value = value | 2;
    }
    if (dukptMode == 1) {
      value = value | 64;
    }
    value = value | 128;
    str = str +
        '1F0406' +
        _intToHex(entype) +
        _intToHex(index) +
        '000000' +
        _intToHex(value);
    // ignore: unnecessary_null_comparison
    if ((random != '') && (random != null)) {
      str = str + _getTLVStr('1F07', random);
    }
    // ignore: unnecessary_null_comparison
    if ((decryptData != '') && (decryptData != null)) {
      str = str + _getTLVStr('1F0E', decryptData);
    }
    // ignore: unnecessary_null_comparison
    if (operationMode == 1 && (ivData != '') && (ivData != null)) {
      str = str + _getTLVStr('1F22', ivData);
    }
    String str1 = '00020410' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  late RequestErrorCallback _requestErrorCallback1;
  late RequestDisplayCallback _requestDisplayCallback1;
  //请求回显
  /**
   * request Display
   * @param model  0 Display on the left , 16 Center display
   * @param timeout timeout 
   * @param asciiString ascii String
   * @param buzzerFrequency Buzzer frequency, network byte order, e.g. 1000Hz, the value is 00 00 03 E8
   * @param buzzerSoundTime  Buzzer sound time, network byte order, e.g. 1000ms, the value is 00 00 03 E8
   * @param buzzerNumber  Buzzer number of times, network byte order, e.g. 3 times, the value is 00 00 00 03
   * @param light 00 red light; 01 green light; 02 yellow light; 03 blue light
   * @param durationTime duration time ms, network byte order, e.g. 1000ms, the value is 00 00 03 E8
   * @param closingTime Closing time ms, network byte order, e.g. 1000ms, the value is 00 00 03 E8
   */
  requestDisplay(
      int model,
      int timeout,
      String asciiString,
      int buzzerFrequency,
      int buzzerSoundTime,
      int buzzerNumber,
      int light,
      int durationTime,
      int closingTime,
      void Function(int status) requestDisplayCallback,
      void Function(int errorID, String msg) requestErrorCallback,
      void Function() waitingcardCallback) {
    _waitingcardCallback1 = waitingcardCallback;
    _requestErrorCallback1 = requestErrorCallback;
    _requestDisplayCallback1 = requestDisplayCallback;
    if (timeout <= 0) {
      timeout = 5;
    }
    String str = '1F1006' + _intToHex(timeout) + _intToHex(model) + '00000000';
    // ignore: unnecessary_null_comparison
    if ((asciiString != '') && (asciiString != null)) {
      str = str + _getTLVStr('1F12', _hexToAsc(asciiString));
    }

    str = str +
        '1F150C' +
        _intToHex(buzzerFrequency).padLeft(8, '0') +
        _intToHex(buzzerSoundTime).padLeft(8, '0') +
        _intToHex(buzzerNumber).padLeft(8, '0');

    str = str +
        '1F160C' +
        _intToHex(light).padLeft(8, '0') +
        _intToHex(durationTime).padLeft(8, '0') +
        _intToHex(closingTime).padLeft(8, '0');

    String str1 = '0002AA10' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  late CalculateMacCallback _calculateMacCallback1;
  //计算mac
  /**
 计算mac
 * @param entype  1:DUKPT ; 2:MK/SK
 * @param index  index
 * @param mactype  0x00 ECB；0x01 CBC； 0x02 X919； 0x03 XOR ;  0x04 CMAC
 * @param macData macData
 */
  calculateMac(
      int entype,
      int index,
      int mactype,
      String macData,
      void Function(String? mac, String? ksn, int status)
          calculateMacCallback) {
    _calculateMacCallback1 = calculateMacCallback;
    String dataStr = '1F0406' +
        _intToHex(entype) +
        _intToHex(index) +
        '0000' +
        _intToHex(mactype) +
        '00';
    dataStr = dataStr + _getTLVStr('1F0F', macData);
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
    // ignore: unnecessary_null_comparison
    if ((pinKey != '') && (pinKey != null)) {
      a = a + 1;
      str1 = str1 + _intToHex(pinKey.length ~/ 2) + pinKey;
    }
    // ignore: unnecessary_null_comparison
    if ((macKey != '') && (macKey != null)) {
      a = a + 1;
      str1 = str1 + _intToHex(macKey.length ~/ 2) + macKey;
    }
    // ignore: unnecessary_null_comparison
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
  late ReadCardError _readCardError;
  late ReadCardDegradeError _readCardDegradeError;
  //刷卡
  startEmvProcess(
      int timeout,
      M6pTradeData tradeData,
      void Function() waitingcardCallback,
      void Function() icCardInsertionCallback,
      void Function() nfcCardDetectionCallback,
      void Function(M6pCardInfo? cardInfo, int status) readCardCallback,
      void Function(int errorID, String msg) readCardError,
      void Function(int errorID, String msg, int code) readCardDegradeError) {
    _waitingcardCallback1 = waitingcardCallback;
    _icCardInsertionCallback1 = icCardInsertionCallback;
    _nfcCardDetectionCallback1 = nfcCardDetectionCallback;
    _readCardCallback1 = readCardCallback;
    _readCardError = readCardError;
    _readCardDegradeError = readCardDegradeError;
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
      String dateTime = _getTLVStr('9A', time.substring(2, 8));
      String dateTime2 = _getTLVStr('9F21', time.substring(8));
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
    //刷卡副标题
    if (tradeData.subTitle != null && (tradeData.subTitle != '')) {
      String str1 = _getTLVStr('1F06', _hexToAsc(tradeData.subTitle!));
      str = str + str1;
      len = len + str1.length ~/ 2;
    }
    //PAN 输入和 Valid Date 输入控制
    if (tradeData.panAndValidInputControl != null &&
        (tradeData.panAndValidInputControl != '')) {
      String str1 = _getTLVStr('1F25', tradeData.panAndValidInputControl!);
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
      String res,
      String data,
      void Function(
              int onlineResult, String? scriptResult, String? data, int status)
          sendOnlineProcessCallback) {
    _sendOnlineProcessCallback1 = sendOnlineProcessCallback;
    int len = data.length ~/ 2 + 4;
    String str = '0002A110' +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        '8A02' +
        _hexToAsc(res) +
        data;
    _sendComd(str);
  }

  late PowerOnAPDUCallback _powerOnAPDUCallback1;

  /**
   *  开始 透传模式  NFC/IC
   *  type  0 -IC, 1 - NFC,  3 - Mifare classic  7 -Mifare Desfire
   */
  powerOnAPDU(
      int type,
      int timeout,
      void Function() waitingcardCallback,
      void Function(String type, String uuid, String data, int status)
          powerOnAPDUCallback) {
    _powerOnAPDUCallback1 = powerOnAPDUCallback;
    _waitingcardCallback1 = waitingcardCallback;
    String str = '0002E0' + _intToHex(timeout) + '0001' + _intToHex(type);
    _sendComd(str);
  }

  late PowerOffAPDUCallback _powerOffAPDUCallback1;
  //结束 APDU NFC/IC
  powerOffAPDU(void Function(int status) powerOffAPDUCallback) {
    _powerOffAPDUCallback1 = powerOffAPDUCallback;
    _sendComd('0002E1100000');
  }

  late SendApduCallback _sendApduCallback1;
  //APDU 发送数据
  sendApdu(List<String> apduData, int timeout,
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
        _intToHex(0) +
        _intToHex(apduData.length) +
        str;
    _sendComd(str2);
  }

  // Mifare classic base cperate
  operateMifareClassic(List<String> apduData, int timeout) {
    String str = '';
    for (String str1 in apduData) {
      str = str + _intToHex(str1.length ~/ 2 + 1) + '40' + str1;
    }
    int len = 2 + str.length ~/ 2;
    String str2 = '0002E2' +
        _intToHex(timeout) +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        _intToHex(0) +
        _intToHex(apduData.length) +
        str;
    _sendComd(str2);
  }

  late OperateMifareCallbock _operateMifareCallbock;
  // Mifare Classic 扇区读卡数据操作
  readMifareClassic(MifareCard mifareCard, int timeout,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    apduData.add('30' + mifareCard.getblockaddr());
    operateMifareClassic(apduData, timeout);
  }

  // Mifare Classic 扇区 写卡数据操作
  writeMifareClassic(MifareCard mifareCard, int timeout,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    if (mifareCard.data != null) {
      apduData.add('A0' + mifareCard.getblockaddr() + mifareCard.data!);
    }
    operateMifareClassic(apduData, timeout);
  }

  // 钱包初始化 初始化后金额可以输入
  walletInitMifare(MifareCard mifareCard, int timeout, int money,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    apduData
        .add('A0' + mifareCard.getblockaddr() + mifareCard.initMoney(money));
    operateMifareClassic(apduData, timeout);
  }

  // 钱包充值 充值金额 money
  walletRechargeMifare(MifareCard mifareCard, int timeout, int money,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    apduData.add(
        'C0' + mifareCard.getblockaddr() + mifareCard.moneyLittleEndian(money));
    apduData.add('B0' + mifareCard.getblockaddr());
    operateMifareClassic(apduData, timeout);
  }

  // 扣款 Deduction
  walletDeductionMifare(MifareCard mifareCard, int timeout, int money,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    apduData.add(
        'C1' + mifareCard.getblockaddr() + mifareCard.moneyLittleEndian(money));
    apduData.add('B0' + mifareCard.getblockaddr());
    operateMifareClassic(apduData, timeout);
  }

  // 钱包余额查询
  walletSurplusMifare(MifareCard mifareCard, int timeout,
      void Function(int status, String msg) operateMifareCallbock) {
    _operateMifareCallbock = operateMifareCallbock;
    List<String> apduData = [];
    if (mifareCard.Akey!.length == 12) {
      apduData.add('60' + mifareCard.getblockaddr() + mifareCard.Akey!);
    }
    if (mifareCard.Bkey!.length == 12) {
      apduData.add('61' + mifareCard.getblockaddr() + mifareCard.Bkey!);
    }
    apduData.add('30' + mifareCard.getblockaddr());
    operateMifareClassic(apduData, timeout);
  }

  // Mifare desfire data
  // TODO  mifare desfire 透传命令
  operateMifareDesfire(List<String> apduData, int timeout,
      void Function(List<String> data, int status) sendApduCallback) {
    _sendApduCallback1 = sendApduCallback;
    String str = '';
    for (String str1 in apduData) {
      str = str + _intToHex(str1.length ~/ 2 + 1) + '41' + str1;
    }
    int len = 2 + str.length ~/ 2;
    String str2 = '0002E2' +
        _intToHex(timeout) +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        _intToHex(0) +
        _intToHex(apduData.length) +
        str;
    _sendComd(str2);
  }

  // 复位卡片
  // TODO 卡片复位
  resetCard(int timeout) {
    String str = 'FF';
    int len = 2 + str.length ~/ 2;
    String str2 = '0002E2' +
        _intToHex(timeout) +
        _intToHex(len ~/ 256) +
        _intToHex(len % 256) +
        _intToHex(0) +
        _intToHex(1) +
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
    // ignore: unnecessary_null_comparison
    if ((tusn != '') && (tusn != null)) {
      str = str + _getTLVStr('1F80', tusn);
    }
    // ignore: unnecessary_null_comparison
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
  downloadAIDParameters(M6pAIDParameters aidParameters,
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
  downloadPublicKey(M6pCAPublicKey caPublicKey,
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

  late TestData _testDataCallback1;
  //大数据测试
  testData(
      String str, void Function(String str, int status) testDataCallback1) {
    _testDataCallback1 = testDataCallback1;
    String str1 = '0009FF10' +
        _intToHex((str.length ~/ 2) ~/ 0x100) +
        _intToHex((str.length ~/ 2) % 0x100) +
        str;
    _sendComd(str1);
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

  /**
   * 更新KEK
   * @param entype 0：TDES , 1：AES 
   * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
   * @param keyData keydata = KEK密文数据: KEK密文
   * @param cmac 用KEK密钥对其他Data数据算CMAC值
   */
  late DownloadKEKCallBack _downloadKEKCallBack;
  downloadKeK(int entype, int keyLength, String kek, String cmac,
      void Function(int status) downloadKEKCallback) {
    _downloadKEKCallBack = downloadKEKCallback;
    String str = '';
    // ignore: unnecessary_null_comparison
    if ((kek != '') && (kek != null)) {
      StringBuffer tradeDataStr = new StringBuffer();
      tradeDataStr.write("1F050600" +
          _intToHex(entype) +
          "00" +
          "10" +
          _intToHex(keyLength) +
          "00");
      tradeDataStr.write("1F10");
      tradeDataStr.write(_intToHex((kek.length ~/ 2) % 256));
      tradeDataStr.write(kek);
      tradeDataStr.write("1F20");
      tradeDataStr.write(_intToHex((cmac.length ~/ 2) % 256));
      tradeDataStr.write((cmac));
      str = tradeDataStr.toString();
      str = '00020D04' +
          _intToHex((str.length ~/ 2) ~/ 256) +
          _intToHex((str.length ~/ 2) % 256) +
          str;
      _sendComd(str);
    } else {
      print('密钥错误');
    }
  }

  /**
   * 更新 MK/DUKPT 指令
   * @param keytype  0 MK , 1 DUKPT
   * @param entype 0：TDES , 1：AES 
   * @param index MK index 0-99; DUKPT 1-5
   * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
   * @param ksn DUKPT 是需要填写
   * @param key  32Byte主密钥密文数据 +  (3Byte 或 5Byte Check Value)
   * @param cmac 用KEK密钥对其他Data数据算CMAC值
   */
  late DownloadMKDUKPTCallBack _downloadMKDUKPTCallBack;
  downloadMKDUKPT(
      int keytype,
      int entype,
      int index,
      int keyLength,
      String ksn,
      String key,
      String cmac,
      void Function(int status) downloadMKDUKPTCallBack) {
    _downloadMKDUKPTCallBack = downloadMKDUKPTCallBack;

    StringBuffer tradeDataStr = new StringBuffer();
    if (keytype == 0) {
      // MK 密钥更新
      tradeDataStr.write("1F050602" +
          _intToHex(entype) +
          _intToHex(index) +
          "11" +
          _intToHex(keyLength) +
          "00");
      tradeDataStr.write("1F10");
      tradeDataStr.write(_intToHex((key.length ~/ 2) % 256));
      tradeDataStr.write(key);
      tradeDataStr.write("1F20");
      tradeDataStr.write(_intToHex((cmac.length ~/ 2) % 256));
      tradeDataStr.write((cmac));
    } else if (keytype == 1) {
      // DUKPT 密钥更新
      tradeDataStr.write("1F050601" +
          _intToHex(entype) +
          _intToHex(index) +
          "12" +
          _intToHex(keyLength) +
          "00");
      tradeDataStr.write("1F10");
      tradeDataStr.write(_intToHex((key.length ~/ 2) % 256));
      tradeDataStr.write(key);
      tradeDataStr.write("1F20");
      tradeDataStr.write(_intToHex((cmac.length ~/ 2) % 256));
      tradeDataStr.write(cmac);
      tradeDataStr.write("1F06");
      tradeDataStr.write(_intToHex((ksn.length ~/ 2) % 256));
      tradeDataStr.write(ksn);
    }

    String str = tradeDataStr.toString();
    str = '00020E04' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str);
  }

  late DownloadSKCallBack _downloadSKCallBack;
  /**
   * 更新 SK
   * @param index 密钥索引
   * @param keytype 密钥类型 0x01 PINkey, 0x02=Data Key, 0x03=Mac Key
   * @param entype 0：TDES , 1：AES 
   * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
   * @param key 密钥
   * @param cmac 用KEK密钥对其他Data数据算CMAC值
   */
  downloadSK(int index, int keytype, int entype, int keyLength, String key,
      String cmac, void Function(int status) downloadSKCallBack) {
    _downloadSKCallBack = downloadSKCallBack;
    StringBuffer tradeDataStr = new StringBuffer();
    tradeDataStr.write("1F050602" +
        _intToHex(entype) +
        _intToHex(index) +
        _intToHex(keytype) +
        _intToHex(keyLength) +
        "00");
    tradeDataStr.write("1F10");
    tradeDataStr.write(_intToHex((key.length ~/ 2) % 256));
    tradeDataStr.write(key);
    tradeDataStr.write("1F20");
    tradeDataStr.write(_intToHex((cmac.length ~/ 2) % 256));
    tradeDataStr.write(cmac);

    String str = tradeDataStr.toString();
    str = '00020F04' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str);
  }

  /**
   * 更新 TPK
   * @param index 密钥索引
   * @param entype 0：TDES , 1：AES 
   * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
   * @param key 密钥
   * @param cmac key 16biytes 0x00 CMAC   DES 3bytes/ AES 5bytes
   */
  downloadTPK(int index, int entype, int keyLength, String key, String cmac,
      void Function(int status) downloadTPKCallBack) {
    downloadSK(index, 0x82, entype, keyLength, key, cmac, downloadTPKCallBack);
  }

  late GetSecretKeyInfoCallback _getSecretKeyInfoCallback1;
  //获取密钥信息
  /**
 获取密钥信息
 * @param keySystem  1:DUKPT ; 2:MK/SK
 * @param entype 0：TDES , 1：AES 
 * @param index  index
 * @param keyType  0x01  PIN Key；0x02   Data Key；0x03  MAC0 Key；0x10   KEK；0x11  MK；0x12   DUKPT IPEK；0x82   Data Key（TPK）
 */
  getSecretKeyInfo(
      int keySystem,
      int entype,
      int index,
      int keyType,
      void Function(String? keyInfo, String? kcv, String? ksn, int status)
          getSecretKeyInfoCallback) {
    _getSecretKeyInfoCallback1 = getSecretKeyInfoCallback;
    String dataStr = '1F0506' +
        _intToHex(keySystem) +
        _intToHex(entype) +
        _intToHex(index) +
        _intToHex(keyType) +
        "0000";
    int len = dataStr.length ~/ 2;
    String str =
        '00020910' + _intToHex(len ~/ 256) + _intToHex(len % 256) + dataStr;
    _sendComd(str);
  }

  late RequestInputCallback _requestInputCallback1;
  //请求输入显示
  /**
   * request Input
   * @param showModel 0x00 is displayed on the upper left; 0x10 is automatically centered (only controls the input box)
   * @param inputmodel  0x00 Function keys only 0x01 number + Function 0x02 lowercase + Function 0x04 capital + Function 0x08 Symbol + Function 0x0F ALL
   * @param minLength  Enter the minimum length, 0 defaults to 0 characters, if skipping is not allowed, please specify a minimum value
   * @param maxLength Enter the maximum length, 0 is 64 characters by default 
   * @param timeout timeout seconds, 0 defaults to 60s
   * @param asciiString The interface title is displayed, automatically left, and the center display needs to manually add spaces
   * @param statusAscii Interface Status display, automatically to the right
   */
  requestInput(
      int showModel,
      int inputmodel,
      int minLength,
      int maxLength,
      int timeout,
      String asciiString,
      String statusAscii,
      void Function(String? input, int status) requestInputCallback,
      void Function(int errorID, String msg) requestErrorCallback,
      void Function() waitingcardCallback) {
    _requestInputCallback1 = requestInputCallback;
    _waitingcardCallback1 = waitingcardCallback;
    _requestErrorCallback1 = requestErrorCallback;
    String str = '1F100605' + _intToHex(showModel) + '00000000';
    str = str +
        '1F2604' +
        _intToHex(inputmodel) +
        _intToHex(minLength) +
        _intToHex(maxLength) +
        _intToHex(timeout);
    // ignore: unnecessary_null_comparison
    if ((asciiString != '') && (asciiString != null)) {
      str = str + _getTLVStr('1F12', _hexToAsc(asciiString));
    }
    // ignore: unnecessary_null_comparison
    if ((statusAscii != '') && (statusAscii != null)) {
      str = str + _getTLVStr('1F13', _hexToAsc(statusAscii));
    }
    str = str + _getTLVStr('1F15', '00000000000003E800000001');
    str = str + _getTLVStr('1F16', '00000001000003E800000000');
    String str1 = '0002AB10' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  late RequestInputAndCheckCallback _requestInputAndCheckCallback1;
  //请求输入卡号和有效期
  /**
   * request InputAndCheck
   * @param minLength  Enter the minimum length, 0 is 10 characters by default
   * @param maxLength Enter the maximum length, 0 is 24 characters by default 
   * @param timeout timeout seconds,0 defaults to 60s
   */
  requestInputAndCheck(
      int minLength,
      int maxLength,
      int timeout,
      void Function(String? cardNo, String? cardexpiryDate, int status)
          requestInputCallback,
      void Function(int errorID, String msg) requestErrorCallback,
      void Function() waitingcardCallback) {
    _requestInputAndCheckCallback1 = requestInputCallback;
    _waitingcardCallback1 = waitingcardCallback;
    _requestErrorCallback1 = requestErrorCallback;
    String str = '1F250601' +
        _intToHex(minLength) +
        _intToHex(maxLength) +
        _intToHex(timeout) +
        '0000';
    String str1 = '0002AC10' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  //请求二维码显示
  /**
   * request QRCodeDisplay
   * @param showModel 0x00 is displayed on the upper left; 0x10 is automatically centered (only controls the input box)
   * @param asciiString The interface title is displayed, automatically left, and the center display needs to manually add spaces
   * @param QRString The interface QRCode is displayed
   * @param statusAscii Interface Status display, automatically to the right
   * @param timeout timeout seconds
   */
  requestQRCodeDisplay(
      int showModel,
      String asciiString,
      String QRString,
      String statusAscii,
      int timeout,
      void Function(String? input, int status) requestInputCallback,
      void Function(int errorID, String msg) requestErrorCallback,
      void Function() waitingcardCallback) {
    _requestInputCallback1 = requestInputCallback;
    _waitingcardCallback1 = waitingcardCallback;
    _requestErrorCallback1 = requestErrorCallback;
    String str =
        '1F1006' + _intToHex(timeout) + _intToHex(showModel) + '00000000';
    // ignore: unnecessary_null_comparison
    if ((asciiString != '') && (asciiString != null)) {
      str = str + _getTLVStr('1F12', _hexToAsc(asciiString));
    }
    // ignore: unnecessary_null_comparison
    if ((statusAscii != '') && (statusAscii != null)) {
      str = str + _getTLVStr('1F13', _hexToAsc(statusAscii));
    }
    str = str + _getTLVStr('1F15', '00000000000003E800000001');
    str = str + _getTLVStr('1F16', '00000001000003E800000000');
    // ignore: unnecessary_null_comparison
    if ((QRString != '') && (QRString != null)) {
      str = str + _getTLVStr('1F18', _hexToAsc(QRString));
    }
    String str1 = '0002AB10' +
        _intToHex((str.length ~/ 2) ~/ 256) +
        _intToHex((str.length ~/ 2) % 256) +
        str;
    _sendComd(str1);
  }

  /**
   * 版本查询
   */
  void _queryTMS(String tusn, String appver, String kerver) async {
    String URL = 'https://www.itrontest.top/terminal/version/query';
    Response response;
    var dio = Dio();
    FormData formData = FormData.fromMap(
        {"tusn": tusn, "appVersion": appver, "kernelVersion": kerver});
    response = await dio.post(
      URL,
      data: formData,
      options: Options(responseType: ResponseType.plain),
    );
    var map = jsonDecode(response.data);
    print(map.toString());
    if ((map["code"] == 200) && (map["data"].toString().length > 2)) {
      print('new Version: ' + map["data"].toString());
    }
  }
}
