import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grmobileallpt/api_service.dart';
import 'package:grmobileallpt/models/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterItemPage extends StatefulWidget {
  @override
  _MasterItemPageState createState() => _MasterItemPageState();
}

class _MasterItemPageState extends State<MasterItemPage> {
  final ApiMaster apiMaster = ApiMaster();
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  String lastSearchedBrand = ''; // To store the last searched brand

  @override
  void initState() {
    super.initState();
    loadLocalMasterItems(); // Load items from the local database on init
    loadLastSearchedBrand(); // Load last searched brand from shared preferences
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

      // Load the local master items after fetching new data
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

  // Method to handle search action
  void searchItems() async {
    final searchQuery = searchController.text.trim(); // Get the trimmed search input
    if (searchQuery.isNotEmpty) {
      // Save the search query (brand) to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSearchedBrand', searchQuery);

      fetchMasterItems(searchQuery);
    }
  }

  // Load the last searched brand from shared preferences and set it to the searchController
  Future<void> loadLastSearchedBrand() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedBrand = prefs.getString('lastSearchedBrand') ?? '';
    setState(() {
      lastSearchedBrand = savedBrand;
      searchController.text = savedBrand; // Set the saved brand to searchController
    });
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
              controller: searchController, // TextController now retains the saved brand
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
              : Column(
                  children: [
                    Center(
                      child: Text(
                        '${items.length} master items saved locally !! ${searchController.text}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // if (lastSearchedBrand.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: Text(
                    //       'Brand: $lastSearchedBrand',
                    //       style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    //     ),
                    //   ),
        ],
      ),
        ]
    ));
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
