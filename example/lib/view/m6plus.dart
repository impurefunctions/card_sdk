import 'package:card_sdk/M6pBleControl.dart';
import 'package:flutter/material.dart';
import 'package:card_sdk/M6pBleBean.dart';
import 'package:dio/dio.dart';
import 'AlertDialogWidget.dart';
/*
void main() {
  runApp(ItronTest());
}*/

class M6plusView extends StatelessWidget {
  const M6plusView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('M6plus Test'),
      ),
      body: ShowPic(),
    );
    /*
    return MaterialApp(
      title: '',
      home: Scaffold(
        appBar: AppBar(
          title: Text('777'),
        ),
        body: ShowPic(),
      ),
    );*/
  }
}

class ShowPic extends StatefulWidget {
  const ShowPic({Key? key}) : super(key: key);

  @override
  _ShowPicState createState() => _ShowPicState();
}

class _ShowPicState extends State<ShowPic> {
  BleControl itronBle = BleControl();
  ScrollController scr = ScrollController();
  String textStr = '';
  String commandStr = 'Terminal info';
  int commandIndex = 0;
  // TODO 命令
  List<String> commandList = [
    "Terminal info",
    "Pay card Or ICCard",
    "Stop",
    "Set automatic Shutdown",
    "Power On APDU",
    "Send APDU",
    "Power Off APDU",
    "Get batteryPower",
    "Download AID parameters",
    "Download publicKey",
    "Calculate MAC",
    "PIN entry",
    "Update terminal time",
    "EMV onlineRespose",
    "Return terminal time",
    "m6plus download",
    "m6plus downloadKey",
    "TestData",
    "download KEK 3DES",
    "Upgrade DUKPT 3DES Index0",
    "Upgrade MK/SK 3DES Index1",
    "Upgrade SK TDES, Index1, TDES 3Keys Data Key",
    "Upgrade SK TDES, Index1, TDES 3Keys PIN Key",
    "Upgrade SK TDES, Index1, TDES 3Keys MAC Key",
    "Upgrade SK TDES, Index1, TDES 2Keys PIN Key",
    "Request Display",
    "download TKP",
    "Request DataEncrypt",
    "Request DataDecrypt",
    "get SecretKey Info",
    "Request Input ZIP Code",
    "Request Input CVV",
    "Request Input And Check",
    "Request QRCode Display",
    "Mifare classic wallet Init",
    "Mifare classic wallet Recharge",
    "Mifare classic wallet Deduction",
    "Mifare classic wallet Balance",
    "Mifare classic read sector",
    "Mifare classic write sector",
    "Mifare Desfire operation",
  ];
  int testNumber = 0;
  @override
  void dispose() {
    super.dispose();
    itronBle.disconnect();
  }

  List<Widget> createSimpleDialogOption(BuildContext context) {
    List<Widget> widgetList = [];
    for (int i = 0; i < commandList.length; i++) {
      SimpleDialogOption simpleDialogOption = SimpleDialogOption(
        child: Text(commandList[i]),
        onPressed: () {
          setState(() {
            commandStr = commandList[i];
          });
          commandIndex = i;
          Navigator.of(context).pop();
        },
      );
      widgetList.add(simpleDialogOption);
    }
    return widgetList;
  }

