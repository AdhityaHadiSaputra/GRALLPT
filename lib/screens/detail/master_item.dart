import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grmobileallpt/api_service.dart';
import 'package:grmobileallpt/models/db_helper.dart';

class MasterItemPage extends StatefulWidget {
  @override
  _MasterItemPageState createState() => _MasterItemPageState();
}

class _MasterItemPageState extends State<MasterItemPage> {
  final ApiMaster apiMaster = ApiMaster();
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLocalMasterItems(); // Load items from the local database on init
  }

  Future<void> loadLocalMasterItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dbItems = await DatabaseHelper().getAllMasterItems();
      setState(() {
        items = dbItems;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${dbItems.length} master items saved locally')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading local data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> clearMasterItems() async {
    try {
      await DatabaseHelper().clearMasterItems();
      setState(() {
        items.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All items cleared successfully')),
      );
    } catch (e) {
      print(e); // Log the actual error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing items: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchMasterItems(String brand) async {
    setState(() {
      isLoading = true;
    });

    try {

      await clearMasterItems();


      await apiMaster.fetchAndSaveMasterItems(brand, (loading) {
        setState(() {
          isLoading = loading;
        });
      });

      await loadLocalMasterItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchItems() {
    final searchQuery = searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      fetchMasterItems(searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Brand',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchItems,
                ),
              ),
              onSubmitted: (_) => searchItems(),
              inputFormatters: [UpperCaseTextFormatter()],
            ),
          ),
          
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                  child: Text(
                    '${items.length} master items saved locally !!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
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
