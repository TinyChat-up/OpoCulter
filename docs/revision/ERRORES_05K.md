# Errores típicos de la fase 05K (para revisión de la dirección)

Los 23 errores que entraron en `Educulter/Content/errores.json` en la fase 05K, con su texto actual. Las explicaciones las redactó Claude Code; la dirección las revisa. Hasta entonces no se cambian.

Todos los textos son de Claude Code. ERR.MAT.GEO.VOL.1–6 corresponden a los errores que pedía el prompt de la 05K; los demás se añadieron porque los necesitan los distractores (D-145, D-146).

## MAT.GEO.VOL · Volumen y capacidad

| Id | Descripción | Explicación (remedio) |
|---|---|---|
| ERR.MAT.GEO.VOL.1 | Sumas las medidas en lugar de multiplicarlas. | El volumen se obtiene multiplicando: largo · ancho · alto. |
| ERR.MAT.GEO.VOL.2 | Calculas el área de la base, no el volumen. | El área de la base es una capa: multiplícala por la altura para tener todas las capas. |
| ERR.MAT.GEO.VOL.3 | Conviertes por 10 o por 100 entre unidades cúbicas. | Entre unidades cúbicas el salto es de 1000: 1 m³ = 1000 dm³ y 1 dm³ = 1000 cm³. |
| ERR.MAT.GEO.VOL.4 | No pasas los dm³ (o cm³, m³) a litros. | 1 dm³ = 1 l: pasa el volumen a dm³ y tendrás los litros. |
| ERR.MAT.GEO.VOL.5 | Usas el diámetro como si fuera el radio. | El radio es la mitad del diámetro: divide entre 2 antes de calcular π · r². |
| ERR.MAT.GEO.VOL.6 | No conviertes las medidas mixtas a la misma unidad. | Antes de multiplicar, pasa todas las medidas a la misma unidad (a dm, si quieres litros). |
| ERR.MAT.GEO.VOL.7 | Usas la altura del depósito, no la del agua. | El agua ocupa un ortoedro con la altura del agua, no con la del depósito. |
| ERR.MAT.GEO.VOL.8 | Das lo que baja el agua, no la altura final. | Calcula cuánto baja el agua y réstalo de la altura que tenía. |
| ERR.MAT.GEO.VOL.9 | Te equivocas al calcular un paso del volumen. | Comprueba cada paso: área de la base (largo · ancho) y después, por la altura. |
| ERR.MAT.GEO.VOL.10 | Das el volumen en unidades lineales o cuadradas. | El volumen va en unidades cúbicas (cm³, m³) o en litros. |

## MAT.PRO.SUCESOS · Tipos de sucesos

| Id | Descripción | Explicación (remedio) |
|---|---|---|
| ERR.MAT.PRO.SUCESOS.1 | Incluyes resultados imposibles en el espacio muestral. | El espacio muestral solo tiene los resultados que pueden salir de verdad. |
| ERR.MAT.PRO.SUCESOS.2 | Olvidas resultados del espacio muestral. | Recorre el experimento entero: cada resultado posible cuenta, aunque se parezca a otro. |
| ERR.MAT.PRO.SUCESOS.3 | Confundes sucesos seguros, posibles e imposibles. | Seguro: ocurre con todos los resultados. Imposible: con ninguno. Posible: solo con algunos. |
| ERR.MAT.PRO.SUCESOS.4 | Tomas como contrario un suceso que deja resultados fuera. | El contrario reúne todos los resultados en que no ocurre el suceso, sin dejarse ninguno. |
| ERR.MAT.PRO.SUCESOS.5 | Tomas como contrario un suceso que comparte resultados. | El contrario no comparte ningún resultado con el suceso. |
| ERR.MAT.PRO.SUCESOS.6 | Confundes sucesos compatibles e incompatibles. | Son compatibles si hay algún resultado en que ocurren los dos a la vez. |

## LEN.CLA.VAR · Palabras variables e invariables

| Id | Descripción | Explicación (remedio) |
|---|---|---|
| ERR.LEN.CLA.VAR.1 | Confundes palabras variables e invariables. | Prueba a ponerla en plural o en femenino: si no admite ningún cambio, es invariable. |
| ERR.LEN.CLA.VAR.2 | Confundes en qué cambia cada clase de palabra. | Adjetivos y determinantes varían en género y número; los verbos, en persona y número. |

## LEN.LEX.DICC · Uso del diccionario

| Id | Descripción | Explicación (remedio) |
|---|---|---|
| ERR.LEN.LEX.DICC.2 | Buscas la palabra tal como aparece, no por su forma de diccionario. | Verbos en infinitivo; sustantivos en singular; adjetivos en masculino singular. |
| ERR.LEN.LEX.DICC.3 | Ordenas ch y ll como si fueran letras aparte. | Desde 2010, ch y ll se ordenan como c + h y l + l: «chocolate» va entre «cesta» y «cielo». |
| ERR.LEN.LEX.DICC.4 | Colocas mal las palabras con ñ. | La ñ es una letra propia: va después de la n y antes de la o. |
| ERR.LEN.LEX.DICC.5 | Crees que la tilde cambia el orden alfabético. | Las tildes no cuentan al ordenar: «cámara» se ordena como «camara». |
| ERR.LEN.LEX.DICC.6 | Ordenas solo por la primera letra. | Si la primera letra coincide, mira la segunda, y así hasta la primera que cambie. |
