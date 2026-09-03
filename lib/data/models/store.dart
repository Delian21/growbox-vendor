class Store {
  final String id;
  final String name;
  final String description;
  final String businessCategory;
  final String phone;
  final String email;
  final String location;
  final String logoUrl;
  final String bannerUrl;
  final bool isOpen;
  final String status; // 'active', 'pending', 'suspended'
  final List<String> operatingDays; // ['Mon', 'Tue', ...]
  final String openTime;  // e.g. '8:00 AM'
  final String closeTime; // e.g. '6:00 PM'

  const Store({
    required this.id,
    required this.name,
    required this.description,
    required this.businessCategory,
    required this.phone,
    required this.email,
    required this.location,
    required this.logoUrl,
    required this.bannerUrl,
    required this.isOpen,
    required this.status,
    this.operatingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.openTime = '8:00 AM',
    this.closeTime = '6:00 PM',
  });

  Store copyWith({
    String? name,
    String? description,
    String? businessCategory,
    String? phone,
    String? email,
    String? location,
    String? logoUrl,
    String? bannerUrl,
    bool? isOpen,
    String? status,
    List<String>? operatingDays,
    String? openTime,
    String? closeTime,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessCategory: businessCategory ?? this.businessCategory,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isOpen: isOpen ?? this.isOpen,
      status: status ?? this.status,
      operatingDays: operatingDays ?? this.operatingDays,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}