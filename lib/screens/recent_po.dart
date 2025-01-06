<<<<<<< HEAD
import 'package:flutter/material.dart';
=======
// import 'package:flutter/material.dart';
// import 'package:grmobileallpt/drawer.dart';
// import 'package:grmobileallpt/models/db_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'detail/recent_po_detail.dart';

// class RecentPOPage extends StatefulWidget {
//   const RecentPOPage({super.key});

//   @override
//   _RecentPOPageState createState() => _RecentPOPageState();
// }

// class _RecentPOPageState extends State<RecentPOPage> {
//   final DatabaseHelper dbHelper = DatabaseHelper();
//   List<Map<String, String>> recentPOs = []; // List to store Transno and PO pairs
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchRecentData();
//   }

//   // Function to fetch recent PO data from SharedPreferences
//   // Future<void> fetchRecentData() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   List<String> recentTransNos = prefs.getStringList('recent_transnos') ?? [];
//   //   List<String> recentNoPOs = prefs.getStringList('recent_transnos') ?? [];

//   //   // Ensure both lists have the same length
//   //   if (recentTransNos.length != recentNoPOs.length) {
//   //     print("Mismatch between PO and Transno list lengths. Please check data integrity.");
//   //     final minLength = recentTransNos.length < recentNoPOs.length
//   //         ? recentTransNos.length
//   //         : recentNoPOs.length;
//   //     recentNoPOs = recentNoPOs.sublist(0, minLength);
//   //     recentTransNos = recentTransNos.sublist(0, minLength);
//   //   }

//   //   // Create a list of Transno and PO pairs
//   //   recentPOs = List.generate(recentTransNos.length, (index) {
//   //     return {
//   //       'transno': recentTransNos[index],
//   //       'transno': recentNoPOs[index],
//   //     };
//   //   });

//   //   // Update UI after fetching data
//   //   setState(() {
//   //     isLoading = false;
//   //   });
//   // }
//   Future<void> fetchRecentData() async {
//   final prefs = await SharedPreferences.getInstance();

//   // Ambil data dari SharedPreferences
//   List<String> recentTransNos = prefs.getStringList('recent_transnos') ?? [];
//   List<String> recentNoPOs = prefs.getStringList('recent_pos') ?? [];

//   // Debug log untuk memastikan data diambil dengan benar
//   print("Fetching data...");
//   print("Transnos: $recentTransNos");
//   print("POs: $recentNoPOs");

//   // Pastikan panjang daftar sesuai
//   if (recentTransNos.length != recentNoPOs.length) {
//     print("Mismatch between Transno and PO lengths.");
//     final minLength = recentTransNos.length < recentNoPOs.length
//         ? recentTransNos.length
//         : recentNoPOs.length;
//     recentTransNos = recentTransNos.sublist(0, minLength);
//     recentNoPOs = recentNoPOs.sublist(0, minLength);
//   }

//   // Gabungkan ke daftar untuk UI
//   recentPOs = List.generate(recentTransNos.length, (index) {
//     return {
//       'transno': recentTransNos[index],
//       'pono': recentNoPOs[index],
//     };
//   });

//   // Perbarui UI
//   setState(() {
//     isLoading = false;
//   });

//   // Debug log untuk memverifikasi data akhir
//   print("Recent POs: $recentPOs");
// }




//   // // Function to add a new Transno and PO to SharedPreferences
//   // Future<void> addRecentPO(String transno, String transNumber) async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   List<String> recentTransNos = prefs.getStringList('recent_transnos') ?? [];
//   //   List<String> recentNoPOs = prefs.getStringList('recent_transnos') ?? [];

//   //   // Ensure unique Transno, not PO
//   //   if (recentTransNos.contains(transno)) {
//   //     print('Transno $transno already exists.');
//   //     return;
//   //   }

//   //   // Add to the beginning of the list (latest first)
//   //   recentTransNos.insert(0, transno);
//   //   recentNoPOs.insert(0, transNumber);

//   //   // Save back to SharedPreferences
//   //   await prefs.setStringList('recent_transnos', recentTransNos);
//   //   await prefs.setStringList('recent_transnos', recentNoPOs);

//   //   // Update UI
//   //   setState(() {
//   //     recentPOs.insert(0, {'transno': transno, 'transno': transNumber});
//   //   });

//   //   // Debug logs
//   //   print("Updated Transno list: $recentTransNos");
//   //   print("Updated PO list: $recentNoPOs");
//   // }
// Future<void> addRecentPO(String transno, String transNumber) async {
//   final prefs = await SharedPreferences.getInstance();

//   // Ambil data dari SharedPreferences
//   List<String> recentTransNos = prefs.getStringList('recent_transnos') ?? [];
//   List<String> recentNoPOs = prefs.getStringList('recent_pos') ?? [];

//   // Tambahkan jika Transno belum ada dalam daftar
//   if (!recentTransNos.contains(transno)) {
//     recentTransNos.insert(0, transno); // Tambahkan Transno ke awal
//     recentNoPOs.insert(0, transNumber);  // Tambahkan PO ke awal
//   }

