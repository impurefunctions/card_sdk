class BleDevice {
  String? name;
  String? UUID;
  int? rssi;
  @override
  String toString() {
    return 'name:${this.name},UUID:${this.UUID},rssi:${this.rssi}';
  }
}

class TerminalInfo {
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
        'softVersion:${this.softVersion}\n';
  }
}

class TransactionInfo {
  String currencyCode = '0840';
  String type = '0840';
  String countryCode = '00';
  @override
  String toString() {
    return 'currencyCode:${this.currencyCode},type:${this.type},countryCode:${this.countryCode}';
  }
}

class TradeData {
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
  TransactionInfo? transactionInfo;
}

class CardInfo {
  String? ksn;
  String? tsn;
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
}

class AIDParameters {
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

class CAPublicKey {
  String? rid;
  int capki = 0;
  int hashInd = 0;
  int arithInd = 0;
  String? modul;
  String? exponent;
  String? expireDate;
  String? checkSum;
}
