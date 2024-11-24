
import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:grmobileallpt/drawer.dart';
import 'package:grmobileallpt/models/db_helper.dart';
import 'package:grmobileallpt/utils/list_extensions.dart';
import 'package:grmobileallpt/utils/storage.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';

final formatQTYRegex = RegExp(r'([.]*0+)(?!.*\d)');

class ScanQRPage extends StatefulWidget {
  final Map<String, dynamic>? initialPOData;

  const ScanQRPage({super.key, this.initialPOData});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final Apiuser apiuser = Apiuser();
  final StorageService storageService = StorageService.instance;
  final ApiService apiservice = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> detailPOData = [];
  List<Map<String, dynamic>> detailPODataScan = [];
  List<Map<String, dynamic>> notInPOItems =[]; 
  List<Map<String, dynamic>> scannedResults = []; 
  List<Map<String, dynamic>> differentScannedResults =[]; 
  List<Map<String, dynamic>> noitemScannedResults =[]; 
  bool isLoading = false;
  final TextEditingController _poNumberController =TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _koliController = TextEditingController();
  final TextEditingController _transnoController = TextEditingController();
  QRViewController? controller;
  String scannedBarcode = "";
  late String userId = '';
  FocusNode textsecond = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<int, TextEditingController> _controllers = {};
  Map<int, TextEditingController> _controllers1 = {};
  Map<int, TextEditingController> _controllers2 = {};


