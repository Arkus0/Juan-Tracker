#!/usr/bin/env python3
"""
Script para añadir descripciones a ejercicios que no las tienen.
Genera descripciones informativas basadas en el tipo de ejercicio.
"""
import json
from pathlib import Path

# Descripciones por ejercicio específico (prioridad alta)
SPECIFIC_DESCRIPTIONS = {
    # PECHO
    "Press banca con maquina": "Versión guiada del press banca. Ideal para principiantes o para ir al fallo con seguridad sin necesidad de spotter.",
    "Press inclinado con barra": "Enfatiza la porción clavicular (superior) del pectoral. Usa un ángulo de 30-45° para máximo estímulo.",
    "Press inclinado con mancuernas": "Mayor rango de movimiento que la barra. Permite mayor estiramiento y contracción del pecho superior.",
    "Press inclinado con maquina": "Versión guiada del press inclinado. Mantén los codos a 45° del torso para proteger los hombros.",
    "Press declinado con barra": "Enfatiza la porción inferior del pectoral. Requiere banco declinado y preferiblemente un spotter.",
    "Press declinado con mancuernas": "Trabaja el pecho inferior con mayor rango de movimiento. Control en la bajada es clave.",
    "Press declinado con maquina": "Versión segura del press declinado. Bueno para series al fallo sin riesgo.",
    "Aperturas con mancuernas": "Ejercicio de aislamiento para el pecho. Mantén una ligera flexión de codos durante todo el movimiento.",
    "Aperturas inclinadas": "Aperturas en banco inclinado para enfatizar el pecho superior. No bajes más allá de la línea del pecho.",
    "Aperturas declinadas": "Aperturas en banco declinado para el pecho inferior. Contrae fuerte en la parte superior.",
    "Aperturas en polea alta": "Cruces de poleas desde arriba. Excelente para el pecho inferior y línea media del pectoral.",
    "Aperturas en polea baja": "Cruces de poleas desde abajo. Enfatiza el pecho superior y la porción clavicular.",
    "Aperturas en polea media": "Cruces a la altura del pecho. Trabajo equilibrado de todo el pectoral.",
    "Contractor de pecho (pec deck)": "Máquina de aislamiento puro para el pecho. Mantén la contracción 1-2 segundos en cada repetición.",
    "Pullover con mancuerna": "Trabaja pecho, dorsales y serratos. Mantén los brazos casi extendidos y baja hasta sentir estiramiento.",
    "Pullover en polea": "Versión con tensión constante del pullover. Excelente para el desarrollo del pecho y dorsales.",
    "Fondos en paralelas (pecho)": "Inclina el torso hacia adelante y codos hacia afuera para enfatizar el pecho sobre el tríceps.",
    "Push-ups (flexiones)": "Ejercicio fundamental de peso corporal. Mantén el core apretado y el cuerpo en línea recta.",
    "Push-ups inclinadas": "Flexiones con manos elevadas. Más fácil que la versión estándar, ideal para principiantes.",
    "Push-ups declinadas": "Flexiones con pies elevados. Aumenta la dificultad y enfatiza el pecho superior.",
    
    # ESPALDA
    "Dominadas": "Ejercicio rey para la espalda. Agarre prono, tira de los codos hacia abajo y atrás.",
    "Dominadas con agarre cerrado": "Enfatiza los dorsales en su porción inferior y los bíceps. Agarre a la anchura de los hombros.",
    "Dominadas supinas (chin-ups)": "Mayor activación del bíceps. Excelente para desarrollar fuerza de tracción.",
    "Dominadas neutras": "Agarre con palmas enfrentadas. Posición más natural para los hombros.",
    "Dominadas lastradas": "Añade peso para progresar cuando las dominadas normales sean fáciles. Usa cinturón de lastre.",
    "Dominadas asistidas": "Versión con asistencia (banda o máquina). Ideal para progresar hacia dominadas completas.",
    "Jalón al pecho": "Simula la dominada en máquina. Tira hacia la clavícula manteniendo el pecho alto.",
    "Jalón tras nuca": "Variante con mayor énfasis en la porción superior del dorsal. Requiere buena movilidad de hombros.",
    "Jalón con agarre cerrado": "Mayor rango de movimiento y énfasis en dorsales inferiores. Agarre supino o neutro.",
    "Jalón con agarre ancho": "Enfatiza la anchura de la espalda. Tira los codos hacia abajo y hacia los costados.",
    "Jalón con agarre neutro": "Posición natural de muñecas. Buen compromiso entre anchura y grosor de espalda.",
    "Remo con barra": "Ejercicio compuesto fundamental. Mantén la espalda recta y tira hacia el abdomen bajo.",
    "Remo con mancuerna": "Permite mayor rango de movimiento unilateral. Apoya una mano en banco para estabilidad.",
    "Remo en polea baja": "Remo sentado con cable. Mantén el pecho alto y tira hacia el ombligo.",
    "Remo en máquina": "Versión guiada del remo. Permite concentrarse en la contracción sin preocuparse del equilibrio.",
    "Remo T-bar": "Remo con barra en esquina o máquina T. Excelente para grosor de espalda media.",
    "Remo Pendlay": "Remo estricto desde el suelo en cada rep. Desarrolla fuerza explosiva de tracción.",
    "Remo Seal": "Remo tumbado en banco elevado. Elimina el impulso y aísla la espalda completamente.",
    "Remo Meadows": "Remo unilateral con barra landmine. Gran rango de movimiento y estiramiento del dorsal.",
    "Remo Yates": "Remo con torso más erguido (45-70°). Menor estrés lumbar que el remo tradicional.",
    "Face pulls": "Ejercicio para deltoides posterior y rotadores externos. Tira hacia la cara con codos altos.",
    "Encogimientos con barra": "Encoge los hombros verticalmente. No rotes los hombros, solo sube y baja.",
    "Encogimientos con mancuernas": "Versión con mancuernas para mayor rango. Mantén los brazos rectos a los lados.",
    "Encogimientos en máquina": "Versión guiada. Permite usar cargas más pesadas con seguridad.",
    "Peso muerto": "Ejercicio fundamental de tracción. Mantén la espalda neutra y empuja el suelo con los pies.",
    "Peso muerto rumano": "Énfasis en isquiotibiales y glúteos. Mantén las rodillas ligeramente flexionadas.",
    "Peso muerto sumo": "Stance ancho con pies hacia afuera. Reduce el rango de movimiento y enfatiza cuádriceps.",
    "Peso muerto con trap bar": "Versión más segura para la espalda baja. El peso está alineado con el centro de gravedad.",
    "Buenos días": "Flexión de cadera con barra en espalda. Excelente para isquios y erectores espinales.",
    "Hiperextensiones": "Extensión de cadera en banco romano. Trabaja erectores espinales, glúteos e isquios.",
    "Hiperextensiones inversas": "Extensión de cadera con torso fijo. Mayor énfasis en glúteos e isquiotibiales.",
    
    # HOMBROS
    "Press militar con barra": "Press vertical fundamental. Mantén el core apretado y no arquees la espalda.",
    "Press militar con mancuernas": "Mayor rango de movimiento y trabajo estabilizador. Permite rotación natural.",
    "Press militar en máquina": "Versión guiada del press de hombros. Ideal para ir al fallo con seguridad.",
    "Press Arnold": "Rotación durante el movimiento para mayor activación del deltoides. Inventado por Schwarzenegger.",
    "Press tras nuca": "Requiere excelente movilidad de hombros. Usa menos peso que el press frontal.",
    "Elevaciones laterales con mancuernas": "Aislamiento del deltoides lateral. Ligera inclinación hacia adelante, codos ligeramente flexionados.",
    "Elevaciones laterales en polea": "Tensión constante durante todo el rango. Excelente para el deltoides lateral.",
    "Elevaciones laterales en máquina": "Versión guiada de las elevaciones. Permite concentrarse en la contracción.",
    "Elevaciones frontales con mancuernas": "Trabaja el deltoides anterior. Alterna brazos o hazlo simultáneo.",
    "Elevaciones frontales con barra": "Versión bilateral para el deltoides anterior. Mantén los codos ligeramente flexionados.",
    "Elevaciones frontales en polea": "Tensión constante en el deltoides anterior. Usa agarre bajo o cuerda.",
    "Pájaros con mancuernas": "Aislamiento del deltoides posterior. Inclínate hacia adelante y levanta hacia los lados.",
    "Pájaros en polea": "Versión con cable para el deltoides posterior. Cruza los cables para mayor rango.",
    "Pájaros en máquina (pec deck inverso)": "Aislamiento guiado del deltoides posterior. Mantén la contracción 1-2 segundos.",
    "Remo al mentón": "Trabaja deltoides y trapecios. Tira de los codos hacia arriba, no de las manos.",
    "Remo al mentón con agarre ancho": "Mayor énfasis en deltoides que en trapecios. Más seguro para los hombros.",
    
    # BÍCEPS
    "Curl con barra": "Ejercicio fundamental de bíceps. Mantén los codos fijos a los costados.",
    "Curl con barra Z": "Posición más natural de muñecas. Reduce el estrés en las articulaciones.",
    "Curl con mancuernas": "Permite rotación (supinación) para mayor activación del bíceps. Alterna o simultáneo.",
    "Curl con mancuernas alterno": "Versión alternada que permite mayor concentración en cada brazo.",
    "Curl martillo": "Agarre neutro que trabaja braquial y braquiorradial además del bíceps.",
    "Curl concentrado": "Aislamiento puro del bíceps. Apoya el codo en el muslo y contrae fuerte.",
    "Curl en banco Scott": "Elimina el impulso del cuerpo. Excelente para la cabeza corta del bíceps.",
    "Curl en polea baja": "Tensión constante durante todo el movimiento. Usa barra recta o cuerda.",
    "Curl en polea alta": "Curl con brazos extendidos hacia arriba. Pose de doble bíceps con resistencia.",
    "Curl inclinado": "Mayor estiramiento del bíceps. Siéntate en banco inclinado con brazos colgando.",
    "Curl araña": "Curl tumbado boca abajo en banco inclinado. Elimina todo impulso.",
    "Curl 21s": "7 reps parciales bajas + 7 altas + 7 completas. Técnica de intensidad.",
    "Curl Zottman": "Sube supinando, baja pronando. Trabaja bíceps y antebrazos en un movimiento.",
    
    # TRÍCEPS
    "Press francés con barra": "Extensión de codos tumbado. Mantén los codos apuntando al techo.",
    "Press francés con barra Z": "Versión más cómoda para las muñecas. Baja hacia la frente o detrás.",
    "Press francés con mancuernas": "Versión unilateral o bilateral. Mayor rango de movimiento.",
    "Extensiones en polea alta": "Pushdowns con cable. Mantén los codos fijos a los costados.",
    "Extensiones en polea alta con cuerda": "Permite separar las manos al final para mayor contracción.",
    "Extensiones en polea alta con barra V": "Agarre que reduce el estrés de muñecas. Muy popular.",
    "Extensiones en polea alta con barra recta": "Versión clásica del pushdown. Mayor énfasis en la cabeza lateral.",
    "Patada de tríceps": "Extensión de codo inclinado hacia adelante. Mantén el codo alto y fijo.",
    "Fondos en paralelas (tríceps)": "Torso vertical y codos hacia atrás para enfatizar tríceps sobre pecho.",
    "Fondos en banco": "Versión más fácil con manos en banco. Añade peso en las piernas para progresar.",
    "Extensiones sobre cabeza con mancuerna": "Trabaja la cabeza larga del tríceps. Una o dos manos.",
    "Extensiones sobre cabeza en polea": "Versión con cable para tensión constante. Usa cuerda o barra.",
    "Press cerrado": "Press de banca con agarre estrecho. Compuesto para tríceps con ayuda de pecho.",
    "JM Press": "Híbrido entre press cerrado y press francés. Muy efectivo para fuerza de tríceps.",
    
    # PIERNAS - CUÁDRICEPS
    "Sentadilla con barra": "Ejercicio rey para piernas. Baja hasta que los muslos estén paralelos o más.",
    "Sentadilla frontal": "Barra en deltoides anteriores. Mayor énfasis en cuádriceps y core.",
    "Sentadilla búlgara": "Zancada con pie trasero elevado. Excelente para equilibrio y fuerza unilateral.",
    "Sentadilla hack": "Máquina de sentadilla con espalda apoyada. Reduce estrés lumbar.",
    "Sentadilla goblet": "Con mancuerna o kettlebell al pecho. Ideal para aprender el patrón de sentadilla.",
    "Sentadilla en multipower": "Sentadilla guiada en Smith. Permite enfocarse en el esfuerzo sin equilibrio.",
    "Prensa de piernas": "Empuje de piernas en máquina. Posición de pies determina el énfasis muscular.",
    "Prensa de piernas 45°": "Versión clásica inclinada. Mayor rango de movimiento que la horizontal.",
    "Prensa de piernas horizontal": "Menor rango pero permite más peso. Buena para series pesadas.",
    "Extensiones de cuádriceps": "Aislamiento puro de cuádriceps. No bloquees completamente las rodillas.",
    "Zancadas con barra": "Zancadas caminando o en el sitio. Trabaja cuádriceps, glúteos e isquios.",
    "Zancadas con mancuernas": "Versión con mancuernas a los lados. Más fácil de equilibrar.",
    "Zancadas en multipower": "Versión guiada de la zancada. Mayor estabilidad para concentrarse en el trabajo muscular.",
    "Step-ups": "Subida a banco o cajón. Excelente ejercicio unilateral funcional.",
    "Sissy squat": "Sentadilla inclinada hacia atrás. Aislamiento extremo de cuádriceps.",
    
    # PIERNAS - ISQUIOTIBIALES
    "Curl femoral tumbado": "Flexión de rodilla tumbado boca abajo. Aislamiento de isquiotibiales.",
    "Curl femoral sentado": "Versión sentada con mayor estiramiento inicial. Complementa al tumbado.",
    "Curl femoral de pie": "Versión unilateral de pie. Trabaja un isquio a la vez.",
    "Curl nórdico": "Flexión de rodilla con peso corporal. Ejercicio avanzado y muy efectivo.",
    "Peso muerto con piernas rígidas": "Flexión de cadera con piernas rectas. Máximo estiramiento de isquios.",
    
    # PIERNAS - GLÚTEOS
    "Hip thrust": "Empuje de cadera con espalda en banco. Ejercicio #1 para desarrollo de glúteos.",
    "Hip thrust con barra": "Versión con barra sobre la cadera. Usa almohadilla para comodidad.",
    "Hip thrust en máquina": "Versión guiada del hip thrust. Muy cómoda y efectiva.",
    "Glute bridge": "Puente de glúteos en el suelo. Versión más accesible del hip thrust.",
    "Patada de glúteo en polea": "Extensión de cadera con cable. Aislamiento efectivo de glúteos.",
    "Patada de glúteo en máquina": "Versión guiada de la patada. Muy popular y efectiva.",
    "Abducción de cadera en máquina": "Abre las piernas contra resistencia. Trabaja glúteo medio.",
    "Aducción de cadera en máquina": "Cierra las piernas contra resistencia. Trabaja aductores.",
    "Sentadilla sumo": "Sentadilla con stance ancho. Mayor énfasis en aductores y glúteos.",
    "Buenos días con barra": "Flexión de cadera con barra. Trabaja glúteos, isquios y erectores.",
    
    # PANTORRILLAS
    "Elevación de talones de pie": "Gemelos de pie. Mantén las rodillas rectas para enfatizar los gastrocnemios.",
    "Elevación de talones sentado": "Trabaja principalmente el sóleo. Importante para pantorrillas completas.",
    "Elevación de talones en prensa": "Usando la máquina de prensa. Buen rango de movimiento.",
    "Elevación de talones con mancuerna": "Versión unilateral con peso libre. Trabaja el equilibrio.",
    "Elevación de talones en máquina": "Versión guiada de pie. Permite cargas pesadas.",
    
    # ABDOMINALES
    "Crunch": "Flexión de tronco básica. No tires del cuello, mira al techo.",
    "Crunch en máquina": "Versión con resistencia añadida. Permite progresar en peso.",
    "Crunch en polea": "Flexión de tronco con cable. Tensión constante.",
    "Crunch invertido": "Eleva las caderas hacia el pecho. Trabaja el abdomen inferior.",
    "Elevación de piernas colgado": "Colgado de barra, eleva las piernas. Muy efectivo para abdomen.",
    "Elevación de piernas en paralelas": "Versión con apoyo de antebrazos. Más accesible.",
    "Plancha": "Isométrico fundamental para el core. Mantén el cuerpo en línea recta.",
    "Plancha lateral": "Trabaja los oblicuos de forma isométrica. Mantén la cadera alta.",
    "Ab wheel (rueda abdominal)": "Extensión con rueda. Muy desafiante para el core.",
    "Giros rusos": "Rotación con peso. Trabaja los oblicuos. Mantén el core apretado.",
    "Woodchops en polea": "Rotación diagonal con cable. Excelente para oblicuos y core funcional.",
    "Pallof press": "Anti-rotación con cable. Trabaja la estabilidad del core.",
    "Dead bug": "Extensión alterna de brazos y piernas tumbado. Trabaja core y coordinación.",
    "Bird dog": "Extensión alterna en cuadrupedia. Core y estabilidad.",
    "Mountain climbers": "Rodillas al pecho alternando. Cardio y core combinados.",
    
    # ANTEBRAZOS
    "Curl de muñeca": "Flexión de muñeca con barra o mancuerna. Trabaja flexores del antebrazo.",
    "Curl de muñeca inverso": "Extensión de muñeca. Trabaja extensores del antebrazo.",
    "Farmer's walk": "Caminar con peso pesado en las manos. Trabaja agarre y core.",
    "Agarre con pinza": "Sostener discos con los dedos. Fortalece el agarre de pinza.",
    "Wrist roller": "Enrollar cuerda con peso. Trabaja flexores y extensores.",
}

