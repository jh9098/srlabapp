class EducationStat {
  const EducationStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class CoreTradingRule {
  const CoreTradingRule({
    required this.number,
    required this.category,
    required this.title,
    required this.description,
    required this.emphasis,
    required this.note,
  });

  final String number;
  final String category;
  final String title;
  final String description;
  final String emphasis;
  final String note;
}

class DetailTradingRule {
  const DetailTradingRule({
    required this.number,
    required this.title,
    required this.corePrinciple,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
    this.example,
    this.goodAction,
    this.warning,
  });

  final String number;
  final String title;
  final String corePrinciple;
  final List<String> paragraphs;
  final List<String> bullets;
  final String? example;
  final String? goodAction;
  final String? warning;
}

class EducationChecklistGroup {
  const EducationChecklistGroup({
    required this.number,
    required this.title,
    required this.items,
  });

  final String number;
  final String title;
  final List<String> items;
}

class WelcomeEducationMessage {
  const WelcomeEducationMessage({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

const List<EducationStat> educationStats = <EducationStat>[
  EducationStat(value: '2종목', label: '기본 보유 원칙'),
  EducationStat(value: '최대 3종목', label: '연구소 추천종목 기준'),
  EducationStat(value: '10~20%', label: '최초 매수비중'),
  EducationStat(value: '5%+', label: '기본 수익실현 기준'),
  EducationStat(value: '70%+', label: '추가매수 자금 확보'),
  EducationStat(value: '20%', label: '계좌 현금 유지'),
];

const List<CoreTradingRule> coreTradingRules = <CoreTradingRule>[
  CoreTradingRule(
    number: '01',
    category: '보유종목 관리',
    title: '추천종목을 전부 사지 않습니다',
    description:
        '추천종목은 선택지를 제공하는 것입니다. 실제 보유는 2종목을 원칙으로 하고, 최대 3종목까지만 관리합니다.',
    emphasis: '2종목 원칙 · 최대 3종목',
    note: '같은 테마·업종의 중복 보유도 가급적 피합니다. 핵심 추천종목은 우선순위를 안내합니다.',
  ),
  CoreTradingRule(
    number: '02',
    category: '비중 관리',
    title: '처음부터 전액 매수하지 않습니다',
    description:
        '종목별 최대 투자금액을 먼저 정하고 최초에는 10~20%만 진입합니다. 남은 자금은 지지선 아래의 계획된 분할매수에 사용합니다.',
    emphasis: '최초 10~20% · 추가자금 70% 이상',
    note: '핵심 추천종목도 분할매수 원칙은 같습니다. 전체 계좌 현금은 20%를 유지합니다.',
  ),
  CoreTradingRule(
    number: '03',
    category: '지지선 진입',
    title: '지지선은 반등 보장선이 아닙니다',
    description:
        '지지선은 매수와 대응을 시작하는 기준구간입니다. 지지선 도달 전에는 미리 사지 않고, 지지선을 포함한 아래 구간까지 나눠 매수합니다.',
    emphasis: '한 가격이 아닌 지지구간으로 판단',
    note: '지지선이 여러 개면 다음 지지선에서 가중치를 높일 수 있습니다. 이탈 여부는 종가를 기준으로 확인합니다.',
  ),
  CoreTradingRule(
    number: '04',
    category: '반등 수익실현',
    title: '바로 반등하면 5%부터 수익을 지킵니다',
    description:
        '지지선에서 바로 반등한 종목은 단기 수익매매로 진행합니다. 평균단가 대비 5% 이상에서 보유수량의 절반 이상을 매도합니다.',
    emphasis: '기본 목표 5% · 절반 이상 매도',
    note: '남은 물량은 추세와 수급을 보며 관리합니다. 바로 급등해도 별도 안내 없이 추격매수하지 않습니다.',
  ),
  CoreTradingRule(
    number: '05',
    category: '스윙 전환',
    title: '지지선 이탈 시 매매방식이 바뀝니다',
    description:
        '종가 기준 지지선 이탈 후 다음 거래일 흐름까지 확인합니다. 이후 계획된 분할매수로 평균단가를 낮추고 기존 지지선 회복을 기다립니다.',
    emphasis: '단기매매 → 스윙매매',
    note: '기존 지지선과 평균단가 대비 5% 가격 중 높은 가격을 목표로 합니다.',
  ),
  CoreTradingRule(
    number: '06',
    category: '멘징과 복리',
    title: '수익 종목이 계좌를 살립니다',
    description:
        '수익 종목을 전량 매도해 실현수익을 확보한 뒤, 회복 가능성이 낮은 부진 종목의 보유수량을 단계적으로 줄입니다.',
    emphasis: '실현수익으로 부진 종목 비중 축소',
    note: '수익금은 신규 진입, 멘징, 현금 확보에 상황별로 사용하며 종목별 최대비중과 현금 20% 원칙은 유지합니다.',
  ),
  CoreTradingRule(
    number: '07',
    category: '추가매수 중단',
    title: '분할매수는 무제한 물타기가 아닙니다',
    description:
        '종목별 최대금액에 도달하거나, 매수 근거가 훼손되거나, 핵심 지지선이 붕괴하거나, 방장이 중단을 안내하면 추가매수를 멈춥니다.',
    emphasis: '최대금액 도달 후 추가매수 금지',
    note: '핵심 지지선 붕괴는 다음 거래일 종가까지 확인합니다. 신용·미수·과도한 레버리지는 사용하지 않습니다.',
  ),
  CoreTradingRule(
    number: '08',
    category: '회원 금지행동',
    title: '계획 없는 매매는 연구소 매매가 아닙니다',
    description:
        '몰빵, 추격매수, 임의 물타기, 지지선 임의 변경, 방장 안내 없는 비중 확대를 하지 않습니다.',
    emphasis: '몰빵 · 추격 · 임의 물타기 금지',
    note: '수익 종목만 팔고 손실 종목만 남기지 않습니다. 개인매매와 연구소 추천매매는 반드시 구분해서 관리합니다.',
  ),
];

const List<DetailTradingRule> detailTradingRules = <DetailTradingRule>[
  DetailTradingRule(
    number: '01',
    title: '추천종목 선택과 보유종목 수',
    corePrinciple: '추천종목은 여러 개여도 실제 보유는 2종목을 원칙으로 하고 최대 3종목까지만 관리합니다.',
    paragraphs: <String>[
      '한 종목이 부진해도 다른 종목의 수익으로 비중을 줄일 수 있어야 하기 때문입니다. 종목이 너무 많으면 지지선, 평균단가, 추가매수 계획을 관리하기 어렵습니다.',
    ],
    goodAction: '핵심 추천종목의 우선순위를 참고해 2종목을 선택하고, 이미 3종목을 보유 중이면 신규 종목을 추가하지 않습니다.',
    warning: '추천종목이 새로 나올 때마다 모두 매수하거나 동일 테마 종목을 여러 개 겹쳐 보유하지 않습니다.',
  ),
  DetailTradingRule(
    number: '02',
    title: '종목별 비중과 현금 관리',
    corePrinciple: '종목별 최대 투자금액을 먼저 정하고 최초에는 10~20%만 진입합니다.',
    paragraphs: <String>[
      '핵심 추천종목에 더 높은 비중을 배정할 수 있지만, 한 번에 매수하지 않고 동일한 분할매수 원칙을 적용합니다.',
    ],
    example:
        '종목별 최대금액이 300만원이라면 최초 매수는 30만~60만원 수준입니다. 최소 70% 이상을 추가매수 자금으로 남기고, 전체 계좌에는 현금 20%를 유지합니다.',
  ),
  DetailTradingRule(
    number: '03',
    title: '지지선 진입과 분할매수',
    corePrinciple: '지지선은 반등을 보장하는 한 가격이 아니라 매수와 대응을 시작하는 지지구간입니다.',
    bullets: <String>[
      '지지선 도달 전에는 미리 매수하지 않습니다.',
      '지지선을 포함해 그 아래 구간까지 종목 변동성에 맞춰 나눠 매수합니다.',
      '지지선이 여러 개라면 1차 구간에서 일정 비율을 매수한 뒤 2차 지지선부터 가중치를 높일 수 있습니다.',
      '가까운 지지선은 하나의 지지구간으로 통합합니다.',
    ],
    example:
        '기존 지지선으로 회복했을 때 평균단가 대비 최소 5% 이상의 수익이 가능하도록 매수가격과 금액을 설계합니다.',
  ),
  DetailTradingRule(
    number: '04',
    title: '반등 시 수익실현',
    corePrinciple: '지지선에서 바로 반등하면 평균단가 대비 5% 이상에서 절반 이상을 매도합니다.',
    paragraphs: <String>[
      '5%는 고정 전량매도 가격이 아니라 수익실현을 시작하는 기준입니다. 10% 이상 급등하면 절반 이상을 매도하고 남은 물량만 추세에 따라 보유합니다.',
    ],
    warning: '최초 10~20%만 매수한 상태에서 바로 급등해도 별도 안내가 없다면 따라 사지 않습니다.',
  ),
  DetailTradingRule(
    number: '05',
    title: '지지선 이탈과 스윙 전환',
    corePrinciple: '종가 기준 지지선 이탈 후 다음 거래일 흐름까지 확인한 뒤 스윙매매로 전환합니다.',
    paragraphs: <String>[
      '계획된 분할매수로 평균단가를 낮추고, 기존 지지선과 평균단가 대비 5% 가격 중 높은 가격을 기본 목표로 합니다.',
    ],
    bullets: <String>[
      '기존 지지선 복귀 시 일부 매도합니다.',
      '수급이 평범하면 지지선 부근에서 대부분 또는 전량 정리합니다.',
      '외국인·기관 순매수가 확인되면 일부를 남겨 지지선 위에서 분할매도할 수 있습니다.',
      '회복 후 다시 종가 기준 지지선을 이탈하면 남은 물량을 전량 매도합니다.',
    ],
  ),
  DetailTradingRule(
    number: '06',
    title: '멘징과 복리식 계좌 운영',
    corePrinciple:
        '멘징은 수익 종목을 전량 매도해 확보한 실현수익으로 회복 가능성이 낮은 부진 종목의 보유수량을 단계적으로 줄이는 계좌관리입니다.',
    paragraphs: <String>[
      '멘징 대상은 수급 약화, 낮은 회복 가능성, 과도한 비중, 매수 근거 훼손 여부를 함께 판단합니다. 손실률이 가장 큰 종목을 무조건 먼저 처리하지 않습니다.',
    ],
    goodAction:
        '실현손익을 반영한 운용원금을 기준으로 다음 매매 규모를 정합니다. 재투자 비율과 증액 시점은 회원이 선택하되 현금 20%와 종목별 최대비중 원칙은 유지합니다.',
  ),
  DetailTradingRule(
    number: '07',
    title: '추가매수 중단과 위험관리',
    corePrinciple:
        '종목별 최대금액 도달, 핵심 지지선 붕괴, 중대한 매수근거 훼손, 방장의 중단 안내 시 추가매수를 멈춥니다.',
    paragraphs: <String>[
      '핵심 지지선 붕괴는 장중 움직임만으로 판단하지 않고 다음 거래일 종가까지 확인합니다.',
    ],
    example:
        '일반적인 단기 뉴스나 변동은 기존 계획을 유지할 수 있습니다. 다만 횡령·배임·거래정지 가능성처럼 매수 근거 자체를 훼손하는 중대한 악재는 추가매수 중단 사유로 봅니다.',
    warning: '신용·미수·과도한 레버리지, 최대금액 초과, 방장 안내 없는 임의 추가매수를 하지 않습니다.',
  ),
  DetailTradingRule(
    number: '08',
    title: '회원 실행 및 금지행동',
    corePrinciple:
        '우리 방의 매매는 종목을 맞히는 방식이 아니라 지지선, 분할매수, 비중조절, 수익실현과 멘징으로 계좌를 관리하는 방식입니다.',
    bullets: <String>[
      '사전에 안내된 가격에 분할주문을 준비합니다.',
      '매수가·수량·평균단가는 회원이 직접 관리합니다.',
      '개인매매와 연구소 추천매매를 구분합니다.',
      '매도 안내를 놓쳤다면 무리하게 재진입하지 말고 다음 안내를 기다립니다.',
      '몰빵, 추격매수, 무계획 물타기, 지지선 임의 변경을 하지 않습니다.',
      '수익 종목만 빨리 팔고 회복 가능성이 낮은 손실 종목만 남기지 않습니다.',
    ],
  ),
];

const List<EducationChecklistGroup> educationChecklistGroups =
    <EducationChecklistGroup>[
  EducationChecklistGroup(
    number: '01',
    title: '종목 선택',
    items: <String>[
      '연구소 추천종목 보유가 2종목 원칙, 최대 3종목 이내인가?',
      '동일 테마·업종을 과도하게 중복 보유하지 않았는가?',
      '이미 상승한 종목을 추격매수하고 있지 않은가?',
    ],
  ),
  EducationChecklistGroup(
    number: '02',
    title: '자금과 비중',
    items: <String>[
      '종목별 최대 투자금액을 미리 정했는가?',
      '최초 매수는 최대금액의 10~20%인가?',
      '추가매수 자금 70% 이상과 계좌 현금 20%를 남겼는가?',
    ],
  ),
  EducationChecklistGroup(
    number: '03',
    title: '지지선과 주문',
    items: <String>[
      '가격이 지지구간에 도달했는가?',
      '다음 지지선과 분할매수 가격을 정했는가?',
      '지지선 회복 시 평균단가 대비 5% 이상 수익이 가능한가?',
    ],
  ),
  EducationChecklistGroup(
    number: '04',
    title: '매도와 위험관리',
    items: <String>[
      '5% 이상 수익 시 절반 이상 매도할 계획이 있는가?',
      '최대금액·핵심 지지선 붕괴·중대한 악재의 중단기준을 확인했는가?',
      '방장 안내 없이 임의 추가매수하거나 신용·미수를 사용하지 않는가?',
    ],
  ),
];

const List<WelcomeEducationMessage> welcomeEducationMessages =
    <WelcomeEducationMessage>[
  WelcomeEducationMessage(
    title: '처음 이용하는 회원께',
    body:
        '지지저항연구소는 추천종목을 무조건 따라 사는 방이 아닙니다.\n\n지지선, 분할매수, 비중조절, 수익실현과 멘징을 통해 계좌를 관리하는 매매를 지향합니다.\n\n추천종목은 여러 개 제공될 수 있지만 실제 보유는 2종목을 원칙으로 하고 최대 3종목까지만 관리합니다. 매매 전 핵심 교육자료와 실전 확인사항을 반드시 읽어주세요.',
  ),
  WelcomeEducationMessage(
    title: '핵심 매매규칙',
    body:
        '1. 추천종목이 많아도 보유는 2종목 원칙, 최대 3종목\n2. 최초 매수는 종목별 최대금액의 10~20%\n3. 추가매수 자금은 최소 70%, 계좌 현금은 20% 유지\n4. 지지선에서 바로 반등하면 5% 이상에서 절반 이상 매도\n5. 종가 기준 지지선 이탈 후 다음 거래일 흐름을 확인해 스윙 전환\n6. 지지선 회복 시 일부 매도, 수급이 약하면 대부분 정리\n7. 수익 종목의 실현수익으로 부진 종목 비중을 줄이는 멘징\n8. 몰빵, 추격매수, 무계획 물타기, 신용·미수 금지',
  ),
  WelcomeEducationMessage(
    title: '회원 책임 및 주의사항',
    body:
        '연구소는 지지선과 대응전략을 제공하지만 실제 매수금액, 주문, 평균단가와 계좌관리는 회원 본인의 책임입니다.\n\n안내되지 않은 추격매수와 임의 추가매수는 연구소의 매매원칙과 다릅니다. 개인매매와 연구소 추천매매를 반드시 구분해 관리해주세요.',
  ),
];
