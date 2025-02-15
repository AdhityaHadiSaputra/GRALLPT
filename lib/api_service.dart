import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grmobileallpt/models/db_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';

class APIUrl{
  static String BASE_URL = 'http://108.136.252.63:8080/pogr';
  static String LOGIN_URL = '$BASE_URL/login.php';
  static String PO_URL = '$BASE_URL/cekpo.php';
  static String MASTER_URL = '$BASE_URL/getmaster.php';
}

// class ApiService {
//   Future<Map<String, dynamic>> loginUser(
//       String USERID, String USERPASSWORD) async {
//     try {
//       final response = await http.post(
//         Uri.parse(APIUrl.LOGIN_URL),
//         body: {
//           'ACTION': 'LOGIN',
//           'USERID': USERID,
//           'USERPASSWORD': USERPASSWORD,
//         },
//       );
//       if (response.statusCode == 200) {
//         Map<String, dynamic> result = jsonDecode(response.body);
        
//         return result;
//       } else {
//         throw Exception('Failed to login');
//       }
//     } catch (error) {
//       print('Error: $error');
//       rethrow;
//     }
//   }
// }

class ApiService {
  Future<Map<String, dynamic>> loginUser(String USERID, String USERPASSWORD, String PT) async {
    try {
      final response = await http.post(
        Uri.parse(APIUrl.LOGIN_URL),
        body: {
          'ACTION': 'LOGIN',
          'USERID': USERID,
          'USERPASSWORD': USERPASSWORD,
          'PT' : PT,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(response.body);
        
        print('API Response: $result');
        
        String? userId;
        if (result['msg'] is List && result['msg'].isNotEmpty) {
          userId = result['msg'][0]['USERID']; 
        }

        if (userId != null && userId.isNotEmpty) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId); 
          print('User ID saved: $userId');
        } else {
          print('Error: userId is null or empty in the API response');
        }

        return result;
      } else {
        throw Exception('Failed to login');
      }
    } catch (error) {
      print('Error: $error');
      rethrow;
    }
  }
}


class Apiuser {
 
  Future<Map<String, dynamic>> fetchPO(String PONO) async {
    try {
      final response = await http.post(
        Uri.parse(APIUrl.PO_URL),
        body: {
          'ACTION': 'GETPO',
          'PONO': PONO,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load PO data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

class ApiMaster {
 Future<void> fetchAndSaveMasterItems(String brand, Function(bool) setLoading) async {
  setLoading(true);
  try {
    print('Fetching master items for brand: $brand');

    final response = await http.post(
      Uri.parse(APIUrl.MASTER_URL),
      body: {
        'ACTION': 'GETITEM',
        'BRAND': brand,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      print('Response received: $data'); 

      if (data['code'] == "1" && data['msg'] != null) {
        final List<dynamic> items = data['msg'];
        print('Number of items received: ${items.length}'); 

        List<Map<String, dynamic>> masterItemsToInsert = [];

        for (var item in items) {
          masterItemsToInsert.add({
            'item_sku': item['ITEMSKU'],
            'item_name': item['ITEMSKUNAME'],
            'barcode': item['BARCODE'] ?? '',
            'vendorbarcode': item['VENDORBARCODE'] ?? '',
          });
        }

        print('Inserting ${masterItemsToInsert.length} items to local database'); 


        await DatabaseHelper().bulkInsertOrUpdateMasterItems(masterItemsToInsert);

        print('Data saved successfully to local database'); 
      } else {
        print('Invalid data structure or no items found'); 
        throw Exception('Failed to load Master Data or invalid data structure');
      }
    } else {
      print('Failed to load Master Data, status code: ${response.statusCode}'); 
      throw Exception('Failed to load Master Data');
    }
  } catch (e) {
    print('Error fetching and saving master items: $e'); 
    throw e; 
  } finally {
    setLoading(false); 
  }
}


}