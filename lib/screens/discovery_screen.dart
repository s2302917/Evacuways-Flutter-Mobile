import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/resource_controller.dart';
import 'chat_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    resourceController.fetchContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Start Conversation',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Personnel'),
            Tab(text: 'Drivers'),
            Tab(text: 'Volunteers'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: resourceController,
        builder: (context, _) {
          if (resourceController.isContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildContactList(resourceController.contacts['personnel'] ?? []),
              _buildContactList(resourceController.contacts['drivers'] ?? []),
              _buildContactList(resourceController.contacts['volunteers'] ?? []),
              _buildContactList(resourceController.contacts['community'] ?? []),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactList(List<Map<String, dynamic>> contactList) {
    if (contactList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No contacts found in this category',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contactList.length,
      itemBuilder: (context, i) {
        final contact = contactList[i];
        final name = "${contact['first_name']} ${contact['last_name']}";
        final role = contact['role'] ?? 'User';
        final id = int.tryParse(contact['user_id'].toString()) ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              contact['first_name'][0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(role.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          trailing: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  otherUserId: id,
                  name: name,
                  subtitle: "Online",
                  color: AppColors.primary,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