//   // Simpan kembali ke SharedPreferences
//   await prefs.setStringList('recent_transnos', recentTransNos);
//   await prefs.setStringList('recent_pos', recentNoPOs);

//   // Perbarui daftar `recentPOs` untuk UI
//   setState(() {
//     recentPOs = List.generate(recentTransNos.length, (index) {
//       return {
//         'transno': recentTransNos[index],
//         'pono': recentNoPOs[index],
//       };
//     });
//   });

//   // Debug log untuk memastikan semua data tersimpan
//   print("Updated Transnos: $recentTransNos");
//   print("Updated POs: $recentNoPOs");
// }



//   // Function to remove Transno and related PO data
//   Future<void> removeRecentPOAndData(String transno, String transNumber, int index) async {
//     final prefs = await SharedPreferences.getInstance();

//     // Remove the Transno and PO pair from the list
//     recentPOs.removeAt(index);
//     await prefs.setStringList('recent_transnos', recentPOs.map((e) => e['transno']!).toList());
//     await prefs.setStringList('recent_pos', recentPOs.map((e) => e['pono']!).toList());

//     // Also delete data from the database for that PO
//     await dbHelper.deletePO(transNumber);
//     await dbHelper.deletePOScannedDifferentResult(transNumber);
//     await dbHelper.deletePOScannedNoItemsResult(transNumber);
//     await dbHelper.deletePOScannedMasterResult(transNumber);

//     // Update UI
//     setState(() {});

//     // Show feedback message
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Transno $transno and PO $transNumber and related data removed')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Recent PO'),
//       ),
//       drawer: const MyDrawer(),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : recentPOs.isEmpty
//               ? const Center(child: Text('No recent PO found'))
//               : ListView.builder(
//                   itemCount: recentPOs.length,
//                   itemBuilder: (context, index) {
//                     final entry = recentPOs[index];
//                     final transNumber = entry['transno']!;
//                     final transNumber = entry['pono']!;

//                     return Card(
//                       margin: const EdgeInsets.all(8.0),
//                       child: ListTile(
//                         title: Text('Transno: $transNumber'),
//                         subtitle: Text('PO: $transNumber'),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => PODetailPage(
//                                       transNumber: transNumber,
//                                       transNumber: transNumber,
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: const Icon(Icons.view_cozy),
//                             ),
//                             const SizedBox(width: 8.0),
//                             TextButton(
//                               onPressed: () => removeRecentPOAndData(
//                                 transNumber,
//                                 transNumber,
//                                 index,
//                               ),
//                               child: const Icon(Icons.delete),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

import 'dart:convert';

import 'package:flutter/material.dart';

>>>>>>> 28e9271fe74f1a0e0c98250124fbbb0ad95cb60c
import 'package:grmobileallpt/drawer.dart';
import 'package:grmobileallpt/models/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail/recent_po_detail.dart';

class RecentPOPage extends StatefulWidget {
  const RecentPOPage({super.key});

  @override
  _RecentPOPageState createState() => _RecentPOPageState();
}

class _RecentPOPageState extends State<RecentPOPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<String> recentNoPOs = [];
<<<<<<< HEAD
=======
  List<String> recentPOs = [];
  List<Map<String,dynamic>> recentTrandPO = [];


