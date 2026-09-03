import '../models/store.dart';
import 'mock_images.dart';

Store mockStore = Store(
  id: 'STR-001',
  name: 'Farm Fresh Ltd',
  description: 'Premium agricultural products sourced directly from local farms. We specialize in fresh vegetables, fruits, and grains.',
  businessCategory: 'Agricultural Produce',
  phone: '+234 801 234 5678',
  email: 'info@farmfresh.ng',
  location: 'No. 12, Farm Road, Kaduna, Nigeria',
  logoUrl: MockImages.storeLogo,
  bannerUrl: MockImages.storeBanner,
  isOpen: true,
  status: 'active',
);