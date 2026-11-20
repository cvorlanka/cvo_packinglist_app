// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print, must_be_immutable, library_private_types_in_public_api

import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:packinglist_app/components/widgets/box/box_info.dart';
import 'package:packinglist_app/components/widgets/box/box_list.dart';
import 'package:packinglist_app/components/widgets/box/box_widget.dart';
import 'package:packinglist_app/components/colors/colors.dart';
import 'package:packinglist_app/components/widgets/box/edit_box.dart';
import 'package:packinglist_app/components/widgets/textfields/custom_textfield.dart';
import 'package:packinglist_app/components/widgets/headers/customer_info.dart';
import 'package:packinglist_app/components/dynamic_widget.dart';
import 'package:packinglist_app/components/widgets/headers/header.dart';
import 'package:packinglist_app/components/item_list.dart';
import 'package:packinglist_app/components/msauth_controller/msal_controller.dart';
import 'package:packinglist_app/components/order_list_panel.dart';
import 'package:packinglist_app/components/widgets/pallet/pallet_list.dart';
import 'package:packinglist_app/components/widgets/pallet/pallet_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:flutter/foundation.dart' show kIsWeb;

const List<String> boxSizeList = <String>['44', '50', '54', 'Custom'];

class PackingPage extends StatefulWidget {
  const PackingPage({
    super.key,
  });

  @override
  State<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends State<PackingPage> {
  List<String> orderNumbers = [];
  String? user = '';
  String po = '';
  String custCode = '';
  String name = '';
  String address = '';

  // lists
  List<dynamic> orderList = [];
  List<dynamic> itemsList = [];
  List<dynamic> tempList = [];
  List<dynamic> orderQtyList = [];
  List<dynamic> rowResultList = [];
  List<dynamic> rowWidgetList = [];
  List<dynamic> boxWidgetList = [];
  List<dynamic> boxResultList = [];
  List<dynamic> palletResultList = [];
  List<dynamic> palletWidgetList = [];
  List<dynamic> textValue = [];
  List<bool> isChecked = [];

  // variables
  String dropdownValue = boxSizeList.first;
  int rowIndex = 0;
  int rowWidgetIndex = 0;
  int loopIndex = 0;
  int boxNum = 1;
  int palletNum = 1;
  int totalPalletWeight = 0;
  int textfieldValue = 0;
  int storedQty = 0;
  double availWidth = 0;
  double availHeight = 0;
  bool duplicate = false;

  // texfield controllers
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final palletLength = TextEditingController();
  final palletWidth = TextEditingController();
  final palletHeight = TextEditingController();
  final palletWeight = TextEditingController();

  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  // get prefs
  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString('user')!;
    po = prefs.getString('po')!;
    custCode = prefs.getString('cust_code')!;
    name = prefs.getString('name')!;
    //name = name.replaceAll('#', '');
    address = prefs.getString('address')!;
    orderNumbers = prefs.getStringList('orders') ?? [];
    getOrderLineData();
    setState(() {});
  }

