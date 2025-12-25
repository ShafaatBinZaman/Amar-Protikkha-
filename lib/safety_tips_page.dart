import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      appBar: AppBar(
        title: const Text('Safety Tips'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance.collection('safety_tips_page').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading tips'));
          }

          final tips = snapshot.data?.docs ?? [];
          if (tips.isEmpty) {
            return const Center(child: Text('No safety tips available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final doc = tips[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data.keys.first;
              final description = data[title];

              return Card(
                color: Colors.white,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

                  // 🌟 improved shield logo
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF64B5F6),
                          Color(0xFF1976D2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
