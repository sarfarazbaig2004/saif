import 'dart:ui';

import 'package:flutter/material.dart';

class LoginDashboardBackdrop extends StatelessWidget {
  const LoginDashboardBackdrop({super.key});

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 1.25, sigmaY: 1.25),
    child: Transform.scale(
      scale: 1.045,
      child: Opacity(
        opacity: 0.76,
        child: Container(
          color: const Color(0xFFE8EDF3),
          padding: const EdgeInsets.fromLTRB(56, 30, 30, 26),
          child: const _DashboardShell(),
        ),
      ),
    ),
  );
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Sidebar(),
      const SizedBox(width: 18),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardTopBar(),
            const SizedBox(height: 22),
            const _KpiStrip(),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                children: [
                  const Expanded(flex: 5, child: _SalesChart()),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        const Expanded(child: _CustomerList()),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              const Expanded(child: _MiniPanel()),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: _cardDecoration,
                                  child: const Center(
                                    child: Icon(
                                      Icons.donut_large_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 92,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: _softShadow,
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3C8D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 30),
        for (final item in const [
          (Icons.dashboard_outlined, 'Dashboard'),
          (Icons.people_outline, 'Customers'),
          (Icons.shopping_bag_outlined, 'Sales'),
          (Icons.inventory_2_outlined, 'Inventory'),
          (Icons.request_quote_outlined, 'Finance'),
          (Icons.build_outlined, 'Service Requests'),
          (Icons.analytics_outlined, 'Analytics'),
        ])
          _NavItem(icon: item.$1, label: item.$2),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF526175)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF273448),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        'Dashboard',
        style: TextStyle(
          color: Color(0xFF142033),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Search anything...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16),
      const CircleAvatar(
        backgroundColor: Color(0xFF174EA6),
        child: Text('AK', style: TextStyle(color: Colors.white, fontSize: 11)),
      ),
    ],
  );
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 4; index++) ...[
        Expanded(
          child: _KpiCard(
            label: const [
              'Total Revenue',
              'Sales Orders',
              'Customers',
              'Gross Profit',
            ][index],
            value: const ['₹2.45M', '1,245', '3,672', '₹1.12M'][index],
            icon: const [
              Icons.currency_rupee,
              Icons.receipt_long_outlined,
              Icons.people_outline,
              Icons.trending_up,
            ][index],
          ),
        ),
        if (index < 3) const SizedBox(width: 14),
      ],
    ],
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF152238),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Overview',
          style: TextStyle(
            color: Color(0xFF142033),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: CustomPaint(painter: _ChartPainter(), size: Size.infinite),
        ),
      ],
    ),
  );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE6EBF2)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      Offset(0, size.height * 0.74),
      Offset(size.width * 0.12, size.height * 0.58),
      Offset(size.width * 0.24, size.height * 0.68),
      Offset(size.width * 0.38, size.height * 0.36),
      Offset(size.width * 0.52, size.height * 0.49),
      Offset(size.width * 0.68, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.38),
      Offset(size.width, size.height * 0.16),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final point in points) {
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CustomerList extends StatelessWidget {
  const _CustomerList();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Customers',
          style: TextStyle(
            color: Color(0xFF142033),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        for (final item in const [
          ('Acme Corporation', 0.88),
          ('Globex Industries', 0.72),
          ('Initech Solutions', 0.62),
          ('Umbrella Corp', 0.51),
        ])
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 10.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: item.$2,
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Orders',
          style: TextStyle(
            color: Color(0xFF142033),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < 4; index++)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFBFDBFE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

const _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: _softShadow,
);

const _softShadow = [
  BoxShadow(color: Color(0x140F172A), blurRadius: 18, offset: Offset(0, 8)),
];
