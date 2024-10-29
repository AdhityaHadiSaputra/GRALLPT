import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/platform/platform.dart';
// import 'package:intl/intl.dart';
import 'package:grmobileallpt/api_service.dart';
import 'package:grmobileallpt/models/db_helper.dart';
import 'package:http/http.dart' as http;
import 'package:grmobileallpt/utils/storage.dart';
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PODetailPage extends StatefulWidget {
  final String poNumber;
  

  PODetailPage({required this.poNumber});

  @override
  _PODetailPageState createState() => _PODetailPageState();
}

class _PODetailPageState extends State<PODetailPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final StorageService storageService = StorageService.instance;
  final ApiService apiservice = ApiService();
  List<Map<String, dynamic>> poDetails = [];
  List<Map<String, dynamic>> scannedResults = [];
  List<Map<String, dynamic>> masterScannedResults = [];
  List<Map<String, dynamic>> noitemScannedResults = [];
  List<Map<String, dynamic>> recentPOSummary = [];
  List<Map<String, dynamic>> recentMasterPOSummary = [];
  List<Map<String, dynamic>> recentNoPOSummary = [];
  bool isLoading = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final apiService = ApiService();
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchPODetails();
    fetchScannedResults();
    fetchMasterItemsResults();
    fetchNoItemsResults();
    fetchSummaryRecentPOs();
    fetchSummaryRecentMasterPOs();
    fetchSummaryRecentNoPO();
    fetchData(); 
  }

  void playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  Future<void> fetchPODetails() async {
  setState(() {
    isLoading = true;
  });

  try {
    final List<Map<String, dynamic>> details = await dbHelper.getPOScannedODetails(widget.poNumber);
    final List<Map<String, dynamic>> details1 = await dbHelper.getPOMasterScannedODetails(widget.poNumber);
    final List<Map<String, dynamic>> details2 = await dbHelper.getNoitemScannedODetails(widget.poNumber);

    final combinedDetails = [...details, ...details1, ...details2];

    setState(() {
      poDetails = combinedDetails;
    });
  } catch (e) {
    
    print('Error fetching PO details: $e');
    
  } finally {
    setState(() {
      isLoading = false; 
    });
  }
}

Future<void> fetchSummaryRecentPOs() async {
  try {
 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); 

    if (userId == null || userId.isEmpty) {
      print('Error: userId is empty');
      return; 
    }

    final summary = await dbHelper.getSummaryRecentPOs(userId);

    setState(() {
      recentPOSummary = summary;
    });

    print('summary: $summary');
  } catch (e) {
    print('Error fetching recent PO summary: $e');
  }
}

