import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_wifi/services/database_service.dart';
import '../utils/database_location.dart';
import '../utils/database_browser.dart';

class DatabaseManagementScreen extends StatefulWidget {
  const DatabaseManagementScreen({super.key});

  @override
  State<DatabaseManagementScreen> createState() =>
      _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  Map<String, dynamic> _dbInfo = {};
  List<String> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _isLoading = true);

    _dbInfo = await DatabaseLocation.getDatabaseInfo();
    _tables = await DatabaseBrowser.getTables();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatabaseInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Database Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Database Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Status',
                          _dbInfo['exists'] ? '✅ Exists' : '❌ Not Found',
                        ),
                        _buildInfoRow(
                          'Location',
                          _dbInfo['path']?.split('/').last ?? 'Unknown',
                        ),
                        _buildInfoRow(
                          'Size',
                          _dbInfo['formattedSize'] ?? '0 B',
                        ),
                        if (_dbInfo['modified'] != null)
                          _buildInfoRow(
                            'Modified',
                            _formatDate(_dbInfo['modified']),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tables Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tables',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._tables.map(
                          (table) => FutureBuilder<int>(
                            future: DatabaseBrowser.getTableRowCount(table),
                            builder: (context, snapshot) {
                              return ListTile(
                                leading: const Icon(Icons.table_rows),
                                title: Text(table),
                                trailing: Text(
                                  '${snapshot.data ?? 0} records',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                onTap: () => _showTablePreview(context, table),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.share, color: Colors.blue),
                          title: const Text('Share Database'),
                          subtitle: const Text('Export database file'),
                          onTap: _shareDatabase,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.analytics,
                            color: Colors.green,
                          ),
                          title: const Text('Export as JSON'),
                          subtitle: const Text('Export all data as JSON'),
                          onTap: _exportAsJson,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.orange),
                          title: const Text('Database Summary'),
                          subtitle: const Text('View complete summary'),
                          onTap: _showDatabaseSummary,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Clear All Data'),
                          subtitle: const Text('Delete all stored data'),
                          onTap: _showClearDataDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showTablePreview(BuildContext context, String tableName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table: $tableName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseBrowser.previewTable(tableName),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const Center(child: Text('No data in table'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: data.first.keys.map((key) {
                        return DataColumn(label: Text(key));
                      }).toList(),
                      rows: data.map((row) {
                        return DataRow(
                          cells: row.values.map((value) {
                            return DataCell(Text(value?.toString() ?? 'null'));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDatabase() async {
    try {
      final dbPath = await DatabaseLocation.getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        await Share.shareXFiles([
          dbPath as XFile,
        ], text: 'Router Manager Database Backup');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database file not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAsJson() async {
    try {
      final export = await DatabaseBrowser.exportDatabaseAsJson();
      final jsonString = jsonEncode(export);

      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/database_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      await Share.shareXFiles([file.path as XFile], text: 'Database Export');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDatabaseSummary() async {
    final summary = await DatabaseBrowser.getDatabaseSummary();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Summary'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Share.share(summary, subject: 'Database Summary');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all stored data? '
          'This includes router profiles, settings, and all configurations. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final dbPath = await DatabaseLocation.getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        await file.delete();

        // Reinitialize database
        await DatabaseService().database;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadDatabaseInfo();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
