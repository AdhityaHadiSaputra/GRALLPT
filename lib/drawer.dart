
import 'package:flutter/material.dart';
import 'package:grmobileallpt/screens/Scaqr_defect.dart';
import 'package:grmobileallpt/screens/dashboard.dart';
import 'package:grmobileallpt/screens/detail/master_item.dart';
import 'package:grmobileallpt/screens/recen_defect.dart';
import 'package:grmobileallpt/screens/recent_po.dart';
import 'package:grmobileallpt/screens/scanqr_page.dart';
import 'package:grmobileallpt/utils/storage.dart';


import 'api_service.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final ApiService apiuser = ApiService();
  final StorageService storageService = StorageService.instance;
  late String userId = '';
  late String JobId = '';
  

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final userData = storageService.get(StorageKeys.USER);
      final response = await apiuser.loginUser(
        userData['USERID'],
        userData['USERPASSWORD'],
        userData['PT'],
      );
      print(response);

      if (response.containsKey('code')) {
        final resultCode = response['code'];

        setState(() {
          if (resultCode == "1") {
            final List<dynamic> msgList = response['msg'];
            if (msgList.isNotEmpty && msgList[0] is Map<String, dynamic>) {
              final Map<String, dynamic> msgMap =
                  msgList[0] as Map<String, dynamic>;
              userId = msgMap[
                  'USERID'];
            }
          } else {
            print('Request failed with code $resultCode');
            print(response["msg"]);
          }
        });
      } else {
        print('Unexpected response structure');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the pop-up
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Authpage()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
   
    return SizedBox(
      child: Drawer(
        child: WillPopScope(
          onWillPop: () async {
            await _showLogoutConfirmationDialog(context);
            return false;
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              
              UserAccountsDrawerHeader(
                accountName: const Text(""),
                
                accountEmail: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      userId,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                  
                ),
                
                decoration: const BoxDecoration(
                  
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  image: DecorationImage(
                    image: AssetImage('assets/gr2.png'), fit: BoxFit.fill 
                  ),
                ),
              ), 
            
              ListTile(
                leading: Icon(Icons.document_scanner),
                title: const Text("Scan PO"),
                onTap: () {
                   Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanQRPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.document_scanner),
                title: const Text("Scan PO Defect"),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanQRDefectPage()),
                  );
                },
              ),


              ListTile(
                leading: Icon(Icons.article),
                title: const Text("Master Item"),
                onTap: () {
                   Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MasterItemPage()),
                  );
                },
              ),
              
              ListTile(
                leading: Icon(Icons.history),
                title: const Text("Recent PO"),
                onTap: () {
                   Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecentPOPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: const Text("Recent PO Defect"),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecentDefectPOPage()),
                  );
                },
              ),

              const Divider(),
              
              ListTile(
                leading: Icon(Icons.logout),
                title: const Text("LogOut"),
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
