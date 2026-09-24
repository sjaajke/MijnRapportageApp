import 'package:flutter/material.dart';

import '../screens/defects_list_page.dart';
import '../screens/herstel_overview_page.dart';
import '../screens/home_page.dart';
import '../screens/inspection_menu_page.dart';
import '../screens/noodverlichting_list_page.dart';
import '../screens/solar_installations_list_page.dart';
import '../screens/switchboards_list_page.dart';
import '../screens/tekeningen_list_page.dart';

enum NavSection { switchboards, solar, noodverlichting, defects }

/// Shortcut bar with the inspection sections, shown at the top of the
/// inspection pages. Scrolls horizontally when the screen is too narrow.
class InspectionNavBar extends StatelessWidget {
  final int inspectionId;

  /// Whether to show the button that returns to the inspection menu; the menu
  /// page itself hides it.
  final bool showInspectionButton;

  /// The section the current page belongs to; its button is hidden.
  final NavSection? current;

  const InspectionNavBar({
    super.key,
    required this.inspectionId,
    this.showInspectionButton = true,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Material(
      elevation: 2,
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _btn(
                    Icons.list_outlined,
                    'Inspecties',
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                      (route) => false,
                    ),
                  ),
                  if (showInspectionButton)
                    _btn(
                      Icons.home_outlined,
                      'Inspectie',
                      () =>
                          open(InspectionMenuPage(inspectionId: inspectionId)),
                    ),
                  if (current != NavSection.switchboards)
                    _btn(
                      Icons.lan,
                      'Verdelers',
                      () => open(
                        SwitchboardsListPage(inspectionId: inspectionId),
                      ),
                    ),
                  if (current != NavSection.solar)
                    _btn(
                      Icons.solar_power,
                      'Zonnestroom',
                      () => open(
                        SolarInstallationsListPage(inspectionId: inspectionId),
                      ),
                    ),
                  if (current != NavSection.noodverlichting)
                    _btn(
                      Icons.emergency,
                      'Noodverlichting',
                      () => open(
                        NoodverlichtingListPage(inspectionId: inspectionId),
                      ),
                    ),
                  _btn(
                    Icons.battery_charging_full,
                    'Accu',
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Accu-installaties: binnenkort beschikbaar',
                        ),
                      ),
                    ),
                  ),
                  if (current != NavSection.defects)
                    _btn(
                      Icons.warning_amber,
                      'Gebreken',
                      () => open(DefectsListPage(inspectionId: inspectionId)),
                    ),
                  _btn(
                    Icons.build_outlined,
                    'Herstel',
                    () => open(HerstelOverviewPage(inspectionId: inspectionId)),
                  ),
                  _btn(
                    Icons.map_outlined,
                    'Tekeningen',
                    () => open(TekeningenListPage(inspectionId: inspectionId)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1976D2)),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
    );
  }
}
