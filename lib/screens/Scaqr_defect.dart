
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

class ScanQRDefectPage extends StatefulWidget {
  final Map<String, dynamic>? initialPOData;

  const ScanQRDefectPage({super.key, this.initialPOData});

  @override
  State<ScanQRDefectPage> createState() => _ScanQRDefectPageState();
}

class _ScanQRDefectPageState extends State<ScanQRDefectPage> {
  final Apiuser apiuser = Apiuser();
  final StorageService storageService = StorageService.instance;
  final ApiService apiservice = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> detailPOData = [];
  List<Map<String, dynamic>> detailPODataScan = [];
  List<Map<String, dynamic>> notInPOItems =[];
  List<Map<String, dynamic>> scannedResults = [];
  List<Map<String, dynamic>> masterScannedResults =[];
  List<Map<String, dynamic>> noitemScannedResults =[];
  bool isLoading = false;
  final TextEditingController _poNumberController =TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _koliController = TextEditingController();
  QRViewController? controller;
  String scannedBarcode = "";
  late String userId = '';
  FocusNode textsecond = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.initialPOData != null) {
      detailPOData = [widget.initialPOData!];
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

   Future<void> fetchPOData(String pono) async {
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

        final localPOs =
        await dbHelper.getPODefectScannedODetails(headerPO[0]['PONO']);
        final scannedPOs =
        await dbHelper.getPODefectItemsScannedDetails(headerPO[0]['PONO']);
        final MasterPOs =
        await dbHelper.getPODefectMasterScannedDetails(headerPO[0]['PONO']);
        final NoPOs =
        await dbHelper.getPODefectNoScannedDetails(headerPO[0]['PONO']);

        scannedPOs.sort((a, b) {
          return DateTime.parse(b['scandate']).compareTo(DateTime.parse(a['scandate']));
        });

        scannedResults = [...scannedPOs];
        masterScannedResults = [...MasterPOs];
        noitemScannedResults = [...NoPOs];
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

    if (poNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please search for a PO before submitting data')),
      );
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
      message: 'Po Data Save',
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
        Future.delayed(const Duration(seconds: 1), () {
          controller?.resumeCamera();
        });
      }
    });
  }

  Future<void> checkAndSumQty(String scannedCode) async {
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
        item['VENDORBARCODE'] == scannedCode
    );

    if (itemInPO != null) {
      // Calculate quantities
      int poQty = int.tryParse((itemInPO['QTYPO'] as String).replaceAll(formatQTYRegex, '')) ?? 0;
      int scannedQty = int.tryParse(itemInPO['QTYS']?.toString() ?? '0') ?? 0;
      int currentQtyD = int.tryParse(itemInPO['QTYD']?.toString() ?? '0') ?? 0;

      print("PO Qty: $poQty, Scanned Qty: $scannedQty, Current QtyD: $currentQtyD");

      int newScannedQty = 1;

      // Prevent over-scanning beyond the PO quantity
      if (newScannedQty > poQty) {
        print("Scanned qty exceeds PO qty.");
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
        'item_sku': itemInPO['ITEMSKU'],
        'item_name': itemInPO['ITEMSKUNAME'],
        'barcode': itemInPO['BARCODENO'],
        'vendorbarcode': itemInPO['VENDORBARCODE'],
        'qty_po': itemInPO['QTYPO'],
        'qty_scanned': 1,
        'qty_different': itemInPO['QTYD'],
        'device_name': deviceName,
        'scandate': itemInPO['scandate'],
        'user': userId,
        'qty_koli': int.tryParse(_koliController.text.trim()) ?? 0,
        'status': itemInPO['QTYD'] != 0 ? 'defect' : 'defect',
        'type': scannedPOType,
      };

      // Add to scanned results
      scannedResults.insert(0, mappedPO);

      // Update the item in the PO and submit results
      await Future.wait([
        updatePO(itemInPO),
        submitScannedResults(),
      ]);
    } else {
      // If item not found in PO, check master items and handle accordingly
      final masterItem = await fetchMasterItem(scannedCode);
      print("Master item fetched: $masterItem");

      if (masterItem != null) {
        final mappedMasterItem = {
          'pono': _poNumberController.text.trim(),
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
          'status': 'defect_master',
          'type': scannedPOType,
        };

        masterScannedResults.insert(0, mappedMasterItem);
             await Future.wait([
       savePOToRecent(_poNumberController.text),
        submitMasterResults(),
      ]);
      } else {
        // If item not found in both PO and Master items, prompt for manual input
        final itemName = await _promptManualItemNameInput(scannedCode);

        if (itemName != null && itemName.isNotEmpty) {
          final manualMasterItem = {
            'pono': _poNumberController.text.trim(),
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
            'status': 'defect_no', // Indicate that this was manually added
            'type': scannedPOType,
          };

          noitemScannedResults.insert(0, manualMasterItem);
             await Future.wait([
       savePOToRecent(_poNumberController.text),
        submitNoResults(),
      ]);
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
    await submitMasterResults();
    await submitNoResults(); // Update the database with new quantities
  }
}

  Future<void> submitScannedResults() async {
    final allPOs = [...scannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedDefectResults(
          result); // Assuming you have a method for this
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanned results saved successfully')),
    );
  }
  Future<void> submitMasterResults() async {
    final allPOs = [...masterScannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedDefectMasterResults(
          result); // Assuming you have a method for this
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanned results saved successfully')),
    );
  }
  Future<void> submitNoResults() async {
    final allPOs = [...noitemScannedResults];
    for (var result in allPOs) {
      await dbHelper.insertOrUpdateScannedDefectNoResults(
          result); // Assuming you have a method for this
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanned results saved successfully')),
    );
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

Future<void> updatePO(Map<String, dynamic> item) async {
    detailPOData = detailPOData.replaceOrAdd(
        item, (po) => po['BARCODE'] == item["BARCODE"]);
    setState(() {});
    savePOToRecent(_poNumberController.text);
    submitDataToDatabase();
  }


  Future<void> savePOToRecent(String updatedPONO) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recentNoPOs = prefs.getStringList('recent_pos_defect') ?? [];

    recentNoPOs =
        recentNoPOs.replaceOrAdd(updatedPONO, (pono) => pono == updatedPONO);
    await prefs.setStringList('recent_pos_defect', recentNoPOs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('PO Defect'),
        ),
        drawer: const MyDrawer(),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children: [

                  const

                  Text(
                    'Scan Pada Artikel Defect',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      ElevatedButton(
          onPressed: () async {
            String poNumber = _poNumberController.text.trim();
            if (poNumber.isNotEmpty) {
              // Show loading indicator
              setState(() {
                isLoading = true;
                // Reset data before fetching new data
                scannedResults.clear();
                masterScannedResults.clear();
                noitemScannedResults.clear();
                detailPOData.clear();
              });

              try {
                // Fetch PO data
                await fetchPOData(poNumber);
                
                // Only show success message if data is valid
                if (detailPOData.isNotEmpty) {
                  Flushbar(
                    message: 'PO berhasil terpanggil!',
                    duration: Duration(seconds: 3),
                    flushbarPosition: FlushbarPosition.TOP,
                    backgroundColor: Colors.green,
                  ).show(context);
                } else {
                  throw Exception('Nomor PO tidak ditemukan!'); // Trigger error notification
                }
              } catch (e) {
                // Handle different error messages
                Flushbar(
                  message: e.toString(),
                  duration: Duration(seconds: 3),
                  flushbarPosition: FlushbarPosition.TOP,
                  backgroundColor: Colors.red,
                ).show(context);
              } finally {
                // Hide loading indicator
                setState(() {
                  isLoading = false;
                });
              }
            } else {
              // Show error if PO number input is empty
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

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Barcode',
                      border: OutlineInputBorder(),
                    ),
                    focusNode: textsecond,
                    onFieldSubmitted: (value)

                    {
                      FocusScope.of(context).requestFocus(textsecond);

                      if (value.isNotEmpty) {
                        checkAndSumQty(value);
                        Future.delayed(Duration(milliseconds: 100), () {
                          _barcodeController.clear();
                        }
                        );
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

                  const SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Scanned Results Defect',
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

                                  DataColumn(label: Text('PO Number')),
                                  DataColumn(label: Text('Item SKU')),
                                  DataColumn(label: Text('Item Name')),
                                  DataColumn(label: Text('Barcode')),
                                  DataColumn(label: Text('VendorBarcode')),
                                  DataColumn(label: Text('Qty Scanned')),
                                  DataColumn(label: Text('User')),
                                  DataColumn(label: Text('Device')),
                                  DataColumn(label: Text('QTY Koli')),
                                  DataColumn(label: Text('Timestamp')),
                                  // DataColumn(label: Text('Actions')),

                                ],
                                rows: [
  ...scannedResults.map(
    (result) {
      // Create a mutable copy of the result
      Map<String, dynamic> mutableResult = Map.from(result);

      return DataRow(
        cells: [
          DataCell(Text(mutableResult['pono'] ?? '')),
          DataCell(Text(mutableResult['item_sku'] ?? '')),
          DataCell(Text(mutableResult['item_name'] ?? '')),
          DataCell(Text(mutableResult['barcode'] ?? '')),
          DataCell(Text(mutableResult['vendorbarcode'] ?? '')),
          DataCell(
            TextFormField(
              initialValue: mutableResult['qty_scanned'].toString(),
              keyboardType: TextInputType.number,
              onFieldSubmitted: (newValue) {
                // Update the scanned quantity directly
                int? updatedQty = int.tryParse(newValue);
                if (updatedQty != null) {
                  setState(() {
                    mutableResult['qty_scanned'] = updatedQty;
                    int index = scannedResults.indexWhere((r) => r['barcode'] == result['barcode']);
                    if (index != -1) {
                      scannedResults[index] = mutableResult;
                    }

                    // Optional: Update backend with new quantity
                    submitScannedResults();
                    submitMasterResults();
                    submitNoResults();
                  });
                }
              },
            ),
          ),
          DataCell(Text(mutableResult['user'] ?? '')),
          DataCell(Text(mutableResult['device_name'] ?? '')),
          DataCell(Text(mutableResult['qty_koli'].toString())),
          DataCell(Text(mutableResult['scandate'] ?? '')),
        ],
      );
    },
  ),
  ...masterScannedResults.map(
    (result) {
      // Create a mutable copy of the result
      Map<String, dynamic> mutableResult = Map.from(result);

      return DataRow(
        cells: [
          DataCell(Text(mutableResult['pono'] ?? '')),
          DataCell(Text(mutableResult['item_sku'] ?? '')),
          DataCell(Text(mutableResult['item_name'] ?? '')),
          DataCell(Text(mutableResult['barcode'] ?? '')),
          DataCell(Text(mutableResult['vendorbarcode'] ?? '')),
          DataCell(
            TextFormField(
              initialValue: mutableResult['qty_scanned'].toString(),
              keyboardType: TextInputType.number,
              onFieldSubmitted: (newValue) {
                // Update the scanned quantity directly
                int? updatedQty = int.tryParse(newValue);
                if (updatedQty != null) {
                  setState(() {
                    mutableResult['qty_scanned'] = updatedQty;
                    int index = masterScannedResults.indexWhere((r) => r['barcode'] == result['barcode']);
                    if (index != -1) {
                      masterScannedResults[index] = mutableResult;
                    }

                    // Optional: Update backend with new quantity
                    submitScannedResults();
                   submitMasterResults();
                    submitNoResults();
                  });
                }
              },
            ),
          ),
          DataCell(Text(mutableResult['user'] ?? '')),
          DataCell(Text(mutableResult['device_name'] ?? '')),
          DataCell(Text(mutableResult['qty_koli'].toString())),
          DataCell(Text(mutableResult['scandate'] ?? '')),
        ],
      );
    },
  ),
  ...noitemScannedResults.map(
    (result) {
      // Create a mutable copy of the result
      Map<String, dynamic> mutableResult = Map.from(result);

      return DataRow(
        cells: [
          DataCell(Text(mutableResult['pono'] ?? '')),
          DataCell(Text(mutableResult['item_sku'] ?? '')),
          DataCell(Text(mutableResult['item_name'] ?? '')),
          DataCell(Text(mutableResult['barcode'] ?? '')),
          DataCell(Text(mutableResult['vendorbarcode'] ?? '')),
          DataCell(
            TextFormField(
              initialValue: mutableResult['qty_scanned'].toString(),
              keyboardType: TextInputType.number,
              onFieldSubmitted: (newValue) {
                // Update the scanned quantity directly
                int? updatedQty = int.tryParse(newValue);
                if (updatedQty != null) {
                  setState(() {
                    mutableResult['qty_scanned'] = updatedQty;
                    int index = noitemScannedResults.indexWhere((r) => r['barcode'] == result['barcode']);
                    if (index != -1) {
                      noitemScannedResults[index] = mutableResult;
                    }

                    // Optional: Update backend with new quantity
                    submitScannedResults();
                    submitMasterResults();
                    submitNoResults();
                  });
                }
              },
            ),
          ),
          DataCell(Text(mutableResult['user'] ?? '')),
          DataCell(Text(mutableResult['device_name'] ?? '')),
          DataCell(Text(mutableResult['qty_koli'].toString())),
          DataCell(Text(mutableResult['scandate'] ?? '')),
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
                          onPressed: () {
                            if (_poNumberController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a PO number before scanning.'),
                                ),
                              );
                              return;
                            }
                            if (_koliController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter koli quantity before scanning'),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRViewExample(
                                  onQRViewCreated: _onQRViewCreated,
                                  onScanComplete: () {},
                                ),
                              ),
                            ).then((_) {
                            });
                          },
                          child: const Text('Scan QR Code'),
                        ),
                      ],
                    ),
                  )
                ]
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
