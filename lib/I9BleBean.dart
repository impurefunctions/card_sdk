class I9BleDevice {
  String? name;
  String? UUID;
  int? rssi;
  @override
  String toString() {
    return 'name:${this.name},UUID:${this.UUID},rssi:${this.rssi}';
  }
}

class I9TransactionInfo {
  String currencyCode = '0840';
  String type = '0840';
  String countryCode = '00';
  @override
  String toString() {
    return 'currencyCode:${this.currencyCode}\n' +
        'type:${this.type}\n' +
        'countryCode:${this.countryCode}\n';
  }
}

class I9TradeData {
  String swipeMode = '70';
  String sign = '10633630';
  String? encryptionAlgorithm;
  String? swipeTitle;
  String? pinTitle;
  String random = '313233';
  String? cash;
  I9TransactionInfo? transactionInfo;
  String? extraData;
  String? displayData;
  @override
  String toString() {
    return 'swipeMode:${this.swipeMode}\n' +
        'sign:${this.sign}\n' +
        'encryptionAlgorithm:${this.encryptionAlgorithm}\n' +
        'swipeTitle:${this.swipeTitle}\n' +
        'pinTitle:${this.pinTitle}\n' +
        'random:${this.random}\n' +
        'cash:${this.cash}\n' +
        'extraData:${this.extraData}\n' +
        'displayData:${this.displayData}\n';
  }
}

class I9CardInfo {
  String? ksn;
  String? tsn;
  String? controlModel;
  String? psamNo;
  String? cardName;
  String? cardNo;
  int? cardType;
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
  String? originalTrack;
  String? originalTracklength;
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
  int? nfcCardType;
  String? swipeFailMessage;
  String? track1;
  String? track2;
  String? track3;
  String? serviceCode;
  String? batteryLevel;
  String? dataKsn;
  String? trackKsn;
  String? macKsn;
  String? emvKsn;
  /*
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
  }*/
}

class I9TerminalInfo {
  int? terminalType;
  String? sn;
  String? tsn;
  String? softVersion;
  String? softVersionDate;
  String? bluetoothName;
  String? bluetoothMAC;
  String? bluetoothVersion;
  String? merchaantName;
  String? merchaantNo;
  String? psamNo;
  String? protocolType;
  String? kernelVersion;
  String? hardwareVersion;
  String? firmwareVersion;
  String? cpuSN;
  String? customerSN;
  String? operationMode;
  String? language;
  /*
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
  }*/
}

class I9AIDParameters {
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

class I9CAPublicKey {
  String? rid;
  int capki = 0;
  int hashInd = 0;
  int arithInd = 0;
  String? modul;
  String? exponent;
  String? expireDate;
  String? checkSum;
}

class I9DownloadTag {
  String? cf;
  String? pl;
  String? dt;
  String? ti;
  String? vr;
  String? na;
  String? pt;
  String? pd;
  String? dO;
  String? ex;
  String? pr;
  String? downloadData;
}
