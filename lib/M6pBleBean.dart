class M6pBleDevice {
  String? name;
  String? UUID;
  int? rssi;
  @override
  String toString() {
    return 'name:${this.name},UUID:${this.UUID},rssi:${this.rssi}';
  }
}

class M6pTerminalInfo {
  String? sn;
  String? tusn;
  String? bluetoothName;
  String? bluetoothMAC;
  String? bluetoothVersion;
  String? appVersion;
  String? appVersionDate;
  String? kernelVersion;
  String? kernelVersionDate;
  String? hardwareVersion;
  String? softVersion;
  String? operationMode;
  String? language;
  @override
  String toString() {
    return 'sn:${this.sn}\n' +
        'tusn:${this.tusn}\n' +
        'bluetoothName:${this.bluetoothName}\n' +
        'bluetoothMAC:${this.bluetoothMAC}\n' +
        'bluetoothVersion:${this.bluetoothVersion}\n' +
        'appVersion:${this.appVersion}\n' +
        'appVersionDate:${this.appVersionDate}\n' +
        'kernelVersion:${this.kernelVersion}\n' +
        'kernelVersionDate:${this.kernelVersionDate}\n' +
        'hardwareVersion:${this.hardwareVersion}\n' +
        'softVersion:${this.softVersion}\n' +
        'operationMode:${this.operationMode}\n' +
        'language:${this.language}\n';
  }
}

class M6pTransactionInfo {
  String currencyCode = '0840';
  String countryCode = '0840';
  String type = '00';
  @override
  String toString() {
    return 'currencyCode:${this.currencyCode},type:${this.type},countryCode:${this.countryCode}';
  }
}

class M6pTradeData {
  String swipeMode = '70';
  String sign = '10633630';
  String? encryptionAlg;
  String? swipeTitle;
  String? pinTitle;
  String random = '313233';
  String? cash;
  String? actionInfo;
  String? extraData;
  String? displayData;
  String? subTitle;
  String? panAndValidInputControl;
  M6pTransactionInfo? transactionInfo;
}

class M6pCardInfo {
  String? ksn;
  String? tsn;
  String? terimalNo;
  String? controlModel;
  String? psamNo;
  String? cardName;
  String? cardNo;
  int cardType = 0;
  String? nfcCompany;
  int tradeChannel = 0;
  String? cardexpiryDate;
  String? pan;
  String? cardSerial;
  String? cvm;
  String? tracks;
  String? trackLen;
  String? originalTrack;
  String? originalTracklength;
  String? encryTrack;
  String? encryTrackLen;
  String? pin;
  String? mac;
  String? tusn;
  String? icdata;
  String? random;
  String? result;
  String? deninalReason;
  String? kernelType;
  String? outcomeParameterSet;
  String? userInterfaceRequestData;
  String? errorIndication;
  int nfcCardType = 0;
  String? swipeFailMessage;
  String? electronicCash;
  String? track1;
  String? track2;
  String? track3;
  String? batteryLevel;
  String? serviceCode;
  String? dataKsn;
  String? trackKsn;
  String? macKsn;
  String? emvKsn;
}

class M6pAIDParameters {
  String? aid;
  int asi = 0;
  String? appVerNum;
  String? tacDefault;
  String? tacOnline;
  String? tacDecline;
  String? floorLimit;
  String? threshold;
  int maxTargetPercent = 0;
  int targetPercent = 0;
  String? termDDOL;
  String? vlptranslimit;
  String? termcvmlimit;
  String? clessofflinelimitamt;
  String? otherTLV;
}

class M6pCAPublicKey {
  String? rid;
  int capki = 0;
  int hashInd = 0;
  int arithInd = 0;
  String? modul;
  String? exponent;
  String? expireDate;
  String? checkSum;
}

class MifareCard {
  // 1K  0 - 15
  // 4K  0 - 39
  int sector = 0;
  // 0 - 4
  int blockID = 0;
  int blockaddr = 0;
  // 16 bytes HexString
  String? data;
  // A key
  String? Akey;
  // B key
  String? Bkey;

  String getblockaddr() {
    if (sector < 32) {
      // 扇区*4 + 块号
      blockaddr = sector * 4 + blockID;
    } else {
      // 扇区 -32  *16 + 块号 + 32*4
      blockaddr = (sector - 32) * 16 + blockID + 32 * 4;
    }
    String num = blockaddr.toRadixString(16);
    if (num.length % 2 != 0) {
      num = '0' + num;
    }
    return num;
  }

  // int 金额转HEX小端格式
  String moneyLittleEndian(int money) {
    String str = money.toRadixString(16);
    if (str.length % 2 != 0) {
      str = '0' + str;
    }
    String str1 = '';
    for (int i = 0; i < str.length; i = i + 2) {
      str1 = str.substring(i, i + 2) + str1;
    }
    while (str1.length < 8) {
      str1 = str1 + '0';
    }
    return str1;
  }

  // 小端HEX转 int类型
  int littleToMoney(String str) {
    String str1 = '';
    for (int i = 0; i < str.length; i = i + 2) {
      str1 = str.substring(i, i + 2) + str1;
    }
    return int.parse(str1, radix: 16);
  }

  String initMoney(int money) {
    String str = moneyLittleEndian(money);
    String initstr = str +
        xorString(str) +
        str +
        getblockaddr() +
        xorString(getblockaddr()) +
        getblockaddr() +
        xorString(getblockaddr());
    return initstr.toUpperCase();
  }

  String xorString(String str) {
    List<int> list = _strToIntArr(str);
    String str1 = '';
    int num = 0;
    for (int i = 0; i < list.length; i++) {
      num = 255 - list[i];
      var binary = num.toRadixString(16);
      if (binary.length % 2 != 0) {
        str1 = str1 + '0' + binary;
      } else {
        str1 = str1 + binary;
      }
    }
    return str1;
  }

  List<int> _strToIntArr(String str) {
    List<int> arr = [];
    for (int i = 0; i < str.length / 2; i++) {
      int a = _hexToInt(str.substring(i * 2, i * 2 + 2));
      arr.add(a);
    }
    return arr;
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
}