  sendCommand(BuildContext context) {
    switch (commandIndex) {
      //Terminal info
      case 0:
        {
          itronBle.getTerminalInfo((terminalInfo, status) {
            String str = '';
            if (status == 0) {
              str = 'getTerminalInfo success\n' +
                  'sn:${terminalInfo!.sn}\n' +
                  'tusn:${terminalInfo.tusn}\n' +
                  'bluetoothName:${terminalInfo.bluetoothName}\n' +
                  'bluetoothMAC:${terminalInfo.bluetoothMAC}\n' +
                  'bluetoothVersion:${terminalInfo.bluetoothVersion}\n' +
                  'appVersion:${terminalInfo.appVersion}\n' +
                  'appVersionDate:${terminalInfo.appVersionDate}\n' +
                  'kernelVersion:${terminalInfo.kernelVersion}\n' +
                  'kernelVersionDate:${terminalInfo.kernelVersionDate}\n' +
                  'hardwareVersion:${terminalInfo.hardwareVersion}\n' +
                  'softVersion:${terminalInfo.softVersion}\n' +
                  'operationMode:${terminalInfo.operationMode}\n' +
                  'language:${terminalInfo.language}\n';
            } else {
              str = 'getTerminalInfo fail';
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Pay card Or ICCard
      case 1:
        {
          AlertDialogWidget().showCupertinoDialog(context,
              (cash, currencyCode, countryCode) {
            M6pTradeData tradeData = M6pTradeData();
            // Transaction amount, cents into units
            tradeData.cash = '1200';
            if ((cash != '') && (cash != null)) {
              tradeData.cash = cash;
            }
            // byte1 DUKPT 01    MK/SK  02
            // bytes2 key index  The key algorithm corresponds to the update key index 03
            tradeData.encryptionAlg = "010000000240"; //'020100000200';
            // return data content
            tradeData.sign = "10000004"; //"86640000";  //'CA650000';
            tradeData.transactionInfo = M6pTransactionInfo();
            tradeData.transactionInfo!.countryCode = '0840';
            tradeData.transactionInfo!.currencyCode = '0840';
            if ((currencyCode != '') && (currencyCode != null)) {
              tradeData.transactionInfo!.countryCode = currencyCode;
            }
            if ((countryCode != '') && (countryCode != null)) {
              tradeData.transactionInfo!.currencyCode = countryCode;
            }
            // Transaction Type
            // 00 : Consumption
            tradeData.transactionInfo!.type = '00';
            //subTitle
            tradeData.subTitle = 'Tip ........... \$1.00\n';
            //pan And Valid Input Control
            tradeData.panAndValidInputControl = '010A10600000';
            itronBle.startEmvProcess(60, tradeData, () {
              setState(() {
                textStr = 'please swipe or ic';
              });
            }, () {
              setState(() {
                textStr = 'IC card have inserted,please wait';
              });
            }, () {
              setState(() {
                textStr = 'NFCCard have detected,please wait';
              });
            }, (cardInfo, status) {
              String str = '';
              String cardType = '';
              if (cardInfo!.cardType == 1) {
                cardType = "IC Card";
              }
              if (cardInfo.cardType == 0) {
                cardType = "Swipe";
              }
              if (cardInfo.cardType == 2) {
                cardType = "Swipe";
              }
              if ((cardInfo.cardType & 0x03) == 0x03) {
                cardType = "NFC";
              }
              if (cardInfo.cardType == 4) {
                cardType = "Enter";
              }
              if (status == 0) {
                str = 'Consume success\n' +
                    'CardNumber:${cardInfo.cardNo!}\n' +
                    'CardName:${cardInfo.cardName}\n' +
                    'CardType:${cardType}\n' +
                    'CardNfcCompany: ${cardInfo.nfcCompany}\n' +
                    'cardexpiryDate:${cardInfo.cardexpiryDate}\n' +
                    'CardSerial:${cardInfo.cardSerial}\n' +
                    'CVM:${cardInfo.cvm}\n' +
                    'ICData:${cardInfo.icdata}\n' +
                    'TUSN:${cardInfo.tusn}\n' +
                    'tsn:${cardInfo.tsn}\n' +
                    'encryTrack:${cardInfo.encryTrack}\n' +
                    'Tracks:${cardInfo.tracks}\n' +
                    'TracksLen:${cardInfo.trackLen}\n' +
                    'OriginalTrack:${cardInfo.originalTrack}\n' +
                    'OriginalTracklength:${cardInfo.originalTracklength}\n' +
                    'serviceCode:${cardInfo.serviceCode}\n' +
                    'batteryLevel:${cardInfo.batteryLevel}\n';

                if (cardInfo.ksn != null) {
                  str = str + 'ksn:${cardInfo.ksn}\n';
                }
                if (cardInfo.dataKsn != null) {
                  str = str + 'dataKsn:${cardInfo.dataKsn}\n';
                }
                if (cardInfo.trackKsn != null) {
                  str = str + 'trackKsn:${cardInfo.trackKsn}\n';
                }
                if (cardInfo.macKsn != null) {
                  str = str + 'macKsn:${cardInfo.macKsn}\n';
                }
                if (cardInfo.emvKsn != null) {
                  str = str + 'emvKsn:${cardInfo.emvKsn}\n';
                }

                if ((cardInfo.originalTrack != null) &&
                    (cardInfo.originalTrack!.length > 0) &&
                    (cardInfo.originalTracklength != null) &&
                    (cardInfo.originalTracklength!.length > 0)) {
                  int track1Len =
                      _hexToInt(cardInfo.originalTracklength!.substring(0, 2)) *
                          2;
                  int track2Len =
                      _hexToInt(cardInfo.originalTracklength!.substring(2, 4));
                  print('track1Len: ${track1Len}  track2Len:${track2Len}');
                  if (track1Len > 0) {
                    cardInfo.track1 =
                        cardInfo.originalTrack!.substring(0, track1Len);
                  }
                  if (track2Len > 0) {
                    cardInfo.track2 = cardInfo.originalTrack!
                        .substring(track1Len, track1Len + track2Len);
                  }
                  str = str +
                      'track1Len: ${track1Len}  track2Len:${track2Len} \n' +
                      'cardInfo.track1: ${cardInfo.track1}  \n' +
                      'cardInfo.track2: ${cardInfo.track2}';

                  print(str);
                }
              } else {
                str = 'Consum fail,error code:' + status.toRadixString(16);
              }
              setState(() {
                textStr = str;
              });
            }, (errorID, msg) {
              setState(() {
                textStr = ' error code: ${errorID} msg: ${msg}';
              });
            }, (errorID, msg, code) {
              setState(() {
                textStr =
                    ' error code: ${errorID} msg: ${msg} data code: ${code}';
              });
            });
          });
        }
        break;
      //Stop
      case 2:
        {
          itronBle.stopTrade((status) {
            String str = '';
            if (status == 0) {
              str = 'stopTrade success\n';
            } else {
              str = 'stopTrade fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Set automatic Shutdown
      case 3:
        {
          itronBle.setAutomaticShutdown(10, (status) {
            String str = '';
            if (status == 0) {
              str = 'setAutomaticShutdown success\n';
            } else {
              str = 'setAutomaticShutdown fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Power On APDU,0 is IC,1 is NFC ,  3 - Mifare classic  5 -Mifare Desfire
      case 4:
        {
          AlertDialogWidget().typeChooseDialog(context, (apdutype) {
            print(apdutype.toString());
            itronBle.powerOnAPDU(apdutype, 30, () {
              setState(() {
                textStr = 'please wait input';
              });
            }, (type, uuid, data, status) {
              String str = '';
              if (status == 0) {
                str =
                    'powerOnAPDU success\nType:${type} \nUUDI:${uuid} \ndata:${data} ';
              } else {
                str = 'powerOnAPDU fail,error code:' + status.toRadixString(16);
              }
              setState(() {
                textStr = str;
              });
            });
          });
        }
        break;
      //Send APDU
      case 5:
        {
          //IC 00A404000E315041592E5359532E4444463031
          //NFC 00A404000E325041592E5359532E4444463031
          String apduStr = "00A404000E315041592E5359532E4444463031";
          itronBle.sendApdu([apduStr], 10, (data, status) {
            String str = '';
            if (status == 0) {
              str = 'sendAPDU success\n';
              for (String str1 in data) {
                str = str + 'result' + str1 + '\n';
              }
            } else {
              str = 'sendAPDU fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Power Off APDU
      case 6:
        {
          itronBle.powerOffAPDU((status) {
            String str = '';
            if (status == 0) {
              str = 'powerOffAPDU success';
            } else {
              str = 'powerOffAPDU fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Get batteryPower
      case 7:
        {
          itronBle.getBatteryPower((power, status) {
            String str = '';
            if (status == 0) {
              str = 'getBatteryPower success,power:${power}';
            } else {
              str =
                  'getBatteryPower fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Download AID parameters
      case 8:
        {
          M6pAIDParameters aidParameters = M6pAIDParameters();
          aidParameters.aid = "A0000000041010";
          aidParameters.asi = 0;
          aidParameters.appVerNum = "0001";
          aidParameters.tacDefault = "cc00fc8000";
          aidParameters.tacOnline = "cc00fc8000";
          aidParameters.tacDecline = "0000000000";
          aidParameters.floorLimit = "00000000";
          aidParameters.threshold = "00000000";
          aidParameters.maxTargetPercent = 99;
          aidParameters.targetPercent = 99;
          aidParameters.termDDOL = "9f3704";
          aidParameters.vlptranslimit = "000000100000";
          aidParameters.termcvmlimit = "000999999999";
          aidParameters.clessofflinelimitamt = "000000100000";
          aidParameters.otherTLV = "9f1a0208405f2a020840";
          itronBle.downloadAIDParameters(aidParameters, (status) {
            String str = '';
            if (status == 0) {
              str = 'downloadAIDParameters success';
            } else {
              str = 'downloadAIDParameters fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Download publicKey
      case 9:
        {
          M6pCAPublicKey caPublicKey = M6pCAPublicKey();
          caPublicKey.rid = "A000000333";
          caPublicKey.capki = 3;
          caPublicKey.hashInd = 1;
          caPublicKey.arithInd = 1;
          caPublicKey.modul =
              "b0627dee87864f9c18c13b9a1f025448bf13c58380c91f4ceba9f9bcb214ff8414e9b59d6aba10f941c7331768f47b2127907d857fa39aaf8ce02045dd01619d689ee731c551159be7eb2d51a372ff56b556e5cb2fde36e23073a44ca215d6c26ca68847b388e39520e0026e62294b557d6470440ca0aefc9438c923aec9b2098d6d3a1af5e8b1de36f4b53040109d89b77cafaf70c26c601abdf59eec0fdc8a99089140cd2e817e335175b03b7aa33d";
          caPublicKey.exponent = "03";
          caPublicKey.expireDate = "20241231";
          caPublicKey.checkSum = "87F0CD7C0E86F38F89A66F8C47071A8B88586F26";
          itronBle.downloadPublicKey(caPublicKey, (status) {
            String str = '';
            if (status == 0) {
              str = 'downloadPublicKey success';
            } else {
              str = 'downloadPublicKey fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Calculate MAC
      case 10:
        {
          // entype  1:DUKPT ; 2:MK/SK
          // index  index
          // mactype  0x00 ECB；0x01 CBC； 0x02 X919； 0x03 XOR ;  0x04 CMAC
          // macData macData
          itronBle.calculateMac(2, 1, 4, '0000000000000000',
              (mac, ksn, status) {
            String str = '';
            if (status == 0) {
              str = 'calculateMac success,mac:${mac},,mac:${ksn}';
            } else {
              str = 'calculateMac fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //PIN entry
      case 11:
        {
          // itronBle.pinEntry('12345678', '01', (pin, status) {
          //   String str = '';
          //   if (status == 0) {
          //     str = 'pinEntry success,pin:${pin}';
          //   } else {
          //     str = 'pinEntry fail,error code:' + status.toRadixString(16);
          //   }
          //   setState(() {
          //     textStr = str;
          //   });
          // });
        }
        break;
      //Update terminal time
      case 12:
        {
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
          itronBle.setTerminalDateTime(time, (status) {
            String str = '';
            if (status == 0) {
              str = 'setTerminalDateTime success';
            } else {
              str = 'setTerminalDateTime fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //EMV onlineRespose   交易结果 00 成功,
      case 13:
        {
          itronBle.sendOnlineProcessResult('00', '',
              (onlineResult, scriptResult, data, status) {
            String str = '';
            if (status == 0) {
              str = 'onlineRespose success\n' +
                  'onlineResult:${onlineResult.toString()}\n' +
                  'scriptResult:${scriptResult}\n' +
                  'data:${data}';
            } else {
              str = 'setTerminalDateTime fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Return terminal time
      case 14:
        {
          itronBle.getTerminalDateTime((time, status) {
            String str = '';
            if (status == 0) {
              str = 'getTerminalDateTime success,time:${time}';
            } else {
              str = 'getTerminalDateTime fail,error code:' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //m6plus download
      case 15:
        {
          _getHttp();
        }
        break;
      //m6plus downloadKey
      case 16:
        {
          itronBle.downloadWorkKey(
              "020000000000",
              'E1634F2E5620037CE1634F2E5620037C',
              'E1634F2E5620037CE1634F2E5620037C',
              'E1634F2E5620037CE1634F2E5620037C', (status) {
            String str = '';
            if (status == 0) {
              str = 'downloadWorkKey success';
            } else {
              str =
                  'downloadWorkKey fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //testData
      case 17:
        {
          testNumber = 0;
          /*
          String str1 =
              '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5';
          itronBle.testData(str1, (str2, status) {
            String str = '';
            if (status == 0) {
              str = 'testData success';
            } else {
              str = 'testData fail,error code:' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });*/
          _testData1();
        }
        break;
      case 18:
        // "Upgrade KEK",
        /**
           * 更新KEK
           * @param entype 0：TDES , 1：AES 
           * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
           * @param keyData keydata = KEK密文数据: KEK密文
           * @param cmac 用KEK密钥对其他Data数据算CMAC值
           */
        // KEK  plaintext 80278BC7F68CE0885FE753ADBE15409680AA8937FE9F5D75
        {
          print('download KEK 3DES');
          //
          String kek = '2BBC760365CE72670A4DD8A7B95517F62E31B9170D943CA1';
          String cmac = "8B014D";
          itronBle.downloadKeK(0, 0x18, kek, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'KEK download success';
            } else {
              str = 'KEK download fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      // "Upgrade DUKPT 3DES Index0",
      case 19:
        {
          print('Upgrade DUKPT 3DES Index0');
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
          // DUKPT plaintext key 6A C2 92 FA A1 31 5B 4D 85 8A B3 A3 D7 D5 93 3A
          String mk = "098AEF205C857CD93A21F7ABAE523C13";
          // TDES calculation mac
          // key TDES ECB 0x0000000000000000  get MAC
          String cmac = "AF8C07";
          String ksn = "FFFF9876543210E00000";
          itronBle.downloadMKDUKPT(1, 0, 0, 0x10, ksn, mk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'MK download success';
            } else {
              str = 'MK download fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      // "Upgrade MK/SK, Index1, 3DES, TMK",
      case 20:
        {
          /**
           * update MK/DUKPT
           * @param keytype  0 MK , 1 DUKPT
           * @param entype 0：TDES , 1：AES 
           * @param index MK index 0-99; DUKPT 1-5
           * @param ksn DUKPT exists
           * @param key
           * @param cmac key 16biytes 0x00 CMAC   DES 3bytes/ AES 5bytes
           */
          // MK plaintext 111111111111111111111111111111112222222222222233
          // key TDES ECB 0x0000000000000000  get MAC
          print('Upgrade MK/SK, Index1, 3DES, TMK');
          String mk = '0FD862575D40413E0FD862575D40413E5E100AF922F7E07A';
          String cmac = '642873';
          itronBle.downloadMKDUKPT(0, 0, 1, 0x18, '', mk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'MK download success';
            } else {
              str = 'MK download fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      // "Upgrade SK TDES, Index1, TDES 3Keys Data Key",
      case 21:
        {
          print('Upgrade SK TDES, Index1, TDES 3Keys Data Key');
          /**
           * 更新 SK
           * @param index 密钥索引
           * @param keytype 密钥类型 0x01 PINkey, 0x02=Data Key, 0x03=Mac Key
           * @param entype 0：TDES , 1：AES 
           * @param keyLength  TDES: 16B or 24B, AES: 16B or 24B
           * @param key 密钥
           * @param cmac 用KEK密钥对其他Data数据算CMAC值
           */
          // key  plaintext F439121BEC83D26B169BDCD5B22AAF8FF439121BEC83D26B
          // key TDES ECB 0x0000000000000000  get MAC
          String mk = "91B9F04806600572E8920E46D056761791B9F04806600572";
          String cmac = "DBC74F";
          itronBle.downloadSK(1, 0x02, 0, 0x18, mk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'DUKPT download success';
            } else {
              str = 'DUKPT download fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      // "Upgrade SK TDES, Index1, TDES 3Keys PIN Key"
      case 22:
        {
          print('Upgrade SK TDES, Index1, TDES 3Keys PIN Key');
          // key plaintext  E039121BEC83D26B169BDCD5B22AAF8FE039121BEC83D26B
          // key TDES ECB 0x0000000000000000  get MAC
          String sk = '31D9FD2C6C2EA9E1E8920E46D056761731D9FD2C6C2EA9E1';
          String cmac = '76AC5E';
          itronBle.downloadSK(1, 0x01, 0, 0x18, sk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'Upgrade PinKey(MK/SK,3DES) download success';
            } else {
              str = 'Upgrade PinKey(MK/SK,3DES) download fail ' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      //Upgrade SK TDES, Index1, TDES 3Keys MAC Key
      case 23:
        {
          print('Upgrade SK TDES, Index1, TDES 3Keys MAC Key');
          //key plaintext F6 39 12 1B EC 83 D2 6B 16 9B DC D5 B2 2A AF 8F
          String sk = '64D22042517B853EE8920E46D0567617';
          // TDES calculation mac
          // key TDES ECB 0x0000000000000000  get MAC
          String cmac = '88ADFF';
          itronBle.downloadSK(1, 0x03, 0, 0x10, sk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'Upgrade PinKey(MK/SK,3DES) download success';
            } else {
              str = 'Upgrade PinKey(MK/SK,3DES) download fail ' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 24:
        //Upgrade SK TDES, Index3, TDES 2Keys PIN Key
        {
          print('Upgrade SK TDES, Index1, TDES 2Keys PIN Key');
          //key plaintext 28 97 3E 34 37 0D B4 16 C4 0F 3F E4 77 FF 5C 6B
          String sk = '56E794D248C76E84B9AC0D800FF5F432';
          // TDES calculation mac
          // key TDES ECB 0x0000000000000000  get MAC
          String cmac = '7EC5F8';
          itronBle.downloadSK(1, 0x01, 0, 0x10, sk, cmac, (status) {
            String str = '';
            if (status == 0) {
              str = 'Upgrade PinKey(MK/SK,3DES) download success';
            } else {
              str = 'Upgrade PinKey(MK/SK,3DES) download fail ' +
                  status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 25:
        //Request Display
        {
          print('Request Display');
          itronBle.requestDisplay(
              16, 5, "Balance: 1000.00", 0, 1000, 2, 0, 5000, 0, (status) {
            String str = '';
            if (status == 0) {
              str = 'Request Display success';
            } else {
              str = 'Request Display fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          }, (errorID, msg) {
            setState(() {
              textStr = ' error code: ${errorID} msg: ${msg}';
            });
          }, () {
            setState(() {
              textStr = 'please wait input';
            });
          });
        }
        break;
      case 26:
        //download TKP
        {
          print('download TKP');
          itronBle.downloadTPK(
              1,
              0,
              0x18,
              "91B9F04806600572E8920E46D05676170110AF4BBFC0AAFF",
              "37730C", (status) {
            String str = '';
            if (status == 0) {
              str = 'download TKP success';
            } else {
              str = 'download TKP fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 27:
        //Request DataEncrypt
        {
          print('Request DataEncrypt');
          itronBle.requestDataEncrypt(
              "343031323334353637383930394439383700000000000000",
              2,
              1,
              "0000000011223344",
              0,
              0,
              "", (encryptedData, ksn, status) {
            String str = '';
            if (status == 0) {
              str = 'Request DataEncrypt success\n' +
                  'encryptedData:${encryptedData}\n' +
                  'ksn:${ksn}\n' +
                  'status:${status}';
            } else {
              str = 'Request DataEncrypt fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 28:
        //Request DataDecrypt
        {
          print('Request DataDecrypt');
          itronBle.requestDataDecrypt(
              "BBB4C2743295207E31BD4B08128F11DA1E2489DC8CEAD201",
              2,
              1,
              "0000000011223344",
              0,
              0,
              "", (decryptData, ksn, status) {
            String str = '';
            if (status == 0) {
              str = 'Request DataDecrypt success\n' +
                  'decryptData:${decryptData}\n' +
                  'ksn:${ksn}\n' +
                  'status:${status}';
            } else {
              str = 'Request DataDecrypt fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 29:
        //get SecretKey Info
        {
          print('get SecretKey Info');
          itronBle.getSecretKeyInfo(2, 0, 1, 0x82, (keyInfo, kcv, ksn, status) {
            String str = '';
            if (status == 0) {
              str = 'get SecretKey Info success\n' +
                  'keyInfo:${keyInfo}\n' +
                  'kcv:${kcv}\n' +
                  'ksn:${ksn}\n' +
                  'status:${status}';
            } else {
              str = 'get SecretKey Info fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          });
        }
        break;
      case 30:
        //Request Input ZIP Code
        {
          print('Request Input ZIP Code');
          itronBle.requestInput(0x10, 1, 0, 16, 60, "\n   Enter ZIP Code", "",
              (input, status) {
            String str = '';
            if (status == 0) {
              str = 'Request Input success\n' + 'input:${input}\n';
            } else {
              str = 'Request Input fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          }, (errorID, msg) {
            setState(() {
              textStr = ' error code: ${errorID} msg: ${msg}';
            });
          }, () {
            setState(() {
              textStr = 'please wait input';
            });
          });
        }
        break;
      case 31:
        //Request Input CVV
        {
          print('Request Input CVV');
          itronBle.requestInput(0x10, 1, 3, 3, 60, "\n   Enter Card CVV", "",
              (input, status) {
            String str = '';
            if (status == 0) {
              str = 'Request Input success\n' + 'input:${input}\n';
            } else {
              str = 'Request Input fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          }, (errorID, msg) {
            setState(() {
              textStr = ' error code: ${errorID} msg: ${msg}';
            });
          }, () {
            setState(() {
              textStr = 'please wait input';
            });
          });
        }
        break;
      case 32:
        //Request Input And Check
        {
          print('Request Input And Check');
          itronBle.requestInputAndCheck(10, 16, 60,
              (cardNo, cardexpiryDate, status) {
            String str = '';
            if (status == 0) {
              str = 'Request Input success\n' +
                  'input:${cardNo}\n' +
                  'expirationDate:${cardexpiryDate}\n';
            } else {
              str = 'Request Input fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          }, (errorID, msg) {
            setState(() {
              textStr = ' error code: ${errorID} msg: ${msg}';
            });
          }, () {
            setState(() {
              textStr = 'please wait input';
            });
          });
        }
        break;
      case 33:
        //Request QRCode Display
        {
          print('Request QRCode Display');
          itronBle.requestQRCodeDisplay(0x00, "Please scan the QR code",
              "https://www.apple.com", "12345\r\n", 60, (input, status) {
            String str = '';
            if (status == 0) {
              str = 'Request Input success\n' + 'input:${input}\n';
            } else {
              str = 'Request Input fail ' + status.toRadixString(16);
            }
            setState(() {
              textStr = str;
            });
          }, (errorID, msg) {
            setState(() {
              textStr = ' error code: ${errorID} msg: ${msg}';
            });
          }, () {
            setState(() {
              textStr = 'please wait input';
            });
          });
        }
        break;
      case 34:
        {
          // Mifare classic wallet Init
          AlertDialogWidget().mifareRechargeDialog(context, (
            Akey,
            Bkey,
            sector,
            blockID,
            cash,
          ) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            print(mifareCard.getblockaddr());
            print(mifareCard.moneyLittleEndian(int.parse(cash!)));
            print(mifareCard.initMoney(int.parse(cash)));
            itronBle.walletInitMifare(mifareCard, 30, int.parse(cash),
                (status, msg) {
              List<String> list = _arryAPDURespondData(msg);
              setState(() {
                textStr = list.toString() + cash;
              });
            });
          });
        }
        break;
      case 35:
        {
          // Mifare classic wallet Recharge
          AlertDialogWidget().mifareRechargeDialog(context, (
            Akey,
            Bkey,
            sector,
            blockID,
            cash,
          ) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            itronBle.walletRechargeMifare(mifareCard, 30, int.parse(cash!),
                (status, msg) {
              List<String> list = _arryAPDURespondData(msg);
              setState(() {
                textStr = list.toString();
              });
            });
          });
        }
        break;
      case 36:
        {
          // Mifare classic wallet Deduction
          AlertDialogWidget().mifareDeductionDialog(context, (
            Akey,
            Bkey,
            sector,
            blockID,
            cash,
          ) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            itronBle.walletDeductionMifare(mifareCard, 30, int.parse(cash!),
                (status, msg) {
              // if (status == 0) {
              //   print("wallet Deduction Mifare Success " + msg);
              // }
              List<String> list = _arryAPDURespondData(msg);
              setState(() {
                textStr = list.toString();
              });
            });
          });
        }
        break;
      case 37:
        {
          // Mifare classic wallet  Surplus
          print("Mifare classic wallet Surplus ");
          AlertDialogWidget().mifareInitDialog(context, (
            Akey,
            Bkey,
            sector,
            blockID,
          ) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            itronBle.walletSurplusMifare(mifareCard, 30, (status, msg) {
              List<String> list = _arryAPDURespondData(msg);
              String str = list[list.length - 1];
              if (str.substring(str.length - 4, str.length) == '9000') {
                setState(() {
                  int cash = mifareCard
                      .littleToMoney(list[list.length - 1].substring(0, 8));
                  textStr = list.toString() + "\n cash: " + cash.toString();
                });
              } else {
                setState(() {
                  textStr = list.toString();
                });
              }
            });
          });
        }
        break;
      case 38:
        {
          // Mifare classic sector read
          print("Mifare classic sector read ");
          AlertDialogWidget().mifareInitDialog(context, (
            Akey,
            Bkey,
            sector,
            blockID,
          ) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            itronBle.readMifareClassic(mifareCard, 30, (status, msg) {
              List<String> list = _arryAPDURespondData(msg);
              String str = list[list.length - 1];
              if ((str.length == 40) &&
                  (str.substring(str.length - 4, str.length) == '9000')) {
                setState(() {
                  textStr = list.toString() +
                      "\n data: " +
                      str.substring(0, str.length - 8);
                });
              } else {
                setState(() {
                  textStr = list.toString();
                });
              }
            });
          });
        }
        break;
      case 39:
        {
          // Mifare classic sector write
          print("Mifare classic sector write ");
          AlertDialogWidget().mifareWriteDialog(context,
              (Akey, Bkey, sector, blockID, data) {
            MifareCard mifareCard = new MifareCard();
            mifareCard.Akey = Akey;
            mifareCard.Bkey = Bkey;
            mifareCard.sector = int.parse(sector!);
            mifareCard.blockID = int.parse(blockID!);
            mifareCard.data = data;
            itronBle.writeMifareClassic(mifareCard, 10, (status, msg) {
              List<String> list = _arryAPDURespondData(msg);
              setState(() {
                textStr = list.toString();
              });
            });
          });
        }
        break;
      case 40:
        {
          // Mifare Desfire operation command
          List<String> apduData = [];
          // Mifare Desfire card execution command
          apduData.add('5A010000');
          apduData.add('BD02000000020000');
          itronBle.operateMifareDesfire(apduData, 10, (data, status) {
            setState(() {
              textStr = data.toString();
            });
          });
        }
        break;
      default:
    }
  }

  _testData1() {
    if (testNumber < 10) {
      testNumber = testNumber + 1;
      String str1 =
          '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5';
      itronBle.testData(str1, (str2, status) {
        String str = '';
        if (status == 0) {
          str = 'testData success:${testNumber} times';
        } else {
          str = 'testData fail::${testNumber} times,error code:' +
              status.toRadixString(16);
        }
        setState(() {
          textStr = str;
        });
        _testData1();
      });
    }
  }

  _getHttp() async {
    String url = 'https://wx.itron.com.cn/mp4/M6Pluz_APP_Sign.bin';

    Response response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    if (response.statusCode == 200) {
      List<int> data = response.data;
      print('请求成功');
      itronBle.firmwareUpdateRequest('01', data, (progress) {
        print('progress:${progress}%');
        setState(() {
          textStr = 'progress:${progress}%';
        });
      }, (status) {
        String str = '';
        if (status == 0) {
          str = 'Update success';
        } else {
          str = 'Update fail,error code:' + status.toRadixString(16);
        }
        setState(() {
          textStr = str;
        });
        print(str);
      });
    }
  }

  // APDU 命令解析
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width1 = size.width;
    return Container(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey,
              width: width1,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: MaterialButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return SimpleDialog(
                                  title: Text('Select Command'),
                                  children: createSimpleDialogOption(context),
                                );
                              });
                        },
                        minWidth: 100,
                        color: Colors.blue,
                        child: Text(commandStr),
                      ),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                    child: Center(
                      child: MaterialButton(
                        onPressed: () {
                          sendCommand(context);
                        },
                        minWidth: 100,
                        color: Colors.red,
                        child: Text('Send Command'),
                      ),
                    ),
                    flex: 1,
                  ),
                ],
              ),
            ),
            flex: 1,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              width: width1,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 50),
                child: Scrollbar(
                  controller: scr,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scr,
                    child: Text(textStr),
                  ),
                ),
              ),
            ),
            flex: 4,
          ),
        ],
      ),
    );
  }
}
