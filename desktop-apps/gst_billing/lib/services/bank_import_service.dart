import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class BankImportService {
  Future<List<List<dynamic>>> importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final csvTable = CsvToListConverter().convert(csvString);
      return csvTable;
    }
    return [];
  }
}