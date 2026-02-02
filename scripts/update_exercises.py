#!/usr/bin/env python3
"""
Script para actualizar la biblioteca de ejercicios:
1. Asignar IDs numéricos estables
2. Añadir ejercicios de femorales/glúteos
3. Poblar descripciones
"""

import json
import os

os.chdir('assets/data')

# Leer archivo actual
with open('exercises_local.json', 'r', encoding='utf-8') as f:
    exercises = json.load(f)

print(f"Ejercicios actuales: {len(exercises)}")

# 1. Asignar IDs numéricos estables (100-299 para no colisionar con custom)
for i, ex in enumerate(exercises, start=100):
    ex['id'] = i
    if 'muscles' not in ex or not ex.get('muscles'):
        ex['muscles'] = [ex['grupoMuscular']]

# 2. Nuevos ejercicios de femorales y glúteos
new_exercises = [
    # FEMORALES
    {'nombre': 'Curl femoral acostado con maquina', 'grupoMuscular': 'Femoral', 'equipo': 'maquina', 'nivel': 'basico', 'descripcion': 'Ejercicio de aislamiento para femorales en posición acostada boca abajo.', 'musculosSecundarios': ['Gemelos']},
    {'nombre': 'Curl femoral sentado con maquina', 'grupoMuscular': 'Femoral', 'equipo': 'maquina', 'nivel': 'intermedio', 'descripcion': 'Variante sentada del curl femoral, mayor énfasis en la porción distal.', 'musculosSecundarios': ['Gemelos']},
    {'nombre': 'Curl femoral con bandas', 'grupoMuscular': 'Femoral', 'equipo': 'bandas', 'nivel': 'intermedio', 'descripcion': 'Curl femoral usando bandas de resistencia.', 'musculosSecundarios': ['Gemelos']},
    {'nombre': 'Curl femoral nordico', 'grupoMuscular': 'Femoral', 'equipo': 'peso corporal', 'nivel': 'avanzado', 'descripcion': 'Ejercicio excéntrico intenso para femorales, requiere fijación de tobillos.', 'musculosSecundarios': ['Gluteos']},
    {'nombre': 'Good morning con mancuernas', 'grupoMuscular': 'Femoral', 'equipo': 'mancuernas', 'nivel': 'intermedio', 'descripcion': 'Flexión de cadera con mancuernas sobre hombros.', 'musculosSecundarios': ['Gluteos', 'Espalda']},
    
    # GLUTEOS
    {'nombre': 'Hip thrust con mancuernas', 'grupoMuscular': 'Gluteos', 'equipo': 'mancuernas', 'nivel': 'intermedio', 'descripcion': 'Empuje de cadera con mancuerna sobre pelvis.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Hip thrust con bandas', 'grupoMuscular': 'Gluteos', 'equipo': 'bandas', 'nivel': 'basico', 'descripcion': 'Hip thrust usando bandas de resistencia ancladas.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Hip thrust a una pierna', 'grupoMuscular': 'Gluteos', 'equipo': 'peso corporal', 'nivel': 'avanzado', 'descripcion': 'Variante unilateral del hip thrust, máxima activación glútea.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Pull through con cable', 'grupoMuscular': 'Gluteos', 'equipo': 'cable', 'nivel': 'intermedio', 'descripcion': 'Tirón de cable entre piernas, excelente para glúteos.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Patada de gluteo con maquina', 'grupoMuscular': 'Gluteos', 'equipo': 'maquina', 'nivel': 'basico', 'descripcion': 'Extensión de cadera en máquina específica.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Patada de gluteo con cable', 'grupoMuscular': 'Gluteos', 'equipo': 'cable', 'nivel': 'intermedio', 'descripcion': 'Patada hacia atrás con tobilleras de cable.', 'musculosSecundarios': ['Femoral']},
    {'nombre': 'Step up con barra', 'grupoMuscular': 'Gluteos', 'equipo': 'barra', 'nivel': 'intermedio', 'descripcion': 'Subida a banco con barra sobre hombros.', 'musculosSecundarios': ['Cuadriceps']},
    {'nombre': 'Step up con mancuernas', 'grupoMuscular': 'Gluteos', 'equipo': 'mancuernas', 'nivel': 'basico', 'descripcion': 'Subida a banco con mancuernas.', 'musculosSecundarios': ['Cuadriceps']},
    {'nombre': 'Sentadilla búlgara con barra', 'grupoMuscular': 'Gluteos', 'equipo': 'barra', 'nivel': 'avanzado', 'descripcion': 'Sentadilla a una pierna con pie trasero elevado.', 'musculosSecundarios': ['Cuadriceps', 'Femoral']},
    {'nombre': 'Sentadilla búlgara con mancuernas', 'grupoMuscular': 'Gluteos', 'equipo': 'mancuernas', 'nivel': 'intermedio', 'descripcion': 'Variante con mancuernas de la sentadilla búlgara.', 'musculosSecundarios': ['Cuadriceps', 'Femoral']},
    {'nombre': 'Sentadilla sumo con barra', 'grupoMuscular': 'Gluteos', 'equipo': 'barra', 'nivel': 'intermedio', 'descripcion': 'Sentadilla con postura amplia y puntas hacia afuera.', 'musculosSecundarios': ['Cuadriceps', 'Femoral']},
    {'nombre': 'Sentadilla sumo con mancuernas', 'grupoMuscular': 'Gluteos', 'equipo': 'mancuernas', 'nivel': 'basico', 'descripcion': 'Variante con mancuerna entre piernas.', 'musculosSecundarios': ['Cuadriceps', 'Femoral']},
    {'nombre': 'Puente de gluteos', 'grupoMuscular': 'Gluteos', 'equipo': 'peso corporal', 'nivel': 'basico', 'descripcion': 'Elevación de cadera en posición supina.', 'musculosSecundarios': ['Core']},
    {'nombre': 'Puente de gluteos con barra', 'grupoMuscular': 'Gluteos', 'equipo': 'barra', 'nivel': 'intermedio', 'descripcion': 'Puente de glúteos con barra sobre pelvis.', 'musculosSecundarios': ['Core']},
    {'nombre': 'Peso muerto sumo con barra', 'grupoMuscular': 'Gluteos', 'equipo': 'barra', 'nivel': 'avanzado', 'descripcion': 'Peso muerto con postura amplia, mayor énfasis en glúteos.', 'musculosSecundarios': ['Femoral', 'Espalda']},
    {'nombre': 'Peso muerto rumano a una pierna', 'grupoMuscular': 'Femoral', 'equipo': 'mancuernas', 'nivel': 'avanzado', 'descripcion': 'Variante unilateral del peso muerto rumano.', 'musculosSecundarios': ['Gluteos', 'Core']},
    {'nombre': 'Sentadilla goblet', 'grupoMuscular': 'Piernas', 'equipo': 'mancuernas', 'nivel': 'basico', 'descripcion': 'Sentadilla con mancuerna sostenida frente al pecho.', 'musculosSecundarios': ['Gluteos', 'Core']},
    {'nombre': 'Hack squat con maquina', 'grupoMuscular': 'Piernas', 'equipo': 'maquina', 'nivel': 'intermedio', 'descripcion': 'Sentadilla en máquina hack, gran énfasis en cuádriceps.', 'musculosSecundarios': ['Gluteos']},
    {'nombre': 'Leg press con maquina', 'grupoMuscular': 'Piernas', 'equipo': 'maquina', 'nivel': 'basico', 'descripcion': 'Prensa de piernas en máquina, posición estándar.', 'musculosSecundarios': ['Gluteos']},
]

