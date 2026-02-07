import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../models/agent_recommendation_model.dart';
import '../../models/cash_flow_prediction_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../analytics_service.dart';
import '../customer_service.dart';
import '../product_service.dart';

/// Revenue Optimizer Agent - Identifies opportunities to increase revenue
/// Generates upsell, cross-sell, and pricing recommendations
class RevenueOptimizerAgent {
  RevenueOptimizerAgent._();
  static final RevenueOptimizerAgent _instance = RevenueOptimizerAgent._();
  static RevenueOptimizerAgent get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  final _productService = ProductService.instance;
  final _customerService = CustomerService.instance;
  final _analyticsService = AnalyticsService.instance;

  /// Run revenue optimization analysis
  Future<List<AgentRecommendationModel>> analyze() async {
    final recommendations = <AgentRecommendationModel>[];
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return recommendations;

    try {
      // Analyze various revenue opportunities
      final priceOptimizations = await _analyzePriceOptimizations();
      final promotionOpportunities = await _analyzePromotionTiming();
      final upsellOpportunities = await _analyzeUpsellOpportunities();

      recommendations.addAll(priceOptimizations);
      recommendations.addAll(promotionOpportunities);
      recommendations.addAll(upsellOpportunities);

      return recommendations;
    } catch (e) {
      return recommendations;
    }
  }

  /// Analyze products for price optimization opportunities
  Future<List<AgentRecommendationModel>> _analyzePriceOptimizations() async {
    final recommendations = <AgentRecommendationModel>[];
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return recommendations;

    final products = await _productService.getProducts();
    final topProducts = await _analyticsService.getTopProducts(limit: 10);

    for (final product in products) {
      // Check for low margin products that sell well
      final topProduct = topProducts.firstWhere(
        (tp) => tp.productId == product.id,
        orElse: () => TopProduct(
          productId: '',
          productName: '',
          category: '',
          unitsSold: 0,
          revenue: 0,
          profit: 0,
          profitMargin: 0,
        ),
      );

      if (topProduct.productId.isNotEmpty) {
        // High-selling product with low margin
        if (topProduct.profitMargin < 15 && topProduct.unitsSold > 10) {
          final suggestedIncrease = (product.sellingPrice * 0.05).round();
          recommendations.add(
            AgentRecommendationModel(
              id: '',
              userId: userId,
              agentType: AgentType.revenue,
              priority: RecommendationPriority.medium,
              title: 'Price Optimization: ${product.name}',
              description:
                  'This product is selling well (${topProduct.unitsSold} units) but has a low margin of '
                  '${topProduct.profitMargin.toStringAsFixed(1)}%. Consider increasing price by ₹$suggestedIncrease.',
              suggestedAction: 'Review and update product pricing',
              actionType: ActionType.navigate,
              actionData: {'route': '/products/${product.id}'},
              data: {
                'product_id': product.id,
                'current_price': product.sellingPrice,
                'suggested_increase': suggestedIncrease,
                'current_margin': topProduct.profitMargin,
                'units_sold': topProduct.unitsSold,
              },
              expiresAt: DateTime.now().add(const Duration(days: 30)),
            ),
          );
        }
      }

      // Check for slow-moving high-margin products (promotion candidates)
      if (product.stockQuantity > 50 && _isSlowMoving(product)) {
        recommendations.add(
          AgentRecommendationModel(
            id: '',
            userId: userId,
            agentType: AgentType.revenue,
            priority: RecommendationPriority.low,
            title: 'Promotion Opportunity: ${product.name}',
            description:
                'This product has ${product.stockQuantity} units in stock but slow sales. '
                'Consider a promotional discount to clear inventory.',
            suggestedAction: 'Create a promotional offer',
            actionType: ActionType.navigate,
            actionData: {'route': '/products/${product.id}'},
            data: {
              'product_id': product.id,
              'current_stock': product.stockQuantity,
              'suggested_discount': 10,
            },
            expiresAt: DateTime.now().add(const Duration(days: 14)),
          ),
        );
      }
    }

    return recommendations;
  }