    Map<String, dynamic> mutableResult = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPOData != null) {
      detailPOData = [widget.initialPOData!];

      mutableResult = widget.initialPOData!; 
    }
    
     for (var i = 0; i < scannedResults.length; i++) {
      _controllers[i] = TextEditingController(
        text: scannedResults[i]['qty_scanned'].toString(),
        
      );
      
     }
     for (var i = 0; i < differentScannedResults.length; i++) {
      _controllers1[i] = TextEditingController(
        text: differentScannedResults[i]['qty_scanned'].toString(),
      );
     }
     for (var i = 0; i < noitemScannedResults.length; i++) {
      _controllers2[i] = TextEditingController(
        text: noitemScannedResults[i]['qty_scanned'].toString(),
      );
     }
  }
  


  @override
  void dispose() {
     _controllers.forEach((key, controller) {
      controller.dispose();
    });
    _controllers1.forEach((key, controller) {
      controller.dispose();
    });
    _controllers2.forEach((key, controller) {
      controller.dispose();
    });
    _audioPlayer.dispose(); 
   
    super.dispose();
  }

  void playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  //   Future<void> fetchPOData(String pono) async {
  //   setState(() => isLoading = true);
  //   try {
  //     final userData = storageService.get(StorageKeys.USER);
  //     final response = await apiservice.loginUser(
  //       userData['USERID'],
  //       userData['USERPASSWORD'],
  //       userData['PT'],
  //     );

  //     if (response.containsKey('code')) {
  //       final resultCode = response['code'];

  //       if (resultCode == "1") {
  //         final List<dynamic> msgList = response['msg'];
  //         if (msgList.isNotEmpty && msgList[0] is Map<String, dynamic>) {
  //           final Map<String, dynamic> msgMap = msgList[0] as Map<String, dynamic>;
  //           userId = msgMap['USERID'];
  //         }
  //       } else {
  //         print('Request failed with code $resultCode');
  //         print(response["msg"]);
  //       }
  //     } else {
  //       print('Unexpected response structure');
  //     }
  //   } catch (error) {
  //     print('Error: $error');
  //   }

  //   try {
  //     final response = await apiuser.fetchPO(pono);

  //     if (response.containsKey('code') && response['code'] == '1') {
  //       final msg = response['msg'];
  //       final headerPO = msg['HeaderPO'];
        
  //       // Check if headerPO is empty to determine if the PO exists
  //       if (headerPO.isEmpty) {
  //         throw Exception('Nomor PO tidak ditemukan!'); // PO not found
  //       }

  //       final localPOs = await dbHelper.getPOScannedODetails(headerPO[0]['PONO']);
  //       final scannedPOs = await dbHelper.getPOResultScannedDetails(headerPO[0]['PONO']);
  //       final differentPOs = await dbHelper.getPODifferentScannedDetails(headerPO[0]['PONO']);
  //       final noitemScanned = await dbHelper.getPONOItemsScannedDetails(headerPO[0]['PONO']);

  //       scannedPOs.sort((a, b) {
  //         return DateTime.parse(b['scandate']).compareTo(DateTime.parse(a['scandate']));
  //       });

  //       scannedResults = [...scannedPOs];
  //       differentScannedResults = [...differentPOs];
  //       noitemScannedResults = [...noitemScanned];
  //       final detailPOList = List<Map<String, dynamic>>.from(msg['DetailPO']);

  //       setState(() {
  //         detailPOData = detailPOList.map((item) {
  //           final product = localPOs.firstWhereOrNull((product) =>
  //               product["barcode"] == item["BARCODENO"] ||
  //               product["vendorbarcode"] == item["VENDORBARCODE"]);
  //           if (product != null) {
  //             item["QTYD"] = product["qty_different"];
  //             item["QTYS"] = scannedPOs.isNotEmpty ? scannedPOs.length : product["qty_scanned"];
  //           }
  //           return item;
  //         }).toList();
  //       });
  //     } else {
  //       _showErrorSnackBar('Request failed: ${response['code']}');
  //     }
  //   } catch (error) {
  //     _showErrorSnackBar('Error fetching PO: $error');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
  Future<void> fetchPOData(String pono, String transno) async {
  setState(() => isLoading = true);
  try {
    final userData = storageService.get(StorageKeys.USER);
    final response = await apiservice.loginUser(
      userData['USERID'],
      userData['USERPASSWORD'],
      userData['PT'],
    );

    if (response.containsKey('code')) {
      final resultCode = response['code'];

      if (resultCode == "1") {
        final List<dynamic> msgList = response['msg'];
        if (msgList.isNotEmpty && msgList[0] is Map<String, dynamic>) {
          final Map<String, dynamic> msgMap = msgList[0] as Map<String, dynamic>;
          userId = msgMap['USERID'];
        }
      } else {
        print('Request failed with code $resultCode');
        print(response["msg"]);
      }
    } else {
      print('Unexpected response structure');
    }
  } catch (error) {
    print('Error: $error');
  }

  try {
    final response = await apiuser.fetchPO(pono);

    if (response.containsKey('code') && response['code'] == '1') {
      final msg = response['msg'];
      final headerPO = msg['HeaderPO'];
      
      // Check if headerPO is empty to determine if the PO exists
      if (headerPO.isEmpty) {
        throw Exception('Nomor PO tidak ditemukan!'); // PO not found
      }

      // Mengambil data menggunakan PO number dan transno
      final localPOs = await dbHelper.getPOScannedODetails(headerPO[0]['PONO'], transno);
      final scannedPOs = await dbHelper.getPOResultScannedDetails(headerPO[0]['PONO'], transno);
      final differentPOs = await dbHelper.getPODifferentScannedDetails(headerPO[0]['PONO'], transno);
      final noitemScanned = await dbHelper.getPONOItemsScannedDetails(headerPO[0]['PONO'], transno);

      scannedPOs.sort((a, b) {
        return DateTime.parse(b['scandate']).compareTo(DateTime.parse(a['scandate']));
      });

      scannedResults = [...scannedPOs];
      differentScannedResults = [...differentPOs];
      noitemScannedResults = [...noitemScanned];
      final detailPOList = List<Map<String, dynamic>>.from(msg['DetailPO']);

      setState(() {
        detailPOData = detailPOList.map((item) {
          final product = localPOs.firstWhereOrNull((product) =>
              product["barcode"] == item["BARCODENO"] ||
              product["vendorbarcode"] == item["VENDORBARCODE"]);
          if (product != null) {
            item["QTYD"] = product["qty_different"];
            item["QTYS"] = scannedPOs.isNotEmpty ? scannedPOs.length : product["qty_scanned"];
          }
          return item;
        }).toList();
      });
    } else {
      _showErrorSnackBar('Request failed: ${response['code']}');
    }
  } catch (error) {
    _showErrorSnackBar('Error fetching PO: $error');
  } finally {
    setState(() => isLoading = false);
  }
}


  void _showErrorSnackBar(String message) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.red,
    ).show(context);
  }

  Future<void> submitDataToDatabase() async {
    String poNumber = _poNumberController.text.trim();
    String transno = _transnoController.text.trim();
await saveTransNoToRecent(transno);

    if (poNumber.isEmpty) {
       Flushbar(
        message: 'Please search for a PO before submitting data',
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.red,
    ).show(context);
      return;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceName = '';

    if (GetPlatform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
    } else if (GetPlatform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceName = '${iosInfo.name} ${iosInfo.systemVersion}';
    } else {
      deviceName = 'Unknown Device';
    }

    String scandate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    for (var item in detailPOData) {
      final poData = {
        'pono': poNumber,
        'transno': transno,
        'item_sku': item['ITEMSKU'],
        'item_name': item['ITEMSKUNAME'],
        'barcode': item['BARCODENO'],
        'vendorbarcode': item['VENDORBARCODE'],
        'qty_po': item['QTYPO'],
        'qty_scanned': item['QTYS'] ?? 0,
        'qty_different': item['QTYD'] ?? 0,
        'device_name': deviceName,
        'scandate': scandate,
        // "status":
        //     item['QTYD'] != null && item['QTYD'] != 0 ? "different" : "scanned"
      };

      await dbHelper.insertOrUpdatePO(poData);
    }
    Flushbar(
        message: 'Scanned Berhasil',
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.green,
    ).show(context);

  }

  void _onQRViewCreated(QRViewController qrController) {
    setState(() {
      controller = qrController;
    });

    controller!.scannedDataStream.listen((scanData) async {
      setState(() {
        scannedBarcode = scanData.code ?? "";
      });

      if (scannedBarcode.isNotEmpty) {
        playBeep();
        controller?.pauseCamera();
        await checkAndSumQty(scannedBarcode);
        Future.delayed(const Duration(seconds: 2), () {
          controller?.resumeCamera();
        });
      }
    });
  }

Future<void> deleteRowByScandate(String pono, String scandate, String item_name) async {
  await dbHelper.deleteScan(pono, scandate, item_name); // Backend call

  setState(() {
    // Remove the item from the list locally
    scannedResults.removeWhere(
      (result) => result['pono'] == pono && result['scandate'] == scandate && result['item_name'] == item_name,
    );

    Flushbar(
      message: 'Row deleted successfully!',
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.green,
    ).show(context);
  });
}

Future<void> deleteRowByScandateMaster(String pono, String scandate, String item_name) async {
  await dbHelper.deleteScanMaster(pono, scandate, item_name); // Backend call

  setState(() {
    // Remove the item from the list locally
    differentScannedResults.removeWhere(
      (result) => result['pono'] == pono && result['scandate'] == scandate && result['item_name'] == item_name,
    );

    Flushbar(
      message: 'Row deleted successfully!',
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.green,
    ).show(context);
  });
}

Future<void> deleteRowByScandateNoItems(String pono, String scandate, String item_name) async {
  await dbHelper.deleteScanNoItems(pono, scandate, item_name); // Backend call

  setState(() {
    // Remove the item from the list locally
    noitemScannedResults.removeWhere(
      (result) => result['pono'] == pono && result['scandate'] == scandate && result['item_name'] == item_name,
    );

    Flushbar(
      message: 'Row deleted successfully!',
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.green,
    ).show(context);
  });
}


Future<void> checkAndSumQty(String scannedCode) async {
  int totalQtyScanned = calculateTotalQtyScanned(); // Get the total scanned quantity

  // Check if total scanned quantity has reached or exceeded 500
  // if (totalQtyScanned >= 5000) {
  //   // Display an error message and prevent further scanning
  //   Flushbar(
  //     message: 'You cannot scan more than 5000 items!',
  //     duration: Duration(seconds: 3),
  //     flushbarPosition: FlushbarPosition.TOP,
  //     backgroundColor: Colors.red,
  //   ).show(context);
  //   return; // Stop further processing if limit is reached
  // }

  final deviceInfoPlugin = DeviceInfoPlugin();
  String deviceName = '';

  if (GetPlatform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    deviceName = '${androidInfo.brand} ${androidInfo.model}';
  } else if (GetPlatform.isIOS) {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    deviceName = '${iosInfo.name} ${iosInfo.systemVersion}';
  } else {
    deviceName = 'Unknown Device';
  }

  // Try finding the item in the existing PO data
  final itemInPO = detailPOData.firstWhereOrNull(
    (item) =>
        item['BARCODENO'] == scannedCode ||
        item['ITEMSKU'] == scannedCode ||
        item['VENDORBARCODE'] == scannedCode,
  );

  if (itemInPO != null) {
    // Calculate quantities
    int poQty = int.tryParse((itemInPO['QTYPO'] as String).replaceAll(formatQTYRegex, '')) ?? 0;
    int scannedQty = int.tryParse(itemInPO['QTYS']?.toString() ?? '0') ?? 0;
    int currentQtyD = int.tryParse(itemInPO['QTYD']?.toString() ?? '0') ?? 0;

    print("PO Qty: $poQty, Scanned Qty: $scannedQty, Current QtyD: $currentQtyD");

    int newScannedQty =  1; // Increment scanned quantity by 1 for the current scan

    // Prevent over-scanning beyond the PO quantity
    if (newScannedQty > poQty) {
      // Notify user that the scanned quantity exceeds the PO quantity
      Flushbar(
        message: 'Scanned quantity cannot exceed PO quantity!',
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.red,
      ).show(context);
      return; // Early return to prevent further processing
    }

    // Update item quantities
    itemInPO['QTYS'] = newScannedQty;
    itemInPO['QTYD'] = newScannedQty < poQty ? poQty - newScannedQty : 0;

    // Update the scan date
    itemInPO['scandate'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    setState(() {});

    // Map the scanned PO data
    final mappedPO = {
      'pono': _poNumberController.text.trim(),
      'transno': _transnoController.text.trim(),
      'item_sku': itemInPO['ITEMSKU'],
      'item_name': itemInPO['ITEMSKUNAME'],
      'barcode': itemInPO['BARCODENO'],
      'vendorbarcode': itemInPO['VENDORBARCODE'],
      'qty_po': itemInPO['QTYPO'],
      'qty_scanned': newScannedQty,
      'qty_different': itemInPO['QTYD'],
      'device_name': deviceName,
      'scandate': itemInPO['scandate'],
      'user': userId,
      'qty_koli': int.tryParse(_koliController.text.trim()) ?? 0,
      'status': 'scanned',
      'type': scannedPOType,
    };

    // Add to scanned results
    scannedResults.insert(0, mappedPO);

    // Update the item in the PO and submit results
    setState(() {});
    await updatePO(itemInPO);
    await submitScannedResults();
  } else {
    // If item not found in PO, check master items and handle accordingly
    final masterItem = await fetchMasterItem(scannedCode);
    print("Master item fetched: $masterItem");

    if (masterItem != null) {
      final mappedMasterItem = {
        'pono': _poNumberController.text.trim(),
        'transno': _transnoController.text.trim(),
        'item_sku': masterItem['item_sku'],
        'item_name': masterItem['item_name'],
        'barcode': masterItem['barcode'],
        'vendorbarcode': masterItem['vendorbarcode'],
        'qty_po': 0,
        'qty_scanned': 1,
        'qty_different': 0,
        'device_name': deviceName,
        'scandate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'user': userId,
        'qty_koli': int.tryParse(_koliController.text.trim()) ?? 0,
        'status': 'different',
        'type': scannedPOType,
      };

      differentScannedResults.insert(0, mappedMasterItem);
      savePOToRecent(_poNumberController.text);
      saveTransNoToRecent(_transnoController.text);
        saveTransPoandTrans(jsonEncode({'transno':_transnoController.text,'pono':_poNumberController.text}));

      setState(() {});
      await submitScannedMasterItemsResults();
    } else {
      // If item not found in both PO and Master items, prompt for manual input
      final itemName = await _promptManualItemNameInput(scannedCode);

      if (itemName != null && itemName.isNotEmpty) {
        final manualMasterItem = {
          'pono': _poNumberController.text.trim(),
          'transno': _transnoController.text.trim(),
          'item_sku': '-', // Using scannedCode as SKU, you can change this as needed
          'item_name': itemName,
          'barcode': scannedCode,
          'vendorbarcode': scannedCode,
          'qty_po': 0,
          'qty_scanned': 1,
          'qty_different': 0,
          'device_name': deviceName,
          'scandate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'user': userId,
          'qty_koli': int.tryParse(_koliController.text.trim()) ?? 0,
          'status': 'noitem', // Indicate that this was manually added
          'type': scannedPOType,
        };

        noitemScannedResults.insert(0, manualMasterItem);
        savePOToRecent(_poNumberController.text);
        saveTransNoToRecent(_transnoController.text);
        saveTransPoandTrans(jsonEncode({'transno':_transnoController.text,'pono':_poNumberController.text}));

        setState(() {});
        await submitScannedNoItemsResults();
      } else {
        print("Manual item name input was cancelled.");
      }
    }
  }
}


Future<String?> _promptManualItemNameInput(String scannedCode) async {
   
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      String itemName = '';

      return AlertDialog(
        title: Text('Enter Item Name'),
        content: TextField(
          onChanged: (value) {
            itemName = value.trim();
          },
          decoration: InputDecoration(
            labelText: 'Item Name',
            hintText: 'Enter the name for item $scannedCode',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(itemName);
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

  Future<void> submitScannedResults() async {
    final allPOs = [...scannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedResults(
          result); // Assuming you have a method for this
    }
    
   
  }
  Future<void> submitScannedMasterItemsResults() async {
    final allPOs = [...differentScannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedMasterItemsResults(
          result); // Assuming you have a method for this
    }
    Flushbar(
        message: 'Scanned Berhasil',
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.green,
    ).show(context);

   
  }
  Future<void> submitScannedNoItemsResults() async {
    final allPOs = [...noitemScannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedNoItemsResults(
          result); // Assuming you have a method for this
    }
    Flushbar(
        message: 'Scanned Berhasil',
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.green,
    ).show(context);

 
  }

Future<Map<String, dynamic>?> fetchMasterItem(String scannedCode) async {
  final db = await DatabaseHelper().database;
  final result = await db.query(
    'master_item',
    where: 'barcode = ? OR item_sku = ? OR vendorbarcode = ?',
    whereArgs: [scannedCode, scannedCode, scannedCode],
  );

  if (result.isNotEmpty) {
    print("Fetched data from database: $result"); // Check if this contains the required fields
    return result.first;
  } else {
    print("No data found for the scanned code: $scannedCode");
    return null;
  }
}

Future<void> updateScannedQty(Map<String, dynamic> item) async {
  // Create a mutable copy of the item
  Map<String, dynamic> mutableItem = Map.from(item);

  // Create a TextEditingController and initialize with the current qty_scanned
  TextEditingController qtyController = TextEditingController(
    text: mutableItem['qty_scanned'].toString(),
  );

  // Prompt the user for the new quantity
  String? newQtyString = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Update Scanned Quantity'),
        content: TextField(
          controller: qtyController, // Set the controller here
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter New Scanned Quantity',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(qtyController.text); // Return the input text
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );

  // If user input a valid quantity, update the item
  if (newQtyString != null && newQtyString.isNotEmpty) {
    int newQty = int.tryParse(newQtyString) ?? 0;

    // Update the quantity in the mutable copy
    setState(() {
      mutableItem['qty_scanned'] = newQty;

      // Find the original item index in scannedResults
      int index = scannedResults.indexWhere((result) => result['barcode'] == item['barcode']);
      if (index != -1) {
        // Update the scannedResults list with the mutable copy
        scannedResults[index] = mutableItem; // Update with the modified item
      }
    });

    // Optionally update the database or do additional actions here
    await submitScannedResults();
    await submitScannedMasterItemsResults();
    await submitScannedNoItemsResults(); // Update the database with new quantities
  }
}

int calculateTotalQtyScanned() {
  int totalQty = 0;
  
  for (var result in scannedResults) {
    totalQty += (result['qty_scanned'] as num?)?.toInt() ?? 0;
  }
  
  for (var result in differentScannedResults) {
    totalQty += (result['qty_scanned'] as num?)?.toInt() ?? 0;
  }
  
  for (var result in noitemScannedResults) {
    totalQty += (result['qty_scanned'] as num?)?.toInt() ?? 0;
  }
  
  return totalQty;
}


  Future<void> updatePO(Map<String, dynamic> item) async {
  detailPOData = detailPOData.replaceOrAdd(
    item,
    (po) => po['BARCODE'] == item["BARCODE"],
  );

  setState(() {});
  
  // Prioritaskan TransNo
  await saveTransNoToRecent(_transnoController.text);
  await savePOToRecent(_poNumberController.text);
  await saveTransPoandTrans(jsonEncode({'transno':_transnoController.text,'pono':_poNumberController.text}));
  submitDataToDatabase();
}

  Future<void> saveTransPoandTrans(String updatedTransandPO) async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? recentTransandPO = prefs.getStringList('recent_transandpo') ?? [];

  // Prioritaskan TransNo
  recentTransandPO = recentTransandPO.replaceOrAdd(
    updatedTransandPO,
    (transno) => transno == updatedTransandPO,
  );

  // Simpan kembali daftar TransNo yang diperbarui
  await prefs.setStringList('recent_transandpo', recentTransandPO);
}


  Future<void> saveTransNoToRecent(String updatedTransNo) async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? recentTransNos = prefs.getStringList('recent_transnos') ?? [];

  // Prioritaskan TransNo
  recentTransNos = recentTransNos.replaceOrAdd(
    updatedTransNo,
    (transno) => transno == updatedTransNo,
  );

  // Simpan kembali daftar TransNo yang diperbarui
  await prefs.setStringList('recent_transnos', recentTransNos);
}

Future<void> savePOToRecent(String updatedPONO) async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? recentNoPOs = prefs.getStringList('recent_pos') ?? [];

  // Pastikan PONO disimpan, tetapi beri prioritas ke TransNo
  List<String>? recentTransNos = prefs.getStringList('recent_transnos') ?? [];
  if (recentTransNos.isNotEmpty) {
    // Logika tambahan jika ingin memastikan TransNo muncul lebih dulu
    recentNoPOs = recentNoPOs.replaceOrAdd(
      updatedPONO,
      (pono) => pono == updatedPONO,
    );
  }

  await prefs.setStringList('recent_pos', recentNoPOs);
}


  void clearSession() {
  _poNumberController.clear();
  _koliController.clear();
  scannedResults.clear();
  differentScannedResults.clear();
  noitemScannedResults.clear();
  detailPOData.clear();
}

String generateTransno() {
  // Pastikan detailPOData tidak kosong dan elemen terakhir memiliki transno yang valid
  String lastTransno = '';
  if (detailPOData.isNotEmpty) {
    var lastEntry = detailPOData.last;
    if (lastEntry != null && lastEntry['transno'] != null) {
      lastTransno = lastEntry['transno'];
    }
  }

  // Cek apakah transno terakhir valid
  if (lastTransno.isEmpty || !RegExp(r'^SC-\d{4}-\d{4}$').hasMatch(lastTransno)) {
    // Jika tidak ada data sebelumnya atau format tidak valid, mulai dari SC-YYMM-0001
    final now = DateTime.now();
    final yearMonth = '${now.year % 100}${now.month.toString().padLeft(2, '0')}';
    return 'SC-$yearMonth-0001';
  }

  // Pisahkan bagian transno terakhir
  final parts = lastTransno.split('-');
  final currentYearMonth = '${DateTime.now().year % 100}${DateTime.now().month.toString().padLeft(2, '0')}';

  // Ambil nomor terakhir
  final lastNumber = int.parse(parts.last);

  // Jika format YYMM sekarang sama dengan transno terakhir
  if (parts[1] == currentYearMonth) {
    final newNumber = (lastNumber + 1).toString().padLeft(4, '0');
    return 'SC-$currentYearMonth-$newNumber';
  } else {
    // Jika bulan atau tahun berbeda, mulai ulang dengan 0001
    return 'SC-$currentYearMonth-0001';
  }
}



  @override
  Widget build(BuildContext context) {
      return WillPopScope(
    onWillPop: () async {
     
      

      // Clear other data if necessary
      _poNumberController.clear();
      _koliController.clear();
      scannedResults.clear();
      differentScannedResults.clear();
      noitemScannedResults.clear();
      detailPOData.clear();

      // Allow the back navigation
      return false; 
    },
    child:  Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('PO Details'),
        ),
        drawer: const MyDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _poNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Enter PO Number',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                ),
                // const SizedBox(width: 10),
                // SizedBox(
                //   width: 75,
                //   child: TextFormField(
                //     controller: _koliController,
                //     keyboardType: TextInputType.number,
                //     decoration: const InputDecoration(
                //       labelText: 'Koli',
                //       border: OutlineInputBorder(),
                //     ),
                //   ),
                // ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _transnoController,
                    decoration: const InputDecoration(
                      labelText: 'Transno',
                      border: OutlineInputBorder(),
                    ),
        inputFormatters: [UpperCaseTextFormatter()],

                  ),
                ),
                    ElevatedButton(
          onPressed: () async {
  String poNumber = _poNumberController.text.trim(); // Gunakan trim
  String koli = _koliController.text.trim();
  String transno = _transnoController.text.trim(); // Trim juga jika diperlukan
   // Trim juga jika diperlukan
  if (poNumber.isNotEmpty) {
    setState(() {
      isLoading = true;
      scannedResults.clear();
      differentScannedResults.clear();
      noitemScannedResults.clear();
      detailPOData.clear();
    });

    try {
      await fetchPOData(poNumber,transno);
      if (detailPOData.isNotEmpty) {
        Flushbar(
          message: 'PO berhasil terpanggil!',
          duration: Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          backgroundColor: Colors.green,
        ).show(context);
      } else {
        throw Exception('Nomor PO tidak ditemukan!');
      }
    } catch (e) {
      Flushbar(
        message: e.toString(),
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.red,
      ).show(context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  } else {
    Flushbar(
      message: 'Silakan masukkan nomor PO yang valid',
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.red,
    ).show(context);
  }
},

          child: const Icon(Icons.search),
        ),


            ],
          ),
          const SizedBox(height: 20),
          // Tampilkan loading indicator saat data sedang diproses
          if (isLoading)
            const CircularProgressIndicator()
          else if (detailPOData.isNotEmpty)
            const Text('Data PO Sudah Tersimpan')
          else
            const Text('Belum ada PO yang Tersimpan'),
      
    Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _barcodeController,
        decoration: const InputDecoration(
          labelText: 'Enter Barcode',
          border: OutlineInputBorder(),
        ),
        focusNode: textsecond,
        enabled: _poNumberController.text.isNotEmpty && _transnoController.text.isNotEmpty,
        onFieldSubmitted: (value) {
          FocusScope.of(context).requestFocus(textsecond);
          if (value.isNotEmpty) {
            checkAndSumQty(value);
            Future.delayed(Duration(milliseconds: 100), () {
              _barcodeController.clear();
            });
          } else {
            Flushbar(
              message: 'Please enter a valid barcode',
              duration: Duration(seconds: 3),
              flushbarPosition: FlushbarPosition.TOP,
              backgroundColor: Colors.red,
            ).show(context);
          }
        },
        inputFormatters: [UpperCaseTextFormatter()],
      ),
    ),
    const SizedBox(width: 10),
    SizedBox(
      width: 75,
      child: TextFormField(
        controller: _koliController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Koli',
          border: OutlineInputBorder(),
        ),
      ),
    ),
     const SizedBox(width: 10),
 ElevatedButton(
  onPressed: () {
    setState(() {
      String newTransno = generateTransno(); // Generate Transno baru
      _transnoController.text = newTransno;  // Masukkan transno baru ke text controller
      detailPOData.add({'transno': newTransno, 'otherField': 'value'});  // Menambahkan entri baru ke detailPOData

      _poNumberController.clear(); // Kosongkan PO Number
      _koliController.clear(); // Kosongkan Koli
      scannedResults.clear(); // Kosongkan scannedResults
      differentScannedResults.clear(); // Kosongkan differentScannedResults
      noitemScannedResults.clear(); // Kosongkan noitemScannedResults
    });
  },
  child: const Text('New'),
),



  ],
),

         
                          const SizedBox(height: 20),
                          Expanded(
                            child: Column(
                              children: [
                                 Text(
                                  'Scanned Results :  ${calculateTotalQtyScanned()}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
    Expanded(
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
    controller: ScrollController(),
    child: DataTable(
    columns: const [
    DataColumn(label: Text('Transno')),
    DataColumn(label: Text('PO Number')),
    DataColumn(label: Text('Item SKU')),
    DataColumn(label: Text('Item Name')),
    DataColumn(label: Text('Barcode')),
    DataColumn(label: Text('VendorBarcode')),
    DataColumn(label: Text('Qty Scanned')),
    // DataColumn(label: Text('User')),
    // DataColumn(label: Text('Device')),
    DataColumn(label: Text('QTY Koli')),
    DataColumn(label: Text('Timestamp')),
    DataColumn(label: Text('Actions')),

    ],
    rows: [
  ...scannedResults.asMap().entries.map(
    (entry) {
      int index = entry.key;
      Map<String, dynamic> result = Map<String, dynamic>.from(entry.value); // Deep copy

      // Initialize the controller if not already present
      _controllers[index] ??= TextEditingController();

      // Update the controller text to match the current qty_scanned
      _controllers[index]!.text = result['qty_scanned']?.toString() ?? '0';

      return DataRow(
        cells: [
          DataCell(Text(result['transno'] ?? '')),
          DataCell(Text(result['pono'] ?? '')),
          DataCell(Text(result['item_sku'] ?? '')),
          DataCell(Text(result['item_name'] ?? '')),
          DataCell(Text(result['barcode'] ?? '')),
          DataCell(Text(result['vendorbarcode'] ?? '')),
          DataCell(
            TextFormField(
              controller: _controllers[index],
              keyboardType: TextInputType.number,
              onFieldSubmitted: (newValue) {
                int? updatedQty = int.tryParse(newValue);

                // Ensure the value is not less than 1
                if (updatedQty != null && updatedQty >= 1) {
                  setState(() {
                    // Update the quantity directly in `scannedResults`
                    result['qty_scanned'] = updatedQty;
                    scannedResults[index] = result;

                    // Optional: Update backend with new quantity
                    submitScannedResults();
                    submitScannedMasterItemsResults();
                    submitScannedNoItemsResults();

                    Flushbar(
                      message: 'Quantity updated successfully!',
                      duration: Duration(seconds: 5),
                      flushbarPosition: FlushbarPosition.TOP,
                      backgroundColor: Colors.green,
                    ).show(context);
                  });
                } else {
                  // Show a warning if the value is below 1
                  Flushbar(
                    message: 'Quantity must be 1 or greater!',
                    duration: Duration(seconds: 3),
                    flushbarPosition: FlushbarPosition.TOP,
                    backgroundColor: Colors.red,
                  ).show(context);

                  // Revert the text field to the last valid value
                  _controllers[index]!.text = result['qty_scanned'].toString();
                }
              },
            ),
          ),
          // DataCell(Text(result['user'] ?? '')),
          // DataCell(Text(result['device_name'] ?? '')),
          DataCell(Text(result['qty_koli']?.toString() ?? '0')),
          DataCell(Text(result['scandate'] ?? '')),

          // Delete action button
          DataCell(
  IconButton(
    icon: Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Yakin ingin menghapus?'),
            content: Text('Apakah Anda yakin ingin menghapus data: ${result['item_name']}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Call the delete function if user confirms
                  deleteRowByScandate(result['pono'], result['scandate'], result['item_name']);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  ),
),


            ],
    );
    },
  ),


    ...differentScannedResults.asMap().entries.map(
          (entry) {
       int index = entry.key;
            Map<String, dynamic> result = entry.value;
            Map<String, dynamic> mutableResult = Map.from(result);

            
            _controllers1[index] ??= TextEditingController(
              text: mutableResult['qty_scanned'].toString(),
            );

      return DataRow(
      color: MaterialStateProperty.all(Colors.orange[100]),
      cells: [
        DataCell(Text(mutableResult['transno'] ?? '')),
        DataCell(Text(mutableResult['pono'] ?? '')),
        DataCell(Text(mutableResult['item_sku'] ?? '')),
        DataCell(Text(mutableResult['item_name'] ?? '')),
        DataCell(Text(mutableResult['barcode'] ?? '')),
        DataCell(Text(mutableResult['vendorbarcode'] ?? '')),
        DataCell(
                  TextFormField(
                    controller: _controllers1[index], // Use controller for each field
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (newValue) {
                      int? updatedQty = int.tryParse(newValue);

                      // Ensure the value is not less than 1
                      if (updatedQty != null && updatedQty >= 1) {
                        setState(() {
                          mutableResult['qty_scanned'] = updatedQty;
                          differentScannedResults[index] = mutableResult;

                          submitScannedResults();
                          submitScannedMasterItemsResults();
                          submitScannedNoItemsResults();

                          Flushbar(
                            message: 'Quantity updated successfully!',
                            duration: Duration(seconds: 5),
                            flushbarPosition: FlushbarPosition.TOP,
                            backgroundColor: Colors.green,
                          ).show(context);
                        });
                      } else {
                        // Show a warning if the value is below 1
                        Flushbar(
                          message: 'Quantity must be 1 or greater!',
                          duration: Duration(seconds: 3),
                          flushbarPosition: FlushbarPosition.TOP,
                          backgroundColor: Colors.red,
                        ).show(context);

                        // Revert the text field to the last valid value
                        _controllers1[index]?.text = mutableResult['qty_scanned'].toString();
                      }
                    },
                  ),
                ),
        // DataCell(Text(mutableResult['user'] ?? '')),
        // DataCell(Text(mutableResult['device_name'] ?? '')),
        DataCell(Text(mutableResult['qty_koli'].toString())),
        DataCell(Text(mutableResult['scandate'] ?? '')),
        DataCell(
  IconButton(
    icon: Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Yakin ingin menghapus?'),
            content: Text('Apakah Anda yakin ingin menghapus data: ${result['item_name']}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Call the delete function if user confirms
                  deleteRowByScandateMaster(result['pono'], result['scandate'], result['item_name']);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  ),
),


      ],
    );
    },
  ),
  ...noitemScannedResults.asMap().entries.map(
          (entry) {
       int index = entry.key;
            Map<String, dynamic> result = entry.value;
            Map<String, dynamic> mutableResult = Map.from(result);

            
            _controllers2[index] ??= TextEditingController(
              text: mutableResult['qty_scanned'].toString(),
            );
      return DataRow(
      color: MaterialStateProperty.all(Colors.red[200]),
      cells: [
        DataCell(Text(mutableResult['transno'] ?? '')),
        DataCell(Text(mutableResult['pono'] ?? '')),
        DataCell(Text(mutableResult['item_sku'] ?? '')),
        DataCell(Text(mutableResult['item_name'] ?? '')),
        DataCell(Text(mutableResult['barcode'] ?? '')),
        DataCell(Text(mutableResult['vendorbarcode'] ?? '')),
        DataCell(
                  TextFormField(
                    controller: _controllers2[index], // Use controller for each field
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (newValue) {
                      int? updatedQty = int.tryParse(newValue);

                      // Ensure the value is not less than 1
                      if (updatedQty != null && updatedQty >= 1) {
                        setState(() {
                          mutableResult['qty_scanned'] = updatedQty;
                          differentScannedResults[index] = mutableResult;

                          // Optional: Update backend with new quantity
                          submitScannedResults();
                          submitScannedMasterItemsResults();
                          submitScannedNoItemsResults();

                          Flushbar(
                            message: 'Quantity updated successfully!',
                            duration: Duration(seconds: 5),
                            flushbarPosition: FlushbarPosition.TOP,
                            backgroundColor: Colors.green,
                          ).show(context);
                        });
                      } else {
                        // Show a warning if the value is below 1
                        Flushbar(
                          message: 'Quantity must be 1 or greater!',
                          duration: Duration(seconds: 3),
                          flushbarPosition: FlushbarPosition.TOP,
                          backgroundColor: Colors.red,
                        ).show(context);

                        // Revert the text field to the last valid value
                        _controllers2[index]?.text = mutableResult['qty_scanned'].toString();
                      }
                    },
                  ),
                ),
        // DataCell(Text(mutableResult['user'] ?? '')),
        // DataCell(Text(mutableResult['device_name'] ?? '')),
        DataCell(Text(mutableResult['qty_koli'].toString())),
        DataCell(Text(mutableResult['scandate'] ?? '')),
        DataCell(
  IconButton(
    icon: Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Yakin ingin menghapus?'),
            content: Text('Apakah Anda yakin ingin menghapus data: ${result['item_name']}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Call the delete function if user confirms
                  deleteRowByScandateNoItems(result['pono'], result['scandate'], result['item_name']);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  ),
),


      ],
    );
    },
  ),
]

            ),
          ),
        ),
      ),
   
      const SizedBox(height: 20),
     ElevatedButton(
  onPressed: (_poNumberController.text.isNotEmpty && _transnoController.text.isNotEmpty)
      ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRViewExample(
                onQRViewCreated: _onQRViewCreated,
                onScanComplete: () {},
              ),
            ),
          ).then((_) {
            // Handle the result if needed
          });
        }
      : null, // Disable button if PO number or koli is empty
  child: const Text('Scan QR Code'),
),
    ],
  ),
)
                        ]
                  )
          )
    ) 
        );
  }
}

class QRViewExample extends StatelessWidget {
  final void Function(QRViewController) onQRViewCreated;
  final VoidCallback onScanComplete;

  const QRViewExample({
    super.key,
    required this.onQRViewCreated,
    required this.onScanComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: QRView(
        key: GlobalKey(debugLabel: 'QR'),
        onQRViewCreated: onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
