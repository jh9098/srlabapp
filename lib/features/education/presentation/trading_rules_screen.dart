import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trading_rules_content.dart';

class TradingRulesScreen extends StatelessWidget {
  const TradingRulesScreen({super.key});

  static const List<IconData> _ruleIcons = <IconData>[
    Icons.dashboard_customize_outlined,
    Icons.pie_chart_outline_rounded,
    Icons.horizontal_rule_rounded,
    Icons.trending_up_rounded,
    Icons.sync_alt_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.block_rounded,
    Icons.gpp_bad_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 매매규칙'),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            8,
            AppSpacing.pageHorizontal,
            48,
          ),
          children: <Widget>[
            const _EducationHero(),
            const SizedBox(height: 16),
            const _StatsGrid(),
            const SizedBox(height: 30),
            const _SectionTitle(
              eyebrow: 'CORE RULES',
              title: '반드시 기억할 8가지 원칙',
              description: '매수 전 가장 먼저 확인해야 할 연구소의 기본 매매원칙입니다.',
            ),
            const SizedBox(height: 14),
            ...List<Widget>.generate(
              coreTradingRules.length,
              (int index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CoreRuleCard(
                  rule: coreTradingRules[index],
                  icon: _ruleIcons[index],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              eyebrow: 'DETAIL GUIDE',
              title: '상세 교육자료',
              description: '각 항목을 눌러 상황별 판단기준과 행동원칙을 확인하세요.',
            ),
            const SizedBox(height: 14),
            ...detailTradingRules.map(
              (DetailTradingRule rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DetailRuleCard(rule: rule),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              eyebrow: 'BEFORE TRADING',
              title: '매매 전 마지막 확인',
              description: '기능형 체크리스트가 아니라, 주문 전 반드시 읽어야 할 확인사항입니다.',
            ),
            const SizedBox(height: 14),
            const _ChecklistCard(),
            const SizedBox(height: 30),
            const _SectionTitle(
              eyebrow: 'START HERE',
              title: '처음 이용하는 회원 안내',
              description: '연구소 매매방식과 회원이 지켜야 할 기본 책임을 정리했습니다.',
            ),
            const SizedBox(height: 14),
            ...welcomeEducationMessages.map(
              (WelcomeEducationMessage message) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WelcomeMessageCard(message: message),
              ),
            ),
            const SizedBox(height: 8),
            const _DisclaimerCard(),
          ],
        ),
    );
  }
}

class _EducationHero extends StatelessWidget {
  const _EducationHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF0C4A6E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -42,
            top: -46,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF7DD3FC).withValues(alpha: 0.24),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.school_outlined,
                      size: 15,
                      color: Color(0xFFBAE6FD),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '회원 필수교육',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '종목을 맞히는 것이 아니라\n계좌를 관리하는 매매',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '지지선, 분할매수, 비중조절, 수익실현과 멘징을 하나의 원칙으로 연결합니다. 추천종목을 무조건 따라 사는 것이 아니라 상황별 대응계획을 먼저 세웁니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFF38BDF8),
                      width: 4,
                    ),
                  ),
                ),
                child: const Text(
                  '좋은 종목보다 중요한 것은 좋은 비중이며,\n좋은 지지선보다 중요한 것은 이탈 후의 대응계획입니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 10;
        final double width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: educationStats
              .map(
                (EducationStat stat) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          stat.value,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stat.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _CoreRuleCard extends StatelessWidget {
  const _CoreRuleCard({
    required this.rule,
    required this.icon,
  });

  final CoreTradingRule rule;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 22, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      rule.category,
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rule.number,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rule.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            rule.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              rule.emphasis,
              style: TextStyle(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  rule.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRuleCard extends StatelessWidget {
  const _DetailRuleCard({required this.rule});

  final DetailTradingRule rule;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              rule.number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            rule.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
          ),
          children: <Widget>[
            _InfoBox(
              icon: Icons.push_pin_outlined,
              title: '핵심원칙',
              body: rule.corePrinciple,
              type: _InfoBoxType.primary,
            ),
            ...rule.paragraphs.map(
              (String paragraph) => Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  paragraph,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                      ),
                ),
              ),
            ),
            if (rule.bullets.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...rule.bullets.map(
                (String bullet) => _BulletRow(text: bullet),
              ),
            ],
            if (rule.example != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.lightbulb_outline_rounded,
                title: '예시와 판단기준',
                body: rule.example!,
                type: _InfoBoxType.neutral,
              ),
            ],
            if (rule.goodAction != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.check_circle_outline_rounded,
                title: '올바른 행동',
                body: rule.goodAction!,
                type: _InfoBoxType.good,
              ),
            ],
            if (rule.warning != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBox(
                icon: Icons.warning_amber_rounded,
                title: '주의할 행동',
                body: rule.warning!,
                type: _InfoBoxType.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _InfoBoxType { primary, neutral, good, warning }

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.body,
    required this.type,
  });

  final IconData icon;
  final String title;
  final String body;
  final _InfoBoxType type;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color foreground;
    late final Color background;
    late final Color border;

    switch (type) {
      case _InfoBoxType.primary:
        foreground = Theme.of(context).colorScheme.primary;
        background = foreground.withValues(alpha: isDark ? 0.13 : 0.06);
        border = foreground.withValues(alpha: 0.18);
        break;
      case _InfoBoxType.neutral:
        foreground = Theme.of(context).colorScheme.onSurfaceVariant;
        background = isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.55)
            : const Color(0xFFF8FAFC);
        border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        break;
      case _InfoBoxType.good:
        foreground = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
        background = const Color(0xFF10B981).withValues(alpha: isDark ? 0.11 : 0.07);
        border = const Color(0xFF10B981).withValues(alpha: 0.2);
        break;
      case _InfoBoxType.warning:
        foreground = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
        background = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.11 : 0.06);
        border = const Color(0xFFEF4444).withValues(alpha: 0.18);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 19, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: isDark ? 0.14 : 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.fact_check_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '계획 없는 매수는 하지 않습니다',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          ...educationChecklistGroups.map(
            (EducationChecklistGroup group) => _ChecklistGroupView(group: group),
          ),
        ],
      ),
    );
  }
}

class _ChecklistGroupView extends StatelessWidget {
  const _ChecklistGroupView({required this.group});

  final EducationChecklistGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                group.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...group.items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18),
        ],
      ),
    );
  }
}

class _WelcomeMessageCard extends StatelessWidget {
  const _WelcomeMessageCard({required this.message});

  final WelcomeEducationMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  size: 19,
                  color: AppTheme.brandAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppTheme.brandAmber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '본 자료는 회원 교육을 위한 일반적인 매매원칙이며 특정 종목의 수익을 보장하지 않습니다. 주식투자는 원금손실이 발생할 수 있으며 최종 투자판단과 책임은 투자자 본인에게 있습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.6,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