>>>>>>> 28e9271fe74f1a0e0c98250124fbbb0ad95cb60c
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    fetchRecentPO(); 
=======
    fetchRecentPO();
    fetchRecentTr(); 
    fetchRecentTranandPO();// Fetch recent POs when the page loads
  }

  
  Future<void> fetchRecentTranandPO() async {
    final prefs = await SharedPreferences.getInstance();
    final recentTrandPOString = prefs.getStringList('recent_transandpo') ?? [];
    recentTrandPOString.forEach((e){
      recentTrandPO.add(jsonDecode(e));
    });
    setState(() {
      isLoading = false;
      print(recentTrandPO);
    });

    print(recentTrandPO);
>>>>>>> 28e9271fe74f1a0e0c98250124fbbb0ad95cb60c
  }

  Future<void> fetchRecentPO() async {
    final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
    recentNoPOs = prefs.getStringList('recent_pos') ?? [];
    setState(() {
      isLoading = false;
    });
  }

  Future<void> removeRecentPO(String poNumber) async {
    final prefs = await SharedPreferences.getInstance();
    recentNoPOs.remove(poNumber);
    await prefs.setStringList('recent_pos', recentNoPOs);

    await dbHelper.deletePO(poNumber);

    setState(() {}); 
  }

  Future<void> removeRecentPOResult(String poNumber) async {
    final prefs = await SharedPreferences.getInstance();
    recentNoPOs.remove(poNumber);
    await prefs.setStringList('recent_pos', recentNoPOs);

    await dbHelper.deletePOScannedDifferentResult(poNumber);

    setState(() {}); 
  }
  Future<void> removeRecentMasterResult(String poNumber) async {
    final prefs = await SharedPreferences.getInstance();
    recentNoPOs.remove(poNumber);
    await prefs.setStringList('recent_pos', recentNoPOs);

    await dbHelper.deletePOScannedMasterResult(poNumber);

    setState(() {}); 
  }
  Future<void> removeRecentNOItemPOResult(String poNumber) async {
    final prefs = await SharedPreferences.getInstance();
    recentNoPOs.remove(poNumber);
    await prefs.setStringList('recent_pos', recentNoPOs);

    await dbHelper.deletePOScannedNoItemsResult(poNumber);

    setState(() {}); 
  }
  Future<void> clearAllScaned() async {
    await dbHelper.clearScanedTable();
    setState(() {
      recentNoPOs.clear(); 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All item PO records deleted')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent PO'),
      ),
      drawer: const MyDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentNoPOs.isEmpty
              ? const Center(child: Text('No recent PO found'))
              : ListView.builder(
                  itemCount: recentNoPOs.length,
                  itemBuilder: (context, index) {
                    final poNumber = recentNoPOs[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(poNumber),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PODetailPage(poNumber: poNumber),
                                  ),
                                );
                              },
                              child: const Column(
                                children: [
                                  Icon(Icons.view_cozy),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            TextButton(
                             onPressed: () {
  removeRecentPO(poNumber);           // Remove from recent POs
  removeRecentPOResult(poNumber);     // Remove scanned with different results
  removeRecentNOItemPOResult(poNumber);
  removeRecentMasterResult(poNumber); // Remove scanned with no items
},

                              child: const Column(
                                children: [
                                  Icon(Icons.delete),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
=======
    recentNoPOs = prefs.getStringList('recent_transnos') ?? [];
    setState(() {
      isLoading = false;
      print(recentNoPOs);
    });
  }
    Future<void> fetchRecentTr() async {
    final prefs = await SharedPreferences.getInstance();
    recentPOs = prefs.getStringList('recent_pos') ?? [];
    setState(() {
      isLoading = false;

    print(recentPOs);
    });
  }


  Future<void> removeRecentTR(String transNumber, String poNumber) async {
    final prefs = await SharedPreferences.getInstance();
    // recentTrandPO.remove({
    //   'transno':transNumber,
    //   'pono':poNumber
    // });
    recentTrandPO = recentTrandPO.where((e)=>!(e['transno']==transNumber)).toList();
    print('hapuspo$poNumber');
    print('hapustrans$transNumber');

    print('hapus$recentTrandPO');
    // recentNoPOs.remove(transNumber);
    // recentPOs.remove(poNumber);

    await prefs.setStringList('recent_transandpo', recentTrandPO.map((e)=>jsonEncode(e)).toList());
    
    // await prefs.setStringList('recent_transnos', recentNoPOs);
    // await prefs.setStringList('recent_pos', recentPOs);

    // Remove PO from the database
    await dbHelper.deletePO1(transNumber);
    await dbHelper.deletePOScannedDifferentResult1(transNumber);
    await dbHelper.deletePOScannedNoItemsResult1(transNumber);
    await dbHelper.deletePOScannedMasterResult1(transNumber);

    await dbHelper.deletePO(poNumber);
    await dbHelper.deletePOScannedDifferentResult(poNumber);
    await dbHelper.deletePOScannedNoItemsResult(poNumber);
    await dbHelper.deletePOScannedMasterResult(poNumber);

    setState(() {}); // Update the UI
  }

 
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Recent PO'),
    ),
    drawer: const MyDrawer(),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        // : recentNoPOs.isEmpty
        : recentTrandPO.isEmpty
            ? const Center(child: Text('No recent PO found'))
            : ListView.builder(
                // itemCount: recentNoPOs.length,
                itemCount: recentTrandPO.length,
                itemBuilder: (context, index) {
                  // final transNumber = recentNoPOs[index];
                  final data = recentTrandPO[index];
                  final transNumber = data['transno'];
                  final poNumber = data['pono'];

                  print(transNumber);
                  // Pastikan recentPOs memiliki data untuk indeks yang sesuai
                  // final poNumber = recentPOs.isNotEmpty && index < recentPOs.length
                  //     ? recentPOs[index]
                  //     : 'Unknown PO'; // Default jika data tidak ditemukan

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(transNumber), // Menampilkan nomor transaksi
                      subtitle: Text(poNumber), // Menampilkan PO Number
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PODetailPage(
                                    transNumber: transNumber,
                                    poNumber: transNumber, // Pastikan poNumber benar
                                  ),
                                ),
                              );
                            },
                            child: const Column(
                              children: [
                                Icon(Icons.view_cozy),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          TextButton(
                            onPressed: () {
                              // Menghapus PO dari daftar, update SharedPreferences dan database
                              removeRecentTR(transNumber, poNumber);
                            },
                            child: const Column(
                              children: [
                                Icon(Icons.delete),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}
>>>>>>> 28e9271fe74f1a0e0c98250124fbbb0ad95cb60c
}