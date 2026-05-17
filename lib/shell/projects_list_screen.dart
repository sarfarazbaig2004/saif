// Screen for Projects List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/projects/models/project_model.dart';
import 'package:intl/intl.dart';

class ProjectsListScreen extends StatefulWidget {
  final String companyId;

  const ProjectsListScreen({super.key, required this.companyId});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: zBorder),
          _buildToolbar(),
          const Divider(height: 1, color: zBorder),
          Expanded(
            child: _buildLiveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: zBlueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_tree_outlined, color: zBlue, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projects & Planning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage production project codes linked to customer POs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: zMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Project Form coming next!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'New Project',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search Project Code, PO, or Name...',
                  hintStyle: const TextStyle(color: zMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: zMuted),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: zCanvasBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBlue),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: zBlue));
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final code = (data['projectCode'] ?? '').toString().toLowerCase();
          final po = (data['linkedPoNumber'] ?? '').toString().toLowerCase();
          final name = (data['projectName'] ?? '').toString().toLowerCase();
          return code.contains(searchQuery) ||
                 po.contains(searchQuery) ||
                 name.contains(searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final projectModel = ProjectModel.fromMap(data, doc.id);

            return _buildProjectCard(projectModel);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final formattedDate = DateFormat('dd MMM yyyy').format(project.createdAt);

    Color statusColor = zBlue;
    Color statusBg = zBlueSoft;
    
    if (project.status.toLowerCase().contains('active') || project.status.toLowerCase().contains('production')) {
      statusColor = zSuccess;
      statusBg = zSuccessSoft;
    } else if (project.status.toLowerCase().contains('completed')) {
      statusColor = zPurple;
      statusBg = zPurpleSoft;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: zBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // TODO: Open Project Dashboard
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: zCanvasBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: zBorder),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: zText, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            project.projectCode.isNotEmpty ? project.projectCode : 'Draft Project',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: zText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              project.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 14, color: zMuted),
                          const SizedBox(width: 4),
                          Text(
                            'PO: ${project.linkedPoNumber.isNotEmpty ? project.linkedPoNumber : 'Not Linked'}',
                            style: const TextStyle(fontSize: 12, color: zMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.business, size: 14, color: zMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.projectName.isNotEmpty ? project.projectName : 'Unknown Project',
                              style: const TextStyle(fontSize: 12, color: zMuted, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Created',
                      style: TextStyle(
                        fontSize: 11,
                        color: zMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: zText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: zMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: zCanvasBg, shape: BoxShape.circle),
            child: const Icon(Icons.account_tree_outlined, size: 48, color: zMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Projects Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: zText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click "New Project" to generate a code from a PO.',
            style: TextStyle(fontSize: 13, color: zMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}