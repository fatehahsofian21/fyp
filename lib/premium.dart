import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F4858),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(color: Colors.white),
        ),
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
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Change the plan that works best for you. All plans include a 30 days trial.",
              style: TextStyle(color: Colors.white),
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
              isCurrentPlan:
                  true, // Indicating this is the current plan selected
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
      color: isCurrentPlan ? Colors.grey : const Color(0xFF2F4858),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF4C6D83),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "MOST POPULAR",
                      style: TextStyle(color: Colors.white, fontSize: 10),
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
                    color: Colors.yellow,
                    size: 30,
                  ),
                const SizedBox(width: 10),
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
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
                color: Colors.white,
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
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              feature,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2, // Limit to 2 lines
                              overflow:
                                  TextOverflow.ellipsis, // Prevent overflow
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
                  backgroundColor: isCurrentPlan ? Colors.grey : const Color.fromARGB(255, 216, 188, 132),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  isCurrentPlan
                      ? "Current Plan"
                      : (showLogo ? "Upgrade to Premium" : "Select Plan"),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
