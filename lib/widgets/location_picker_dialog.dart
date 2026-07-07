import 'package:flutter/material.dart';

class LocationPickerDialog extends StatefulWidget {
  /// Single flat list — shown as one section with one search field.
  final List<String>? options;

  /// Named sections. When 2+ entries are provided the dialog shows a tab per
  /// section, each with its own independent search field.
  final Map<String, List<String>>? sections;

  const LocationPickerDialog({super.key, this.options, this.sections})
      : assert(options != null || sections != null,
            'Provide either options or sections');

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late final List<String> _queries;

  Map<String, List<String>> get _sections =>
      widget.sections ?? {'': widget.options!};

  @override
  void initState() {
    super.initState();
    final count = _sections.length;
    _queries = List.filled(count, '');
    if (count > 1) {
      _tabController = TabController(length: count, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<String> _filtered(List<String> options, String query) {
    if (query.isEmpty) return options;
    final q = query.toLowerCase();
    return options.where((o) => o.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _sections.keys.toList();
    final isMulti = keys.length > 1;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kies locatie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tabs (only when multiple sections)
          if (isMulti)
            TabBar(
              controller: _tabController,
              tabs: keys.map((k) => Tab(text: k)).toList(),
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1976D2),
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          // Content
          Expanded(
            child: isMulti
                ? TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      keys.length,
                      (i) => _buildSection(_sections[keys[i]]!, i),
                    ),
                  )
                : _buildSection(_sections[keys[0]]!, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<String> options, int index) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        final query = _queries[index];
        final filtered = _filtered(options, query);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                autofocus: index == 0,
                decoration: const InputDecoration(
                  hintText: 'Zoeken...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setLocal(() => _queries[index] = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? 'Geen opties beschikbaar.'
                            : 'Geen resultaten voor "$query".',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(filtered[i]),
                        onTap: () => Navigator.pop(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