  // delete prefs
  Future<void> delPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // coerce API numeric values (int, double or numeric string) to int
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return num.tryParse(v.trim())?.round() ?? 0;
    return 0;
  }

  // get data from api
  Future<void> getOrderLineData() async {
    for (var i = 0; i < orderNumbers.length; i++) {
      final url = Uri.parse(
        'https://cycling-api.cvoapis.com/dc/order_lines/${orderNumbers[i]}',
      );
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          // Normalise numeric fields: since the API moved to PHP 8.3,
          // quantities may arrive as strings ("5") or doubles (5.0)
          // instead of ints, which breaks the int arithmetic below.
          var temp = List.from(json.decode(response.body)).map((line) {
            final map = Map<String, dynamic>.from(line as Map);
            map['pack_qty'] = _toInt(map['pack_qty']);
            return map;
          }).toList();
          orderList.add(temp);
          itemsList.add(temp);
          setState(() {});
        } else {
          throw Exception('Failed to load data');
        }
        //print(orderList);
      } catch (e) {
        print('Error fetching data $e');
      }
    }
  }

  // read image data
  Future<List<int>> readImageData(String name) async {
    final ByteData data = await rootBundle.load('assets/images/$name');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  // create Visionworks & Sam's Club box excel file
  Future<void> customExcelOutput() async {
    String cvoAddress = '425 RABRO DRIVE, SUITE 2 HAUPPAUGE, NY 11788';
    String cvoTelephone = '1-631-787-1500';
    String cvoFax = '1-631-787-1560';
    String customerName = name;
    String customerPO = po;
    String customerAddress = address;
    int row = 10;
    int itemAndQtyRow = 11;
    int totalRows = 15;

    for (var i = 0; i < boxResultList.length; i++) {
      totalRows += boxResultList.length;
      for (var j = 0; j < (boxResultList[i]['LINES']).length; j++) {
        totalRows += (boxResultList[i]['LINES'].length) as int;
      }
    }

    // print('totalRows: $totalRows');

    // create workbook
    final excel.Workbook workbook = excel.Workbook();
    // access it via index
    final excel.Worksheet sheet = workbook.worksheets[0];
    // enable sheet calculations
    sheet.enableSheetCalculations();

    // cell ranges
    // columns
    excel.Range columnA = sheet.getRangeByName('A1:A$totalRows');
    excel.Range columnB = sheet.getRangeByName('B1:B$totalRows');
    excel.Range columnC = sheet.getRangeByName('C1:C$totalRows');
    excel.Range columnD = sheet.getRangeByName('D1:D$totalRows');
    // full workbook
    excel.Range fullWorkbook = sheet.getRangeByName('A1:D30');
    // logo range
    excel.Range logoCellRange = sheet.getRangeByName('A1:D1');
    // cvo address range
    excel.Range cvoAddressRange = sheet.getRangeByName('A2:D2');
    // packing list logo range
    excel.Range packingListLogo = sheet.getRangeByName('A3:D3');
    // customer name and po range
    excel.Range custNameAndPO = sheet.getRangeByName('A4:D5');
    // customer address range
    excel.Range custAddress = sheet.getRangeByName('A6:D6');
    // lines range
    excel.Range boxDetails = sheet.getRangeByName('A7:A8');
    excel.Range productDescription = sheet.getRangeByName('B7:B8');
    excel.Range customerPartNumber = sheet.getRangeByName('C7:C8');
    excel.Range qty = sheet.getRangeByName('D7:D8');

    // cell styles
    excel.Style logoCellStyle = workbook.styles.add('logoCellStyle');
    logoCellStyle.fontSize = 50;
    logoCellStyle.bold = true;
    logoCellStyle.hAlign = excel.HAlignType.center;
    logoCellStyle.vAlign = excel.VAlignType.center;
    logoCellStyle.borders.all.color = '#000000';
    logoCellStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style fullWorkbookStyle = workbook.styles.add('fullWorkbookStyle');
    fullWorkbookStyle.borders.all.lineStyle = excel.LineStyle.thin;
    fullWorkbookStyle.borders.all.color = '#000000';

    excel.Style cvoAddressStyle = workbook.styles.add('addressStyles');
    cvoAddressStyle.fontSize = 10;
    cvoAddressStyle.hAlign = excel.HAlignType.center;
    cvoAddressStyle.vAlign = excel.VAlignType.center;
    cvoAddressStyle.borders.all.color = '#000000';
    cvoAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style packingListLogoStyle =
        workbook.styles.add('packingListLogoStyle');
    packingListLogoStyle.fontSize = 14;
    packingListLogoStyle.bold = true;
    packingListLogoStyle.underline = true;
    packingListLogoStyle.hAlign = excel.HAlignType.center;
    packingListLogoStyle.vAlign = excel.VAlignType.center;
    packingListLogoStyle.borders.all.color = '#000000';
    packingListLogoStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custNameAndPOStyle = workbook.styles.add('custNameAndPOStyle');
    custNameAndPOStyle.fontSize = 14;
    custNameAndPOStyle.bold = true;
    custNameAndPOStyle.hAlign = excel.HAlignType.center;
    custNameAndPOStyle.vAlign = excel.VAlignType.center;
    custNameAndPOStyle.borders.all.color = '#000000';
    custNameAndPOStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custAddressStyle = workbook.styles.add('custAddressStyle');
    custAddressStyle.fontSize = 10;
    custAddressStyle.bold = true;
    custAddressStyle.hAlign = excel.HAlignType.center;
    custAddressStyle.vAlign = excel.VAlignType.center;
    custAddressStyle.borders.all.color = '#000000';
    custAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style boxDescQtyStyle = workbook.styles.add('boxDescQtyStyle');
    boxDescQtyStyle.fontSize = 11;
    boxDescQtyStyle.bold = true;
    boxDescQtyStyle.hAlign = excel.HAlignType.center;
    boxDescQtyStyle.vAlign = excel.VAlignType.center;
    boxDescQtyStyle.borders.all.color = '#000000';
    boxDescQtyStyle.borders.all.lineStyle = excel.LineStyle.thin;

    // set data in the worksheet
    fullWorkbook.cellStyle = fullWorkbookStyle;
    fullWorkbook.columnWidth = 30;

    // set data in the worksheet
    columnA.cellStyle = fullWorkbookStyle;
    columnA.columnWidth = 20;

    columnB.cellStyle = fullWorkbookStyle;
    columnB.columnWidth = 45;

    columnC.cellStyle = fullWorkbookStyle;
    columnC.columnWidth = 10;

    columnD.cellStyle = fullWorkbookStyle;
    columnD.columnWidth = 9;

    logoCellRange.merge();
    // logoCellRange.setValue('CLEARVISION');
    logoCellRange.cellStyle = logoCellStyle;

    cvoAddressRange.merge();
    cvoAddressRange.setValue('$cvoAddress   tel: $cvoTelephone   fax: $cvoFax');
    cvoAddressRange.cellStyle = cvoAddressStyle;

    packingListLogo.merge();
    packingListLogo.setValue('PACKING LIST');
    packingListLogo.cellStyle = packingListLogoStyle;

    custNameAndPO.merge();
    custNameAndPO.setValue('$customerName - PO $customerPO');
    custNameAndPO.cellStyle = custNameAndPOStyle;

    custAddress.merge();
    custAddress.setValue(customerAddress);
    custAddress.cellStyle = custAddressStyle;

    boxDetails.merge();
    boxDetails.setValue('BOX\n(DIMS & WGT)');
    boxDetails.cellStyle = boxDescQtyStyle;

    productDescription.merge();
    productDescription.setValue('PRODUCT DESCRIPTION');
    productDescription.cellStyle = boxDescQtyStyle;

    customerPartNumber.merge();
    customerPartNumber.setValue('');
    customerPartNumber.cellStyle = boxDescQtyStyle;

    qty.merge();
    qty.setValue('QTY');
    qty.cellStyle = boxDescQtyStyle;

    // add a picture to the files
    if (kIsWeb) {
      // for web
      // final ByteData imageData =
      //     await rootBundle.load('assets/images/cvoPackingListLogo.png');
      // final List<int> imgBytes = imageData.buffer.asUint8List();
      final String image =
          base64.encode(await readImageData('cvoPackingListLogo.png'));
      final excel.Picture picture = sheet.pictures.addBase64(1, 2, image);
      picture.height = 20;
      picture.width = 350;
    } else {
      // for desktop
      final List<int> imgBytes =
          File('assets/images/cvoPackingListLogo.png').readAsBytesSync();
      final excel.Picture picture = sheet.pictures.addStream(1, 2, imgBytes);
      picture.height = 20;
      picture.width = 350;
    }

    // loop through each box
    for (var i = 0; i < boxResultList.length; i++) {
      // box dimensions
      int len = boxResultList[i]['DIMS']['LENGTH'];
      int wid = boxResultList[i]['DIMS']['WIDTH'];
      int hgt = boxResultList[i]['DIMS']['HEIGHT'];
      int wgt = boxResultList[i]['DIMS']['WEIGHT'];
      int bxNum = boxResultList[i]['BOX'];

      // box dim ranges
      excel.Range boxNumber = sheet.getRangeByName('A$row');
      excel.Range dimensions = sheet.getRangeByName('A${row + 1}');
      excel.Range weight = sheet.getRangeByName('A${row + 2}');

      // box dims values and styles
      boxNumber.setValue('Box $bxNum');
      boxNumber.cellStyle = boxDescQtyStyle;

      dimensions.setValue('${len}L x ${wid}W x ${hgt}H');
      dimensions.cellStyle = boxDescQtyStyle;

      weight.setValue('$wgt lbs');
      weight.cellStyle = boxDescQtyStyle;

      // products description and qty
      var currentElement = boxResultList[i]['LINES'];

      // loop through the line items of [i] box
      for (var j = 0; j < currentElement.length; j++) {
        // item ranges
        excel.Range item = sheet.getRangeByName('B$itemAndQtyRow');
        excel.Range custPart = sheet.getRangeByName('C$itemAndQtyRow');
        excel.Range itemQty = sheet.getRangeByName('D$itemAndQtyRow');

        // item values and style
        item.setValue('${currentElement[j]['description']}');
        item.cellStyle = cvoAddressStyle;

        if (currentElement[j]['cust_part'] != null) {
          custPart.setValue('${currentElement[j]['cust_part']}');
        } else {
          custPart.setValue('');
        }
        custPart.cellStyle = cvoAddressStyle;

        itemQty.setValue('${currentElement[j]['user_input']}');
        itemQty.cellStyle = cvoAddressStyle;

        // increase itemAndQtyRow count
        itemAndQtyRow++;
      }
      // increase row count and reset the itemAndQtyRow count
      row = itemAndQtyRow + 2;
      itemAndQtyRow = row + 1;
    }

    // save workbook to stream and dispose
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // check if program runs on web, if so download output file from browser
    if (kIsWeb) {
      name = name.replaceAll('#', ' ');
      AnchorElement(
          href:
              'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$name - $po.xlsx')
        ..click();
    } else {
      // otherwise save file to local storage and open it
      final String path = (await getApplicationSupportDirectory()).path;
      String fileName = Platform.isWindows
          ? '$path\\$name -$po.xlsx'
          : '$path/$name - $po.xlsx';
      fileName = fileName.replaceAll('#', ' ');
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(fileName);
    }
  }

  // create box format excel file
  Future<void> boxExcelOutput() async {
    String cvoAddress = '425 RABRO DRIVE, SUITE 2 HAUPPAUGE, NY 11788';
    String cvoTelephone = '1-631-787-1500';
    String cvoFax = '1-631-787-1560';
    String customerName = name;
    String customerPO = po;
    String customerAddress = address;
    int row = 10;
    int itemAndQtyRow = 11;
    int totalRows = 15;

    for (var i = 0; i < boxResultList.length; i++) {
      totalRows += boxResultList.length;
      for (var j = 0; j < (boxResultList[i]['LINES']).length; j++) {
        totalRows += (boxResultList[i]['LINES'].length) as int;
      }
    }

    // print('totalRows: $totalRows');

    // create workbook
    final excel.Workbook workbook = excel.Workbook();
    // access it via index
    final excel.Worksheet sheet = workbook.worksheets[0];
    // enable sheet calculations
    sheet.enableSheetCalculations();

    // cell ranges
    excel.Range columnA = sheet.getRangeByName('A1:A$totalRows');
    excel.Range columnB = sheet.getRangeByName('B1:B$totalRows');
    excel.Range columnC = sheet.getRangeByName('C1:C$totalRows');
    excel.Range fullWorkbook = sheet.getRangeByName('A1:C30');
    excel.Range logoCellRange = sheet.getRangeByName('A1:C1');
    excel.Range cvoAddressRange = sheet.getRangeByName('A2:C2');
    excel.Range packingListLogo = sheet.getRangeByName('A3:C3');
    excel.Range custNameAndPO = sheet.getRangeByName('A4:C5');
    excel.Range custAddress = sheet.getRangeByName('A6:C6');
    excel.Range boxDetails = sheet.getRangeByName('A7:A8');
    excel.Range productDescription = sheet.getRangeByName('B7:B8');
    excel.Range qty = sheet.getRangeByName('C7:C8');

    // cell styles
    excel.Style logoCellStyle = workbook.styles.add('logoCellStyle');
    logoCellStyle.fontSize = 50;
    logoCellStyle.bold = true;
    logoCellStyle.hAlign = excel.HAlignType.center;
    logoCellStyle.vAlign = excel.VAlignType.center;
    logoCellStyle.borders.all.color = '#000000';
    logoCellStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style fullWorkbookStyle = workbook.styles.add('fullWorkbookStyle');
    fullWorkbookStyle.borders.all.lineStyle = excel.LineStyle.thin;
    fullWorkbookStyle.borders.all.color = '#000000';

    excel.Style cvoAddressStyle = workbook.styles.add('addressStyles');
    cvoAddressStyle.fontSize = 10;
    cvoAddressStyle.hAlign = excel.HAlignType.center;
    cvoAddressStyle.vAlign = excel.VAlignType.center;
    cvoAddressStyle.borders.all.color = '#000000';
    cvoAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style packingListLogoStyle =
        workbook.styles.add('packingListLogoStyle');
    packingListLogoStyle.fontSize = 14;
    packingListLogoStyle.bold = true;
    packingListLogoStyle.underline = true;
    packingListLogoStyle.hAlign = excel.HAlignType.center;
    packingListLogoStyle.vAlign = excel.VAlignType.center;
    packingListLogoStyle.borders.all.color = '#000000';
    packingListLogoStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custNameAndPOStyle = workbook.styles.add('custNameAndPOStyle');
    custNameAndPOStyle.fontSize = 14;
    custNameAndPOStyle.bold = true;
    custNameAndPOStyle.hAlign = excel.HAlignType.center;
    custNameAndPOStyle.vAlign = excel.VAlignType.center;
    custNameAndPOStyle.borders.all.color = '#000000';
    custNameAndPOStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custAddressStyle = workbook.styles.add('custAddressStyle');
    custAddressStyle.fontSize = 10;
    custAddressStyle.bold = true;
    custAddressStyle.hAlign = excel.HAlignType.center;
    custAddressStyle.vAlign = excel.VAlignType.center;
    custAddressStyle.borders.all.color = '#000000';
    custAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style boxDescQtyStyle = workbook.styles.add('boxDescQtyStyle');
    boxDescQtyStyle.fontSize = 11;
    boxDescQtyStyle.bold = true;
    boxDescQtyStyle.hAlign = excel.HAlignType.center;
    boxDescQtyStyle.vAlign = excel.VAlignType.center;
    boxDescQtyStyle.borders.all.color = '#000000';
    boxDescQtyStyle.borders.all.lineStyle = excel.LineStyle.thin;

    // set data in the worksheet
    fullWorkbook.cellStyle = fullWorkbookStyle;
    fullWorkbook.columnWidth = 30;

    // set data in the worksheet
    columnA.cellStyle = fullWorkbookStyle;
    columnA.columnWidth = 20;

    columnB.cellStyle = fullWorkbookStyle;
    columnB.columnWidth = 48;

    columnC.cellStyle = fullWorkbookStyle;
    columnC.columnWidth = 18;

    logoCellRange.merge();
    // logoCellRange.setValue('CLEARVISION');
    logoCellRange.cellStyle = logoCellStyle;

    cvoAddressRange.merge();
    cvoAddressRange.setValue('$cvoAddress   tel: $cvoTelephone   fax: $cvoFax');
    cvoAddressRange.cellStyle = cvoAddressStyle;

    packingListLogo.merge();
    packingListLogo.setValue('PACKING LIST');
    packingListLogo.cellStyle = packingListLogoStyle;

    custNameAndPO.merge();
    custNameAndPO.setValue('$customerName - PO $customerPO');
    custNameAndPO.cellStyle = custNameAndPOStyle;

    custAddress.merge();
    custAddress.setValue(customerAddress);
    custAddress.cellStyle = custAddressStyle;

    boxDetails.merge();
    boxDetails.setValue('BOX\n(DIMS & WGT)');
    boxDetails.cellStyle = boxDescQtyStyle;

    productDescription.merge();
    productDescription.setValue('PRODUCT DESCRIPTION');
    productDescription.cellStyle = boxDescQtyStyle;

    qty.merge();
    qty.setValue('QTY');
    qty.cellStyle = boxDescQtyStyle;

    // add a picture to the files
    if (kIsWeb) {
      // for web
      // final ByteData imageData =
      //     await rootBundle.load('assets/images/cvoPackingListLogo.png');
      // final List<int> imgBytes = imageData.buffer.asUint8List();
      final String image =
          base64.encode(await readImageData('cvoPackingListLogo.png'));
      final excel.Picture picture = sheet.pictures.addBase64(1, 2, image);
      picture.height = 20;
      picture.width = 350;
    } else {
      // for desktop
      final List<int> imgBytes =
          File('assets/images/cvoPackingListLogo.png').readAsBytesSync();
      final excel.Picture picture = sheet.pictures.addStream(1, 2, imgBytes);
      picture.height = 20;
      picture.width = 350;
    }

    // loop through each box
    for (var i = 0; i < boxResultList.length; i++) {
      // box dimensions
      int len = boxResultList[i]['DIMS']['LENGTH'];
      int wid = boxResultList[i]['DIMS']['WIDTH'];
      int hgt = boxResultList[i]['DIMS']['HEIGHT'];
      int wgt = boxResultList[i]['DIMS']['WEIGHT'];
      int bxNum = boxResultList[i]['BOX'];

      // box dim ranges
      excel.Range boxNumber = sheet.getRangeByName('A$row');
      excel.Range dimensions = sheet.getRangeByName('A${row + 1}');
      excel.Range weight = sheet.getRangeByName('A${row + 2}');

      // box dims values and styles
      boxNumber.setValue('Box $bxNum');
      boxNumber.cellStyle = boxDescQtyStyle;

      dimensions.setValue('${len}L x ${wid}W x ${hgt}H');
      dimensions.cellStyle = boxDescQtyStyle;

      weight.setValue('$wgt lbs');
      weight.cellStyle = boxDescQtyStyle;

      // products description and qty
      var currentElement = boxResultList[i]['LINES'];

      // loop through the line items of [i] box
      for (var j = 0; j < currentElement.length; j++) {
        // item ranges
        excel.Range item = sheet.getRangeByName('B$itemAndQtyRow');
        excel.Range itemQty = sheet.getRangeByName('C$itemAndQtyRow');

        //print('boxResultList.length: ${boxResultList.length}\ncurrentElement.length: ${currentElement.length}');

        // item values and style
        item.setValue('${currentElement[j]['description']}');
        item.cellStyle = cvoAddressStyle;

        itemQty.setValue('${currentElement[j]['user_input']}');
        itemQty.cellStyle = cvoAddressStyle;

        // increase itemAndQtyRow count
        itemAndQtyRow++;
      }
      // increase row count and reset the itemAndQtyRow count
      row = itemAndQtyRow + 2;
      itemAndQtyRow = row + 1;
    }

    // save workbook to stream and dispose
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // check if program runs on web, if so download output file from browser
    if (kIsWeb) {
      name = name.replaceAll('#', ' ');
      AnchorElement(
          href:
              'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$name - $po.xlsx')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      String fileName = Platform.isWindows
          ? '$path\\$name -$po.xlsx'
          : '$path/$name - $po.xlsx';
      fileName = fileName.replaceAll('#', ' ');
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(fileName);
    }
  }

  // create Visionworks & Sam's Club pallet excel file
  Future<void> customExcelPalletOutput() async {
    String cvoAddress = '425 RABRO DRIVE, SUITE 2 HAUPPAUGE, NY 11788';
    String cvoTelephone = '1-631-787-1500';
    String cvoFax = '1-631-787-1560';
    String customerName = name;
    String customerPO = po;
    String customerAddress = address;
    int palletRow = 10;
    int boxRow = 14;
    int itemAndQtyRow = 15;
    int totalRows = 20;

    // // get number of lines
    // for (var i = 0; i < palletResultList.length; i++) {
    //   totalRows += palletResultList.length;
    //   for (var j = 0; j < (palletResultList[i]['LINES']).length; j++) {
    //     totalRows += (palletResultList[i]['LINES'].length) as int;
    //     for (var k = 0;
    //         k < palletResultList[i]['LINES'][j]['LINES'].length;
    //         k++) {
    //       totalRows += (palletResultList[i]['LINES'][j]['LINES'].length) as int;
    //     }
    //   }
    // }

    // Calculate total rows dynamically based on nested data
    for (var i = 0; i < palletResultList.length; i++) {
      // Add rows for pallet level
      totalRows += palletResultList[i]['LINES'].length as int;

      // For each line inside pallet
      for (var j = 0; j < palletResultList[i]['LINES'].length; j++) {
        // Add rows for each sub-line in a line
        totalRows += palletResultList[i]['LINES'][j]['LINES'].length as int;
      }
    }

    // print('totalRows: $totalRows');

    // create workbook
    final excel.Workbook workbook = excel.Workbook();
    // access it via index
    final excel.Worksheet sheet = workbook.worksheets[0];
    // enable sheet calculations
    sheet.enableSheetCalculations();

    // cell ranges
    // columns
    excel.Range columnA = sheet.getRangeByName('A1:A$totalRows');
    excel.Range columnB = sheet.getRangeByName('B1:B$totalRows');
    excel.Range columnC = sheet.getRangeByName('C1:C$totalRows');
    excel.Range columnD = sheet.getRangeByName('D1:D$totalRows');

    // logo range
    excel.Range logoCellRange = sheet.getRangeByName('A1:D1');

    // cvo address range
    excel.Range cvoAddressRange = sheet.getRangeByName('A2:D2');

    // packing list logo range
    excel.Range packingListLogo = sheet.getRangeByName('A3:D3');

    // customer name and po range
    excel.Range custNameAndPO = sheet.getRangeByName('A4:D5');

    // customer address range
    excel.Range custAddress = sheet.getRangeByName('A6:D6');

    // box details range
    excel.Range boxDetails = sheet.getRangeByName('A7:A8');
    excel.Range productDescription = sheet.getRangeByName('B7:B8');
    excel.Range customerPartNumber = sheet.getRangeByName('C7:C8');
    excel.Range qty = sheet.getRangeByName('D7:D8');

    // cell styles
    excel.Style logoCellStyle = workbook.styles.add('logoCellStyle');
    logoCellStyle.fontSize = 40;
    logoCellStyle.bold = true;
    logoCellStyle.hAlign = excel.HAlignType.center;
    logoCellStyle.vAlign = excel.VAlignType.center;
    logoCellStyle.borders.all.color = '#000000';
    logoCellStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style fullWorkbookStyle = workbook.styles.add('fullWorkbookStyle');
    fullWorkbookStyle.borders.all.lineStyle = excel.LineStyle.thin;
    fullWorkbookStyle.borders.all.color = '#000000';

    excel.Style cvoAddressStyle = workbook.styles.add('addressStyles');
    cvoAddressStyle.fontSize = 10;
    cvoAddressStyle.hAlign = excel.HAlignType.center;
    cvoAddressStyle.vAlign = excel.VAlignType.center;
    cvoAddressStyle.borders.all.color = '#000000';
    cvoAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style packingListLogoStyle =
        workbook.styles.add('packingListLogoStyle');
    packingListLogoStyle.fontSize = 14;
    packingListLogoStyle.bold = true;
    packingListLogoStyle.underline = true;
    packingListLogoStyle.hAlign = excel.HAlignType.center;
    packingListLogoStyle.vAlign = excel.VAlignType.center;
    packingListLogoStyle.borders.all.color = '#000000';
    packingListLogoStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custNameAndPOStyle = workbook.styles.add('custNameAndPOStyle');
    custNameAndPOStyle.fontSize = 14;
    custNameAndPOStyle.bold = true;
    custNameAndPOStyle.hAlign = excel.HAlignType.center;
    custNameAndPOStyle.vAlign = excel.VAlignType.center;
    custNameAndPOStyle.borders.all.color = '#000000';
    custNameAndPOStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custAddressStyle = workbook.styles.add('custAddressStyle');
    custAddressStyle.fontSize = 10;
    custAddressStyle.bold = true;
    custAddressStyle.hAlign = excel.HAlignType.center;
    custAddressStyle.vAlign = excel.VAlignType.center;
    custAddressStyle.borders.all.color = '#000000';
    custAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style boxDescQtyStyle = workbook.styles.add('boxDescQtyStyle');
    boxDescQtyStyle.fontSize = 11;
    boxDescQtyStyle.bold = true;
    boxDescQtyStyle.hAlign = excel.HAlignType.center;
    boxDescQtyStyle.vAlign = excel.VAlignType.center;
    boxDescQtyStyle.borders.all.color = '#000000';
    boxDescQtyStyle.borders.all.lineStyle = excel.LineStyle.thin;

    // set data in the worksheet
    columnA.cellStyle = fullWorkbookStyle;
    columnA.columnWidth = 20;

    columnB.cellStyle = fullWorkbookStyle;
    columnB.columnWidth = 45;

    columnC.cellStyle = fullWorkbookStyle;
    columnC.columnWidth = 10;

    columnD.cellStyle = fullWorkbookStyle;
    columnD.columnWidth = 9;

    logoCellRange.merge();
    logoCellRange.cellStyle = logoCellStyle;

    cvoAddressRange.merge();
    cvoAddressRange.setValue('$cvoAddress   tel: $cvoTelephone   fax: $cvoFax');
    cvoAddressRange.cellStyle = cvoAddressStyle;

    packingListLogo.merge();
    packingListLogo.setValue('PACKING LIST');
    packingListLogo.cellStyle = packingListLogoStyle;

    custNameAndPO.merge();
    custNameAndPO.setValue('$customerName - PO $customerPO');
    custNameAndPO.cellStyle = custNameAndPOStyle;

    custAddress.merge();
    custAddress.setValue(customerAddress);
    custAddress.cellStyle = custAddressStyle;

    boxDetails.merge();
    boxDetails.setValue('BOX\n(DIMS & WGT)');
    boxDetails.cellStyle = boxDescQtyStyle;

    productDescription.merge();
    productDescription.setValue('PRODUCT DESCRIPTION');
    productDescription.cellStyle = boxDescQtyStyle;

    customerPartNumber.merge();
    customerPartNumber.setValue('');
    customerPartNumber.cellStyle = boxDescQtyStyle;

    qty.merge();
    qty.setValue('QTY');
    qty.cellStyle = boxDescQtyStyle;

    // add a picture to the files
    if (kIsWeb) {
      // for web
      final String image =
          base64.encode(await readImageData('cvoPackingListLogo.png'));
      final excel.Picture picture = sheet.pictures.addBase64(1, 2, image);
      picture.height = 20;
      picture.width = 350;
    } else {
      // for desktop
      final List<int> imgBytes =
          File('assets/images/cvoPackingListLogo.png').readAsBytesSync();
      final excel.Picture picture = sheet.pictures.addStream(1, 2, imgBytes);
      picture.height = 20;
      picture.width = 350;
    }

    // for every pallet in pallet list
    for (var i = 0; i < palletResultList.length; i++) {
      // pallet dimensions & weight
      int palletL = palletResultList[i]['DIMS']['LENGTH'];
      int palletW = palletResultList[i]['DIMS']['WIDTH'];
      int palletH = palletResultList[i]['DIMS']['HEIGHT'];
      int palletWgt = palletResultList[i]['DIMS']['WEIGHT'];
      int palletNum = palletResultList[i]['PALLET'];

      // list of boxes in current pallet
      var currentPallet = palletResultList[i]['LINES'];

      // print('PALLET $palletNum \n$palletL x $palletW x $palletH\n${palletWgt}LBS');
      // print('currentPalletItems: $currentPallet');

      // pallet dim ranges
      excel.Range palletNumber = sheet.getRangeByName('B$palletRow');
      excel.Range dimensions = sheet.getRangeByName('B${palletRow + 1}');
      excel.Range weight = sheet.getRangeByName('B${palletRow + 2}');

      // pallet dims values and styles
      palletNumber.setValue('PALLET $palletNum');
      palletNumber.cellStyle = custAddressStyle;

      dimensions.setValue('$palletL x $palletW x $palletH');
      dimensions.cellStyle = custAddressStyle;

      weight.setValue('$palletWgt LBS');
      weight.cellStyle = custAddressStyle;

      // for every box in the current pallet
      for (var j = 0; j < currentPallet.length; j++) {
        // box dimensions & weight
        int boxL = currentPallet[j]['DIMS']['LENGTH'];
        int boxW = currentPallet[j]['DIMS']['WIDTH'];
        int boxH = currentPallet[j]['DIMS']['HEIGHT'];
        int boxWgt = currentPallet[j]['DIMS']['WEIGHT'];
        int boxNumber = currentPallet[j]['BOX'];

        // list of lines in current box
        var currentBox = currentPallet[j]['LINES'];

        // box ranges
        excel.Range boxNumberRange = sheet.getRangeByName('A$boxRow');
        excel.Range boxDimsRange = sheet.getRangeByName('A${boxRow + 1}');
        excel.Range boxWeightRange = sheet.getRangeByName('A${boxRow + 2}');

        // each box range's values and style
        boxNumberRange.setValue('BOX $boxNumber');
        boxNumberRange.cellStyle = custAddressStyle;
        boxNumberRange.cellStyle.underline = true;

        boxDimsRange.setValue('${boxL}L x ${boxW}W x ${boxH}H');
        boxDimsRange.cellStyle = custAddressStyle;

        boxWeightRange.setValue('$boxWgt LBS');
        boxWeightRange.cellStyle = custAddressStyle;

        // for each line in current box
        for (int k = 0; k < currentBox.length; k++) {
          // current item description and qty
          var currentItem = currentBox[k]['description'];
          var currentItemQty = currentBox[k]['user_input'];

          // print('currentItem: $currentItem \t\t currentItemQty: $currentItemQty');

          // current item ranges
          excel.Range currentItemRange =
              sheet.getRangeByName('B$itemAndQtyRow');
          excel.Range custPart = sheet.getRangeByName('C$itemAndQtyRow');
          excel.Range currentItemQtyRange =
              sheet.getRangeByName('D$itemAndQtyRow');

          // each item range's values and style
          currentItemRange.setValue(currentItem);
          currentItemRange.cellStyle = boxDescQtyStyle;

          if (currentBox[k]['cust_part'] != null) {
            custPart.setValue('${currentBox[k]['cust_part']}');
          } else {
            custPart.setValue('');
          }
          custPart.cellStyle = cvoAddressStyle;

          currentItemQtyRange.setValue(currentItemQty);
          currentItemQtyRange.cellStyle = boxDescQtyStyle;

          // increase the itemAndQtyRow count after each item
          itemAndQtyRow++;
        }

        // increase boxRow count
        boxRow = itemAndQtyRow + 2;
        itemAndQtyRow = boxRow + 1;
      }
      // increase palletRow and boxRow count
      palletRow = boxRow + 1;
      boxRow = palletRow + 4;
      itemAndQtyRow = boxRow + 1;
    }

    // save workbook to stream and dispose
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // check if program runs on web, if so download output file from browser
    if (kIsWeb) {
      name = name.replaceAll('#', ' ');
      AnchorElement(
          href:
              'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$name - $po.xlsx')
        ..click();
    } else {
      // otherwise save file to local storage and open it
      final String path = (await getApplicationSupportDirectory()).path;
      String fileName = Platform.isWindows
          ? '$path\\$name - $po.xlsx'
          : '$path/$name - $po.xlsx';
      fileName = fileName.replaceAll('#', ' ');
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(fileName);
    }
  }

  // create pallet format excel file
  Future<void> palletExcelOutput() async {
    String cvoAddress = '425 RABRO DRIVE, SUITE 2 HAUPPAUGE, NY 11788';
    String cvoTelephone = '1-631-787-1500';
    String cvoFax = '1-631-787-1560';
    String customerName = name;
    String customerPO = po;
    String customerAddress = address;
    int palletRow = 10;
    int boxRow = 14;
    int itemAndQtyRow = 15;
    int totalRows = 20;

    // // Calculate total rows dynamically based on nested data
    // for (var i = 0; i < palletResultList.length; i++) {
    //   // add rows for pallet level
    //   totalRows += palletResultList.length;
    //   for (var j = 0; j < (palletResultList[i]['LINES']).length; j++) {
    //     totalRows += (palletResultList[i]['LINES'].length) as int;
    //     for (var k = 0;
    //         k < palletResultList[i]['LINES'][j]['LINES'].length;
    //         k++) {
    //       totalRows += (palletResultList[i]['LINES'][j]['LINES'].length) as int;
    //     }
    //   }
    // }

    // Calculate total rows dynamically based on nested data
    for (var i = 0; i < palletResultList.length; i++) {
      // Add rows for pallet level
      totalRows += palletResultList[i]['LINES'].length as int;

      // For each line inside pallet
      for (var j = 0; j < palletResultList[i]['LINES'].length; j++) {
        // Add rows for each sub-line in a line
        totalRows += palletResultList[i]['LINES'][j]['LINES'].length as int;
      }
    }

    // print('totalRows: $totalRows');

    // create workbook
    final excel.Workbook workbook = excel.Workbook();
    // access it via index
    final excel.Worksheet sheet = workbook.worksheets[0];
    // enable sheet calculations
    sheet.enableSheetCalculations();

    // cell ranges
    excel.Range columnA = sheet.getRangeByName('A1:A$totalRows');
    excel.Range columnB = sheet.getRangeByName('B1:B$totalRows');
    excel.Range columnC = sheet.getRangeByName('C1:C$totalRows');
    excel.Range logoCellRange = sheet.getRangeByName('A1:C1');
    excel.Range cvoAddressRange = sheet.getRangeByName('A2:C2');
    excel.Range packingListLogo = sheet.getRangeByName('A3:C3');
    excel.Range custNameAndPO = sheet.getRangeByName('A4:C5');
    excel.Range custAddress = sheet.getRangeByName('A6:C6');
    excel.Range boxDetails = sheet.getRangeByName('A7:A8');
    excel.Range productDescription = sheet.getRangeByName('B7:B8');
    excel.Range qty = sheet.getRangeByName('C7:C8');

    // cell styles
    excel.Style logoCellStyle = workbook.styles.add('logoCellStyle');
    logoCellStyle.fontSize = 40;
    logoCellStyle.bold = true;
    logoCellStyle.hAlign = excel.HAlignType.center;
    logoCellStyle.vAlign = excel.VAlignType.center;
    logoCellStyle.borders.all.color = '#000000';
    logoCellStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style fullWorkbookStyle = workbook.styles.add('fullWorkbookStyle');
    fullWorkbookStyle.borders.all.lineStyle = excel.LineStyle.thin;
    fullWorkbookStyle.borders.all.color = '#000000';

    excel.Style cvoAddressStyle = workbook.styles.add('addressStyles');
    cvoAddressStyle.fontSize = 10;
    cvoAddressStyle.hAlign = excel.HAlignType.center;
    cvoAddressStyle.vAlign = excel.VAlignType.center;
    cvoAddressStyle.borders.all.color = '#000000';
    cvoAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style packingListLogoStyle =
        workbook.styles.add('packingListLogoStyle');
    packingListLogoStyle.fontSize = 14;
    packingListLogoStyle.bold = true;
    packingListLogoStyle.underline = true;
    packingListLogoStyle.hAlign = excel.HAlignType.center;
    packingListLogoStyle.vAlign = excel.VAlignType.center;
    packingListLogoStyle.borders.all.color = '#000000';
    packingListLogoStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custNameAndPOStyle = workbook.styles.add('custNameAndPOStyle');
    custNameAndPOStyle.fontSize = 14;
    custNameAndPOStyle.bold = true;
    custNameAndPOStyle.hAlign = excel.HAlignType.center;
    custNameAndPOStyle.vAlign = excel.VAlignType.center;
    custNameAndPOStyle.borders.all.color = '#000000';
    custNameAndPOStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style custAddressStyle = workbook.styles.add('custAddressStyle');
    custAddressStyle.fontSize = 10;
    custAddressStyle.bold = true;
    custAddressStyle.hAlign = excel.HAlignType.center;
    custAddressStyle.vAlign = excel.VAlignType.center;
    custAddressStyle.borders.all.color = '#000000';
    custAddressStyle.borders.all.lineStyle = excel.LineStyle.thin;

    excel.Style boxDescQtyStyle = workbook.styles.add('boxDescQtyStyle');
    boxDescQtyStyle.fontSize = 11;
    boxDescQtyStyle.bold = true;
    boxDescQtyStyle.hAlign = excel.HAlignType.center;
    boxDescQtyStyle.vAlign = excel.VAlignType.center;
    boxDescQtyStyle.borders.all.color = '#000000';
    boxDescQtyStyle.borders.all.lineStyle = excel.LineStyle.thin;

    // set data in the worksheet
    columnA.cellStyle = fullWorkbookStyle;
    columnA.columnWidth = 20;

    columnB.cellStyle = fullWorkbookStyle;
    columnB.columnWidth = 48;

    columnC.cellStyle = fullWorkbookStyle;
    columnC.columnWidth = 18;

    logoCellRange.merge();
    //logoCellRange.setValue('CLEARVISION');
    logoCellRange.cellStyle = logoCellStyle;

    cvoAddressRange.merge();
    cvoAddressRange.setValue('$cvoAddress   tel: $cvoTelephone   fax: $cvoFax');
    cvoAddressRange.cellStyle = cvoAddressStyle;

    packingListLogo.merge();
    packingListLogo.setValue('PACKING LIST');
    packingListLogo.cellStyle = packingListLogoStyle;

    custNameAndPO.merge();
    custNameAndPO.setValue('$customerName - PO $customerPO');
    custNameAndPO.cellStyle = custNameAndPOStyle;

    custAddress.merge();
    custAddress.setValue(customerAddress);
    custAddress.cellStyle = custAddressStyle;

    boxDetails.merge();
    boxDetails.setValue('BOX\n(DIMS & WGT)');
    boxDetails.cellStyle = boxDescQtyStyle;

    productDescription.merge();
    productDescription.setValue('PRODUCT DESCRIPTION');
    productDescription.cellStyle = boxDescQtyStyle;

    qty.merge();
    qty.setValue('QTY');
    qty.cellStyle = boxDescQtyStyle;

    // add a picture to the files
    if (kIsWeb) {
      // for web
      final String image =
          base64.encode(await readImageData('cvoPackingListLogo.png'));
      final excel.Picture picture = sheet.pictures.addBase64(1, 2, image);
      picture.height = 20;
      picture.width = 350;
    } else {
      // for desktop
      final List<int> imgBytes =
          File('assets/images/cvoPackingListLogo.png').readAsBytesSync();
      final excel.Picture picture = sheet.pictures.addStream(1, 2, imgBytes);
      picture.height = 20;
      picture.width = 350;
    }

    // for every pallet in pallet list
    for (var i = 0; i < palletResultList.length; i++) {
      // pallet dimensions & weight
      int palletL = palletResultList[i]['DIMS']['LENGTH'];
      int palletW = palletResultList[i]['DIMS']['WIDTH'];
      int palletH = palletResultList[i]['DIMS']['HEIGHT'];
      int palletWgt = palletResultList[i]['DIMS']['WEIGHT'];
      int palletNum = palletResultList[i]['PALLET'];

      // list of boxes in current pallet
      var currentPallet = palletResultList[i]['LINES'];

      // print('PALLET $palletNum \n$palletL x $palletW x $palletH\n${palletWgt}LBS');
      // print('currentPalletItems: $currentPallet');

      // pallet dim ranges
      excel.Range palletNumber = sheet.getRangeByName('B$palletRow');
      excel.Range dimensions = sheet.getRangeByName('B${palletRow + 1}');
      excel.Range weight = sheet.getRangeByName('B${palletRow + 2}');

      // pallet dims values and styles
      palletNumber.setValue('PALLET $palletNum');
      palletNumber.cellStyle = custAddressStyle;

      dimensions.setValue('$palletL x $palletW x $palletH');
      dimensions.cellStyle = custAddressStyle;

      weight.setValue('$palletWgt LBS');
      weight.cellStyle = custAddressStyle;

      // for every box in the current pallet
      for (var j = 0; j < currentPallet.length; j++) {
        // box dimensions & weight
        int boxL = currentPallet[j]['DIMS']['LENGTH'];
        int boxW = currentPallet[j]['DIMS']['WIDTH'];
        int boxH = currentPallet[j]['DIMS']['HEIGHT'];
        int boxWgt = currentPallet[j]['DIMS']['WEIGHT'];
        int boxNumber = currentPallet[j]['BOX'];

        // list of lines in current box
        var currentBox = currentPallet[j]['LINES'];

        // box ranges
        excel.Range boxNumberRange = sheet.getRangeByName('A$boxRow');
        excel.Range boxDimsRange = sheet.getRangeByName('A${boxRow + 1}');
        excel.Range boxWeightRange = sheet.getRangeByName('A${boxRow + 2}');

        // each box range's values and style
        boxNumberRange.setValue('BOX $boxNumber');
        boxNumberRange.cellStyle = custAddressStyle;
        boxNumberRange.cellStyle.underline = true;

        boxDimsRange.setValue('${boxL}L x ${boxW}W x ${boxH}H');
        boxDimsRange.cellStyle = custAddressStyle;

        boxWeightRange.setValue('$boxWgt LBS');
        boxWeightRange.cellStyle = custAddressStyle;

        // for each line in current box
        for (int k = 0; k < currentBox.length; k++) {
          // current item description and qty
          var currentItem = currentBox[k]['description'];
          var currentItemQty = currentBox[k]['user_input'];

          // print('currentItem: $currentItem \t\t currentItemQty: $currentItemQty');

          // current item ranges
          excel.Range currentItemRange =
              sheet.getRangeByName('B$itemAndQtyRow');
          excel.Range currentItemQtyRange =
              sheet.getRangeByName('C$itemAndQtyRow');

          // each item range's values and style
          currentItemRange.setValue(currentItem);
          currentItemRange.cellStyle = boxDescQtyStyle;

          currentItemQtyRange.setValue(currentItemQty);
          currentItemQtyRange.cellStyle = boxDescQtyStyle;

          // increase the itemAndQtyRow count after each item
          itemAndQtyRow++;
        }

        // increase boxRow count
        boxRow = itemAndQtyRow + 2;
        itemAndQtyRow = boxRow + 1;
      }
      // increase palletRow and boxRow count
      palletRow = boxRow + 1;
      boxRow = palletRow + 4;
      itemAndQtyRow = boxRow + 1;
    }

    // save workbook to stream and dispose
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // check if program runs on web, if so download output file from browser
    if (kIsWeb) {
      AnchorElement(
          href:
              'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download', '$name - $po.xlsx')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      String fileName = Platform.isWindows
          ? '$path\\$name - $po.xlsx'
          : '$path/$name - $po.xlsx';
      fileName = fileName.replaceAll('#', ' ');
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(fileName);
    }
  }

  // sign user out
  Future<void> signOut(BuildContext context) async {
    // Clear all data and navigate to the login page
    // Clear all lists and variables
    orderList.clear();
    itemsList.clear();
    orderQtyList.clear();
    tempList.clear();
    textValue.clear();
    rowResultList.clear();
    rowWidgetList.clear();
    boxWidgetList.clear();
    boxResultList.clear();
    palletResultList.clear();
    palletWidgetList.clear();
    delPrefs();

    // Reset variables to initial state
    isChecked.clear;
    dropdownValue = boxSizeList.first;
    lengthController.text = '';
    widthController.text = '';
    heightController.text = '';
    weightController.text = '';
    rowIndex = 0;
    loopIndex = 0;
    textfieldValue = 0;
    boxNum = 1;
    storedQty = 0;
    setState(() {});

    await MSALController.logOut();
    // Navigate to the login page
    // Navigator.pushReplacementNamed(context, '/');
    setState(() {});
  }

  // start new packing list
  Future<void> startNewPacKingList(BuildContext context) async {
    // clear prefs except username
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('po');
    prefs.remove('name');
    prefs.remove('address');
    prefs.remove('orders');

    // Clear all lists and variables
    orderList.clear();
    itemsList.clear();
    orderQtyList.clear();
    tempList.clear();
    textValue.clear();
    rowResultList.clear();
    rowWidgetList.clear();
    boxWidgetList.clear();
    boxResultList.clear();
    palletResultList.clear();
    palletWidgetList.clear();

    // Reset variables to initial state
    isChecked.clear;
    dropdownValue = boxSizeList.first;
    lengthController.text = '';
    widthController.text = '';
    heightController.text = '';
    weightController.text = '';
    rowIndex = 0;
    loopIndex = 0;
    textfieldValue = 0;
    boxNum = 1;
    storedQty = 0;

    print(
        'SharedPrefs: \n\t\tuser: test\n\t\tpo: $po\n\t\tname: $name\n\t\taddress: $address\n\t\torders: $orderNumbers');

    // navigate to home page
    Navigator.pushNamed(context, '/');
    setState(() {});
  }

  // start new packing list prompt
  void startNewPackingListPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning'),
        content: Text('Start new packing list?'),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => startNewPacKingList(context),
                child: Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
    setState(() {});
  }

  // get all the items and place them in next box
  void getAllItems() {
    textValue.clear();
    // check if teeh box's details have been entered
    if (lengthController.text.isNotEmpty &&
        lengthController.text != '0' &&
        widthController.text.isNotEmpty &&
        widthController.text != '0' &&
        heightController.text.isNotEmpty &&
        heightController.text != '0' &&
        weightController.text.isNotEmpty &&
        weightController.text != '0') {
      // if so move on to function
      List<bool> amountsAreValid = [];
      // get values of each item in list
      for (var i = 0; i < tempList.length; i++) {
        var currentQty = tempList[i]['pack_qty'];
        DynamicWidget currentWidget = rowWidgetList[i];
        var userValue = currentWidget.textfieldValue;
        // check if (i) item has been given a value by user
        int parsedValue = (userValue != null && userValue.isNotEmpty)
            ? int.tryParse(userValue) ?? 0
            : 0;

        // add to textValue as int
        textValue.add(parsedValue);

        // if so check that it's non zero and not negative
        amountsAreValid.add(parsedValue > 0 && parsedValue <= currentQty);
      }
      // print('textValues: $textValue\namountsAreValid: $amountsAreValid');

      // if any amounts are invalid show alert
      if (amountsAreValid.contains(false)) {
        showAlertDialog('Please enter positive values for all SKUs');
      } else {
        for (var j = 0; j < tempList.length; j++) {
          DynamicWidget currentWidget = rowWidgetList[j];
          // set temp values
          if (textValue[j] > 0) {
            var currentQty = tempList[j]['pack_qty'];
            var remainder = currentQty - textValue[j];
            var updatedRowResult = tempList[j];
            // set updatedRow values
            updatedRowResult['box_number'] = boxNum;
            updatedRowResult['pack_qty'] = remainder;
            updatedRowResult['user_input'] = textValue[j];

            // set original list values
            tempList[j]['pack_qty'] = remainder;
            // itemsList[0][j]['pack_qty'] = remainder;

            // add a deep copy to new list
            rowResultList.add(json.decode(json.encode(updatedRowResult)));
          }
          // reset widget fields
          // currentWidget.enabled = false;
          currentWidget.textfieldValue = '';
        }
        nextBox();
        tempList.clear();
        rowWidgetList.clear();
      }
      // print('rowResultList: $rowResultList\n\n');
      // print('rowWidgetList: $rowWidgetList\n\n');
      // print('boxResultList: $boxResultList');
    } else {
      // if box's details have not been filled throw alert
      showAlertDialog('Please fill in all the box details');
    }
    // clear textValue, rowResultList and update UI
    textValue.clear();
    rowResultList.clear();
    setState(() {});
  }

  // "Box" button handler: run getAllItems and surface any unexpected error
  // (e.g. a type change in the API payload) instead of failing silently
  void onBoxPressed() {
    try {
      getAllItems();
    } catch (e, st) {
      print('Error creating box: $e\n$st');
      textValue.clear();
      rowResultList.clear();
      setState(() {});
      showAlertDialog('Could not create box: $e');
    }
  }

  // create box widget and clear row widgets
  void nextBox() {
    var boxDetails = {
      'LENGTH': int.parse(lengthController.text),
      'WIDTH': int.parse(widthController.text),
      'HEIGHT': int.parse(heightController.text),
      'WEIGHT': int.parse(weightController.text),
    };

    // totalPalletWeight += int.parse(weightController.text);
    var boxLines = json.decode(json.encode(rowResultList));
    boxResultList.add({
      'BOX': boxNum,
      'LINES': [...boxLines],
      'DIMS': boxDetails,
    });
    boxWidgetList.add(
      BoxWidget(
        boxNumber: boxLines[0]['box_number'],
        availHeight: availHeight,
        availWidth: availWidth,
      ),
    );
    boxNum++;
    weightController.text = '';
    onSelected('Custom');
  }

  // on duplicate icon btn pressed show dialog to confirm user wants to duplicate the selected box
  // give option to not ask again
  void onDuplicatePressed(int boxIndex) {
    // print('Box to Duplicate: ${boxResultList[boxIndex]}');
    int currentBox = boxWidgetList[boxIndex].boxNumber;
    if (duplicate == false) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Warning!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text('Would you like to duplicate Box $currentBox'),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Don't show again",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Checkbox(
                        value: duplicate,
                        onChanged: (value) => setState(() {
                          duplicate = value!;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          duplicateBox(boxIndex);
                          Navigator.of(context).pop();
                        },
                        child: Text('Yes'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ).then(
        (value) {
          setState(() {});
        },
      );
    } else {
      duplicateBox(boxIndex);
      setState(() {});
    }
  }

  // when called, duplicate the selected box and propagate changes to original lists
  void duplicateBox(int boxIndex) {
    List<bool> checkIfAmountsGoOver = [];
    List<dynamic> lineItems = boxResultList[boxIndex]['LINES'];
    // check if any of the amounts will go over the original quantities
    // and add true or false to the bool list accordingly
    for (var i = 0; i < lineItems.length; i++) {
      var currentItem = lineItems[i];
      int remainder = currentItem['pack_qty'] - currentItem['user_input'];
      remainder < 0
          ? checkIfAmountsGoOver.add(false)
          : checkIfAmountsGoOver.add(true);
    }

    // if any amounts go over throw error
    if (checkIfAmountsGoOver.contains(false)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error!'),
          content: Text(
              'Some items are going over the original amount they contain'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // if no amounts go over proceed to make changes to original list
      for (var i = 0; i < lineItems.length; i++) {
        bool beenFound = false;
        var currentItem = lineItems[i];
        for (var j = 0; j < orderList.length; j++) {
          if (beenFound == false) {
            List<dynamic> currentOrder = List.from(orderList[j] as List);
            for (var k = 0; k < currentOrder.length; k++) {
              var orderItem = currentOrder[k];
              if (orderItem['order_no'] == currentItem['order_no'] &&
                  orderItem['part_no'] == currentItem['part_no']) {
                orderItem['user_input'] += currentItem['user_input'];
                orderItem['pack_qty'] -= currentItem['user_input'];
                currentItem['pack_qty'] -= currentItem['user_input'];
                beenFound = true;
                break;
              }
            }
          } else {
            beenFound = true;
            break;
          }
        }
      }
      boxResultList.add(json.decode(json.encode(boxResultList[boxIndex])));
      boxResultList[boxResultList.length - 1]['BOX'] = boxNum;
      boxWidgetList.add(
        BoxWidget(
          boxNumber: boxNum,
          availHeight: availHeight,
          availWidth: availWidth,
        ),
      );
      boxNum++;
    }
    setState(() {});
  }

  // create pallet and clear box widgets
  void onCompletePallet() async {
    var canCreate = false;

    // initialize isChecked list with all false values
    isChecked = List<bool>.filled(boxWidgetList.length, false, growable: true);

    // show alert for user to enter pallet details
    await showDialog(
      context: context,
      builder: (context) => CustomDialog(
        palletNum: palletNum,
        palletLength: palletLength,
        palletWidth: palletWidth,
        palletHeight: palletHeight,
        palletWeight: palletWeight,
        isChecked: isChecked,
        boxWidgetList: boxWidgetList,
        onTap: boxDetailsPopup,
        onPressed: () {
          // if at least one box is checked allow the user to create pallet
          canCreate = isChecked.any((element) => element);

          // print(canCreate);
          if (canCreate) {
            if (palletLength.text.isNotEmpty &&
                palletLength.text != '0' &&
                palletWidth.text.isNotEmpty &&
                palletWidth.text != '0' &&
                palletHeight.text.isNotEmpty &&
                palletHeight.text != '0' &&
                palletWeight.text.isNotEmpty &&
                palletWeight.text != '0') {
              var palletLines = [];
              totalPalletWeight += int.parse(palletWeight.text);

              // find the boxes that were checked and add them to the pallet
              // as well as their weight
              for (int i = 0; i < isChecked.length; i++) {
                if (isChecked[i]) {
                  // Based on Team's feedback
                  //////totalPalletWeight += boxResultList[i]['DIMS']['WEIGHT'] as int;
                  palletLines.add(json.decode(json.encode(boxResultList[i])));
                }
              }

              // set pallet dimensions
              var palletDimensions = {
                'LENGTH': int.parse(palletLength.text),
                'WIDTH': int.parse(palletWidth.text),
                'HEIGHT': int.parse(palletHeight.text),
                'WEIGHT': totalPalletWeight,
              };

              palletResultList.add({
                'PALLET': palletNum,
                'LINES': [...palletLines],
                'DIMS': palletDimensions,
              });

              // set new state
              setState(() {
                // reverse iterate to avoid indexing issues while removing items
                for (int i = isChecked.length - 1; i >= 0; i--) {
                  if (isChecked[i]) {
                    boxResultList.removeAt(i);
                    boxWidgetList.removeAt(i);
                  }
                }

                // update pallet section
                palletWidgetList.add(PalletWidget(palletNumber: palletNum));
                palletNum++;
              });
              // clear isChecked list and close dialog
              isChecked = List<bool>.from(isChecked, growable: true);
              isChecked.clear();
              Navigator.pop(context);
            } else {
              showAlertDialog('Please enter all details');
            }
          } else {
            showAlertDialog('Please select at least one box to create');
          }
          // reset flag
          canCreate = false;
        },
      ),
    );

    // reset input fields
    palletLength.text = '';
    palletWidth.text = '';
    palletHeight.text = '';
    palletWeight.text = '';
    totalPalletWeight = 0;
  }

  // add row widget to list operation
  void addToRowWidgetList(
    int index,
    List<dynamic> itemList,
    List<dynamic> tempList,
  ) {
    // check if the item clicked on is already
    // in the list, if so, throw alert
    // if not, add item to list
    tempList.contains(itemList[index])
        ? showAlertDialog('Item is already in the list')
        : {
            tempList.add(itemList[index]),
            rowWidgetList.add(DynamicWidget(
              key: ValueKey(itemList[index]),
              list: itemList,
              index: index,
              screenHgt: availHeight,
              screenWdt: availWidth,
            ))
          };
    setState(() {});
    // print(tempList);
  }

  // get full qty amounts for each order
  Future<void> getOrderQty() async {
    var count = 0;
    for (var i = 0; i < orderList.length; i++) {
      // print('orderListLength: ${orderList.length}');
      var currentElement = orderList[i];
      for (var j = 0; j < currentElement.length; j++) {
        // print('${orderList[i][j]}');
        count += orderList[i][j]['pack_qty'] as int;
      }
      orderQtyList.add(count);
    }
    print('orderQtyList: $orderQtyList');
  }

  // alert dialog with custom message
  void showAlertDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // remove box from list and update boxNum variable
  void boxRemovalHandler(int boxIndex) {
    if (boxResultList[boxIndex] != boxResultList.last) {
      // if box is not the last in the list
      // remove box from list, update each box's numbers and update boxNum variable
      for (int i = 0; i < boxResultList.length; i++) {
        if (boxIndex != i) {
          if (boxResultList[i]['BOX'] < boxResultList[boxIndex]['BOX']) {
            continue;
          } else {
            boxResultList[i]['BOX'] -= 1;
            BoxWidget currentBoxWidget = boxWidgetList[i];
            currentBoxWidget.boxNumber -= 1;
          }
        } else {
          continue;
        }
      }
    }
    setState(() {
      boxResultList.removeAt(boxIndex);
      boxWidgetList.removeAt(boxIndex);
      boxNum -= 1;
    });
  }

  // popup of box contents
  void boxDetailsPopup(int boxIndex) {
    List<dynamic> currentElement = boxResultList[boxIndex]['LINES'];
    var dims = boxResultList[boxIndex]['DIMS'];
    var boxNumber = boxResultList[boxIndex]['BOX'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Box $boxNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < currentElement.length; i++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${currentElement[i]['description']}'),
                  const SizedBox(width: 50),
                  Text('${currentElement[i]['user_input']} PCS'),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Text('L: ${dims['LENGTH']}'),
                    const SizedBox(width: 10),
                    Text('W: ${dims['WIDTH']}'),
                    const SizedBox(width: 10),
                    Text('H: ${dims['HEIGHT']}'),
                  ],
                ),
                Text('Wgt: ${dims['WEIGHT']} LBS'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EditBoxWidget(
                    boxNumber: boxNumber,
                    orderList: orderList,
                    currentElement: currentElement,
                    dims: dims,
                  ),
                ).then((value) {
                  if (value != null) {
                    Navigator.of(context).pop();
                    orderList = value;
                    if (currentElement.isEmpty) {
                      boxRemovalHandler(boxIndex);
                      // boxResultList.removeAt(boxIndex);
                      // boxWidgetList.removeAt(boxIndex);
                    }
                    setState(() {});
                  }
                });
              },
              child: const Text('Edit')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() {});
  }

  // display pallet contents on widget tap
  void palletDetailsPopup(int palletIndex) {
    var currentElement = palletResultList[palletIndex]['LINES'];
    var dims = palletResultList[palletIndex]['DIMS'];
    var palletNumber = palletResultList[palletIndex]['PALLET'];
    // print(currentElement[0]['LINES'][0]['description']);
    // print(dims);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pallet #$palletNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < currentElement.length; i++) ...[
              Text(
                'BOX ${currentElement[i]['BOX']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var j = 0; j < currentElement[i]['LINES'].length; j++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currentElement[i]['LINES'][j]['description']}'),
                    const SizedBox(width: 50),
                    Text('${currentElement[i]['LINES'][j]['user_input']} PCS'),
                  ],
                ),
              ],
              const SizedBox(height: 15),
            ],
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Text('L: ${dims['LENGTH']}'),
                    const SizedBox(width: 10),
                    Text('W: ${dims['WIDTH']}'),
                    const SizedBox(width: 10),
                    Text('H: ${dims['HEIGHT']}'),
                  ],
                ),
                Text('Wgt: ${dims['WEIGHT']} LBS'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // decides which excel format to use
  void excelFormat() {
    if (palletResultList.isNotEmpty && boxResultList.isEmpty) {
      if (custCode == '045183' || custCode == '057956') {
        customExcelPalletOutput();
      } else {
        palletExcelOutput();
      }

      startNewPackingListPrompt(context);
    } else if (boxResultList.isNotEmpty && palletResultList.isEmpty) {
      if (custCode == '045183' || custCode == '057956') {
        customExcelOutput();
      } else {
        boxExcelOutput();
      }
      startNewPackingListPrompt(context);
    } else if (palletResultList.isNotEmpty && boxResultList.isNotEmpty) {
      showAlertDialog('There are boxes not yet palleted');
    } else {
      showAlertDialog('There are no boxes or pallets created');
    }
  }

  // dropdown menu cases
  void onSelected(String? value) {
    setState(() {
      dropdownValue = value!;
      switch (dropdownValue) {
        case '44':
          lengthController.text = '18';
          widthController.text = '14';
          heightController.text = '12';
          break;
        case '50':
          lengthController.text = '20';
          widthController.text = '16';
          heightController.text = '14';
          break;
        case '54':
          lengthController.text = '20';
          widthController.text = '19';
          heightController.text = '17';
          break;
        case 'Custom':
          dropdownValue = 'Custom';
          lengthController.clear();
          widthController.clear();
          heightController.clear();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          availWidth = constraints.maxWidth;
          availHeight = constraints.maxHeight;
          if (availWidth > 1700 && availHeight >= 900) {
            return UltraWideLayout(
              screenHgt: availHeight,
              screenWdt: availWidth,
              user: '$user',
              customerName: name,
              customerAddress: address,
              customerPO: po,
              boxNum: boxNum,
              loopIndex: loopIndex,
              rowIndex: rowIndex,
              orderList: orderList,
              orderQtyList: orderQtyList,
              tempList: tempList,
              itemsList: itemsList,
              rowResultList: rowResultList,
              rowWidgetList: rowWidgetList,
              boxResultList: boxResultList,
              boxWidgetList: boxWidgetList,
              palletWidgetList: palletWidgetList,
              // nextItem: nextItem,
              nextBox: onBoxPressed, // nextBox,
              boxDetailsPopup: boxDetailsPopup,
              dropdownValue: dropdownValue,
              addToRowWidgetList: addToRowWidgetList,
              excelFormat: excelFormat,
              heightController: heightController,
              lengthController: lengthController,
              weightController: weightController,
              widthController: widthController,
              // onAddItem: nextItem,
              onCompletePallet: onCompletePallet,
              onSignOut: signOut,
              onNewOrderClick: startNewPackingListPrompt,
              palletDetailsPopup: palletDetailsPopup,
              onSelected: onSelected,
              onDuplicatePressed: onDuplicatePressed,
            );
          } else {
            return WideLayout(
              screenHgt: availHeight,
              screenWdt: availWidth,
              user: '$user',
              customerName: name,
              customerAddress: address,
              customerPO: po,
              boxNum: boxNum,
              loopIndex: loopIndex,
              rowIndex: rowIndex,
              orderList: orderList,
              orderQtyList: orderQtyList,
              tempList: tempList,
              itemsList: itemsList,
              rowResultList: rowResultList,
              rowWidgetList: rowWidgetList,
              boxResultList: boxResultList,
              boxWidgetList: boxWidgetList,
              palletWidgetList: palletWidgetList,
              // nextItem: nextItem,
              nextBox: onBoxPressed, // nextBox,
              boxDetailsPopup: boxDetailsPopup,
              dropdownValue: dropdownValue,
              addToRowWidgetList: addToRowWidgetList,
              excelFormat: excelFormat,
              heightController: heightController,
              lengthController: lengthController,
              weightController: weightController,
              widthController: widthController,
              // onAddItem: nextItem,
              onCompletePallet: onCompletePallet,
              onSignOut: signOut,
              onNewOrderClick: startNewPackingListPrompt,
              palletDetailsPopup: palletDetailsPopup,
              onSelected: onSelected,
              onDuplicatePressed: onDuplicatePressed,
            );
          }
        },
      ),
    );
  }
}

