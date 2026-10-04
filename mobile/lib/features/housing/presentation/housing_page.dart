import 'package:flutter/material.dart';

import '../domain/housing_listing.dart';
import '../domain/housing_repository.dart';

class HousingPage extends StatefulWidget {
  const HousingPage({required this.repository, super.key});

  final HousingRepository repository;

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  late Future<List<HousingListing>> _listings;
  String _query = '';
  RoomType? _roomType;
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _listings = widget.repository.findAll();
  }

  void _retry() => setState(() => _listings = widget.repository.findAll());

  List<HousingListing> _filter(List<HousingListing> listings) {
    final query = _query.trim().toLowerCase();
    return listings
        .where((listing) {
          final searchable = '${listing.title} ${listing.address}'
              .toLowerCase();
          return (query.isEmpty || searchable.contains(query)) &&
              (_roomType == null || listing.roomType == _roomType) &&
              (!_verifiedOnly || listing.isVerified);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm trọ')),
      body: FutureBuilder<List<HousingListing>>(
        future: _listings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _HousingErrorState(onRetry: _retry);
          }
          final listings = _filter(snapshot.data ?? const []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const _BetaNotice(),
              const SizedBox(height: 20),
              const Text(
                'Chỗ ở quanh bạn',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tìm nhanh theo khu vực, loại phòng và trạng thái xác thực.',
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Tên trường hoặc khu vực',
                  hintText: 'Ví dụ: Cao Lãnh',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _roomType == null,
                      onSelected: (_) => setState(() => _roomType = null),
                    ),
                    const SizedBox(width: 8),
                    ...RoomType.values.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_roomTypeLabel(type)),
                          selected: _roomType == type,
                          onSelected: (_) => setState(() => _roomType = type),
                        ),
                      ),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Đã xác thực'),
                      selected: _verifiedOnly,
                      onSelected: (value) =>
                          setState(() => _verifiedOnly = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${listings.length} chỗ ở phù hợp',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (listings.isEmpty)
                const _HousingEmptyState()
              else
                ...listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HousingCard(listing: listing),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BetaNotice extends StatelessWidget {
  const _BetaNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Thông báo bản thử nghiệm',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bản beta · Dữ liệu minh họa, không phải tin đăng thật.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HousingCard extends StatelessWidget {
  const _HousingCard({required this.listing});
  final HousingListing listing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _HousingDetails(listing: listing),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apartment, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (listing.isVerified)
                          const Tooltip(
                            message: 'Tin đã xác thực',
                            child: Icon(Icons.verified, size: 19),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_formatPrice(listing.price)}/tháng · ${listing.area.toStringAsFixed(0)} m²',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HousingDetails extends StatelessWidget {
  const _HousingDetails({required this.listing});
  final HousingListing listing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(listing.address),
            const SizedBox(height: 18),
            Text(
              '${_formatPrice(listing.price)}/tháng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: listing.amenities
                  .map((amenity) => Chip(label: Text(amenity)))
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tính năng liên hệ sẽ mở sau giai đoạn beta.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Liên hệ chủ trọ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HousingEmptyState extends StatelessWidget {
  const _HousingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy phòng phù hợp',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử đổi từ khóa hoặc bỏ bớt bộ lọc.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HousingErrorState extends StatelessWidget {
  const _HousingErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chưa tải được danh sách phòng. Vui lòng thử lại.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

String _roomTypeLabel(RoomType type) => switch (type) {
  RoomType.privateRoom => 'Phòng riêng',
  RoomType.sharedRoom => 'Ở ghép',
  RoomType.studio => 'Studio',
};

String _formatPrice(int price) {
  final millions = price / 1000000;
  final text = millions == millions.roundToDouble()
      ? millions.toStringAsFixed(0)
      : millions.toStringAsFixed(1);
  return '$text triệu';
}
