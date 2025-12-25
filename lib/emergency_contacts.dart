import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<Map<String, String>> savedContacts = [];
  List<Map<String, String>> displayedContacts = [];
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadSavedContacts();
  }

  Future<void> loadSavedContacts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("No user is logged in.");
      setState(() => loading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("emergency_contacts")
          .get();

      print("Snapshot received: ${snapshot.docs.length} contacts.");

      savedContacts = snapshot.docs
          .map((doc) => {
        "name": doc["name"] as String,
        "number": doc["number"] as String,
        "id": doc.id,
      })
          .toList();

      displayedContacts = List.from(savedContacts);

      print("Contacts loaded: $savedContacts");

      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error loading contacts: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> addContact() async {
    if (!await FlutterContacts.requestPermission()) return;

    final contacts = await FlutterContacts.getContacts(withProperties: true);


    final selected = await showModalBottomSheet<Contact?>(
      context: context,
      builder: (context) {
        return SearchableContactsList(
          contacts: contacts,
          onContactSelected: (contact) => Navigator.pop(context, contact),
        );
      },
    );

    if (selected == null) return;

    final number =
    selected.phones.isNotEmpty ? selected.phones.first.number : "";

    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This contact has no phone number")),
      );
      return;
    }


    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("emergency_contacts")
        .add({
      "name": selected.displayName,
      "number": number,
    });


    setState(() {
      savedContacts.add({
        "name": selected.displayName,
        "number": number,
        "id": doc.id,
      });
      displayedContacts = List.from(savedContacts);
    });
  }

  Future<void> removeContact(String id) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("emergency_contacts")
        .doc(id)
        .delete();

    setState(() {
      savedContacts.removeWhere((c) => c["id"] == id);
      displayedContacts = List.from(savedContacts);
    });
  }


  Future<void> callNumber(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to place call")),
      );
    }
  }

  void searchContacts(String query) {
    setState(() {
      searchQuery = query;
      displayedContacts = savedContacts
          .where((contact) => contact["name"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E88E5),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addContact,
        child: const Icon(Icons.add, size: 30),
      ),

      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: searchContacts,
              decoration: const InputDecoration(
                labelText: "Search Contacts",
                border: OutlineInputBorder(),
              ),
            ),
          ),


          loading
              ? const Center(child: CircularProgressIndicator())
              : displayedContacts.isEmpty
              ? const Center(
            child: Text(
              "No emergency contacts added.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: displayedContacts.length,
              itemBuilder: (_, index) {
                final c = displayedContacts[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      c["name"]!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(c["number"]!),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => callNumber(c["number"]!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeContact(c["id"]!), // delete contact
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class SearchableContactsList extends StatefulWidget {
  final List<Contact> contacts;
  final Function(Contact) onContactSelected;

  const SearchableContactsList({
    Key? key,
    required this.contacts,
    required this.onContactSelected,
  }) : super(key: key);

  @override
  _SearchableContactsListState createState() => _SearchableContactsListState();
}

class _SearchableContactsListState extends State<SearchableContactsList> {
  List<Contact> filteredContacts = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    filteredContacts = widget.contacts;
  }

  void searchContacts(String query) {
    setState(() {
      searchQuery = query;
      filteredContacts = widget.contacts
          .where((contact) => contact.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: searchContacts,
            decoration: const InputDecoration(
              labelText: "Search Contacts",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredContacts.length,
            itemBuilder: (_, index) {
              final contact = filteredContacts[index];
              return ListTile(
                title: Text(contact.displayName),
                subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : "No number"),
                onTap: () => widget.onContactSelected(contact),
              );
            },
          ),
        ),
      ],
    );
  }
}
