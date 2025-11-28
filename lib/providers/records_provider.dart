import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recolle/models/record.dart';

final recordsProvider = Provider<List<Record>>((ref) {
  return [
    Record(
      id: '1',
      type: RecordType.live,
      title: 'DOME TOUR 2024',
      artistOrAuthor: 'ONE OK ROCK',
      date: DateTime(2024, 11, 14),
      ticketImageUrl: 'https://placehold.jp/150x150.png?text=LIVE',
      ticketSource: 'e+',
      setlist: '1. We are\n2. Taking Off\n3. The Beginning...',
      mcMemo: 'Takaが「最高だ！」と言っていた。',
      impressions: '熱気がすごかった。また行きたい！',
    ),
    Record(
      id: '2',
      type: RecordType.movie,
      title: '君たちはどう生きるか',
      artistOrAuthor: '宮崎駿',
      date: DateTime(2024, 10, 20),
      ticketImageUrl: 'https://placehold.jp/150x150.png?text=MOVIE',
      ticketSource: 'TOHOシネマズ',
      impressions: '考えさせられる内容だった。映像美が素晴らしい。',
    ),
    Record(
      id: '3',
      type: RecordType.book,
      title: 'ノルウェイの森',
      artistOrAuthor: '村上春樹',
      date: DateTime(2024, 9, 15),
      ticketImageUrl: 'https://placehold.jp/150x150.png?text=BOOK',
      impressions: '静かで深い物語。何度も読み返したい。',
    ),
    Record(
      id: '4',
      type: RecordType.live,
      title: 'King Gnu Stadium Live',
      artistOrAuthor: 'King Gnu',
      date: DateTime(2024, 5, 20),
      ticketImageUrl: 'https://placehold.jp/150x150.png?text=LIVE2',
      ticketSource: 'ローチケ',
      setlist: '1. SPECIALZ\n2. 一途\n3. 逆夢',
      mcMemo: '井口さんが面白かった。',
      impressions: '雨だったけど最高だった。',
    ),
    Record(
      id: '5',
      type: RecordType.other,
      title: 'デザイン展',
      artistOrAuthor: '美術館',
      date: DateTime(2024, 8, 10),
      ticketImageUrl: 'https://placehold.jp/150x150.png?text=OTHER',
      impressions: '刺激を受けた。',
    ),
  ];
});