# Asignar IDs y estructura completa
next_id = max([e.get('id', 0) for e in exercises]) + 1
for ex in new_exercises:
    ex['id'] = next_id
    ex['muscles'] = [ex['grupoMuscular']]
    if 'musculosSecundarios' not in ex:
        ex['musculosSecundarios'] = []
    next_id += 1

# Añadir a lista principal
exercises.extend(new_exercises)

print(f"Añadidos {len(new_exercises)} ejercicios nuevos")
print(f"Total: {len(exercises)} ejercicios")
print(f"Rango de IDs: 100-{max(e['id'] for e in exercises)}")

# 3. Poblar descripciones para top 50 ejercicios más comunes
descriptions = {
    'Press banca con barra': 'Ejercicio compuesto fundamental para desarrollo de pecho. Mantén los pies firmes en el suelo y la espalda con ligero arco natural.',
    'Press banca con mancuernas': 'Variante con mayor rango de movimiento y trabajo estabilizador. Permite rotación natural de muñecas.',
    'Sentadilla con barra': 'El rey de los ejercicios de piernas. Mantén el core apretado y baja hasta que los muslos estén paralelos al suelo.',
    'Peso muerto con barra': 'Ejercicio compuesto que trabaja toda la cadena posterior. Mantén la espalda neutra throughout el movimiento.',
    'Press militar con barra': 'Desarrollo de hombros con barra. Puedes hacerlo de pie o sentado según tu nivel de estabilidad.',
    'Dominadas': 'Ejercicio corporal exigente para espalda. Agarre pronado, tirar hasta que el mentón supere la barra.',
    'Remo con barra': 'Ejercicio de jalón hacia el abdomen, trabaja dorsales y romboides. Mantén la espalda recta.',
    'Curl biceps con mancuernas': 'Ejercicio de aislamiento para bíceps. Evita balancear el cuerpo, usa solo los brazos.',
    'Extension triceps con cable': 'Aislamiento de tríceps con polea. Mantén los codos fijos al costado del cuerpo.',
    'Elevaciones laterales con mancuernas': 'Ejercicio de aislamiento para deltoides laterales. Levanta hasta la altura del hombro.',
    'Plancha': 'Ejercicio isométrico para core. Mantén el cuerpo en línea recta desde cabeza a talones.',
    'Fondos': 'Ejercicio corporal para pecho y tríceps. Baja hasta que los hombros estén al nivel de los codos.',
    'Hip thrust con barra': 'Ejercicio específico para glúteos. Apoya la espalda en un banco y empuja la barra con las caderas.',
    'Curl femoral con maquina': 'Aislamiento de isquiotibiales. Flexiona las rodillas llevando los talones hacia los glúteos.',
    'Zancadas con mancuernas': 'Ejercicio unilateral para piernas. Da un paso largo hacia adelante bajando la rodilla trasera.',
    'Face pull con cable': 'Ejercicio de postura y hombros. Jala hacia la cara manteniendo los codos altos.',
    'Pullover con mancuernas': 'Ejercicio que trabaja pecho y dorsales. Realiza un arco controlado sobre la cabeza.',
    'Aperturas con mancuernas': 'Aislamiento de pecho con énfasis en estiramiento. Brazos ligeramente flexionados throughout.',
    'Encogimientos con barra': 'Desarrollo de trapecios. Eleva los hombros hacia las orejas contrayendo arriba.',
    'Burpees': 'Ejercicio cardiovascular de cuerpo completo. Combina sentadilla, flexión y salto vertical.',
    'Kettlebell swing': 'Movimiento balístico para glúteos y espalda. Impulsa con las caderas, no con los brazos.',
    'Clean and press con barra': 'Levantamiento olímpico de potencia. Arranca la barra hasta los hombros y luego empuja.',
    'Remo invertido': 'Ejercicio corporal para espalda. Usa una barra baja o anillas, tira el pecho hacia la barra.',
    'Flexiones': 'Ejercicio corporal clásico. Mantén el cuerpo recto y baja hasta que el pecho casi toque el suelo.',
    'Crunch': 'Ejercicio de abdominales. Eleva los hombros del suelo contrayendo el recto abdominal.',
    'Elevacion de piernas': 'Trabajo de abdominales inferiores. Eleva las piernas rectas o semiflexionadas.',
    'Farmer walk': 'Ejercicio de agarre y core. Camina manteniendo mancuernas pesadas a los costados.',
    'Sentadilla búlgara con mancuernas': 'Variante unilateral desafiante. Pie trasero elevado, baja controladamente.',
    'Peso muerto rumano con barra': 'Énfasis en femorales y glúteos. Mantén las rodillas ligeramente flexionadas, flexiona caderas.',
}

updated_count = 0
for ex in exercises:
    if ex['nombre'] in descriptions and not ex.get('descripcion'):
        ex['descripcion'] = descriptions[ex['nombre']]
        updated_count += 1

print(f"Descripciones añadidas: {updated_count}")

# Guardar
with open('exercises_local.json', 'w', encoding='utf-8') as f:
    json.dump(exercises, f, ensure_ascii=False, indent=2)

print("Archivo guardado correctamente")

# Estadísticas por grupo muscular
from collections import Counter
groups = Counter(e['grupoMuscular'] for e in exercises)
print("\nDistribución actual:")
for group, count in sorted(groups.items(), key=lambda x: -x[1]):
    print(f"  {group}: {count}")
