import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/store_model.dart';
import '../../../providers/store_providers.dart';

class StoreMapScreen extends ConsumerStatefulWidget {
  const StoreMapScreen({super.key});

  @override
  ConsumerState<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends ConsumerState<StoreMapScreen> {
  final MapController _mapController = MapController();
  StoreModel? _selectedStore;

  // Van Gogh color palette
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgDarkEspresso = const Color(0xFF1A1105);

  // Default coordinate: Center of Vietnam (or Hanoi)
  final LatLng _defaultCenter = const LatLng(16.047079, 108.206230); // Da Nang center

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _launchDirections(StoreModel store) async {
    final lat = store.latitude;
    final lng = store.longitude;
    final name = Uri.encodeComponent(store.storeName);

    // Google Maps URL format
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name');
    // Apple Maps URL format (iOS native maps)
    final appleMapsUrl = Uri.parse(
        'https://maps.apple.com/?daddr=$lat,$lng&q=$name');

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Maps app';
        }
      } else {
        // Android or Web
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to web link if external application launcher isn't registered
          await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở bản đồ chỉ đường: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _centerOnStore(StoreModel store) {
    setState(() {
      _selectedStore = store;
    });
    _mapController.move(LatLng(store.latitude, store.longitude), 15.5);
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);
    final size = MediaQuery.sizeOf(context);
    final isWideScreen = size.width > 850;

    // Resolve tile provider url template (Goong Map tiles or OSM fallback)
    final bool hasGoongKey = AppConstants.goongMapTilesKey.isNotEmpty &&
        AppConstants.goongMapTilesKey != 'YOUR_GOONG_MAPTILES_KEY';
    final String tileUrlTemplate = hasGoongKey
        ? 'https://tiles.goong.io/vtile/{z}/{x}/{y}.png?api_key=${AppConstants.goongMapTilesKey}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: vgMidnight,
      appBar: AppBar(
        title: const Text(
          'Hệ thống cửa hàng',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: vgMidnight,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: storesAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: 'Không thể tải danh sách cửa hàng: $err',
          onRetry: () => ref.invalidate(storesProvider),
        ),
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(
              child: Text(
                'Hiện tại chưa có chi nhánh cửa hàng nào hoạt động.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          // Automatically center on first store if nothing selected
          final centerLatLng = _selectedStore != null
              ? LatLng(_selectedStore!.latitude, _selectedStore!.longitude)
              : LatLng(stores.first.latitude, stores.first.longitude);

          final markers = stores.map((store) {
            final isSelected = _selectedStore?.id == store.id;
            return Marker(
              point: LatLng(store.latitude, store.longitude),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _centerOnStore(store),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? vgStarGold : vgMidnight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        store.storeName.replaceAll('BigSize Shop - ', ''),
                        style: TextStyle(
                          color: isSelected ? vgMidnight : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.location_on,
                      color: isSelected ? Colors.redAccent : vgStarGold,
                      size: isSelected ? 34 : 28,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          Widget buildMapWidget() {
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 13.0,
                maxZoom: 18.0,
                minZoom: 4.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrlTemplate,
                  userAgentPackageName: 'com.bigsizeshop.app',
                  retinaMode: true,
                ),
                MarkerLayer(markers: markers),
                if (!hasGoongKey)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'OSM Demo Mode (No Goong Key)',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          Widget buildBranchCard(StoreModel store) {
            final isSelected = _selectedStore?.id == store.id;
            return InkWell(
              onTap: () => _centerOnStore(store),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? vgCyanSky.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? vgStarGold : Colors.white10,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: vgStarGold, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.address,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (store.openingHours != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            store.openingHours!,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (store.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            store.phone!,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _launchDirections(store),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vgStarGold,
                        foregroundColor: vgMidnight,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildSidebarList() {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vgMidnight,
                border: isWideScreen
                    ? Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DANH SÁCH CHI NHÁNH',
                    style: TextStyle(
                      color: vgStarGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: stores.length,
                      itemBuilder: (context, idx) => buildBranchCard(stores[idx]),
                    ),
                  ),
                ],
              ),
            );
          }

          if (isWideScreen) {
            return Row(
              children: [
                SizedBox(
                  width: 380,
                  child: buildSidebarList(),
                ),
                Expanded(
                  child: buildMapWidget(),
                ),
              ],
            );
          }

          // Mobile Layout
          return Column(
            children: [
              Expanded(
                flex: 4,
                child: buildMapWidget(),
              ),
              Expanded(
                flex: 3,
                child: buildSidebarList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