  /// Analyze sales patterns for promotion timing
  Future<List<AgentRecommendationModel>> _analyzePromotionTiming() async {
    final recommendations = <AgentRecommendationModel>[];
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return recommendations;

    // Get revenue trend
    final revenueTrend = await _analyticsService.getRevenueTrend(daysBack: 30);

    // If revenue is declining, suggest promotional action
    if (!revenueTrend.isPositive && revenueTrend.changePercent < -10) {
      recommendations.add(
        AgentRecommendationModel(
          id: '',
          userId: userId,
          agentType: AgentType.revenue,
          priority: RecommendationPriority.high,
          title: 'Revenue Declining - Promotional Action Suggested',
          description:
              'Revenue has declined by ${revenueTrend.changePercent.abs().toStringAsFixed(1)}% '
              'compared to the previous period. Consider running a promotion to boost sales.',
          suggestedAction: 'Plan a promotional campaign',
          actionType: ActionType.navigate,
          actionData: {'route': '/analytics'},
          data: {
            'revenue_change': revenueTrend.changePercent,
            'current_period': revenueTrend.currentPeriodRevenue,
            'previous_period': revenueTrend.previousPeriodRevenue,
          },
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
      );
    }

    return recommendations;
  }

  /// Analyze customer behavior for upsell opportunities
  Future<List<AgentRecommendationModel>> _analyzeUpsellOpportunities() async {
    final recommendations = <AgentRecommendationModel>[];
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return recommendations;

    final customers = await _customerService.getCustomers();

    // Find high-value customers who haven't purchased recently
    final highValueCustomers = customers
        .where(
          (c) =>
              c.segment == CustomerSegment.gold ||
              c.segment == CustomerSegment.silver,
        )
        .toList();

    for (final customer in highValueCustomers.take(5)) {
      // Check if customer hasn't purchased recently
      if (customer.lastPurchaseDate != null) {
        final daysSincePurchase = DateTime.now()
            .difference(customer.lastPurchaseDate!)
            .inDays;

        if (daysSincePurchase > 30 && daysSincePurchase <= 90) {
          recommendations.add(
            AgentRecommendationModel(
              id: '',
              userId: userId,
              agentType: AgentType.revenue,
              priority: RecommendationPriority.medium,
              title: 'Re-engage: ${customer.name}',
              description:
                  'This ${customer.segment.displayName} customer hasn\'t purchased in $daysSincePurchase days. '
                  'Lifetime value: ₹${customer.totalSpent.toStringAsFixed(0)}. Consider reaching out.',
              suggestedAction: 'Send personalized offer or follow-up',
              actionType: ActionType.navigate,
              actionData: {'route': '/customer/${customer.id}'},
              data: {
                'customer_id': customer.id,
                'customer_name': customer.name,
                'segment': customer.segment.name,
                'days_since_purchase': daysSincePurchase,
                'lifetime_value': customer.totalSpent,
              },
              expiresAt: DateTime.now().add(const Duration(days: 14)),
            ),
          );
        }
      }
    }

    return recommendations;
  }

  /// Get all revenue opportunities from database
  Future<List<RevenueOpportunity>> getOpportunities({
    OpportunityStatus? status,
    int limit = 20,
  }) async {
    PostgrestFilterBuilder query = _client
        .from('revenue_opportunities')
        .select();

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => RevenueOpportunity.fromSupabase(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Save a revenue opportunity
  Future<void> saveOpportunity(RevenueOpportunity opportunity) async {
    await _client
        .from('revenue_opportunities')
        .insert(opportunity.toSupabase());
  }

  /// Mark opportunity as actioned
  Future<void> actionOpportunity(String id) async {
    await _client
        .from('revenue_opportunities')
        .update({
          'status': 'actioned',
          'actioned_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Dismiss an opportunity
  Future<void> dismissOpportunity(String id) async {
    await _client
        .from('revenue_opportunities')
        .update({'status': 'dismissed'})
        .eq('id', id);
  }

  bool _isSlowMoving(ProductModel product) {
    // Simple heuristic: if stock hasn't moved much recently
    // In a real implementation, this would check sales velocity
    return product.stockQuantity > 30;
  }
}
