import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlertDialogWidget {
  showCupertinoDialog(
      BuildContext context,
      void Function(String? cash, String? currencyCode, String? countryCode)
          showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          String cashValue = '';
          String currencyValue = '';
          String countryValue = '';
          return CupertinoAlertDialog(
            title: Text('Please enter cash, currency code, country code'),
            content: Card(
              elevation: 0.0,
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    placeholder: 'cash 1200',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      cashValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'currency code 0840',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      currencyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'country code 0840',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      countryValue = value;
                    },
                  ),
                  // TextField(
                  //   keyboardType: TextInputType.number,
                  //   decoration: InputDecoration(
                  //     hintText: 'cash 1200',
                  //   ),
                  //   onChanged: (value) {
                  //     cashValue = value;
                  //   },
                  // ),
                  // TextField(
                  //   keyboardType: TextInputType.number,
                  //   decoration: InputDecoration(
                  //     hintText: 'currency code 0840',
                  //   ),
                  //   onChanged: (value) {
                  //     currencyValue = value;
                  //   },
                  // ),
                  // TextField(
                  //   keyboardType: TextInputType.number,
                  //   decoration: InputDecoration(
                  //     hintText: 'country code 0840',
                  //   ),
                  //   onChanged: (value) {
                  //     countryValue = value;
                  //   },
                  // ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  showDialogCallback(cashValue, currencyValue, countryValue);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  mifareInitDialog(
      BuildContext context,
      void Function(String? AKey, String? Bkey, String? sector, String? blockID)
          showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          String AKeyValue = 'FFFFFFFFFFFF';
          String BKeyValue = '';
          String SectorValue = '1';
          String blockIDValue = '0';
          return CupertinoAlertDialog(
            title: Text(
                'Mifare Wallet init Please enter Mifare Akey, Bkey, sector, blockID'),
            content: Card(
              elevation: 0.0,
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    placeholder: 'Akey FFFFFFFFFFFF',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      if (value.length == 12) {
                        AKeyValue = value;
                      } else {
                        print("A Key length error");
                      }
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Akey FFFFFFFFFFFF',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      if (value.length == 12) {
                        AKeyValue = value;
                      } else {
                        print("B Key length error");
                      }
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Sector 1',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      SectorValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'blockID 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      blockIDValue = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  showDialogCallback(
                      AKeyValue, BKeyValue, SectorValue, blockIDValue);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  // 充值输入框
  mifareRechargeDialog(
      BuildContext context,
      void Function(String? AKey, String? Bkey, String? sector, String? blockID,
              String? cash)
          showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          String AKeyValue = 'FFFFFFFFFFFF';
          String BKeyValue = '';
          String SectorValue = '1';
          String blockIDValue = '0';
          String cashValue = '0';
          return CupertinoAlertDialog(
            title: Text(
                'Mifare Wallet Recharge Please enter Akey, Bkey, sector , blockID ,recharge cash'),
            content: Card(
              elevation: 0.0,
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    placeholder: 'Akey FFFFFFFFFFFF',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      AKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Bkey ',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      BKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Sector 1',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      SectorValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'blockID 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      blockIDValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'cash 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      cashValue = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  showDialogCallback(AKeyValue, BKeyValue, SectorValue,
                      blockIDValue, cashValue);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  // 消费输入框
  mifareDeductionDialog(
      BuildContext context,
      void Function(String? AKey, String? Bkey, String? sector, String? blockID,
              String? cash)
          showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          String AKeyValue = 'FFFFFFFFFFFF';
          String BKeyValue = '';
          String SectorValue = '1';
          String blockIDValue = '0';
          String cashValue = '0';
          return CupertinoAlertDialog(
            title: Text(
                'Mifare Wallet Deductio Please enter Akey, Bkey, sector , blockID, deductio cash'),
            content: Card(
              elevation: 0.0,
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    placeholder: 'Akey FFFFFFFFFFFF',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      AKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Bkey',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      BKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Sector 1',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      SectorValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'blockID 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      blockIDValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'cash 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      cashValue = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  showDialogCallback(AKeyValue, BKeyValue, SectorValue,
                      blockIDValue, cashValue);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  // 消费输入框
  mifareWriteDialog(
      BuildContext context,
      void Function(String? Akey, String? Bkey, String? sector, String? blockID,
              String? data)
          showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          String AKeyValue = 'FFFFFFFFFFFF';
          String BKeyValue = '';
          String SectorValue = '2';
          String blockIDValue = '0';
          String dataValue = '00000000000000000000000000000000';
          return CupertinoAlertDialog(
            title: Text(
                'Mifare Wallet Deductio Please enter Akey or Bkey, sector , blockID, \n data 0x00-0xFF, len 16 bytes '),
            content: Card(
              elevation: 0.0,
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    placeholder: 'key FFFFFFFFFFFF',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      AKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Bkey ',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      BKeyValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'Sector 2',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      SectorValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'blockID 0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      blockIDValue = value;
                    },
                  ),
                  CupertinoTextField(
                    placeholder: 'data: 00000000000000000000000000000000',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      dataValue = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  showDialogCallback(AKeyValue, BKeyValue, SectorValue,
                      blockIDValue, dataValue);
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  typeChooseDialog(
      BuildContext context, void Function(int apdutype) showDialogCallback) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
              title: Text('Please select APDU type'),
              content: Card(
                  elevation: 0.0,
                  child: Column(children: <Widget>[
                    DropdownButton<int>(
                      // 弹框列表
                      items: [
                        DropdownMenuItem(
                          child: Text("APDU IC"),
                          value: 0,
                          onTap: () {
                            Navigator.pop(context);
                            showDialogCallback(0);
                          },
                        ),
                        DropdownMenuItem(
                          child: Text("APDU NFC"),
                          value: 1,
                          onTap: () {
                            Navigator.pop(context);
                            showDialogCallback(1);
                          },
                        ),
                        DropdownMenuItem(
                          child: Text("APDU Mifare classic"),
                          value: 3,
                          onTap: () {
                            Navigator.pop(context);
                            showDialogCallback(3);
                          },
                        ),
                        DropdownMenuItem(
                          child: Text("APDU Mifare Desfire"),
                          value: 5,
                          onTap: () {
                            Navigator.pop(context);
                            showDialogCallback(5);
                          },
                        )
                      ],
                      hint: Text("下拉按钮"), // 下拉按钮的文字
                      value:
                          0, // 按钮默认显示弹框列表的哪个 item，和 DropdownMenuItem 的 value 相对应
                      // 选了某个选项时触发
                      onChanged: (selected) {
                        // print("_MyHomePageState - build onChanged $selected");
                        // apdutype = apdutypeValue;
                      },
                    )
                  ])));
        });
  }
}
