import 'package:flutter/material.dart';
import 'home.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FF), // baby blue
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F0FF),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Color(0xFF223A5E)), // Home icon
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(color: Color(0xFF223A5E)),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Simple, Transparent Pricing",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF223A5E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Change the plan that works best for you. All plans include a 30 days trial.",
              style: TextStyle(color: Color(0xFF223A5E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildPlanCard(
              "FREE PLAN",
              "MYR 0/month",
              [
                "Detect 50 times skin cancer.",
                "Suggest nearest hospitals.",
              ],
              false,
              isCurrentPlan: true,
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              "PREMIUM",
              "MYR 22/month",
              [
                "Detect skin cancer 10,000 times.",
                "Suggest nearest hospitals.",
                "Navigate to the hospital.",
              ],
              true,
              isPopular: true,
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              "UNLIMITED",
              "MYR 55/month",
              [
                "Unlimited detection.",
                "Suggest nearest hospitals.",
                "Navigate to the hospital.",
              ],
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      String planName, String price, List<String> features, bool showLogo,
      {bool isPopular = false, bool isCurrentPlan = false}) {
    return Card(
      color: Colors.white,
      elevation: isPopular ? 12 : 6,
      shadowColor: isPopular ? const Color(0xFFF9B572) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isPopular
              ? Border.all(color: const Color(0xFFF9B572), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9B572),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "MOST POPULAR",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                if (showLogo)
                  const Icon(
                    Icons.star,
                    color: Color(0xFFF9B572),
                    size: 30,
                  ),
                if (showLogo) const SizedBox(width: 10),
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF223A5E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8DC6A7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF8DC6A7),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: Color(0xFF223A5E),
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () {
                        // Add navigation logic for upgrading
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan
                      ? Colors.grey[300]
                      : const Color(0xFF4C6D83),
                  foregroundColor:
                      isCurrentPlan ? Colors.black54 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  elevation: isCurrentPlan ? 0 : 4,
                ),
                child: Text(
                  isCurrentPlan
                      ? "Current Plan"
                      : (showLogo ? "Upgrade to Premium" : "Select Plan"),
                  style: TextStyle(
                    fontSize: 16,
                    color: isCurrentPlan ? Colors.black54 : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
