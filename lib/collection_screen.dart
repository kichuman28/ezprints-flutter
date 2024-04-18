part of 'main.dart';

class CollectionScreen extends StatefulWidget {
  final mongo.DbCollection collection;

  const CollectionScreen({super.key, required this.collection});

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Timer _timer;
  late Future<List<dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => _refreshData());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<List<dynamic>> _fetchData() async {
    final data = await widget.collection.find().toList();
    return data;
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureData = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Files available to print:',
          style: GoogleFonts.reemKufiFun(),
        ),
        automaticallyImplyLeading: false, // Removes the back button
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.arrowRightFromBracket,
              color: Colors.red,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _futureData,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                List<dynamic> data = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.only(right: 650, left: 30, bottom: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xA669F0FF),
                    ),
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(
                            size: 20,
                            FontAwesomeIcons.filePdf, // You can change the icon as per your preference
                            color: Colors.blue, // You can adjust the color of the bullet point
                          ),
                          title: Text(
                            data[index]['name'] ?? '',
                            style: GoogleFonts.reemKufiFun(fontSize: 20),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              onPressed: () async {
                var data = await widget.collection.find().toList();
                var filenamesFromDatabase = data.map((e) => e['name']).toList();

                List<Uint8List> pdfs = [];
                List<String> filenamesToDelete = []; // List to store filenames to delete

                for (var filename in filenamesFromDatabase) {
                  var pdf = await DriveFunctions.loadPdfFromDrive(filename);
                  if (pdf != null) {
                    pdfs.add(pdf);
                    filenamesToDelete.add(filename); // Add filename to the list
                  }
                }

                // Delete filenames from the collection
                for (var filename in filenamesToDelete) {
                  await widget.collection.remove({'name': filename});
                }

                for (var pdf in pdfs) {
                  await Printing.layoutPdf(onLayout: (_) => pdf);
                }

                // Refresh data to reflect changes after deletion
                _refreshData();
              },
              child: const Text('Print'),
            ),
          ),
        ],
      ),
    );
  }
}
