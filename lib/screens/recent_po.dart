import 'package:flutter/material.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecentPO(); 
  }

  Future<void> fetchRecentPO() async {
    final prefs = await SharedPreferences.getInstance();
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
}