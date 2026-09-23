import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tailor_app/screens/account/measurement_controller.dart';
import 'package:tailor_app/screens/alter_clothes_screen.dart';
import 'package:tailor_app/screens/customize_clothes_screen.dart';
import 'package:tailor_app/screens/fabric_collection_screen.dart';
import 'package:tailor_app/screens/help_support_screen.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/services/token_storage.dart';
import 'package:tailor_app/screens/notifications_screen.dart';
import 'package:tailor_app/screens/order_tracking_screen.dart';
import '../dress_collection_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> banners = [
    {
      'title': 'Custom Fit.\nA Better You.',
      'subtitle': 'Premium fabrics. Perfect fitting.\nYour style, our craftsmanship.',
      'button': 'Get Started',
      'image': 'assets/images/dress_western_classic.jpg',
      'gradient': [const Color(0xFFF8EFEA), const Color(0xFFF3E7DF)],
      'btnBg': const Color(0xFF4E342E),
      'screen': CustomizeClothesScreen(),
    },
    {
      'title': 'Exclusive\nFabrics Sale.',
      'subtitle': 'Handpicked silk, cotton & yarn.\nCraft your unique look today.',
      'button': 'Explore Collection',
      'image': 'assets/images/fabric_pinksilk.webp',
      'gradient': [const Color(0xFFFFF0F5), const Color(0xFFFCE4EC)],
      'btnBg': const Color(0xFF880E4F),
      'screen': FabricCollectionScreen(),
    },
    {
      'title': 'Expert Tailoring\n& Alterations.',
      'subtitle': 'Perfect alterations done fast.\nDoorstep pickup & delivery available.',
      'button': 'Alter Now',
      'image': 'assets/images/dress_denim_jacket.jpg',
      'gradient': [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
      'btnBg': const Color(0xFF1B5E20),
      'screen': AlterClothesScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        _bannerPageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    await getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 28, color: Colors.black87),
                      onPressed: () {},
                    ),
                    Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Cloth',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Serif',
                                ),
                              ),
                              TextSpan(
                                text: 'Crafters',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6D4C41),
                                  fontFamily: 'Serif',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'TAILORED FOR YOU',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, size: 26, color: Colors.black87),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage('assets/images/person.webp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. Hero Banner Carousel (Auto-Sliding Loop)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: PageView.builder(
                        controller: _bannerPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.all(18.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: banner['gradient'],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        banner['title'],
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                          color: Color(0xFF3E2723),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        banner['subtitle'],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF795548),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => banner['screen']),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: banner['btnBg'],
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              banner['button'],
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_rounded, size: 14),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    banner['image'],
                                    width: 100,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Active Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(banners.length, (index) {
                        final bool isActive = _currentBannerIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF4E342E) : Colors.grey.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Grid Feature Cards (2 Columns Layout)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Give\nMeasurement',
                            subtitle: 'Quick & Easy',
                            icon: Icons.accessibility_new_rounded,
                            bgColor: const Color(0xFFFFF9E6),
                            iconBgColor: const Color(0xFFFFF0C2),
                            accentColor: const Color(0xFFD9A000),
                            screen: MeasurementController(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Fabric\nCollection',
                            subtitle: 'Explore Premium Fabrics',
                            icon: Icons.collections_bookmark_rounded,
                            bgColor: const Color(0xFFFFF2EC),
                            iconBgColor: const Color(0xFFFFDFD1),
                            accentColor: const Color(0xFFE65100),
                            screen: FabricCollectionScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Alter\nClothes',
                            subtitle: 'Repairs & Alterations',
                            icon: Icons.content_cut_rounded,
                            bgColor: const Color(0xFFEBF5FE),
                            iconBgColor: const Color(0xFFD4EBFE),
                            accentColor: const Color(0xFF0288D1),
                            screen: AlterClothesScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Customize\nClothes',
                            subtitle: 'Design Your Style',
                            icon: Icons.edit_note_rounded,
                            bgColor: const Color(0xFFEEF9F5),
                            iconBgColor: const Color(0xFFD5F3E7),
                            accentColor: const Color(0xFF2E7D32),
                            screen: CustomizeClothesScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Tailor Made\nClothes',
                            subtitle: 'Made Just for You',
                            icon: Icons.checkroom_rounded,
                            bgColor: const Color(0xFFF3EFFF),
                            iconBgColor: const Color(0xFFE2D9FF),
                            accentColor: const Color(0xFF673AB7),
                            screen: DressCollectionScreen(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildFeatureCard(
                            context: context,
                            title: 'Help &\nSupport',
                            subtitle: 'We\'re Here for You',
                            icon: Icons.headset_mic_rounded,
                            bgColor: const Color(0xFFFDF0F2),
                            iconBgColor: const Color(0xFFFFDADE),
                            accentColor: const Color(0xFFC62828),
                            screen: HelpSupportScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Full Width Order Tracking Card
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderTrackingScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF4FE),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4E7FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: Color(0xFF0288D1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Order Tracking',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Track Your Order in Real Time',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4E7FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF0288D1),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Fabric Collection Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Our Fabric Collection',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Serif',
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Explore a wide range of premium fabrics',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FabricCollectionScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF5D4037)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Fabric Collection Horizontal List
              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: fabricCollection.length,
                  itemBuilder: (context, index) {
                    final fabric = fabricCollection[index];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.asset(
                                    fabric['image']!,
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fabric['title']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fabric['subtitle'] ?? 'Elegant & Luxurious',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE8E8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Explore',
                                      style: TextStyle(
                                        color: Color(0xFFC62828),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 5. Best Selling Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Best Selling Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Serif',
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Handcrafted custom tailor-made outfits',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DressCollectionScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF5D4037)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Best Selling Products Horizontal List
              SizedBox(
                height: 210,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: bestSellingProducts.length,
                  itemBuilder: (context, index) {
                    final item = bestSellingProducts[index];
                    return Container(
                      width: 145,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.asset(
                              item['image']!,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '₹1,499',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconBgColor,
    required Color accentColor,
    required Widget screen,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: accentColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, String>> fabricCollection = [
    {'image': 'assets/images/fabric_silk.jpg', 'title': 'Silk Fabric', 'subtitle': 'Elegant & Smooth'},
    {'image': 'assets/images/fabric_yarn.jpg', 'title': 'Yarn Fabric', 'subtitle': 'Warm & Cozy'},
    {'image': 'assets/images/fabric_cotton.jpg', 'title': 'Cotton Fabric', 'subtitle': 'Soft & Breathable'},
    {'image': 'assets/images/fabric_pinksilk.webp', 'title': 'Pink Silk', 'subtitle': 'Rich Gloss Finish'},
    {'image': 'assets/images/fabric_jute.jpg', 'title': 'Jute Fabric', 'subtitle': 'Eco & Durable'},
    {'image': 'assets/images/fabric_floral.jpg', 'title': 'Cambay Fabric', 'subtitle': 'Floral Prints'},
    {'image': 'assets/images/fabric_denim.jpg', 'title': 'Denim Fabric', 'subtitle': 'Rugged Quality'},
  ];

  final List<Map<String, String>> bestSellingProducts = [
    {'image': 'assets/images/dress_denim_jacket.jpg', 'title': 'Denim Jacket'},
    {'image': 'assets/images/dress_western_classic.jpg', 'title': 'Western Classic'},
    {'image': 'assets/images/dress_yarn_classic.jpg', 'title': 'Yarn Classic'},
    {'image': 'assets/images/dress_silk_saree.jpg', 'title': 'Silk Saree'},
    {'image': 'assets/images/dress_jeans.jpg', 'title': 'Handcrafted Jeans'},
    {'image': 'assets/images/dress_floral.jpg', 'title': 'Floral Dress'},
  ];
}
