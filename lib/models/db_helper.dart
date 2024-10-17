import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const scannedPOType = 'scanned_po';
const scannedPOType1 = 'defect_po';

const inputPOType = 'input_po';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'po_database.db');
    print('Database path: $path');  
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        print('Creating database...');  
        await _onCreate(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print(
            'Upgrading database from version $oldVersion to $newVersion');  
        await _onUpgrade(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        print('Opening database...');  
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      print('Executing CREATE TABLE statement...');  
      await db.execute(
        '''
        CREATE TABLE po(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          barcode TEXT,
          vendorbarcode TEXT,
          scandate TEXT,
          device_name TEXT,
          type TEXT
        )
        ''',
      );
      await db.execute(
        '''
        CREATE TABLE scanned_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
      await db.execute(
        '''
        CREATE TABLE scanned_master(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
       await db.execute(
        '''
        CREATE TABLE noitems(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
       await db.execute(
        '''
        CREATE TABLE master_item(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT
        )
        ''',
      );
      await db.execute(
        '''
        CREATE TABLE defect(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
      await db.execute(
        '''
        CREATE TABLE defect_master(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
      await db.execute(
        '''
        CREATE TABLE defect_no(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pono TEXT,
          item_sku TEXT,
          item_name TEXT,
          barcode TEXT,
          vendorbarcode TEXT,
          qty_po INTEGER,
          qty_scanned INTEGER,
          qty_different INTEGER,
          user TEXT,
          device_name TEXT,
          scandate TEXT,
          qty_koli TEXT,
          type TEXT,
          status TEXT
        )
        ''',
      );
    } catch (e) {
      print('Error creating tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await db.execute(
          '''
          ALTER TABLE master_item ADD COLUMN vendorbarcode TEXT;
          ''',
        );
      }
    } catch (e) {
      print('Error upgrading database: $e');
    }
  }

  Future<int> insertScannedResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('scanned_results', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }

  Future<List<Map<String, dynamic>>> getScannedResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_results',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }
   Future<int> insertScannedMasterItemsResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('scanned_master', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }

  Future<List<Map<String, dynamic>>> getScannedMasteritemResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_master',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }
  Future<int> insertScannedNoItemsResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('noitems', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }

  Future<List<Map<String, dynamic>>> getScannedNoitemResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'noitems',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }
  Future<int> insertScannedDefectItemsResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('defect', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }
  Future<int> insertScannedDefectMasterResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('defect_master', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }
  Future<int> insertScannedDefectNoResult(Map<String, dynamic> scannedData) async {
    try {
      final db = await database;
      return await db.insert('defect_no', scannedData);
    } catch (e) {
      print('Error inserting scanned result: $e');
      return -1;  
    }
  }

  Future<List<Map<String, dynamic>>> getScannedDefectitemResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }
  Future<List<Map<String, dynamic>>> getScannedDefectmasterResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_master',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }
  Future<List<Map<String, dynamic>>> getScannedDefectnoResultsByPONumber(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_no',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'scandate DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getScannedPODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_results',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
    Future<List<Map<String, dynamic>>> getScannedMasterPODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_master',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<List<Map<String, dynamic>>> getScannedNoItemsDetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'noitems',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<List<Map<String, dynamic>>> getScannedPODefectDetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<List<Map<String, dynamic>>> getScannedPODefectMasterDetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_master',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<List<Map<String, dynamic>>> getScannedPODefectNoDetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_no',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<void> clearDefectTable() async {
    final db = await database;
    await db.delete('defect');  
  }
  Future<void> clearDefectMasterTable() async {
    final db = await database;
    await db.delete('defect_master');  
  }
  Future<void> clearDefectNoTable() async {
    final db = await database;
    await db.delete('defect_no');  
  }
  Future<void> clearScanedTable() async {
    final db = await database;
    await db.delete('noitems'); 
    await db.delete('scanned_master');  
     
  }


  Future<bool> scannedPOExists(String poNumber, String barcode, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'po',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType],
    );
    return result.isNotEmpty;
  }

  Future<bool> poScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'scanned_results',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }
  Future<bool> poMasterScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'scanned_master',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }
  Future<bool> poNoItemScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'noitems',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }

  Future<bool> poDefectScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'defect',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }
  Future<bool> poDefectMasterScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'defect_master',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }
  Future<bool> poDefectNoScannedExists(
      String poNumber, String barcode, String scandate, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'defect_no',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, scannedPOType, scandate],
    );
    return result.isNotEmpty;
  }


  Future<void> insertOrUpdateScannedResults(Map<String, dynamic> poData) async {
    final db = await database;  

    try {
      // First try updating the defect data
      int updateCount = await db.update(
        'scanned_results',
        poData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [poData['pono'], poData['barcode'], poData['vendorbarcode'], poData['type'], poData['scandate']],
      );

      // If no rows were updated, insert the new defect data
      if (updateCount == 0) {
        await db.insert(
          'scanned_results',
          poData,

        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
    // final db = await database;

    // bool exists = await poScannedExists(
    //     poData['pono'], poData['barcode'], poData['vendorbarcode'], poData['scandate']);
    // final mappedPOData = {...poData, "type": scannedPOType};
    // // poData["type"] = scannedPOType;
    // // await db.insert('scanned_results', poData);

    // if (exists) {
    //   await db.update(
    //     'scanned_results',
    //     mappedPOData,
    //     where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
    //     whereArgs: [
    //       mappedPOData['pono'],
    //       mappedPOData['barcode'],
    //       mappedPOData['vendorbarcode'],
    //       scannedPOType,
    //       mappedPOData['scandate']
    //     ],
    //   );
    //   print(
    //       'CEKK PO updated: ${mappedPOData['pono']} - Barcode: ${mappedPOData['barcode']} - VendorBarcode: ${mappedPOData['vendorbarcode']} - Scandate: ${mappedPOData['scandate']}');
    // } else {
    //   await db.insert('scanned_results', mappedPOData);
    //   print(
    //       'CEKK PO inserted: ${mappedPOData['pono']} - Barcode: ${mappedPOData['barcode']} - VendorBarcode: ${mappedPOData['vendorbarcode']} - Scandate: ${mappedPOData['scandate']}');
    // }
  }
 
 Future<void> insertOrUpdateScannedMasterItemsResults(Map<String, dynamic> masterData) async {
    final db = await database;  

    try {
      // First try updating the defect data
      int updateCount = await db.update(
        'scanned_master',
        masterData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [masterData['pono'], masterData['barcode'], masterData['vendorbarcode'], masterData['type'], masterData['scandate']],
      );

      // If no rows were updated, insert the new defect data
      if (updateCount == 0) {
        await db.insert(
          'scanned_master',
          masterData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
  }

  Future<void> insertOrUpdateScannedNoItemsResults(Map<String, dynamic> noItemsData) async {
    final db = await database;  

    try {
      int updateCount = await db.update(
        'noitems',
        noItemsData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [noItemsData['pono'], noItemsData['barcode'], noItemsData['vendorbarcode'], noItemsData['type'], noItemsData['scandate']],
      );
      if (updateCount == 0) {
        await db.insert(
          'noitems',
          noItemsData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
  }
  Future<void> insertOrUpdateScannedDefectResults(Map<String, dynamic> defectData) async {
    final db = await database; 

    try {
     
      int updateCount = await db.update(
        'defect',
        defectData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [defectData['pono'], defectData['barcode'], defectData['vendorbarcode'], defectData['type'], defectData['scandate']],
      );

      if (updateCount == 0) {
        await db.insert(
          'defect',
          defectData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
  }
  Future<void> insertOrUpdateScannedDefectMasterResults(Map<String, dynamic> defectMasterData) async {
    final db = await database; 

    try {
      int updateCount = await db.update(
        'defect_master',
        defectMasterData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [defectMasterData['pono'], defectMasterData['barcode'], defectMasterData['vendorbarcode'], defectMasterData['type'], defectMasterData['scandate']],
      );

      if (updateCount == 0) {
        await db.insert(
          'defect_master',
          defectMasterData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
  }
  Future<void> insertOrUpdateScannedDefectNoResults(Map<String, dynamic> defectNoData) async {
    final db = await database; 

    try {
      int updateCount = await db.update(
        'defect_no',
        defectNoData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
        whereArgs: [defectNoData['pono'], defectNoData['barcode'], defectNoData['vendorbarcode'], defectNoData['type'], defectNoData['scandate']],
      );

      if (updateCount == 0) {
        await db.insert(
          'defect_no',
          defectNoData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error inserting or updating data: $e');
    }
  }


  Future<void> bulkInsertOrUpdateMasterItems(List<Map<String, dynamic>> masterItems) async {
  final db = await DatabaseHelper().database;

  await db.transaction((txn) async {
    for (var masterItem in masterItems) {
      final result = await txn.query(
        'master_item',
        where: 'item_sku = ?',
        whereArgs: [masterItem['item_sku']],
      );

      if (result.isNotEmpty) {
        await txn.update(
          'master_item',
          masterItem,
          where: 'item_sku = ?',
          whereArgs: [masterItem['item_sku']],
        );
      } else {
        await txn.insert('master_item', masterItem);
      }
    }
  });
}



Future<void> clearMasterItems() async {
  final db = await database; 
  await db.delete('master_item'); 
}

  Future<void> clearScannedResults() async {
    final db = await database;
    await db.delete('scanned_results');
  }
    Future<void> clearMasterScannedResults() async {
    final db = await database;
    await db.delete('scanned_master');
  }

  Future<int> insertPO(Map<String, dynamic> poData) async {
    final db = await database;
    poData["type"] = inputPOType;
    return await db.insert('po', poData);
  }

  Future<int> updatePO(Map<String, dynamic> poData) async {
    final db = await database;
    return await db.update(
      'po',
      poData,
      where: 'id = ? AND type = ?',
      whereArgs: [poData['id'], inputPOType],
    );
  }

  
  

  Future<void> printScannedResults() async {
    try {
      final db = await database;
      List<Map<String, dynamic>> results = await db.query('scanned_results');

      if (results.isEmpty) {
        print('No scanned results found.');
      } else {
        print('Scanned Results:');
        for (var result in results) {
          print(result);
        }
      }
    } catch (e) {
      print('Error fetching scanned results: $e');
    }
  }

  Future<bool> poExists(String poNumber, String barcode, String vendorbarcode) async {
    final db = await database;
    final result = await db.query(
      'po',
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ? AND scandate = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, inputPOType],
    );
    return result.isNotEmpty;
  }


  Future<void> insertOrUpdatePO(Map<String, dynamic> poData) async {
    final db = await database;

    bool exists = await poExists(poData['pono'], poData['barcode'], poData['vendorbarcode']);
    poData["type"] = inputPOType;
    if (exists) {
      await db.update(
        'po',
        poData,
        where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ?',
        whereArgs: [poData['pono'], poData['barcode'], poData['vendorbarcode'], inputPOType],
      );
      print('PO updated: ${poData['pono']} - Barcode: ${poData['barcode']} - VendorBarcode: ${poData['vendorbarcode']}');
    } else {
      await db.insert('po', poData);
      print('PO inserted: ${poData['pono']} - Barcode: ${poData['barcode']} - VendorBarcode: ${poData['vendorbarcode']}');
    }
    
  }


  Future<List<Map<String, dynamic>>> getItemsByPONumber(String poNumber) async {
    final db = await database;
    return await db.query(
      'po',
      where: 'pono = ?',
      whereArgs: [poNumber],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPODetails(String poNumber) async {
    final db = await database;
    return await db.query(
      'po',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, inputPOType],
    );
  }

  Future<List<Map<String, dynamic>>> getPOScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_results',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }
  Future<List<Map<String, dynamic>>> getPOMasterScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'scanned_master',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }
  Future<List<Map<String, dynamic>>> getNoitemScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'noitems',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }
  Future<List<Map<String, dynamic>>> getPODefectScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }
  Future<List<Map<String, dynamic>>> getPODefectMasterScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_master',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }
  Future<List<Map<String, dynamic>>> getPODefectNoScannedODetails(
      String poNumber) async {
    final db = await database;
    return await db.query(
      'defect_no',
      where: 'pono = ?',
      whereArgs: [poNumber],
    );
  }


  Future<List<Map<String, dynamic>>> getPOResultScannedDetails(
      String poNumber) async {
    final poDetails = await getPOScannedODetails(poNumber);
    final resultScanned =
        poDetails.where((e) => e['status'] == 'scanned').toList();
          print("CEK Scanned SCANNED $resultScanned");
    // print("CEK RESULT ${poDetails.length} SCANNED ${jsonEncode(poDetails)}\n ");
    // print("CEK RESULT SCANNED $resultScanned");
    return resultScanned;
  }

  Future<List<Map<String, dynamic>>> getPODifferentScannedDetails(
      String poNumber) async {
    final poDetails = await getPOMasterScannedODetails(poNumber);
    final differentScanned =
        poDetails.where((e) => e['status'] == 'different').toList();
    print("CEK Different SCANNED $differentScanned");
    return differentScanned;
  }

  Future<List<Map<String, dynamic>>> getPONOItemsScannedDetails(
      String poNumber) async {
    final poDetails = await getNoitemScannedODetails(poNumber);
    final noitemScanned =
        poDetails.where((e) => e['status'] == 'noitem').toList();
    print("CEK No Item SCANNED $noitemScanned");
    return noitemScanned;
  }

  Future<List<Map<String, dynamic>>> getPODefectItemsScannedDetails(
      String poNumber) async {
    final poDetails = await getPODefectScannedODetails(poNumber);
    final defectitemScanned =
    poDetails.where((e) => e['status'] == 'defect').toList();
    print("CEK defect Items $defectitemScanned");
    return defectitemScanned;
  }
  Future<List<Map<String, dynamic>>> getPODefectMasterScannedDetails(
      String poNumber) async {
    final poDetails = await getPODefectMasterScannedODetails(poNumber);
    final defectMasterScanned =
    poDetails.where((e) => e['status'] == 'defect_master').toList();
    print("CEK defect Master Items $defectMasterScanned");
    return defectMasterScanned;
  }
  Future<List<Map<String, dynamic>>> getPODefectNoScannedDetails(
      String poNumber) async {
    final poDetails = await getPODefectNoScannedODetails(poNumber);
    final defectNoScanned =
    poDetails.where((e) => e['status'] == 'defect_no').toList();
    print("CEK defect NO Items $defectNoScanned");
    return defectNoScanned;
  }
    
  Future<List<Map<String, dynamic>>> getRecentPOs({int? limit}) async {
    final db = await database;
    final query =
        'SELECT * FROM po ORDER BY id DESC${limit != null ? ' LIMIT $limit' : ''}';
    return await db.rawQuery(query);
  }
  

 
 Future<List<Map<String, dynamic>>> getSummaryRecentPOs(String userId) async {
  final db = await database;
  final query = 'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM scanned_results WHERE user = ? GROUP BY item_sku, item_name, barcode';
  return await db.rawQuery(query, [userId]); 
}
 Future<List<Map<String, dynamic>>> getSummaryMasterRecentPOs(String userId) async {
  final db = await database;
  final query = 'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM scanned_master WHERE user = ? GROUP BY item_sku, item_name, barcode';
  return await db.rawQuery(query, [userId]); 
}
   Future<List<Map<String, dynamic>>> getSummaryRecentNoPO(String userId) async {
    final db = await database;
    final query = 
        'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM noitems WHERE user = ? GROUP BY item_sku, item_name, barcode';
    return await db.rawQuery(query, [userId]); 
  }
  Future<List<Map<String, dynamic>>> getSummaryDefecttPOs(String userId) async {
    final db = await database;
    final query = 'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM defect WHERE user = ? GROUP BY item_sku, item_name, barcode';
    return await db.rawQuery(query, [userId]); 
  }
Future<List<Map<String, dynamic>>> getSummaryDefectMasterPOs(String userId) async {
    final db = await database;
    final query = 'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM defect_master WHERE user = ? GROUP BY item_sku, item_name, barcode';
    return await db.rawQuery(query, [userId]); 
  }
  Future<List<Map<String, dynamic>>> getSummaryDefectNoPOs(String userId) async {
    final db = await database;
    final query = 'SELECT item_sku, item_name, barcode, vendorbarcode, SUM(qty_scanned) as totalscan FROM defect_no WHERE user = ? GROUP BY item_sku, item_name, barcode';
    return await db.rawQuery(query, [userId]); 
  }

  Future<void> clearPOs() async {
    final db = await database;
    await db.delete('po');
  }

  Future<bool> checkTableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
    return result.isNotEmpty;
  }


  Future<void> checkTable() async {
    bool exists = await checkTableExists('po');
    print('Table exists: $exists');
  }

  Future<void> deletePO(String poNumber) async {
    final db = await database;
    await db.delete(
      'po',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, inputPOType],
    );
  }



  Future<void>  deletePOResult(String poNumber, String scandate) async {
    final db = await database;
    await db.delete(
      'scanned_results',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber, scandate],
    );
  }
    Future<void>  deletePOMasterResult(String poNumber, String scandate) async {
    final db = await database;
    await db.delete(
      'scanned_master',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber, scandate],
    );
  }
  Future<void>  deletePONoItemResult(String poNumber, String scandate) async {
    final db = await database;
    await db.delete(
      'noitems',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber, scandate],
    );
  }
  Future<void>  deleteDefectPOResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'defect',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber],
    );
  }
  Future<void>  deletePONoItemsResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'noitems',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber],
    );
  }
  Future<void>  deletePODefectItemsResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'defect',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber],
    );
  }
  Future<void> removeAllDefects(String poNumber) async {
    final db = await database;
    await db.delete('defect',
      where: 'pono = ? AND scandate = ?',
      whereArgs: [poNumber],
    ); 
  }
  



Future<void> deletePOScannedDifferentResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'scanned_results',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<void> deletePOScannedMasterResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'scanned_master',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType],
    );
  }
  Future<void> deletePOScannedDefectResult(String poNumber) async {
    final db = await database;
    await db.delete(
      'defect',
      where: 'pono = ? AND type = ?',
      whereArgs: [poNumber, scannedPOType1],
    );
  }
 Future<void> deleteMasterItem(String itemSKU) async {
    final db = await database;
    await db.delete(
      'master_item',
      where: 'item_sku = ?',
      whereArgs: [itemSKU],
    );
  }
  Future<void> updatePOItem(
      String poNumber, String barcode, String vendorbarcode, int qtyScanned, int qtyDifferent) async {
    final db = await database;
    await db.update(
      'po',
      {
        'qty_scanned': qtyScanned,
        'qty_different': qtyDifferent,
      },
      where: 'pono = ? AND barcode = ? AND vendorbarcode = ? AND type = ?',
      whereArgs: [poNumber, barcode, vendorbarcode, inputPOType],
    );
  }
Future<List<Map<String, dynamic>>> getAllMasterItems() async {
  final db = await database;
  final result = await db.query('master_item');
  print('Fetched Items: $result');
  return result.isNotEmpty ? result : [];
}


 
}