// Created by: Adwaith Jayasankar, Created at: 18-04-2024 23:47
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

class DriveFunctions {
  static Future<Uint8List?> loadPdfFromDrive(String filename) async {
    final credentialsJson = await rootBundle.loadString('assets/apikeys.json');
    final credentials = auth.ServiceAccountCredentials.fromJson(credentialsJson);
    final scopes = [drive.DriveApi.driveFileScope];
    final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(credentials, scopes, http.Client());
    final authClient = auth.authenticatedClient(http.Client(), accessCredentials);
    final driveApi = drive.DriveApi(authClient);

    final fileListResponse = await driveApi.files.list(
      q: "name = '$filename'",
    );

    if (fileListResponse.files != null && fileListResponse.files!.isNotEmpty) {
      final fileId = fileListResponse.files![0].id!;
      return printFile(fileId);
    } else {
      return null;
    }
  }

  static Future<Uint8List> printFile(String fileId) async {
    try {
      final pdfUrl = 'https://drive.google.com/uc?id=$fileId';
      final response = await http.get(Uri.parse(pdfUrl));
      return response.bodyBytes.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to load PDF');
    }
  }

  static Future<String> getFileId(String fileName) async {
    final serviceAccountCredentials = rootBundle.loadString('assets/apikeys.json');
    final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountCredentials);
    final scopes = [drive.DriveApi.driveScope];
    final client = await auth.clientViaServiceAccount(credentials, scopes);
    final driveApi = drive.DriveApi(client);

    try {
      final response = await driveApi.files.list(q: "name = '$fileName'");
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        final fileId = files.first.id;
        return fileId!;
      } else {
        throw Exception('File not found');
      }
    } finally {
      client.close();
    }
  }
}
