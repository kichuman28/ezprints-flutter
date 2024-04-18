import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'functions.dart'; // Import the functions
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
part 'collection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ezprints and Google Drive Files',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController phoneNumberController = TextEditingController();
  String? _printerStatus = '';
  bool _isLoading = false; // Added isLoading state

  void checkPhoneNumber() async {
    setState(() {
      _isLoading = true; // Set loading state to true when login button is pressed
    });

    String phoneNumber = phoneNumberController.text;
    var db = await mongo.Db.create(
        "mongodb+srv://abel:abel@cluster0.iqgx2js.mongodb.net/ezprints?retryWrites=true&w=majority&appName=Cluster0");
    await db.open();
    var collection = db.collection(phoneNumber);

    final count = await collection.count();

    if (count == 0) {
      setState(() {
        _printerStatus = 'User not found';
        _isLoading = false; // Reset loading state
      });
    } else {
      setState(() {
        _printerStatus = 'Collection found';
        _isLoading = false; // Reset loading state
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionScreen(collection: collection),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ezprints',
          style: GoogleFonts.reemKufiFun(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.arrowRightFromBracket,
              color: Colors.red,
              size: 25,
            ),
            onPressed: () {
              setState(() {
                _printerStatus = null;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 50.0, right: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ezprints',
              style: GoogleFonts.reemKufiFun(
                color: Colors.deepPurpleAccent,
                fontSize: 50,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 70),
            TextField(
              controller: phoneNumberController,
              onSubmitted: (_) {
                checkPhoneNumber();
              },
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                hoverColor: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 90),
            ElevatedButton(
              onPressed: _isLoading ? null : checkPhoneNumber, // Disable button when loading
              child: _isLoading ? CircularProgressIndicator() : const Text('Login'),
            ),
            const SizedBox(height: 20),
            Text(_printerStatus ?? ''),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }
}
