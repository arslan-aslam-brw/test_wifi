// lib/screens/parental_control_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider_extended.dart';
import '../models/parental_control.dart';
import '../models/device_model.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );
    setState(() => _isLoading = true);
    await provider.loadParentalControls();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );
    await provider.loadParentalControls();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Controls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Consumer<ExtendedRouterProvider>(
        builder: (context, provider, child) {
          if (_isLoading || _isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.parentalRules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No parental control rules',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRuleDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rule'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.parentalRules.length,
              itemBuilder: (context, index) {
                final rule = provider.parentalRules[index];
                return _buildParentalRuleCard(rule, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentalRuleCard(
    ParentalControlRule rule,
    ExtendedRouterProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: rule.enabled
              ? Colors.green.shade100
              : Colors.grey.shade100,
          child: Icon(
            Icons.child_care,
            color: rule.enabled ? Colors.green : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                rule.childName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Switch(
              value: rule.enabled,
              onChanged: (value) async {
                // Create updated rule with toggled enabled state
                final updatedRule = ParentalControlRule(
                  id: rule.id,
                  deviceId: rule.deviceId,
                  deviceName: rule.deviceName,
                  childName: rule.childName,
                  schedules: rule.schedules,
                  contentFilters: rule.contentFilters,
                  enabled: value,
                  expiryDate: rule.expiryDate,
                );
                await provider.updateParentalControlRule(updatedRule);
              },
            ),
          ],
        ),
        subtitle: Text(rule.deviceName),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedules section
                const Text(
                  'Schedules',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (rule.schedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No schedules configured'),
                  )
                else
                  ...rule.schedules.map(
                    (schedule) => ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(schedule.name),
                      subtitle: Text(
                        '${_formatDays(schedule.days)} • '
                        '${schedule.startTime.format(context)} - '
                        '${schedule.endTime.format(context)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Edit schedule
                        },
                      ),
                    ),
                  ),

                const Divider(),

                // Content filters section
                const Text(
                  'Content Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (rule.contentFilters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No content filters configured'),
                  )
                else
                  ...rule.contentFilters.map((filter) {
                    if (filter.type == FilterType.youtubeRestricted) {
                      return ListTile(
                        leading: const Icon(Icons.video_library),
                        title: const Text('YouTube'),
                        subtitle: Text(
                          filter.youtubeRestricted
                              ? 'Restricted Mode'
                              : 'Normal',
                        ),
                        trailing: Switch(
                          value: filter.youtubeRestricted,
                          onChanged: (value) {
                            // Toggle YouTube restricted mode
                          },
                        ),
                      );
                    } else {
                      return ListTile(
                        leading: Icon(filter.icon),
                        title: Text(filter.displayName),
                        subtitle: Text(filter.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Edit filter
                          },
                        ),
                      );
                    }
                  }),

                const Divider(),

                // Expiry
                if (rule.expiryDate != null)
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Expires'),
                    subtitle: Text(_formatDate(rule.expiryDate!)),
                  ),

                const SizedBox(height: 8),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showEditRuleDialog(context, rule, provider);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () =>
                          _showDeleteDialog(context, rule.id, provider),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );
    final devices = provider.connectedDevices;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Parental Control'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Device:'),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.devices)),
                      title: Text(device.name),
                      subtitle: Text(device.ipAddress),
                      onTap: () {
                        Navigator.pop(context);
                        _showRuleConfigurationDialog(context, device);
                      },
                    );
                  },
                ),
              ),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No devices connected'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditRuleDialog(
    BuildContext context,
    ParentalControlRule rule,
    ExtendedRouterProvider provider,
  ) {
    // Find the device
    final device = provider.connectedDevices.firstWhere(
      (d) => d.macAddress == rule.deviceId,
      orElse: () => DeviceModel(
        macAddress: rule.deviceId,
        ipAddress: '',
        name: rule.deviceName,
        hostname: rule.deviceName,
      ),
    );

    _showRuleConfigurationDialog(context, device, existingRule: rule);
  }

  void _showRuleConfigurationDialog(
    BuildContext context,
    DeviceModel device, {
    ParentalControlRule? existingRule,
  }) {
    // Get provider at the beginning of the method
    final provider = Provider.of<ExtendedRouterProvider>(
      context,
      listen: false,
    );

    final childNameController = TextEditingController(
      text: existingRule?.childName ?? '',
    );
    List<ScheduleRule> schedules = existingRule?.schedules.toList() ?? [];
    List<ContentFilter> filters = existingRule?.contentFilters.toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existingRule == null
                ? 'Configure Rule for ${device.name}'
                : 'Edit Rule for ${device.name}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: childNameController,
                  decoration: const InputDecoration(
                    labelText: 'Child Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule section
                const Text(
                  'Schedules',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...schedules.map(
                  (schedule) => ListTile(
                    title: Text(schedule.name),
                    subtitle: Text(
                      '${_formatDays(schedule.days)} • '
                      '${schedule.startTime.format(context)} - '
                      '${schedule.endTime.format(context)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          schedules.remove(schedule);
                        });
                      },
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddScheduleDialog(context, (schedule) {
                    setState(() {
                      schedules.add(schedule);
                    });
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Schedule'),
                ),

                const SizedBox(height: 16),

                // Content filters
                const Text(
                  'Content Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Web Filtering
                CheckboxListTile(
                  title: const Text('Enable Web Filtering'),
                  value: filters.any(
                    (f) => f.type != FilterType.youtubeRestricted,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        filters.add(
                          ContentFilter(
                            type: FilterType.moderate,
                            safeSearch: true,
                          ),
                        );
                      } else {
                        filters.removeWhere(
                          (f) => f.type != FilterType.youtubeRestricted,
                        );
                      }
                    });
                  },
                ),

                if (filters.any((f) => f.type != FilterType.youtubeRestricted))
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      children: [
                        DropdownButtonFormField<FilterType>(
                          value: filters
                              .firstWhere(
                                (f) => f.type != FilterType.youtubeRestricted,
                                orElse: () =>
                                    ContentFilter(type: FilterType.moderate),
                              )
                              .type,
                          decoration: const InputDecoration(
                            labelText: 'Filter Level',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: FilterType.strict,
                              child: Text('Strict'),
                            ),
                            DropdownMenuItem(
                              value: FilterType.moderate,
                              child: Text('Moderate'),
                            ),
                            DropdownMenuItem(
                              value: FilterType.custom,
                              child: Text('Custom'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                filters.removeWhere(
                                  (f) => f.type != FilterType.youtubeRestricted,
                                );
                                filters.add(
                                  ContentFilter(type: value, safeSearch: true),
                                );
                              });
                            }
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('SafeSearch'),
                          value: filters
                              .firstWhere(
                                (f) => f.type != FilterType.youtubeRestricted,
                                orElse: () =>
                                    ContentFilter(type: FilterType.moderate),
                              )
                              .safeSearch,
                          onChanged: (value) {
                            setState(() {
                              final index = filters.indexWhere(
                                (f) => f.type != FilterType.youtubeRestricted,
                              );
                              if (index != -1 && value != null) {
                                final filter = filters[index];
                                filters[index] = ContentFilter(
                                  type: filter.type,
                                  safeSearch: value,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // YouTube Restricted Mode
                CheckboxListTile(
                  title: const Text('YouTube Restricted Mode'),
                  value: filters.any(
                    (f) => f.type == FilterType.youtubeRestricted,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        filters.add(
                          ContentFilter(
                            type: FilterType.youtubeRestricted,
                            youtubeRestricted: true,
                          ),
                        );
                      } else {
                        filters.removeWhere(
                          (f) => f.type == FilterType.youtubeRestricted,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (childNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter child name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final rule = ParentalControlRule(
                  id:
                      existingRule?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  deviceId: device.macAddress,
                  deviceName: device.name,
                  childName: childNameController.text,
                  schedules: schedules,
                  contentFilters: filters,
                  enabled: existingRule?.enabled ?? true,
                  expiryDate: existingRule?.expiryDate,
                );

                bool success;
                if (existingRule == null) {
                  success = await provider.addParentalControlRule(rule);
                } else {
                  success = await provider.updateParentalControlRule(rule);
                }

                if (context.mounted) {
                  Navigator.pop(context); // Close configuration dialog
                  Navigator.pop(context); // Close parent dialog if needed

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Rule ${existingRule == null ? 'added' : 'updated'} successfully'
                            : 'Failed to ${existingRule == null ? 'add' : 'update'} rule',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: Text(existingRule == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    Function(ScheduleRule) onAdd,
  ) {
    final nameController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Monday-Friday

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Schedule Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Day selector
              const Text('Days:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip('Mon', 1, selectedDays, setState),
                  _buildDayChip('Tue', 2, selectedDays, setState),
                  _buildDayChip('Wed', 3, selectedDays, setState),
                  _buildDayChip('Thu', 4, selectedDays, setState),
                  _buildDayChip('Fri', 5, selectedDays, setState),
                  _buildDayChip('Sat', 6, selectedDays, setState),
                  _buildDayChip('Sun', 0, selectedDays, setState),
                ],
              ),

              const SizedBox(height: 16),

              // Time pickers
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    setState(() => startTime = time);
                  }
                },
              ),

              ListTile(
                title: const Text('End Time'),
                subtitle: Text(endTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    setState(() => endTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter schedule name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final schedule = ScheduleRule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  days: selectedDays,
                  startTime: startTime,
                  endTime: endTime,
                );
                onAdd(schedule);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(
    String label,
    int value,
    List<int> selectedDays,
    StateSetter setState,
  ) {
    final isSelected = selectedDays.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedDays.add(value);
          } else {
            selectedDays.remove(value);
          }
        });
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String ruleId,
    ExtendedRouterProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteParentalControlRule(ruleId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Rule deleted successfully'
                          : 'Failed to delete rule',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(0)) {
      return 'Weekends';
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} days';
    } else if (difference.inDays == 0) {
      return 'Expires today';
    } else {
      return 'Expired';
    }
  }
}

extension ListContains on List<int> {
  bool containsAll(List<int> values) {
    for (var value in values) {
      if (!contains(value)) return false;
    }
    return true;
  }
}
