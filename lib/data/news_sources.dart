import '../services/content_store.dart';

/// مصدر أخبار. لكل مصدر أكثر من رابط تغذية محتمل، ويُعتمد أول مصدر يعيد أخبارًا.
class NewsSource {
  final String name;
  final String? site;
  final List<String> feeds;
  final int limit;
  const NewsSource(this.name, this.feeds, {this.site, this.limit = 10});
}

String _gnews(String query, {String lang = 'ar', String country = 'LY'}) =>
    'https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}'
    '&hl=$lang&gl=$country&ceid=$country:$lang';

/// مصادر الأخبار المضمّنة. المصادر الرسمية مفصولة عن الإعلام المستقل،
/// مع إبقاء أخبار جوجل كطبقة تجميع احتياطية عندما لا يتوفر RSS مباشر.
final List<NewsSource> defaultNewsSources = [
  NewsSource('أخبار ليبيا', [_gnews('ليبيا when:1d')], limit: 25),
  NewsSource('عاجل', [_gnews('ليبيا عاجل when:1d')], limit: 15),
  NewsSource(
      'طرابلس وبنغازي',
      [
        _gnews('طرابلس OR بنغازي OR مصراتة OR سبها when:2d'),
      ],
      limit: 15),
  NewsSource(
      'اقتصاد',
      [
        _gnews(
          'الدينار الليبي OR مصرف ليبيا المركزي OR المؤسسة الوطنية للنفط when:3d',
        ),
      ],
      limit: 15),
  NewsSource(
      'Libya News',
      [
        _gnews('Libya when:1d', lang: 'en', country: 'US'),
      ],
      limit: 12),

  // ------------------------- مصادر رسمية -------------------------
  NewsSource(
    'وكالة الأنباء الليبية - وال',
    [_gnews('site:lana.gov.ly ليبيا when:2d')],
    site: 'https://lana.gov.ly/?lang=ar',
    limit: 15,
  ),
  NewsSource(
    'مجلس النواب - أخبار',
    [_gnews('site:parl.ly ليبيا مجلس النواب when:7d')],
    site: 'https://parl.ly/',
    limit: 12,
  ),
  NewsSource(
    'المجلس الأعلى للدولة - أخبار',
    [_gnews('site:hcs.gov.ly ليبيا المجلس الأعلى للدولة when:7d')],
    site: 'https://hcs.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'وزارة الدفاع - أخبار',
    [_gnews('site:mod.gov.ly ليبيا وزارة الدفاع when:7d')],
    site: 'https://www.mod.gov.ly/category/last-news/',
    limit: 12,
  ),
  NewsSource(
    'وزارة الداخلية - أخبار',
    [_gnews('site:moi.gov.ly ليبيا وزارة الداخلية when:7d')],
    site: 'https://www.moi.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'وزارة الصحة - أخبار',
    [_gnews('site:moh.gov.ly ليبيا وزارة الصحة when:7d')],
    site: 'https://moh.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'مصلحة الجوازات - أخبار',
    [_gnews('site:lpa.gov.ly ليبيا الجوازات when:7d')],
    site: 'https://lpa.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'مصلحة الجمارك - أخبار',
    [_gnews('site:customs.gov.ly ليبيا الجمارك when:7d')],
    site: 'https://customs.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'مصلحة المطارات - أخبار',
    [_gnews('site:laa.gov.ly ليبيا المطارات when:7d')],
    site: 'https://laa.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'ديوان المحاسبة - أخبار',
    [_gnews('site:audit.gov.ly ليبيا ديوان المحاسبة when:7d')],
    site: 'https://www.audit.gov.ly/ar/',
    limit: 12,
  ),
  NewsSource(
    'مصرف ليبيا المركزي',
    [
      _gnews('site:cbl.gov.ly مصرف ليبيا المركزي when:7d'),
      'https://cbl.gov.ly/feed/',
    ],
    site: 'https://cbl.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'المؤسسة الوطنية للنفط',
    [_gnews('site:noc.ly المؤسسة الوطنية للنفط ليبيا when:7d')],
    site: 'https://noc.ly/',
    limit: 12,
  ),

  NewsSource(
    'وزارة الخارجية - أخبار',
    [_gnews('site:foreign.gov.ly ليبيا وزارة الخارجية when:7d')],
    site: 'https://foreign.gov.ly/MOFA/',
    limit: 12,
  ),
  NewsSource(
    'وزارة العدل - أخبار',
    [_gnews('site:aladel.gov.ly ليبيا وزارة العدل قوانين when:7d')],
    site: 'https://aladel.gov.ly/home/',
    limit: 12,
  ),
  NewsSource(
    'وزارة المالية - أخبار',
    [_gnews('site:mof.gov.ly ليبيا وزارة المالية when:7d')],
    site: 'https://mof.gov.ly/blog/',
    limit: 12,
  ),
  NewsSource(
    'وزارة العمل - أخبار',
    [_gnews('site:labour.gov.ly ليبيا وزارة العمل when:7d')],
    site: 'https://labour.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'وزارة التعليم العالي - أخبار',
    [_gnews('site:mohe.edu.ly ليبيا التعليم العالي when:7d')],
    site: 'https://www.mohe.edu.ly/',
    limit: 12,
  ),
  NewsSource(
    'وزارة الحكم المحلي - أخبار',
    [_gnews('site:lgm.gov.ly ليبيا وزارة الحكم المحلي when:7d')],
    site: 'https://www.lgm.gov.ly/',
    limit: 12,
  ),
  NewsSource(
    'أخبار الجيش الليبي - بحث متعدد المصادر',
    [_gnews('ليبيا الجيش الليبي أخبار when:3d')],
    site: 'https://www.mod.gov.ly/category/last-news/',
    limit: 15,
  ),

  // ------------------------- إعلام مستقل -------------------------
  const NewsSource(
      'عين ليبيا',
      [
        'https://www.eanlibya.com/feed/',
      ],
      site: 'https://www.eanlibya.com/'),
  const NewsSource(
      'ليبيا هيرالد',
      [
        'https://libyaherald.com/feed',
      ],
      site: 'https://libyaherald.com/'),
  const NewsSource(
      'بوابة الوسط',
      [
        'https://alwasat.ly/rss',
        'https://alwasat.ly/feed',
      ],
      site: 'https://alwasat.ly/'),
  const NewsSource(
      'ليبيا أوبزرفر',
      [
        'https://www.libyaobserver.ly/rss.xml',
        'https://www.libyaobserver.ly/feed',
      ],
      site: 'https://www.libyaobserver.ly/'),
  const NewsSource(
      'ليبيا ريفيو',
      [
        'https://libyareview.com/feed/',
      ],
      site: 'https://libyareview.com/'),
  const NewsSource(
      'المرصد',
      [
        'https://almarsad.co/feed/',
      ],
      site: 'https://almarsad.co/'),
  const NewsSource(
      'ليبيا الأحرار',
      [
        'https://libyaalahrar.net/feed/',
      ],
      site: 'https://libyaalahrar.net/'),
];

List<NewsSource> get newsSources => ContentStore.instance.newsSources;

List<NewsSource> get newsSourcesWithSite =>
    newsSources.where((s) => s.site != null).toList();
