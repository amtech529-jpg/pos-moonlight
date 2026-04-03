import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/core/app_colors.dart';

class RecentOrdersCard extends StatelessWidget {
  const RecentOrdersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final orders = provider.orders.take(7).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Recent Orders",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Order ID",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Customer",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 100, // Fixed width to match badges
                          alignment: Alignment.center,
                          child: Text(
                            "Status",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                        SizedBox(width: 70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Table Rows List
            if (provider.isLoading && orders.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ))
            else if (orders.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No recent orders found"),
              ))
            else
              ...orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildOrderRow(
                  o.orderNumber,
                  o.customerName,
                  o.formattedTotalAmount,
                  o.statusText,
                  o.statusColor,
                ),
              )),
          ],
        );
      },
    );
  }

  Widget _buildOrderRow(
    String orderId,
    String customer,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              orderId,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              customer,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 100, // Same fixed width as header
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 70), // Move slightly back from the edge
              ],
            ),
          ),
        ],
      ),
    );
  }
}



