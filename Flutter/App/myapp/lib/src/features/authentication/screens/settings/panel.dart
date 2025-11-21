import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  List<List<dynamic>> csvTable = [];

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  Future<void> loadCSV() async {
    final rawData = await rootBundle.loadString('assets/tracking_data.csv');
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    setState(() {
      csvTable = listData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Tracking Data')),
          body: csvTable.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: csvTable[0]
                  .map((header) => DataColumn(
                  label: Text(header.toString(),
                      style:
                      const TextStyle(fontWeight: FontWeight.bold))))
                  .toList(),
              rows: csvTable.sublist(1).map(
                    (row) => DataRow(
                  cells:
                  row.map((cell) => DataCell(Text(cell.toString()))).toList(),
                ),
              ).toList(),
            ),
          ),
        ));
  }
}