class CustomDialog extends StatefulWidget {
  final int palletNum;
  List<bool> isChecked;
  final List<dynamic> boxWidgetList;
  TextEditingController palletLength = TextEditingController();
  TextEditingController palletWidth = TextEditingController();
  TextEditingController palletHeight = TextEditingController();
  TextEditingController palletWeight = TextEditingController();
  final Function(int i)? onTap;
  final void Function()? onPressed;

  CustomDialog({
    super.key,
    required this.palletNum,
    required this.isChecked,
    required this.boxWidgetList,
    required this.onPressed,
    required this.onTap,
    required this.palletLength,
    required this.palletWidth,
    required this.palletHeight,
    required this.palletWeight,
  });

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 20,
      ),
      title: Text(
        'Pallet ${widget.palletNum}',
        style: const TextStyle(
          color: Colors.black,
        ),
      ),
      content: Column(
        children: [
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    for (var i = 0; i < widget.boxWidgetList.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: widget.isChecked[i],
                              onChanged: (value) {
                                setState(() {
                                  widget.isChecked[i] = value!;
                                  // print(value);
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => widget.onTap!(i),
                                child: widget.boxWidgetList[i],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 100,
                    child: CustomTextField(
                      height: 30,
                      width: 60,
                      textfieldFontSize: 15,
                      controller: widget.palletLength,
                      labelText: 'Length',
                      allowChars: '[0-9]',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'X',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 60,
                    width: 100,
                    child: CustomTextField(
                      height: 30,
                      width: 60,
                      textfieldFontSize: 15,
                      controller: widget.palletWidth,
                      labelText: 'Width',
                      allowChars: '[0-9]',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'X',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 60,
                    width: 100,
                    child: CustomTextField(
                      height: 30,
                      width: 60,
                      textfieldFontSize: 15,
                      controller: widget.palletHeight,
                      labelText: 'Height',
                      allowChars: '[0-9]',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              SizedBox(
                height: 60,
                width: 100,
                child: CustomTextField(
                  height: 30,
                  width: 60,
                  textfieldFontSize: 15,
                  controller: widget.palletWeight,
                  labelText: 'Weight',
                  allowChars: '[0-9]',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
        TextButton(
          onPressed: widget.onPressed,
          child: const Text(
            'Submit',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class UltraWideLayout extends StatefulWidget {
  final String user;
  final String customerName;
  final String customerAddress;
  final String customerPO;
  String dropdownValue;

  final int boxNum;
  final int loopIndex;
  final int rowIndex;
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> orderList;
  final List<dynamic> orderQtyList;
  final List<dynamic> tempList;
  final List<dynamic> itemsList;
  final List<dynamic> rowResultList;
  final List<dynamic> rowWidgetList;
  final List<dynamic> boxResultList;
  final List<dynamic> boxWidgetList;
  final List<dynamic> palletWidgetList;

  TextEditingController lengthController;
  TextEditingController widthController;
  TextEditingController heightController;
  TextEditingController weightController;

  void Function(BuildContext context) onSignOut;
  void Function(BuildContext context) onNewOrderClick;
  void Function(int, List<dynamic>, List<dynamic>)? addToRowWidgetList;
  final void Function() nextBox;
  final dynamic Function(String?)? onSelected;
  void Function() onCompletePallet;
  void Function()? excelFormat;
  final void Function(int) boxDetailsPopup;
  void Function(int) palletDetailsPopup;
  void Function(int) onDuplicatePressed;

  UltraWideLayout({
    super.key,
    required this.screenHgt,
    required this.screenWdt,
    required this.user,
    required this.customerName,
    required this.customerAddress,
    required this.customerPO,
    required this.boxNum,
    required this.loopIndex,
    required this.rowIndex,
    required this.orderList,
    required this.orderQtyList,
    required this.tempList,
    required this.itemsList,
    required this.rowResultList,
    required this.rowWidgetList,
    required this.boxResultList,
    required this.boxWidgetList,
    required this.palletWidgetList,
    required this.nextBox,
    this.onSelected,
    required this.boxDetailsPopup,
    required this.dropdownValue,
    required this.addToRowWidgetList,
    required this.excelFormat,
    required this.heightController,
    required this.lengthController,
    required this.weightController,
    required this.widthController,
    required this.onCompletePallet,
    required this.onSignOut,
    required this.onNewOrderClick,
    required this.palletDetailsPopup,
    required this.onDuplicatePressed,
  });

  @override
  State<UltraWideLayout> createState() => _UltraWideLayoutState();
}

class _UltraWideLayoutState extends State<UltraWideLayout> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(
          screenHgt: widget.screenHgt,
          screenWdt: widget.screenWdt,
          userName: widget.user,
          onSignOut: () => widget.onSignOut(context),
          onNewOrderClick: () => widget.onNewOrderClick(context),
        ),
        CustomerInfo(
          screenHgt: widget.screenHgt,
          screenWdt: widget.screenWdt,
          name: widget.customerName,
          address: widget.customerAddress,
          poNumber: widget.customerPO,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: MediaQuery.of(context).size.height - 135,
              width: MediaQuery.of(context).size.width / 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              child: OrderListPanel(
                screenHgt: widget.screenHgt,
                screenWdt: widget.screenWdt,
                orderList: widget.orderList,
                orderQtyList: widget.orderQtyList,
                tempList: widget.tempList,
                addToRowWidgetList: widget.addToRowWidgetList,
              ),
            ),
            Expanded(
              // main container
              child: Container(
                color: AppColor.primary,
                height: MediaQuery.of(context).size.height - 135,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 30,
                    top: 20,
                    right: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ItemList(
                        screenHgt: widget.screenHgt,
                        screenWdt: widget.screenWdt,
                        boxNum: widget.boxNum,
                        rowWidgetList: widget.rowWidgetList,
                        tempList: widget.tempList,
                      ),
                      BoxInfo(
                        screenHgt: widget.screenHgt,
                        screenWdt: widget.screenWdt,
                        rowIndex: widget.rowIndex,
                        itemsList: widget.itemsList,
                        resultList: widget.rowResultList,
                        rowList: widget.rowWidgetList,
                        boxList: widget.boxWidgetList,
                        palletList: widget.palletWidgetList,
                        onAddItem: () {},
                        onCompleteBox: () {
                          widget.nextBox();
                          widget.dropdownValue = 'Custom';
                          setState(() {});
                        },
                        lengthController: widget.lengthController,
                        widthController: widget.widthController,
                        heightController: widget.heightController,
                        weightController: widget.weightController,
                        onSelected: widget.onSelected,
                        onCompletePallet: () {
                          widget.onCompletePallet();
                          setState(() {});
                        },
                        onCompleteForm: widget.excelFormat,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height - 135,
              width: MediaQuery.of(context).size.width / 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      child: BoxList(
                        screenHgt: widget.screenHgt,
                        screenWdt: widget.screenWdt,
                        boxWidgetList: widget.boxWidgetList,
                        onBoxTap: widget.boxDetailsPopup,
                        resultList: widget.rowResultList,
                        tempList: widget.tempList,
                        onCompleteBox: () {
                          widget.nextBox();
                        },
                        onDuplicatePressed: widget.onDuplicatePressed,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      child: PalletList(
                        screenHgt: widget.screenHgt,
                        screenWdt: widget.screenWdt,
                        onPalletTap: widget.palletDetailsPopup,
                        palletWidgetList: widget.palletWidgetList,
                        boxList: widget.boxWidgetList,
                        onCompletePallet: () {
                          widget.onCompletePallet();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WideLayout extends StatefulWidget {
  final String user;
  final String customerName;
  final String customerAddress;
  final String customerPO;
  String dropdownValue;

  final int boxNum;
  final int loopIndex;
  final int rowIndex;
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> orderList;
  final List<dynamic> orderQtyList;
  final List<dynamic> tempList;
  final List<dynamic> itemsList;
  final List<dynamic> rowResultList;
  final List<dynamic> rowWidgetList;
  final List<dynamic> boxResultList;
  final List<dynamic> boxWidgetList;
  final List<dynamic> palletWidgetList;

  TextEditingController lengthController;
  TextEditingController widthController;
  TextEditingController heightController;
  TextEditingController weightController;

  void Function(BuildContext context) onSignOut;
  void Function(BuildContext context) onNewOrderClick;
  void Function(int, List<dynamic>, List<dynamic>)? addToRowWidgetList;
  final void Function() nextBox;
  final dynamic Function(String?)? onSelected;
  void Function() onCompletePallet;
  void Function()? excelFormat;
  final void Function(int) boxDetailsPopup;
  void Function(int) palletDetailsPopup;
  void Function(int) onDuplicatePressed;

  WideLayout({
    super.key,
    required this.screenHgt,
    required this.screenWdt,
    required this.user,
    required this.customerName,
    required this.customerAddress,
    required this.customerPO,
    required this.boxNum,
    required this.loopIndex,
    required this.rowIndex,
    required this.orderList,
    required this.orderQtyList,
    required this.tempList,
    required this.itemsList,
    required this.rowResultList,
    required this.rowWidgetList,
    required this.boxResultList,
    required this.boxWidgetList,
    required this.palletWidgetList,
    required this.nextBox,
    this.onSelected,
    required this.boxDetailsPopup,
    required this.dropdownValue,
    required this.addToRowWidgetList,
    required this.excelFormat,
    required this.heightController,
    required this.lengthController,
    required this.weightController,
    required this.widthController,
    required this.onCompletePallet,
    required this.onSignOut,
    required this.onNewOrderClick,
    required this.palletDetailsPopup,
    required this.onDuplicatePressed,
  });

  @override
  State<WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<WideLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            screenHgt: widget.screenHgt,
            screenWdt: widget.screenWdt,
            userName: widget.user,
            onSignOut: () => widget.onSignOut(context),
            onNewOrderClick: () => widget.onNewOrderClick(context),
          ),
          CustomerInfo(
            screenHgt: widget.screenHgt,
            screenWdt: widget.screenWdt,
            name: widget.customerName,
            address: widget.customerAddress,
            poNumber: widget.customerPO,
          ),
          Row(
            children: [
              Container(
                height: MediaQuery.of(context).size.height - 80,
                width: MediaQuery.of(context).size.width / 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                child: OrderListPanel(
                  screenHgt: widget.screenHgt,
                  screenWdt: widget.screenWdt,
                  orderList: widget.orderList,
                  orderQtyList: widget.orderQtyList,
                  tempList: widget.tempList,
                  addToRowWidgetList: widget.addToRowWidgetList,
                ),
              ),
              Expanded(
                // main container
                child: Container(
                  color: AppColor.primary,
                  height: MediaQuery.of(context).size.height - 80,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      top: 10,
                      right: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemList(
                          screenHgt: widget.screenHgt,
                          screenWdt: widget.screenWdt,
                          boxNum: widget.boxNum,
                          rowWidgetList: widget.rowWidgetList,
                          // loopIndex: widget.loopIndex,
                          tempList: widget.tempList,
                        ),
                        BoxInfo(
                          screenHgt: widget.screenHgt,
                          screenWdt: widget.screenWdt,
                          rowIndex: widget.rowIndex,
                          itemsList: widget.itemsList,
                          resultList: widget.rowResultList,
                          rowList: widget.rowWidgetList,
                          boxList: widget.boxWidgetList,
                          palletList: widget.palletWidgetList,
                          onAddItem: () {},
                          onCompleteBox: () {
                            widget.nextBox();
                            widget.dropdownValue = 'Custom';
                            setState(() {});
                          },
                          lengthController: widget.lengthController,
                          widthController: widget.widthController,
                          heightController: widget.heightController,
                          weightController: widget.weightController,
                          onSelected: widget.onSelected,
                          onCompletePallet: () {
                            widget.onCompletePallet();
                            setState(() {});
                          },
                          onCompleteForm: widget.excelFormat,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height - 80,
                width: MediaQuery.of(context).size.width / 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          child: BoxList(
                            screenHgt: widget.screenHgt,
                            screenWdt: widget.screenWdt,
                            boxWidgetList: widget.boxWidgetList,
                            onBoxTap: widget.boxDetailsPopup,
                            resultList: widget.rowResultList,
                            tempList: widget.tempList,
                            onCompleteBox: () {
                              widget.nextBox();
                            },
                            onDuplicatePressed: widget.onDuplicatePressed,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          child: PalletList(
                            screenHgt: widget.screenHgt,
                            screenWdt: widget.screenWdt,
                            onPalletTap: widget.palletDetailsPopup,
                            palletWidgetList: widget.palletWidgetList,
                            boxList: widget.boxWidgetList,
                            onCompletePallet: () {
                              widget.onCompletePallet();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
