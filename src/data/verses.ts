import type { Verse } from '../types'

/**
 * Sample verses. Text is KJV (public domain).
 * Add new verses here. Each verse references Strong's keys defined in ./strongs.ts.
 * Commentary is paraphrased from Matthew Henry's Concise Commentary (public domain).
 */
export const VERSES: Verse[] = [
  {
    id: 'gen-1-1',
    reference: 'Genesis 1:1',
    testament: 'OT',
    text: 'In the beginning God created the heaven and the earth.',
    words: [
      { word: 'In' },
      { word: 'the' },
      { word: 'beginning', strongs: 'H7225' },
      { word: 'God', strongs: 'H430' },
      { word: 'created', strongs: 'H1254' },
      { word: 'the' },
      { word: 'heaven', strongs: 'H8064' },
      { word: 'and' },
      { word: 'the' },
      { word: 'earth', strongs: 'H776' }
    ],
    crossRefs: [
      { ref: 'John 1:1', preview: 'In the beginning was the Word…' },
      { ref: 'Hebrews 11:3', preview: 'The worlds were framed by the word of God.' },
      { ref: 'Psalm 33:6', preview: 'By the word of the LORD were the heavens made.' },
      { ref: 'Colossians 1:16', preview: 'By him were all things created.' }
    ],
    commentary: [
      'The plain account of creation overthrows all false notions. God is the first cause, before all worlds.',
      '"Created" — out of nothing, by mere act of will. The heavens and earth are the universe entire.',
      'See here the power, wisdom, and goodness of the Creator; learn to give him the glory due his name.'
    ]
  },
  {
    id: 'psa-23-1',
    reference: 'Psalm 23:1',
    testament: 'OT',
    text: 'The LORD is my shepherd; I shall not want.',
    words: [
      { word: 'The' },
      { word: 'LORD', strongs: 'H3068' },
      { word: 'is' },
      { word: 'my' },
      { word: 'shepherd', strongs: 'H7462' },
      { word: ';' },
      { word: 'I' },
      { word: 'shall' },
      { word: 'not' },
      { word: 'want', strongs: 'H2637' }
    ],
    crossRefs: [
      { ref: 'John 10:11', preview: 'I am the good shepherd.' },
      { ref: 'Isaiah 40:11', preview: 'He shall feed his flock like a shepherd.' },
      { ref: 'Ezekiel 34:11–12', preview: 'I will search and seek out my sheep.' },
      { ref: 'Philippians 4:19', preview: 'My God shall supply all your need.' }
    ],
    commentary: [
      'From this comfort the believer may draw: the LORD himself condescends to be shepherd.',
      'Under his care we cannot want what is truly good for us; he leads, feeds, protects, restores.',
      'A sheep is weak and prone to wander, yet under such a shepherd is perfectly safe.'
    ]
  },
  {
    id: 'isa-53-5',
    reference: 'Isaiah 53:5',
    testament: 'OT',
    text: 'But he was wounded for our transgressions, he was bruised for our iniquities: the chastisement of our peace was upon him; and with his stripes we are healed.',
    words: [
      { word: 'But' },
      { word: 'he' },
      { word: 'was' },
      { word: 'wounded', strongs: 'H2490' },
      { word: 'for' },
      { word: 'our' },
      { word: 'transgressions', strongs: 'H6588' },
      { word: ',' },
      { word: 'he' },
      { word: 'was' },
      { word: 'bruised', strongs: 'H1792' },
      { word: 'for' },
      { word: 'our' },
      { word: 'iniquities', strongs: 'H5771' },
      { word: ':' },
      { word: 'the' },
      { word: 'chastisement', strongs: 'H4148' },
      { word: 'of' },
      { word: 'our' },
      { word: 'peace', strongs: 'H7965' },
      { word: 'was' },
      { word: 'upon' },
      { word: 'him' },
      { word: ';' },
      { word: 'and' },
      { word: 'with' },
      { word: 'his' },
      { word: 'stripes', strongs: 'H2250' },
      { word: 'we' },
      { word: 'are' },
      { word: 'healed', strongs: 'H7495' },
      { word: '.' }
    ],
    crossRefs: [
      { ref: '1 Peter 2:24', preview: 'By whose stripes ye were healed.' },
      { ref: 'Romans 4:25', preview: 'Delivered for our offences.' },
      { ref: '2 Corinthians 5:21', preview: 'He hath made him to be sin for us.' },
      { ref: 'Galatians 3:13', preview: 'Christ hath redeemed us from the curse of the law.' }
    ],
    commentary: [
      'See here the cause of his sorrows: not his own sin, but ours. His sufferings make our peace.',
      'The atonement is set forth — wounded, bruised, chastised; and the result, that we are healed.',
      'Faith looks to the stripes of Christ as the spring of our spiritual recovery.'
    ]
  },
  {
    id: 'hos-2-19',
    reference: 'Hosea 2:19',
    testament: 'OT',
    text: 'And I will betroth thee unto me for ever; yea, I will betroth thee unto me in righteousness, and in judgment, and in lovingkindness, and in mercies.',
    words: [
      { word: 'And' },
      { word: 'I' },
      { word: 'will' },
      { word: 'betroth', strongs: 'H781' },
      { word: 'thee' },
      { word: 'unto' },
      { word: 'me' },
      { word: 'for' },
      { word: 'ever', strongs: 'H5769' },
      { word: ';' },
      { word: 'yea' },
      { word: ',' },
      { word: 'I' },
      { word: 'will' },
      { word: 'betroth', strongs: 'H781' },
      { word: 'thee' },
      { word: 'unto' },
      { word: 'me' },
      { word: 'in' },
      { word: 'righteousness', strongs: 'H6664' },
      { word: ',' },
      { word: 'and' },
      { word: 'in' },
      { word: 'judgment', strongs: 'H4941' },
      { word: ',' },
      { word: 'and' },
      { word: 'in' },
      { word: 'lovingkindness', strongs: 'H2617' },
      { word: ',' },
      { word: 'and' },
      { word: 'in' },
      { word: 'mercies', strongs: 'H7356' },
      { word: '.' }
    ],
    crossRefs: [
      { ref: 'Jeremiah 31:3', preview: 'I have loved thee with an everlasting love.' },
      { ref: '2 Corinthians 11:2', preview: 'Espoused you to one husband, to present you as a chaste virgin to Christ.' },
      { ref: 'Isaiah 54:5', preview: 'Thy Maker is thine husband.' },
      { ref: 'Revelation 19:7', preview: 'The marriage of the Lamb is come.' }
    ],
    commentary: [
      'God will not only return mercy, but renew the covenant as a marriage covenant — forever.',
      'It is grounded in righteousness and judgment, lest any think mercy ignores justice.',
      'Lovingkindness and mercies are the warm springs from which this covenant flows.'
    ]
  },
  {
    id: 'mat-6-33',
    reference: 'Matthew 6:33',
    testament: 'NT',
    text: 'But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.',
    words: [
      { word: 'But' },
      { word: 'seek', strongs: 'G2212' },
      { word: 'ye' },
      { word: 'first', strongs: 'G4412' },
      { word: 'the' },
      { word: 'kingdom', strongs: 'G932' },
      { word: 'of' },
      { word: 'God', strongs: 'G2316' },
      { word: ',' },
      { word: 'and' },
      { word: 'his' },
      { word: 'righteousness', strongs: 'G1343' },
      { word: ';' },
      { word: 'and' },
      { word: 'all' },
      { word: 'these' },
      { word: 'things' },
      { word: 'shall' },
      { word: 'be' },
      { word: 'added', strongs: 'G4369' },
      { word: 'unto' },
      { word: 'you' },
      { word: '.' }
    ],
    crossRefs: [
      { ref: 'Psalm 37:4', preview: 'Delight thyself also in the LORD.' },
      { ref: '1 Kings 3:11–13', preview: "Because thou hast asked wisdom, I have given thee riches also." },
      { ref: 'Luke 12:31', preview: 'Rather seek ye the kingdom of God.' },
      { ref: 'Romans 14:17', preview: 'The kingdom of God is righteousness, peace, and joy.' }
    ],
    commentary: [
      'Make God\'s kingdom your chief and first care — rule of grace within, and glory hereafter.',
      'The promise is large: necessaries shall be added; God can be trusted with the lesser things.',
      'Seek first, and seek above all; this dethrones the world from the heart.'
    ]
  },
  {
    id: 'jhn-3-16',
    reference: 'John 3:16',
    testament: 'NT',
    text: 'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
    words: [
      { word: 'For' },
      { word: 'God', strongs: 'G2316' },
      { word: 'so' },
      { word: 'loved', strongs: 'G25' },
      { word: 'the' },
      { word: 'world', strongs: 'G2889' },
      { word: ',' },
      { word: 'that' },
      { word: 'he' },
      { word: 'gave', strongs: 'G1325' },
      { word: 'his' },
      { word: 'only' },
      { word: 'begotten', strongs: 'G3439' },
      { word: 'Son', strongs: 'G5207' },
      { word: ',' },
      { word: 'that' },
      { word: 'whosoever', strongs: 'G3956' },
      { word: 'believeth', strongs: 'G4100' },
      { word: 'in' },
      { word: 'him' },
      { word: 'should' },
      { word: 'not' },
      { word: 'perish', strongs: 'G622' },
      { word: ',' },
      { word: 'but' },
      { word: 'have' },
      { word: 'everlasting', strongs: 'G166' },
      { word: 'life', strongs: 'G2222' },
      { word: '.' }
    ],
    crossRefs: [
      { ref: 'Romans 5:8', preview: 'God commendeth his love toward us.' },
      { ref: '1 John 4:9', preview: 'God sent his only begotten Son into the world.' },
      { ref: 'John 1:29', preview: 'Behold the Lamb of God.' },
      { ref: 'Romans 6:23', preview: 'The gift of God is eternal life.' }
    ],
    commentary: [
      'Here is the great love of God — vast, unmeasured; the world the object, the Son the gift.',
      '"Whosoever believeth": the door is wide, the way is one. Faith joins the soul to Christ.',
      'The contrast: perish, or have life everlasting — there is no third state.'
    ]
  },
  {
    id: 'rom-8-28',
    reference: 'Romans 8:28',
    testament: 'NT',
    text: 'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.',
    words: [
      { word: 'And' },
      { word: 'we' },
      { word: 'know', strongs: 'G1492' },
      { word: 'that' },
      { word: 'all' },
      { word: 'things' },
      { word: 'work' },
      { word: 'together', strongs: 'G4903' },
      { word: 'for' },
      { word: 'good', strongs: 'G18' },
      { word: 'to' },
      { word: 'them' },
      { word: 'that' },
      { word: 'love', strongs: 'G25' },
      { word: 'God', strongs: 'G2316' },
      { word: ',' },
      { word: 'to' },
      { word: 'them' },
      { word: 'who' },
      { word: 'are' },
      { word: 'the' },
      { word: 'called', strongs: 'G2822' },
      { word: 'according' },
      { word: 'to' },
      { word: 'his' },
      { word: 'purpose', strongs: 'G4286' },
      { word: '.' }
    ],
    crossRefs: [
      { ref: 'Genesis 50:20', preview: 'Ye thought evil; God meant it unto good.' },
      { ref: 'Jeremiah 29:11', preview: 'Thoughts of peace, and not of evil.' },
      { ref: 'Ephesians 1:11', preview: 'Predestinated according to the purpose of him.' },
      { ref: '2 Corinthians 4:17', preview: 'Light affliction worketh a far more exceeding weight of glory.' }
    ],
    commentary: [
      'A great support to the people of God: all things — adverse as well as pleasant — work for their good.',
      'The good intended is spiritual, conformity to Christ, more than any temporal comfort.',
      'The persons described: love God in return, and are effectually called according to his purpose.'
    ]
  },
  {
    id: 'eph-2-8',
    reference: 'Ephesians 2:8',
    testament: 'NT',
    text: 'For by grace are ye saved through faith; and that not of yourselves: it is the gift of God:',
    words: [
      { word: 'For' },
      { word: 'by' },
      { word: 'grace', strongs: 'G5485' },
      { word: 'are' },
      { word: 'ye' },
      { word: 'saved', strongs: 'G4982' },
      { word: 'through' },
      { word: 'faith', strongs: 'G4102' },
      { word: ';' },
      { word: 'and' },
      { word: 'that' },
      { word: 'not' },
      { word: 'of' },
      { word: 'yourselves' },
      { word: ':' },
      { word: 'it' },
      { word: 'is' },
      { word: 'the' },
      { word: 'gift', strongs: 'G1435' },
      { word: 'of' },
      { word: 'God', strongs: 'G2316' },
      { word: ':' }
    ],
    crossRefs: [
      { ref: 'Titus 3:5', preview: 'Not by works of righteousness which we have done.' },
      { ref: 'Romans 3:24', preview: 'Justified freely by his grace.' },
      { ref: 'Romans 6:23', preview: 'The gift of God is eternal life.' },
      { ref: '2 Timothy 1:9', preview: 'Saved us, and called us with an holy calling.' }
    ],
    commentary: [
      'Salvation is wholly of grace; faith is the receiving hand, not the price.',
      'Even the faith by which we receive is God\'s gift — boasting is excluded.',
      'Mark the source (grace), the means (faith), the cause (God\'s gift).'
    ]
  }
]

export const VERSE_INDEX: Record<string, Verse> = Object.fromEntries(
  VERSES.map(v => [v.id, v])
)
