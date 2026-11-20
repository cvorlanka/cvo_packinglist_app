import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packinglist_app/components/widgets/textfields/custom_textfield.dart';
import 'package:packinglist_app/pages/packing_page.dart';

class BoxInfo extends StatefulWidget {
  final int rowIndex;
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> itemsList;
  final List<dynamic> resultList;
  final List<dynamic> rowList;
  final List<dynamic> boxList;
  final List<dynamic> palletList;

  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController weightController;

  final VoidCallback onAddItem;
  final VoidCallback onCompleteBox;
  final VoidCallback onCompletePallet;
  final Function(String?)? onSelected;
  final void Function()? onCompleteForm;

  const BoxInfo({
    super.key,
    required this.onAddItem,
    required this.onCompleteBox,
    required this.onCompletePallet,
    required this.lengthController,
    required this.widthController,
    required this.heightController,
    required this.weightController,
    required this.onSelected,
    required this.onCompleteForm,
    required this.itemsList,
    required this.resultList,
    required this.rowList,
    required this.boxList,
    required this.palletList,
    required this.rowIndex,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  State<BoxInfo> createState() => _BoxInfoState();
}

class _BoxInfoState extends State<BoxInfo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // drop down menu
            DropdownMenu<String>(
              initialSelection: boxSizeList.last,
              onSelected: widget.onSelected,
              label: const Text(
                'BoxSize',
                style: TextStyle(color: Colors.black),
              ),
              textStyle: const TextStyle(color: Colors.black),
              dropdownMenuEntries:
                  boxSizeList.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
              inputDecorationTheme: InputDecorationTheme(
                constraints: BoxConstraints.tightFor(
                  height: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 60
                      : 55,
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 130
                      : 120,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                  ),
                ),
                iconColor: Colors.white,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Row(
              children: [
                CustomTextField(
                  height: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 60
                      : 55,
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 100
                      : 90,
                  textfieldFontSize:
                      (widget.screenHgt > 900 && widget.screenWdt > 1700)
                          ? 18
                          : 15,
                  controller: widget.lengthController,
                  labelText: 'Length',
                  allowChars: '[0-9]',
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
                CustomTextField(
                  height: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 60
                      : 55,
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 100
                      : 90,
                  textfieldFontSize:
                      (widget.screenHgt > 900 && widget.screenWdt > 1700)
                          ? 18
                          : 15,
                  controller: widget.widthController,
                  labelText: 'Width',
                  allowChars: '[0-9]',
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
                CustomTextField(
                  height: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 60
                      : 55,
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 100
                      : 90,
                  textfieldFontSize:
                      (widget.screenHgt > 900 && widget.screenWdt > 1700)
                          ? 18
                          : 15,
                  controller: widget.heightController,
                  labelText: 'Height',
                  allowChars: '[0-9]',
                ),
                SizedBox(
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 100
                      : 50,
                ),
                CustomTextField(
                  height: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 60
                      : 55,
                  width: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 100
                      : 90,
                  textfieldFontSize:
                      (widget.screenHgt > 900 && widget.screenWdt > 1700)
                          ? 18
                          : 15,
                  controller: widget.weightController,
                  labelText: 'Weight',
                  allowChars: '[0-9]',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: widget.palletList.isEmpty && widget.boxList.isEmpty ? null : widget.onCompleteForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              icon: Icon(
                Icons.article_outlined,
                color: Colors.white,
                size: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                    ? 30
                    : 20,
              ),
              label: Text(
                'PACKING LIST',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                      ? 25
                      : 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