Future<void> fetchSummaryRecentMasterPOs() async {
 try {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); 

    if (userId == null || userId.isEmpty) {
      print('Error: userId is empty');
      return; 
    }
    final summary = await dbHelper.getSummaryMasterRecentPOs(userId);

    setState(() {
      recentMasterPOSummary = summary;
    });

    print('summary: $summary');
  } catch (e) {
    print('Error fetching recent PO summary: $e');
  }
}
Future<void> fetchSummaryRecentNoPO() async {
 try {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); 

    if (userId == null || userId.isEmpty) {
      print('Error: userId is empty');
      return;  
    }

    final summary = await dbHelper.getSummaryRecentNoPO(userId);

    setState(() {
      recentNoPOSummary = summary;
    });

    print('summary: $summary');
  } catch (e) {
    print('Error fetching recent PO summary: $e');
  }
}

  Future<void> fetchData() async {
    try {
      final userData = storageService.get(StorageKeys.USER);
      final response = await apiservice.loginUser(
        userData['USERID'],
        userData['USERPASSWORD'],
        userData['PT']
      );

      if (response.containsKey('code') && response['code'] == "1") {
        final List<dynamic> msgList = response['msg'];
        if (msgList.isNotEmpty && msgList[0] is Map<String, dynamic>) {
          setState(() {
            userId = msgList[0]['USERID'];
          });
        }
      } else {
        print('Request failed with code ${response['code']}');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<void> fetchScannedResults() async {
    try {
      final results = await dbHelper.getScannedPODetails(widget.poNumber);
      setState(() {
        scannedResults = results;
      });
      print(results);
    } catch (e) {
      print('Error fetching scanned results: $e');
    }
  }
    Future<void> fetchMasterItemsResults() async {
    try {
      final results = await dbHelper.getScannedMasterPODetails(widget.poNumber);
      setState(() {
        masterScannedResults = results;
      });
    } catch (e) {
      print('Error fetching scanned results: $e');
    }
  }
  Future<void> fetchNoItemsResults() async {
    try {
      final results = await dbHelper.getScannedNoItemsDetails(widget.poNumber);
      setState(() {
        noitemScannedResults = results;
      });
    } catch (e) {
      print('Error fetching scanned results: $e');
    }
  }



  void _deleteScannedResult(String scandate) async {
    await dbHelper.deletePOResult(widget.poNumber, scandate);
    fetchScannedResults();
    // fetchScannedOverResults();
  }
  void _deleteScannedNoItemResult(String scandate) async {
    await dbHelper.deletePONoItemResult(widget.poNumber, scandate);
    fetchScannedResults();
    // fetchScannedOverResults();
  }

  void submitScannedResults() async {
    final url = 'http://108.136.252.63:8080/pogr/trans.php';
   
    final deviceInfoPlugin = DeviceInfoPlugin();
    String device_name = '';

    if (GetPlatform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      device_name = '${androidInfo.brand} ${androidInfo.model}';
    } else if (GetPlatform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      device_name = '${iosInfo.name} ${iosInfo.systemVersion}';
    } else {
      device_name = 'Unknown Device';
    }
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch USERID')),
      );
      return;
    }

    List<Map<String, dynamic>> dataScan = scannedResults.map((item) {
      return {
        "pono": item['pono'],
        "itemsku": item['item_sku'],
        "skuname": item['item_name'],
        "barcode": item['barcode'] ?? '',
        "vendorbarcode": item['vendorbarcode'] ?? '',
        "qty": item['qty_scanned'].toString(),
        "scandate": item['scandate'],
        "machinecd": item['device_name'],
        "qtykoli": item['qty_koli'].toString(),

      };
    }).toList();

List<Map<String, dynamic>> allResults = [];

if (masterScannedResults.isNotEmpty) {
  allResults.addAll(masterScannedResults);
}
if (noitemScannedResults.isNotEmpty) {
  allResults.addAll(noitemScannedResults);
}
    List<Map<String, dynamic>> dataScanOver = allResults.map((item1) {
      return {
        "pono": item1['pono'],
        "itemsku": item1['item_sku'],
        "skuname": item1['item_name'],
        "barcode": item1['barcode'] ?? '',
        "vendorbarcode": item1['vendorbarcode'] ?? '',
        "qty": item1['qty_scanned'].toString(),
        "scandate": item1['scandate'],
        "machinecd": item1['device_name'],
        "qtykoli": item1['qty_koli'].toString(),
      };
    }).toList();

    final body = json.encode({
      "USERID": userId,
      "MACHINECD": device_name,
      "PONO": widget.poNumber,
      "DATASCAN": dataScan,
      "DATAOVER": dataScanOver,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit data: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
Map<String, List<Map<String, dynamic>>> groupSummaryByPONumber(List<Map<String, dynamic>> summary) {
  final Map<String, List<Map<String, dynamic>>> groupedSummary = {};

  for (var item in summary) {
    String pono = item['pono'];
    if (!groupedSummary.containsKey(pono)) {
      groupedSummary[pono] = [];
    }
    groupedSummary[pono]!.add(item);
  }

  return groupedSummary;
}

  Widget buildRecentPOSummary() {
    final groupedSummary = groupSummaryByPONumber(recentPOSummary);
    final groupedSummary1 = groupSummaryByPONumber(recentMasterPOSummary);
    final groupedSummary2 = groupSummaryByPONumber(recentNoPOSummary);

    

 int grandTotal = 0; // Initialize grandTotal to 0

if (groupedSummary.containsKey(widget.poNumber)) {
  // Only proceed if the key exists
  grandTotal = groupedSummary[widget.poNumber]!.fold(0, (int sum, detail) {
    return sum + (detail['totalscan'] as int? ?? 0);
  });
} else {
  // Optionally handle the case where the key does not exist
  print('PO number ${widget.poNumber} not found in groupedSummary.');
}

 int calculateGrandTotal() {
 
  int totalMaster = 0;
  int totalNoPO = 0;

  if (groupedSummary1.containsKey(widget.poNumber)) {
    totalMaster = groupedSummary1[widget.poNumber]!.fold(0, (sum, detail) {
      return sum + (detail['totalscan'] as int? ?? 0);
    });
  }

  if (groupedSummary2.containsKey(widget.poNumber)) {
    totalNoPO = groupedSummary2[widget.poNumber]!.fold(0, (sum, detail) {
      return sum + (detail['totalscan'] as int? ?? 0);
    });
  }

  return totalMaster + totalNoPO;  
}


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
       Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,  
        children: [
          const Text(
            'Grand Total PO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          Text(
            grandTotal.toString(),
            style: const TextStyle(
              
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
        ],
      ),
    ),
  Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,  
        children: [
          
          const Text(
            'Grand Total Unrecognize',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
           Text(
             calculateGrandTotal().toString(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
        
    ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'PO Summary',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('PO NO')),
            DataColumn(label: Text('Item SKU')),
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Barcode')),
            DataColumn(label: Text('VendorBarcode')),
            DataColumn(label: Text('Total Scanned')),
          ],
        rows: [
  // Check if the key exists in groupedSummary before accessing it
  if (groupedSummary.containsKey(widget.poNumber)) ...groupedSummary[widget.poNumber]!.reversed.map((detail) {
    return DataRow(cells: [
                DataCell(Text(detail['pono'] ?? '')),
                DataCell(Text(detail['item_sku'] ?? '')),
                DataCell(Text(detail['item_name'] ?? '')),
                DataCell(Text(detail['barcode'] ?? '')),
                DataCell(Text(detail['vendorbarcode'] ?? '')),
                DataCell(Text(detail['totalscan'].toString())),
              ]);
            }).toList(),
           
          ],
        ),
      ),
    ],
  );
}
Widget buildRecentNoPOSummary() {
  final groupedSummary1 = groupSummaryByPONumber(recentMasterPOSummary);
  final groupedSummary2 = groupSummaryByPONumber(recentNoPOSummary);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Unrecognized Summary',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('PO NO')),
            DataColumn(label: Text('Item SKU')),
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Barcode')),
            DataColumn(label: Text('Vendor Barcode')),
            DataColumn(label: Text('Total Scanned')),
          ],
          rows: [
            // Check if groupedSummary1 contains widget.poNumber
            if (groupedSummary1.containsKey(widget.poNumber))
              ...groupedSummary1[widget.poNumber]!.reversed.map((detail) {
                return DataRow(cells: [
                  DataCell(Text(detail['pono'] ?? '')),
                  DataCell(Text(detail['item_sku'] ?? '')),
                  DataCell(Text(detail['item_name'] ?? '')),
                  DataCell(Text(detail['barcode'] ?? '')),
                  DataCell(Text(detail['vendorbarcode'] ?? '')),
                  DataCell(Text(detail['totalscan']?.toString() ?? '0')),
                ]);
              }).toList(),
            // Check if groupedSummary2 contains widget.poNumber
            if (groupedSummary2.containsKey(widget.poNumber))
              ...groupedSummary2[widget.poNumber]!.reversed.map((detail) {
                return DataRow(cells: [
                  DataCell(Text(detail['pono'] ?? '')),
                  DataCell(Text(detail['item_sku'] ?? '')),
                  DataCell(Text(detail['item_name'] ?? '')),
                  DataCell(Text(detail['barcode'] ?? '')),
                  DataCell(Text(detail['vendorbarcode'] ?? '')),
                  DataCell(Text(detail['totalscan']?.toString() ?? '0')),
                ]);
              }).toList(),
          ],
        ),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
         title: Text('${widget.poNumber}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : poDetails.isEmpty
              ? Center(child: Text('No details found for this PO'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       buildRecentPOSummary(),
                       buildRecentNoPOSummary(),
                 
                      SizedBox(height: 20),  
                    Center(
                      child: ElevatedButton(
                        onPressed: submitScannedResults,
                        child: Text('Submit Results'),
                      ),
                      
                    ),
                    
                    ],
                  ),
              )

    );
    // ]))]))); 
  }
}
