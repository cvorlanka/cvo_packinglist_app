import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packinglist_app/components/colors/colors.dart';
import 'package:packinglist_app/components/msauth_controller/msal_controller.dart';
import 'package:packinglist_app/components/widgets/textfields/textfield.dart';
import 'package:http/http.dart' as http;
import 'package:packinglist_app/components/widgets/buttons/customBtn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final orderNumber = TextEditingController();
  String? user;
  List<String> orderList = [];
  List orderWidgetList = [];
  bool isLoading = false;
  bool addressCheck = true;

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  // Check for number
  bool isNumeric(String str) {
    if (str.isEmpty) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  // check if address from new order matches address from first order
  Future<void> checkAddress() async {
    if (orderList.isNotEmpty) {
      final url1 = Uri.parse(
          'https://cycling-api.cvoapis.com/dc/order/${orderNumber.text}');
      final url2 =
          Uri.parse('https://cycling-api.cvoapis.com/dc/order/${orderList[0]}');
      try {
        final response1 = await http.get(url1);
        final response2 = await http.get(url2);

        if (response1.statusCode == 200 && response2.statusCode == 200) {
          final json1 = jsonDecode(response1.body);
          final json2 = jsonDecode(response2.body);

          if (json1 is List &&
              json2 is List &&
              json1.isNotEmpty &&
              json2.isNotEmpty) {
            // textfield order address
            var oNaddress1 = json1[0]['address1'] ?? ''.trim().toLowerCase();
            var oNaddress2 = json1[0]['address2'] ?? ''.trim().toLowerCase();
            var oNcity = json1[0]['city'] ?? ''.trim().toLowerCase();
            var oNstate = json1[0]['state'] ?? ''.trim().toLowerCase();

            // orderList first order textfield address
            var oLaddress1 = json2[0]['address1'] ?? ''.trim().toLowerCase();
            var oLaddress2 = json2[0]['address2'] ?? ''.trim().toLowerCase();
            var oLcity = json2[0]['city'] ?? ''.trim().toLowerCase();
            var oLstate = json2[0]['state'] ?? ''.trim().toLowerCase();

            // if addresses match set addressCheck to true otherwise set to false
            addressCheck = (oNaddress1 == oLaddress1 &&
                oNaddress2 == oLaddress2 &&
                oNcity == oLcity &&
                oNstate == oLstate);
          } else {
            showAlertDialog('Order not found or invalid response format');
          }
        } else {
          showAlertDialog(
              'Failed to fetch order. Error code: ${response1.statusCode} and ${response2.statusCode}');
        }
      } catch (e) {
        showAlertDialog('Error fetching data: $e');
      }
    }
  }

  // add next order
  Future<void> nextOrder() async {
    if (orderNumber.text.isNotEmpty)
        //&&
        //isNumeric(orderNumber.text) &&
        //(int.parse(orderNumber.text) < 9999999)
      {
      // check for duplicate
      if (orderList.contains(orderNumber.text)) {
        showAlertDialog('Order is already scanned');
      } else {
        // await address check
        await checkAddress();
        // validate based on check
        addressCheck == true
            ? setState(() {
                orderList.add(orderNumber.text);
                orderWidgetList.add(OrderWidget(orderNumber: orderNumber.text));
                orderNumber.clear();
              })
            : showAlertDialog('This order has a different shipping address');
      }
      print('On Insertion - OrderList: $orderList');
    } else {
      showAlertDialog('Please enter a valid order number');
    }
    // _saveState();
  }

  // delete order on click
  void deleteOrder(int i) {
    if (orderWidgetList.isNotEmpty) {
      setState(() {
        orderWidgetList.removeAt(i);
        orderList.removeAt(i);
      });
      print('On Deletion - OrderList: $orderList');
    } else {
      showAlertDialog('The orders list is empty');
    }
  }

  // set sharedPrefs
  Future<void> setPrefs(
    String po, String customerCode ,String name, String address, List<String> orders) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', user!);
    prefs.setString('po', po);
    prefs.setString('cust_code', customerCode);
    prefs.setString('name', name);
    prefs.setString('address', address);
    prefs.setStringList('orders', orders);
  }

  Future<void> getUserName() async {
    String? token = await MSALController.getToken();
    if (token != null) {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        // print('User Info: ${response.body}');
        List<dynamic> userDetails = [jsonDecode(response.body)];
        user = '${userDetails[0]['givenName']} ${userDetails[0]['surname']}';
        print('USER: $user');
      } else {
        throw Exception(
            'Failed to load user info. Status Code: ${response.statusCode}, Body: ${response.body}');
      }
    } else {
      print('Failed to authenticate token');
    }
    setState(() {});
  }

  // get sharedPrefs
  // void getPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     user = prefs.getString('user')!;
  //   });
  //   print('user: $user');
  // }

  // delete sharedPrefs
  Future<void> delPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // clear data and sign out
  Future<void> signOut() async {
    orderList.clear();
    orderWidgetList.clear();
    // delPrefs();
    await MSALController.logOut();
    // Navigator.pushReplacementNamed(context, '/');
    setState(() {});
  }

  Future<void> fetchOrder() async {
    if (orderList.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      final url =
          Uri.parse('https://cycling-api.cvoapis.com/dc/order/${orderList[0]}');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json.isNotEmpty) {
            String customerPO = json[0]['cust_po'];
            String customerCode = json[0]['cust_code'];
            String customerName = json[0]['name'];
            String customerAddress =
                json[0]['address1'] + ' ' + json[0]['address2'];

            setPrefs(customerPO, customerCode ,customerName, customerAddress, orderList);
            // ignore: use_build_context_synchronously
            Navigator.pushNamed(context, '/packing');
          } else {
            showAlertDialog('Order not found.');
          }
        } else {
          showAlertDialog(
              'Failed to fetch order. Error Code: ${response.statusCode}\n${response.body}');
        }
      } catch (e) {
        showAlertDialog('Error fetching data: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      showAlertDialog('Please enter a valid order number.');
    }
  }

  // Alert function
  showAlertDialog(String msg) {
    AlertDialog alert = AlertDialog(
      title: const Text(
        'Error',
        style: TextStyle(
          color: Colors.black,
          fontSize: 25,
        ),
      ),
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (context) => alert,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primary,
      body: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColor.secondary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'CLEARVISION OPTICAL',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$user',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 25),
                      CustomButton(
                        onPressed: () {
                          signOut();
                          setState(() {});
                        },
                        color: Colors.transparent,
                        height: 50,
                        minWidth: 50,
                        child: Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 4,
                ),
                child: Row(
                  children: [
                    // textfield
                    SizedBox(
                      width: 200,
                      child: MyTextField(
                        controller: orderNumber,
                        labelText: 'Order',
                        obscureText: false,
                        allowChars: '[0-9-]'
                      ),
                    ),
                    // add order
                    CustomButton(
                      onPressed: nextOrder,
                      color: Colors.amber,
                      height: 50,
                      minWidth: 50,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 25),
                    // enter button
                    CustomButton(
                      onPressed: fetchOrder,
                      color: Colors.green,
                      height: 50,
                      minWidth: 60,
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 4 + 20),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: orderWidgetList.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    orderWidgetList[index],
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => deleteOrder(index),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (isLoading) ...[
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderWidget extends StatelessWidget {
  final orderNumber;

  const OrderWidget({
    super.key,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$orderNumber',
      style: const TextStyle(color: Colors.black, fontSize: 25),
    );
  }
}
