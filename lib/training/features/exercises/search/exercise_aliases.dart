/// Mapa completo de sinónimos para búsqueda de ejercicios
/// Soporta español, inglés y abreviaturas comunes
const Map<String, List<String>> exerciseAliases = {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRESS DE PECHO / BENCH PRESS
  // ═══════════════════════════════════════════════════════════════════════════
  'press banca': ['press de pecho', 'bench press', 'barbell bench press', 'bp', 'press plano', 'chest press'],
  'press de pecho': ['press banca', 'bench press', 'press plano'],
  'bench press': ['press banca', 'press de pecho', 'bp'],
  'barbell bench press': ['press banca', 'press de pecho'],
  'bp': ['bench press', 'press banca'],
  'press plano': ['press banca', 'bench press'],
  'chest press': ['press pecho', 'press de pecho'],
  
  // Variantes
  'press inclinado': ['incline bench press', 'incline press'],
  'incline bench press': ['press inclinado', 'press banca inclinado'],
  'press declinado': ['decline bench press', 'decline press'],
  'decline bench press': ['press declinado', 'press banca declinado'],
  
  // Short forms
  'banca': ['press banca', 'press de banca', 'bench press'],
  'banco': ['press banca', 'fondos en banco'],

  // ═══════════════════════════════════════════════════════════════════════════
  // SENTADILLA / SQUAT
  // ═══════════════════════════════════════════════════════════════════════════
  'sentadilla': ['squat', 'sentadillas', 'back squat', 'squat libre'],
  'squat': ['sentadilla', 'sentadillas', 'back squat'],
  'sentadillas': ['squat', 'sentadilla'],
  'back squat': ['sentadilla', 'squat trasera'],
  'squat libre': ['sentadilla libre', 'free squat'],
  
  // Variantes
  'front squat': ['sentadilla frontal', 'squat frontal'],
  'sentadilla frontal': ['front squat', 'squat frontal'],
  'goblet squat': ['sentadilla goblet', 'squat con mancuerna'],
  'sentadilla goblet': ['goblet squat'],
  'hack squat': ['sentadilla hack', 'máquina hack'],
  'sentadilla hack': ['hack squat'],
  'sissy squat': ['sentadilla sissy'],
  'bulgarian split squat': ['sentadilla búlgara', 'split squat'],
  'sentadilla bulgara': ['bulgarian split squat', 'split squat'],
  'split squat': ['sentadilla dividida', 'sentadilla búlgara'],
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PESO MUERTO / DEADLIFT
  // ═══════════════════════════════════════════════════════════════════════════
  'peso muerto': ['deadlift', 'dl', 'peso muerto convencional'],
  'deadlift': ['peso muerto', 'dl', 'levantamiento tierra'],
  'dl': ['deadlift', 'peso muerto'],
  'levantamiento tierra': ['deadlift', 'peso muerto'],
  
  // Variantes
  'peso muerto rumano': ['romanian deadlift', 'rdl', 'peso muerto rumanesco'],
  'romanian deadlift': ['peso muerto rumano', 'rdl'],
  'rdl': ['romanian deadlift', 'peso muerto rumano'],
  'sumo deadlift': ['peso muerto sumo'],
  'peso muerto sumo': ['sumo deadlift'],
  'trap bar deadlift': ['peso muerto barra hexagonal'],
  'peso muerto hexagonal': ['trap bar deadlift'],
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DOMINADAS / PULL UPS
  // ═══════════════════════════════════════════════════════════════════════════
  'dominada': ['pull up', 'pull-up', 'dominadas', 'chin up', 'barra fija'],
  'dominadas': ['pull up', 'pull-up', 'chin up', 'dominada'],
  'pull up': ['dominada', 'dominadas', 'pull-up'],
  'pull-up': ['dominada', 'dominadas'],
  'chin up': ['dominada supina', 'dominada'],
  'barra fija': ['dominada', 'dominadas'],
  
  // Variantes
  'muscle up': ['dominada completa'],
  'pull over': ['pullover'],
  
  // ═══════════════════════════════════════════════════════════════════════════
  // JALÓN / PULLDOWN
  // ═══════════════════════════════════════════════════════════════════════════
  'jalon': ['pulldown', 'lat pulldown', 'jalón al pecho'],
  'jalón': ['pulldown', 'lat pulldown', 'jalón al pecho'],
  'pulldown': ['jalón', 'jalón al pecho', 'lat pulldown'],
  'lat pulldown': ['jalón', 'jalón al pecho'],
  'jalon al pecho': ['lat pulldown', 'pulldown'],
  'jalón al pecho': ['lat pulldown', 'pulldown'],
  
  // Variantes
  'close grip pulldown': ['jalón agarre cerrado'],
  'jalon agarre cerrado': ['close grip pulldown'],
  'v-bar pulldown': ['jalón barra v'],

  // ═══════════════════════════════════════════════════════════════════════════
  // REMO / ROW
  // ═══════════════════════════════════════════════════════════════════════════
  'remo': ['row', 'remo con barra', 'barbell row'],
  'row': ['remo', 'remo con barra'],
  'remo con barra': ['barbell row', 'bent over row', 'row'],
  'barbell row': ['remo con barra', 'bent over row'],
  'bent over row': ['remo con barra', 'barbell row'],
  
  // Variantes
  't-bar row': ['remo t', 'remo en t'],
  'remo t': ['t-bar row'],
  'dumbbell row': ['remo con mancuerna', 'remo mancuerna'],
  'remo con mancuerna': ['dumbbell row', 'remo mancuerna'],
  'seated row': ['remo sentado', 'remo en polea'],
  'remo sentado': ['seated row', 'seated cable row'],
  'cable row': ['remo en polea'],
  'remo en polea': ['cable row', 'seated row'],
  'pendlay row': ['remo pendlay'],
  'face pull': ['remo a la cara', 'facepull'],
  'remo a la cara': ['face pull', 'facepull'],

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESS MILITAR / OVERHEAD PRESS
  // ═══════════════════════════════════════════════════════════════════════════
  'press militar': ['overhead press', 'military press', 'press hombros', 'ohp', 'press de hombros'],
  'overhead press': ['press militar', 'press hombros', 'ohp'],
  'military press': ['press militar', 'press de hombros'],
  'ohp': ['overhead press', 'press militar', 'press hombros'],
  'press hombros': ['overhead press', 'press militar', 'shoulder press'],
  'press de hombros': ['shoulder press', 'overhead press'],
  'shoulder press': ['press hombros', 'press militar'],
  
  // Variantes
  'arnold press': ['press arnold'],
  'press arnold': ['arnold press'],
  'push press': ['push press', 'press con impulso'],

  // ═══════════════════════════════════════════════════════════════════════════
  // CURL / CURL DE BÍCEPS
  // ═══════════════════════════════════════════════════════════════════════════
  'curl': ['curl bíceps', 'curl de bíceps', 'bicep curl', 'curl de biceps'],
  'curl biceps': ['curl de bíceps', 'bicep curl'],
  'curl de biceps': ['bicep curl', 'curl'],
  'bicep curl': ['curl de bíceps', 'curl bíceps'],
  'biceps curl': ['curl de bíceps'],
  
  // Variantes
  'hammer curl': ['curl martillo', 'curl neutro'],
  'curl martillo': ['hammer curl', 'curl neutro'],
  'concentration curl': ['curl concentración', 'curl scott'],
  'curl concentracion': ['concentration curl'],
  'preacher curl': ['curl predicador', 'curl en banco scott'],
  'curl predicador': ['preacher curl', 'curl scott'],
  'incline curl': ['curl en banco inclinado'],
  'drag curl': ['curl arrastre'],

  // ═══════════════════════════════════════════════════════════════════════════
  // EXTENSIONES / EXTENSION TRICEPS
  // ═══════════════════════════════════════════════════════════════════════════
  'extension': ['extension triceps', 'extensión de tríceps'],
  'extension triceps': ['extensión tríceps', 'tricep extension'],
  'extension de triceps': ['tricep extension', 'triceps extension'],
  'tricep extension': ['extensión de tríceps', 'extension triceps'],
  'triceps extension': ['extensión de tríceps'],
  
  // Variantes
  'skullcrusher': ['extensión francesa', 'press francés', 'candlestick'],
  'skull crusher': ['extensión francesa', 'press francés'],
  'extensión francesa': ['skullcrusher', 'candlestick'],
  'extension francesa': ['skullcrusher'],
  'press frances': ['skullcrusher', 'extensión francesa'],
  'cable pushdown': ['extensión polea', 'pushdown'],
  'pushdown': ['extensión polea', 'extension en polea'],
  'diamond push up': ['flexión diamante', 'push up diamante'],
  'flexion diamante': ['diamond push up'],

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVACIONES / RAISES
  // ═══════════════════════════════════════════════════════════════════════════
  'elevacion lateral': ['lateral raise', 'elevación lateral', 'vuelos laterales'],
  'elevación lateral': ['lateral raise', 'vuelos laterales'],
  'lateral raise': ['elevación lateral', 'vuelos laterales'],
  'vuelos laterales': ['lateral raise', 'elevación lateral'],
  
  'elevacion frontal': ['front raise', 'elevación frontal'],
  'elevación frontal': ['front raise'],
  'front raise': ['elevación frontal'],
  
  'rear delt fly': ['pájaro posterior', 'vuelo posterior'],
  'pajaro posterior': ['rear delt fly', 'rear deltoid fly'],
  'shrugs': ['encogimientos', 'shrugs trapecio'],
  'encogimientos': ['shrugs', 'shrug'],

  // ═══════════════════════════════════════════════════════════════════════════
  // FLEXIONES / PUSH UPS
  // ═══════════════════════════════════════════════════════════════════════════
  'flexion': ['push up', 'push-up', 'flexiones', 'lagartija'],
  'flexiones': ['push up', 'push-up', 'lagartijas'],
  'push up': ['flexión', 'flexiones', 'push-up'],
  'push-up': ['flexión', 'flexiones'],
  'lagartija': ['flexión', 'push up'],
  'lagartijas': ['flexiones', 'push ups'],
  
  // Variantes
  'dips': ['fondos', 'fondos en paralelas'],
  'fondos': ['dips', 'parallel dips'],
  'fondos en paralelas': ['dips', 'parallel bar dips'],
  'fondos en banco': ['bench dips', 'tricep dips'],

  // ═══════════════════════════════════════════════════════════════════════════
  // ABDOMINALES / CORE
  // ═══════════════════════════════════════════════════════════════════════════
  'abdominales': ['abs', 'crunches', 'abdominal'],
  'abs': ['abdominales', 'abdominal'],
  'crunch': ['crunch abdominal', 'abdominal'],
  'crunches': ['abdominales'],
  'plancha': ['plank'],
  'plank': ['plancha'],
  
  // Variantes
  'leg raise': ['elevación piernas', 'elevadion piernas'],
  'elevacion piernas': ['leg raise'],
  'hanging leg raise': ['elevación piernas colgado'],
  'russian twist': ['giros rusos', 'twist ruso'],
  'giros rusos': ['russian twist'],
  'dragon flag': ['bandera dragón'],
  'ab wheel': ['rueda abdominal', 'wheel'],
  'rueda abdominal': ['ab wheel', 'ab roller'],

  // ═══════════════════════════════════════════════════════════════════════════
  // MÚSCULOS / MUSCLE GROUPS
  // ═══════════════════════════════════════════════════════════════════════════
  'pecho': ['pectoral', 'pectorales', 'chest', 'tórax'],
  'pectoral': ['pecho', 'chest'],
  'pectorales': ['pecho', 'chest'],
  'chest': ['pecho', 'tórax'],
  'torax': ['pecho', 'chest'],
  
  'espalda': ['back', 'dorso', 'lats', 'latissimus'],
  'back': ['espalda', 'dorso'],
  'dorso': ['espalda', 'back'],
  'lats': ['dorsal', 'dorsales'],
  'latissimus': ['dorsal ancho'],
  
  'piernas': ['legs', 'lower body', 'tren inferior', 'pierna'],
  'legs': ['piernas', 'tren inferior'],
  'pierna': ['leg', 'piernas'],
  'cuadriceps': ['cuádriceps', 'quads', 'muslo anterior'],
  'cuádriceps': ['quadriceps', 'quads'],
  'quads': ['cuádriceps'],
  'femoral': ['isquios', 'isquiotibiales', 'hamstrings'],
  'femorales': ['isquiotibiales', 'hamstrings'],
  'isquios': ['isquiotibiales', 'hamstrings', 'femoral'],
  'isquiotibiales': ['hamstrings', 'femorales'],
  'hamstrings': ['isquiotibiales', 'femorales'],
  'gluteo': ['glúteo', 'glutes', 'glute'],
  'glúteo': ['glute', 'glutes'],
  'glutes': ['glúteos'],
  'pantorrilla': ['gemelos', 'soleo', 'calves', 'pantorrillas'],
  'pantorrillas': ['calves', 'gemelos'],
  'gemelos': ['pantorrillas', 'calves'],
  'calves': ['pantorrillas', 'gemelos'],
  
  'hombros': ['shoulders', 'deltoides', 'delts', 'hombro'],
  'shoulders': ['hombros', 'deltoides'],
  'deltoides': ['hombros', 'shoulders', 'delts'],
  'delts': ['deltoides', 'hombros'],
  'hombro': ['shoulder', 'deltoides'],
  
  'biceps': ['bíceps', 'bis'],
  'bíceps': ['biceps', 'bis'],
  'bis': ['bíceps', 'biceps'],
  
  'triceps': ['tríceps', 'tris'],
  'tríceps': ['triceps', 'tris'],
  'tris': ['tríceps', 'triceps'],
  
  'trapecio': ['traps', 'trap', 'trapecios'],
  'traps': ['trapecio', 'trapecios'],
  
  'antebrazo': ['forearm', 'forearms'],
  'antebrazos': ['forearms'],

  // ═══════════════════════════════════════════════════════════════════════════
  // EQUIPAMIENTO / EQUIPMENT
  // ═══════════════════════════════════════════════════════════════════════════
  'mancuerna': ['dumbbell', 'mancuernas'],
  'mancuernas': ['dumbbells'],
  'dumbbell': ['mancuerna', 'mancuernas'],
  'dumbbells': ['mancuernas'],
  
  'barra': ['barbell', 'barra libre', 'bar'],
  'barra libre': ['barbell', 'barbell free'],
  'barbell': ['barra', 'barra libre'],
  
  'polea': ['cable', 'máquina', 'poleas'],
  'poleas': ['cables', 'máquina'],
  'cable': ['polea', 'máquina'],
  'cables': ['poleas'],
  'maquina': ['machine', 'máquina', 'polea'],
  'máquina': ['machine', 'maquina'],
  'machine': ['máquina', 'maquina'],
  
  'smith': ['máquina smith', 'smith machine'],
  'smith machine': ['máquina smith'],
  'maquina smith': ['smith machine'],
  
  'cuerda': ['rope'],
  'rope': ['cuerda'],
  'landmine': ['mina terrestre'],
  'kettlebell': ['pesa rusa', 'kb'],
  'pesa rusa': ['kettlebell', 'kb'],
  'kb': ['kettlebell', 'pesa rusa'],
  
  'trx': ['suspension', 'entrenamiento suspension'],
  'suspension': ['trx'],
};
