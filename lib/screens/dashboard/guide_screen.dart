import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';
import '../../models/feature_data.dart';
import '../../widgets/feature_detail_sheet.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String _searchQuery = '';

  final List<FeatureModel> _features = FeatureRegistry.allFeatures;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    // Filter logic
    final filteredFeatures = _features.where((f) {
      final text = '${f.title} ${f.description} ${f.category}'.toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    // Group by category
    final Map<String, List<FeatureModel>> grouped = {};
    for (var f in filteredFeatures) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: canPop ? 16 : 40, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SightSync Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Master your hardware and AI capabilities.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                
                // Search Bar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search features, hardware, AI...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final category = grouped.keys.elementAt(index);
                final items = grouped[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    ...items.map((item) => _FeatureTile(item: item)),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 90), // Bottom nav padding
        ],
      ),
    );

    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: AmbientBackground(child: content),
      );
    }

    return Scaffold(
      body: AmbientBackground(
        isPremium: true,
        child: content,
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final FeatureModel item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showFeatureDetail(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.interaction,
                    style: TextStyle(
                      color: item.color.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }
}