# Plantillas genéricas por tipo de ejercicio
def generate_description(exercise: dict) -> str:
    nombre = exercise.get("nombre", "")
    grupo = exercise.get("grupoMuscular", "").lower()
    equipo = exercise.get("equipo", "").lower()
    
    # Primero buscar descripción específica
    if nombre in SPECIFIC_DESCRIPTIONS:
        return SPECIFIC_DESCRIPTIONS[nombre]
    
    # Generar descripción basada en patrones
    nombre_lower = nombre.lower()
    
    # Press
    if "press" in nombre_lower:
        if "inclinado" in nombre_lower:
            return f"Variante inclinada que enfatiza la porción superior del músculo objetivo. Usa un ángulo de 30-45° para óptimos resultados."
        elif "declinado" in nombre_lower:
            return f"Variante declinada que enfatiza la porción inferior del músculo objetivo. Requiere banco declinado."
        elif "militar" in nombre_lower or "hombro" in nombre_lower:
            return "Press vertical para desarrollo de hombros. Mantén el core apretado y evita arquear la espalda."
        else:
            return f"Ejercicio de empuje para {grupo}. Controla el movimiento en ambas fases."
    
    # Curl
    if "curl" in nombre_lower:
        if "femoral" in nombre_lower:
            return "Ejercicio de aislamiento para isquiotibiales. Contrae fuerte en la parte superior del movimiento."
        elif "martillo" in nombre_lower:
            return "Agarre neutro que trabaja el braquial además del bíceps. Mantén los codos fijos."
        else:
            return "Ejercicio de aislamiento para bíceps. Mantén los codos fijos a los costados durante todo el movimiento."
    
    # Extensiones
    if "extension" in nombre_lower or "extensión" in nombre_lower:
        if "triceps" in nombre_lower or "tricep" in nombre_lower:
            return "Aislamiento de tríceps. Mantén los codos fijos y extiende completamente."
        elif "cuadriceps" in nombre_lower or "pierna" in nombre_lower:
            return "Aislamiento de cuádriceps. No bloquees completamente las rodillas al final."
        else:
            return f"Ejercicio de extensión para {grupo}. Controla el peso en todo el rango de movimiento."
    
    # Remo
    if "remo" in nombre_lower:
        if "polea" in nombre_lower or "cable" in nombre_lower:
            return "Remo con cable para espalda. Mantén el pecho alto y tira hacia el abdomen."
        elif "mancuerna" in nombre_lower:
            return "Remo unilateral con mancuerna. Apoya una mano para estabilidad y tira el codo hacia atrás."
        else:
            return "Ejercicio de tracción para la espalda. Mantén la espalda neutra y tira de los codos."
    
    # Elevaciones
    if "elevacion" in nombre_lower or "elevación" in nombre_lower:
        if "lateral" in nombre_lower:
            return "Aislamiento del deltoides lateral. Ligera inclinación hacia adelante, codos ligeramente flexionados."
        elif "frontal" in nombre_lower:
            return "Aislamiento del deltoides anterior. Eleva hasta la altura de los hombros."
        elif "talones" in nombre_lower or "pantorrilla" in nombre_lower:
            return "Ejercicio para pantorrillas. Usa rango completo: estira abajo, contrae arriba."
        else:
            return f"Ejercicio de elevación para {grupo}. Controla el movimiento y evita usar impulso."
    
    # Sentadilla
    if "sentadilla" in nombre_lower or "squat" in nombre_lower:
        if "bulgara" in nombre_lower or "búlgara" in nombre_lower:
            return "Sentadilla unilateral con pie trasero elevado. Excelente para fuerza y equilibrio."
        elif "frontal" in nombre_lower:
            return "Barra en deltoides anteriores. Mayor énfasis en cuádriceps y core que la sentadilla trasera."
        else:
            return "Ejercicio fundamental para piernas. Baja hasta paralelo o más, mantén la espalda neutra."
    
    # Dominadas/Jalón
    if "dominada" in nombre_lower or "jalon" in nombre_lower or "jalón" in nombre_lower:
        return "Ejercicio de tracción vertical para espalda y bíceps. Tira de los codos hacia abajo y atrás."
    
    # Aperturas
    if "apertura" in nombre_lower:
        if "polea" in nombre_lower:
            return f"Cruces con cable para {grupo}. Tensión constante durante todo el movimiento."
        else:
            return f"Ejercicio de aislamiento para {grupo}. Mantén ligera flexión de codos."
    
    # Hip thrust / Glúteos
    if "hip thrust" in nombre_lower or "glute" in nombre_lower:
        return "Ejercicio para desarrollo de glúteos. Contrae fuerte en la parte superior y mantén 1-2 segundos."
    
    # Peso muerto
    if "peso muerto" in nombre_lower:
        return "Ejercicio fundamental de tracción. Mantén la espalda neutra y empuja el suelo con los pies."
    
    # Zancadas
    if "zancada" in nombre_lower or "lunge" in nombre_lower:
        return "Ejercicio unilateral para piernas. Mantén el torso erguido y la rodilla alineada con el pie."
    
    # Fondos
    if "fondo" in nombre_lower or "dip" in nombre_lower:
        return "Ejercicio de empuje con peso corporal. Baja hasta 90° de flexión de codos y empuja fuerte."
    
    # Plancha
    if "plancha" in nombre_lower:
        return "Ejercicio isométrico para el core. Mantén el cuerpo en línea recta, sin hundir la cadera."
    
    # Crunch
    if "crunch" in nombre_lower:
        return "Flexión de tronco para abdominales. Eleva los hombros del suelo contrayendo el abdomen."
    
    # Por equipo si no hay patrón específico
    if equipo == "maquina" or equipo == "máquina":
        return f"Versión en máquina que ofrece movimiento guiado y seguro. Ideal para principiantes o para ir al fallo."
    elif equipo == "polea" or equipo == "cable":
        return f"Ejercicio con cable que proporciona tensión constante durante todo el rango de movimiento."
    elif equipo == "mancuernas":
        return f"Versión con mancuernas que permite mayor rango de movimiento y trabajo estabilizador."
    elif equipo == "barra":
        return f"Versión con barra que permite usar cargas más pesadas. Mantén la técnica estricta."
    elif equipo == "peso corporal" or equipo == "bodyweight":
        return f"Ejercicio con peso corporal. Progresa aumentando repeticiones o dificultad."
    
    # Descripción genérica por grupo muscular
    group_descriptions = {
        "pecho": "Ejercicio para desarrollo del pectoral. Controla el peso y mantén la contracción.",
        "espalda": "Ejercicio para desarrollo de la espalda. Tira de los codos, no de las manos.",
        "hombros": "Ejercicio para desarrollo de deltoides. Evita usar impulso del cuerpo.",
        "biceps": "Ejercicio para bíceps. Mantén los codos fijos durante el movimiento.",
        "triceps": "Ejercicio para tríceps. Extiende completamente los codos en cada repetición.",
        "piernas": "Ejercicio para piernas. Usa rango completo de movimiento.",
        "gluteos": "Ejercicio para glúteos. Contrae fuerte en la parte superior.",
        "abdominales": "Ejercicio para abdominales. Mantén la tensión y evita usar impulso.",
        "core": "Ejercicio para el core. Mantén el abdomen contraído durante todo el movimiento.",
    }
    
    return group_descriptions.get(grupo, f"Ejercicio para {grupo}. Mantén buena técnica y control del movimiento.")


def main():
    # Cargar ejercicios
    exercises_path = Path(__file__).parent.parent / "assets" / "data" / "exercises_local.json"
    
    with open(exercises_path, "r", encoding="utf-8") as f:
        exercises = json.load(f)
    
    # Contar ejercicios sin descripción
    empty_before = sum(1 for e in exercises if not e.get("descripcion"))
    print(f"Ejercicios sin descripción antes: {empty_before}")
    
    # Añadir descripciones
    updated = 0
    for exercise in exercises:
        current_desc = exercise.get("descripcion", "")
        if not current_desc or current_desc.strip() == "":
            new_desc = generate_description(exercise)
            exercise["descripcion"] = new_desc
            updated += 1
            print(f"  + {exercise['nombre']}: {new_desc[:50]}...")
    
    # Guardar
    with open(exercises_path, "w", encoding="utf-8") as f:
        json.dump(exercises, f, ensure_ascii=False, indent=2)
    
    empty_after = sum(1 for e in exercises if not e.get("descripcion"))
    print(f"\n✅ Actualizados: {updated} ejercicios")
    print(f"   Sin descripción después: {empty_after}")


if __name__ == "__main__":
    main()
