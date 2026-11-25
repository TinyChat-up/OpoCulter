#!/usr/bin/env python3
"""Soluciones de Matemáticas de los 7 exámenes oficiales (prueba común A1), calculadas con código.

Solo biblioteca estándar. Cada solución se calcula con aritmética exacta (fractions.Fraction) y se
redacta en 2–4 pasos. Ejecutar el módulo comprueba todos los cálculos y los imprime:
    python3 scripts/tribunal/matematicas.py

`SOLUCIONES[(id_examen, numero)]` → texto de la solución (lo usa construir.py).
"""

from fractions import Fraction as F
from math import gcd, lcm
from statistics import median, multimode


def mean(datos):
    """Media exacta (Fraction)."""
    return F(sum(F(x) for x in datos)) / len(datos)

SOLUCIONES = {}


def num(x, dec=4):
    """Número en formato español: coma decimal, punto de miles, sin ceros sobrantes."""
    x = F(x)
    if x.denominator == 1:
        entero = int(x)
        s = f"{abs(entero):,}".replace(",", ".") if abs(entero) >= 10000 else str(abs(entero))
        return ("−" if entero < 0 else "") + s
    v = round(float(x), dec)
    s = f"{v:.{dec}f}".rstrip("0").rstrip(".")
    entero, _, frac = s.partition(".")
    neg = entero.startswith("-")
    entero = entero.lstrip("-")
    if len(entero) > 4:
        entero = f"{int(entero):,}".replace(",", ".")
    return ("−" if neg else "") + entero + ("," + frac if frac else "")


def fr(x):
    x = F(x)
    return str(x.numerator) if x.denominator == 1 else f"{x.numerator}/{x.denominator}"


def romano(n):
    tabla = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
             (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    out = ""
    for v, s in tabla:
        while n >= v:
            out += s
            n -= v
    return out


def arabigo(r):
    val = {"M": 1000, "D": 500, "C": 100, "L": 50, "X": 10, "V": 5, "I": 1}
    total = 0
    for i, c in enumerate(r):
        v = val[c]
        total += -v if i + 1 < len(r) and val[r[i + 1]] > v else v
    assert romano(total) == r, r
    return total


def sol(examen, n, pasos, resultado):
    assert 1 <= len(pasos) <= 4, (examen, n)
    texto = " ".join(f"{i}) {p}" for i, p in enumerate(pasos, 1)) + f" Resultado: {resultado}"
    SOLUCIONES[(examen, n)] = texto


def orden(valores, mayor_a_menor=True):
    """valores: lista de (etiqueta, valor exacto). Devuelve la cadena ordenada."""
    ords = sorted(valores, key=lambda x: x[1], reverse=mayor_a_menor)
    signo = " > " if mayor_a_menor else " < "
    return signo.join(e for e, _ in ords), ords


# ------------------------------------------------------------------ 2017 O
E = "OF.2017.O"
a, b = F(300) / F("1.5"), F(8888) / 40
assert a == 200 and b == F("222.2")
sol(E, 1, ["a = 300 : 1,5 = 3000 : 15 = 200.", "b = 8888 : 40 = 222,2 (la división no es exacta)."], "a = 200; b = 222,2.")
txt, _ = orden([("2/3", F(2, 3)), ("0,5", F(1, 2)), ("1/4", F(1, 4)), ("0,6", F(3, 5))])
sol(E, 2, ["Se pasan a decimal: 2/3 = 0,666…; 1/4 = 0,25.", "Se comparan con 0,5 y 0,6."], txt + ".")
for x in (F(12, 20), F(48, 112), F(90, 150)):
    pass
assert F(12, 20) == F(90, 150) == F(3, 5) and F(48, 112) == F(3, 7)
sol(E, 3, ["Se simplifican: 12/20 = 3/5 (÷4); 48/112 = 3/7 (÷16); 90/150 = 3/5 (÷30).",
           "Son equivalentes las que dan la misma fracción irreducible (o productos cruzados iguales: 12 · 150 = 20 · 90 = 1800)."],
    "12/20 y 90/150 son equivalentes (ambas valen 3/5); 48/112 no.")
sol(E, 4, ["Complementarios suman 90°: 90° − 80° = 10°.", "Suplementarios suman 180°: 180° − 25° = 155°."], "a) 10°; b) 155°.")
cuadrado, circulo = 16, F("3.14") * 9
assert cuadrado + circulo == F("44.26")
sol(E, 5, ["Parcela cuadrada: 4 × 4 = 16 m².", "Rotonda: π · r² = 3,14 × 3² = 28,26 m².", "Total: 16 + 28,26."], "44,26 m².")
assert [romano(x) for x in (334, 975, 2069)] == ["CCCXXXIV", "CMLXXV", "MMLXIX"]
sol(E, 6, ["334 = 300 + 30 + 4 = CCC + XXX + IV.", "975 = 900 + 70 + 5 = CM + LXX + V.", "2069 = 2000 + 60 + 9 = MM + LX + IX."],
    "CCCXXXIV; CMLXXV; MMLXIX.")
pago = 675 * F(85, 100)
assert pago == F("573.75")
sol(E, 7, ["Descuento: 15 % de 675 = 675 × 0,15 = 101,25 €.", "Precio final: 675 − 101,25 (o 675 × 0,85)."], "573,75 €.")
assert lcm(36, 48) == 144
sol(E, 8, ["36 = 2² · 3²; 48 = 2⁴ · 3.", "m.c.m. = 2⁴ · 3² = 144 (factores comunes y no comunes con el mayor exponente)."], "Volverán a coincidir dentro de 144 días.")
sol(E, 9, ["1928 l = 1,928 kl (÷1000); 0,53 hm = 53 m (×100); 7 g = 0,007 kg (÷1000).",
           "70.000 m² = 7 ha (1 ha = 10.000 m²); 9 ml = 0,009 dm³ (1 dm³ = 1 l = 1000 ml); 54 dam = 540.000 mm (×10.000)."],
    "a) 1,928 kl; b) 53 m; c) 0,007 kg; d) 7 ha; e) 0,009 dm³; f) 540.000 mm.")
r = (16 * 8 + 12) / F(4) - 3 * (38 - 5 * 4)
assert r == -19
sol(E, 10, ["Paréntesis, primero los productos: 16 × 8 + 12 = 140; 38 − 5 × 4 = 18.", "140 : 4 = 35; 3 × 18 = 54.", "35 − 54."], "−19.")

# ------------------------------------------------------------------ 2019 O
E = "OF.2019.O"
ops = {"a": F(4, 5) + F(2, 10) + F(2, 15) - F(2, 5), "b": F(3, 4) + F(2, 6) - F(3, 12),
       "c": F(4, 9) + F(2, 6) - F(2, 5), "d": F(2, 6) + F(6, 12) + F(7, 6) - F(2, 3)}
assert ops == {"a": F(11, 15), "b": F(5, 6), "c": F(17, 45), "d": F(4, 3)}
sol(E, 1, ["a) m.c.m. 30: 24/30 + 6/30 + 4/30 − 12/30 = 22/30 = 11/15.",
           "b) m.c.m. 12: 9/12 + 4/12 − 3/12 = 10/12 = 5/6.",
           "c) m.c.m. 90: 40/90 + 30/90 − 36/90 = 34/90 = 17/45.",
           "d) m.c.m. 12: 4/12 + 6/12 + 14/12 − 8/12 = 16/12 = 4/3."], "a) 11/15; b) 5/6; c) 17/45; d) 4/3.")
assert 10 * 3600 + 10 * 60 == 36600 and F(170 * 60 + 600, 3600) == 3 and F(110 * 60 + 300, 60) == 115
sol(E, 2, ["a) 10 h = 36.000 s; 10′ = 600 s; total 36.600 s.", "b) 600″ = 10′; 170′ + 10′ = 180′ = 3 h.",
           "c) 300″ = 5′; 110′ + 5′ = 115′."], "a) 36.600 s; b) 3 h; c) 115 minutos.")
assert F(1012, 44) == 23 and F(2425, 485) == 5
sol(E, 3, ["a = 1012 : 44 = 23 (comprobación: 44 × 23 = 1012).", "b = 2425 : 485 = 5 (comprobación: 485 × 5 = 2425)."], "a = 23; b = 5.")
txt, _ = orden([("4/7", F(4, 7)), ("0,4", F(2, 5)), ("1/2", F(1, 2)), ("3,3", F(33, 10))])
sol(E, 4, ["4/7 = 0,571…; 1/2 = 0,5.", "Se ordenan los decimales: 3,3; 0,571…; 0,5; 0,4."], txt + ".")
vol = 7 * 5 * 3
sol(E, 5, ["Se pasa todo a metros: 50 dm = 5 m; 300 cm = 3 m.", "Volumen: 7 × 5 × 3 = 105 m³.", "1 m³ = 1000 l → 105.000 l."], "b) 105.000 litros.")
d = [6, 4, 7, 9, 9]
assert mean(d) == 7 and multimode(d) == [9] and max(d) - min(d) == 5
sol(E, 6, ["Media: (6 + 4 + 7 + 9 + 9) : 5 = 35 : 5 = 7.", "Moda: el valor más repetido, 9.", "Rango: 9 − 4 = 5."], "Media 7; moda 9; rango 5.")
votos = {"Juan": 5, "María": 15, "Luisa": 3, "Roberto": 2}
tot = sum(votos.values())
filas = "; ".join(f"{k}: {v}, {num(F(v, tot))}, {num(F(v, tot) * 100)} %" for k, v in votos.items())
assert tot == 25
sol(E, 7, ["Total de votos: 25.", "Frecuencia relativa = votos : 25; porcentaje = relativa × 100."], filas + " (suman 25, 1 y 100 %).")
z1, z2, circ = 30 * 10, 50 * 30, F("3.14") * 10 ** 2
assert z1 + z2 + circ == 2114
sol(E, 8, ["En metros: 3 dam = 30 m; 0,5 hm = 50 m; 1000 cm = 10 m.", "Rectángulos: 30 × 10 = 300 m²; 50 × 30 = 1500 m².",
           "Círculo: 3,14 × 10² = 314 m².", "Total: 300 + 1500 + 314."], "2114 m².")
assert [romano(x) for x in (824, 1223, 793)] == ["DCCCXXIV", "MCCXXIII", "DCCXCIII"]
sol(E, 9, ["824 = DCCC + XX + IV.", "1223 = M + CC + XX + III.", "793 = DCC + XC + III."], "DCCCXXIV; MCCXXIII; DCCXCIII.")
r = (16 * 8 + 12) / F(4) + 3 * (38 - 5 * 4)
assert r == 89
sol(E, 10, ["(16 × 8 + 12) : 4 = 140 : 4 = 35.", "3 × (38 − 20) = 3 × 18 = 54.", "35 + 54."], "89.")

# ------------------------------------------------------------------ 2019 A
E = "OF.2019.A"
j = 60 * F(1, 12); q1 = 60 - j; m = q1 * F(2, 11); q2 = q1 - m; an = q2 * F(3, 15); q3 = q2 - an
assert (j, m, an, q3) == (5, 10, 9, 36)
sol(E, 1, ["Juan: 1/12 de 60 = 5; quedan 55.", "María: 2/11 de 55 = 10; quedan 45.", "Ana: 3/15 de 45 = 9; quedan 36."], "Quedan 36 globos sin hinchar.")
A, B, C = 3 * 60 + 10, 210 + 10, 190 + 40
assert A + B + C == 640
sol(E, 2, ["A: 3 h 10′ = 190 min.", "B: 600″ = 10′ → 220 min. C: 2400″ = 40′ → 230 min.", "Sucesivas: 190 + 220 + 230."], "640 minutos.")
assert F(9591, 23) == 417 and F(24024, 88) == 273
sol(E, 3, ["a = 9591 : 23 = 417 (23 × 417 = 9591).", "b = 24024 : 88 = 273 (88 × 273 = 24.024)."], "a = 417; b = 273.")
txt, _ = orden([("2,1", F(21, 10)), ("23/24", F(23, 24)), ("8/4", F(2)), ("0,8", F(4, 5))])
sol(E, 4, ["8/4 = 2; 23/24 = 0,958…", "Se comparan: 2,1 > 2 > 0,958… > 0,8."], txt + ".")
k = F(5, 4)
rec = {"zanahorias": (250, "g"), "harina": (200, "g"), "levadura": (7, "g"), "aceite": (120, "ml"), "huevos": (4, ""), "azúcar": (200, "g")}
res = "; ".join(f"{num(v * k)} {n}" if not u else f"{num(v * k)} {u} de {n}" for n, (v, u) in rec.items())
assert 7 * k == F("8.75")
sol(E, 5, ["Razón de proporcionalidad: 5/4 = 1,25.", "Cada cantidad se multiplica por 1,25."], res + ".")
assert len([x for x in range(10) if x % 2]) == 5 and len([x for x in range(10) if x > 6]) == 3
sol(E, 6, ["Casos posibles: 10 (bolas 0–9). Regla de Laplace: favorables / posibles.",
           "Impares (1, 3, 5, 7, 9): 5/10. Mayor que 6 (7, 8, 9): 3/10. El 8: 1/10. Menor que 10: todas, 10/10 (suceso seguro)."],
    "Impar → 5/10; mayor que 6 → 3/10; el 8 → 1/10; menor que 10 → 10/10.")
pir, cil = F(1, 3) * 16 * 8, F("3.14") * 4 * 8
assert pir == F(128, 3) and cil == F("100.48")
sol(E, 7, ["Pirámide: V = (área de la base × altura) : 3 = (4² × 8) : 3 = 128/3.", "Cilindro: V = π · r² · h = 3,14 × 2² × 8."],
    "a) 128/3 ≈ 42,67 m³; b) 100,48 m³.")
d = [4, 5, 7, 8, 9]
assert mean(d) == F("6.6") and median(d) == 7
sol(E, 8, ["Media: 33 : 5 = 6,6.", "Mediana: datos ordenados (4, 5, 7, 8, 9), el central es 7.", "Rango: 9 − 4 = 5."], "Media 6,6; mediana 7; rango 5.")
vals = [arabigo(x) for x in ("MMCCCXLV", "CCCXLVII", "CDXCIII")]
assert vals == [2345, 347, 493]
sol(E, 9, ["MM CCC XL V = 2000 + 300 + 40 + 5.", "CCC XL VII = 300 + 40 + 7.", "CD XC III = 400 + 90 + 3."], "2345; 347; 493.")
r = (12 * 4 - 8) / F(4) + 2 * (23 - 2 * 3)
assert r == 44
sol(E, 10, ["(12 × 4 − 8) : 4 = 40 : 4 = 10.", "2 × (23 − 6) = 2 × 17 = 34.", "10 + 34."], "44.")

# ------------------------------------------------------------------ 2022 O
E = "OF.2022.O"
g = gcd(gcd(24, 12), 18)
assert g == 6
sol(E, 1, ["Para repartir por igual cada color en los collares, el número de collares debe dividir a 24, 12 y 18.",
           "m.c.d.(24, 12, 18) = 6.", "24 : 6 = 4 blancos; 12 : 6 = 2 rojos; 18 : 6 = 3 azules."],
    "6 collares, cada uno con 4 blancos, 2 rojos y 3 azules (9 abalorios).")
txt, _ = orden([("Lucas (3/4)", F(3, 4)), ("Ainara (1/2)", F(1, 2)), ("Berta (2/5)", F(2, 5))])
sol(E, 2, ["Denominador común 20: 1/2 = 10/20; 3/4 = 15/20; 2/5 = 8/20.", "Como la revista es la misma, más fracción = más páginas."], f"Lucas ha leído más: {txt}.")
a_ = F("71.46") - F("14.7") * F("5.32") + F("13.051")
b_ = F("2.45") + F("146.9") / 5
assert a_ == F("6.307") and b_ == F("31.83")
sol(E, 3, ["a) Primero el producto: 14,7 × 5,32 = 78,204.", "a) 71,46 − 78,204 + 13,051 = 6,307.",
           "b) Primero la división: 146,9 : 5 = 29,38; después 2,45 + 29,38."], "a) 6,307; b) 31,83.")
assert 3000 + 400 + 30 == 3430 and 20 + 24 + F("1.6") == F("45.6") and 80 + F("0.09") + F("0.015") == F("80.105")
sol(E, 4, ["a) 3 km = 3000 m; 4 hm = 400 m; 3 dam = 30 m.", "b) 2 kg = 20 hg; 16 dag = 1,6 hg; 20 + 24 + 1,6.",
           "c) 8 dal = 80 l; 9 cl = 0,09 l; 15 ml = 0,015 l."], "a) 3430 m; b) 45,6 hg; c) 80,105 l.")
area = 12 * F("8.5") + 4 * 3 + F(4) * F("2.5") / 2
assert area == 119 and area * F("3.5") == F("416.5")
sol(E, 5, ["Planta baja: 12 × 8,5 = 102 m². Torre: 4 × 3 = 12 m².", "Triángulo: (4 × 2,5) : 2 = 5 m².",
           "Fachada: 102 + 12 + 5 = 119 m²; coste 119 × 3,5."], "416,50 €.")
pct = {"Novelas": 22, "Poesía": 20, "Historia": 10, "Ciencias": 22, "Enciclopedias": 26}
res = {k: 1250 * v // 100 for k, v in pct.items()}
assert sum(res.values()) == 1250 and all(1250 * v % 100 == 0 for v in pct.values())
sol(E, 6, ["El 1 % de 1250 es 12,5.", "Cada tipo: porcentaje × 12,5."], "; ".join(f"{k}: {v}" for k, v in res.items()) + " (suman 1250).")
tabla = {16: 3, 17: 3, 18: 5, 19: 6, F("20.5"): 4, 21: 4, 22: 3, F("23.5"): 2}
datos = [x for x, f in tabla.items() for _ in range(f)]
assert len(datos) == 30 and mean(datos) == F("19.4") and multimode(datos) == [19] and median(datos) == 19
sol(E, 7, ["N = 30 días; Σ(x · f) = 48 + 51 + 90 + 114 + 82 + 84 + 66 + 47 = 582.", "Media: 582 : 30 = 19,4 °C. Moda: 19 °C (frecuencia 6).",
           "Mediana: los datos 15.º y 16.º (frecuencias acumuladas 3, 6, 11, 17) valen 19 °C.", "Rango: 23,5 − 16 = 7,5 °C."],
    "Media 19,4 °C; moda 19 °C; mediana 19 °C; rango 7,5 °C.")
assert 7 * 10 ** 3 == 7000 and 34 * 10 ** 7 == 340_000_000 and 29 * 10 ** 4 == 290_000 and 3 * 10 ** 6 == 3_000_000
assert 53 * 10 ** 6 == 53_000_000 and 572 * 10 ** 5 == 57_200_000
sol(E, 8, ["Multiplicar por 10ⁿ añade n ceros (o desplaza la coma n lugares).", "c) 290.000 : 29 = 10⁴; d) 3.000.000 : 3 = 10⁶.",
           "e) 53.000.000 : 10⁶ = 53; f) 57.200.000 : 10⁵ = 572."],
    "a) 7000; b) 340.000.000; c) 10⁴; d) 10⁶; e) 53; f) 572.")
assert F("6.80") / 10 == F("0.68") and F("0.85") - F("0.68") == F("0.17")
sol(E, 9, ["a) 6,80 : 10 = 0,68 € por viaje.", "b) Ahorro por viaje: 0,85 − 0,68 = 0,17 €; en un abono de 10 viajes: 8,50 − 6,80 = 1,70 €."],
    "a) 0,68 €; b) 0,17 € por viaje (1,70 € por cada abono de 10 viajes).")
v1, v2, v3 = 1 * 2 * 8, 3 * F("2.5") * 9, 12 * 11 * 3
assert v1 + v2 + v3 == F("479.5")
sol(E, 10, ["Todo en cm: c = 0,1 dm = 1 cm; a = 80 mm = 8 cm; d = 0,3 dm = 3 cm; f = 0,09 m = 9 cm; h = 30 mm = 3 cm; g = 0,0012 hm = 12 cm.",
            "Bloque superior: 1 × 2 × 8 = 16 cm³. Bloque central: 3 × 2,5 × 9 = 67,5 cm³.", "Bloque inferior: 12 × 11 × 3 = 396 cm³."],
    "479,5 cm³.")

# ------------------------------------------------------------------ 2024 O
E = "OF.2024.O"
txt, _ = orden([("1,904 · 10", F("19.04")), ("2/3 de 29,1", F(2, 3) * F("29.1")), ("2² + 4² − 0,56", 4 + 16 - F("0.56")),
                ("58,26/3", F("58.26") / 3)], mayor_a_menor=False)
sol(E, 1, ["2/3 de 29,1 = 19,4; 1,904 · 10 = 19,04.", "2² + 4² − 0,56 = 20 − 0,56 = 19,44; 58,26 : 3 = 19,42."], txt + ".")
r = (F(3, 5) + F(1, 4) * F(2, 3)) / ((1 + F(1, 5)) * F(16, 4))
assert r == F(23, 144)
sol(E, 2, ["Primer corchete: 1/4 × 2/3 = 1/6; 3/5 + 1/6 = 23/30.", "Segundo corchete: 1 + 1/5 = 6/5; 6/5 × 16/4 = 6/5 × 4 = 24/5.",
           "División: 23/30 : 24/5 = 23/30 × 5/24 = 115/720 = 23/144."], "23/144.")
sol(E, 3, ["Se multiplica cada cifra por la potencia de 10 de su posición."],
    "a) 9 · 10⁷ + 6 · 10⁵ + 7 · 10⁴ + 3 · 10² + 4; b) 4 · 10⁴ + 5 · 10²; c) 8 · 10⁵ + 9 · 10³ + 7 · 10² + 5.")
assert 90_670_304 == 9 * 10**7 + 6 * 10**5 + 7 * 10**4 + 3 * 10**2 + 4 and 40_500 == 4 * 10**4 + 5 * 10**2
assert 809_705 == 8 * 10**5 + 9 * 10**3 + 7 * 10**2 + 5
cands = [n for n in range(300, 351) if n % 3 == n % 4 == n % 7 == 0]
assert cands == [336] and lcm(3, 4, 7) == 84
sol(E, 4, ["El número es múltiplo común de 3, 4 y 7: m.c.m.(3, 4, 7) = 84.", "Múltiplos de 84: 84, 168, 252, 336, 420…",
           "El único entre 300 y 350 es 336."], "336 páginas.")
dia = F(1, 15) + F(1, 30)
assert 1 / dia == 10
sol(E, 5, ["En un día, Alonso pinta 1/15 de la fachada y Alberto 1/30.", "Juntos: 1/15 + 1/30 = 3/30 = 1/10 al día.", "Tardan 1 : (1/10) días."], "10 días.")
total = F("2.6") + F("1.08") + F("1.007")
assert total == F("4.687")
sol(E, 6, ["Bolsa 1: 2 kg 6 hg = 2,6 kg. Bolsa 2: 1 kg 8 dag = 1,08 kg. Bolsa 3: 1 kg 70 dg = 1 kg 7 g = 1,007 kg.",
           "Total: 2,6 + 1,08 + 1,007 = 4,687 kg.", "4,687 kg > 4,5 kg."], "No: las bolsas pesan 4,687 kg y el carrito soporta 4,5 kg.")
va = 13 * 13 * 22
vb = F(5) * F("12.5") * F("8.57") / 2 * 12
assert va == 3718 and vb == F("3213.75")
sol(E, 7, ["A (prisma de base cuadrada): 13 cm × 13 cm × 22 cm = 3718 cm³ = 3,718 l.",
           "B (prisma pentagonal): área de la base = perímetro × apotema : 2 = (5 × 12,5) × 8,57 : 2 = 267,8125 cm².",
           "Volumen de B: 267,8125 × 12 = 3213,75 cm³ = 3,21375 l.", f"3,718 − 3,21375 = {num(F(va) / 1000 - vb / 1000, 5)} l."],
    "a) 3,718 litros; b) le sobrará agua: unos 0,504 l (504,25 cm³).")
sol(E, 8, ["Cuadrantes: I (+, +); II (−, +); III (−, −); IV (+, −)."], "A (−4, +2): II; B (−1, −4): III; C (+3, +5): I; D (+2, −3): IV.")
datos = [21, 30, 22, 21, 13, 20, 24, 30, 20, 27, 17, 21, 17, 20, 20, 30, 19, 24, 20, 26, 17, 30, 19, 17, 23, 20, 25, 24, 19, 30]
assert len(datos) == 30
me, md, mo = mean(datos), median(datos), multimode(datos)
assert sum(datos) == 666 and me == F("22.2") and md == 21 and mo == [20] and datos.count(20) == 6
sol(E, 10, ["N = 30 datos; suma = 666.", "Media: 666 : 30 = 22,2.",
            "Mediana: con los datos ordenados, el 15.º y el 16.º valen 21 → 21.", "Moda: 20 (aparece 6 veces)."],
    "Media 22,2 €; mediana 21 €; moda 20 €.")

# ------------------------------------------------------------------ 2026 O
E = "OF.2026.O"
assert F("1.25") == F(5, 4)
sol(E, 1, ["1,25 tiene un número finito de cifras decimales: es un decimal exacto.", "1,25 = 125/100; m.c.d.(125, 100) = 25 → 5/4."], "Sí, es decimal exacto; 1,25 = 5/4.")
sol(E, 2, ["a) 4 filas × 4 asientos = 4 × 4.", "b) 3 vitrinas × 3 baldas × 3 maquetas = 3 × 3 × 3.", "c) 6 cajas × 6 galletas = 6 × 6."],
    "a) 4² (= 16); b) 3³ (= 27); c) 6² (= 36).")
h = 1 - (F(1, 4) + F(1, 5) + F(1, 10))
assert h == F(9, 20)
sol(E, 3, ["m.c.m.(4, 5, 10) = 20: 1/4 + 1/5 + 1/10 = 5/20 + 4/20 + 2/20 = 11/20.", "Historia: 1 − 11/20."], "9/20 de los libros.")
filas = [5 * 10 + 4, 7 * 100 + F(6, 100), 8 + F(5, 10), 6 * 1000]
assert filas == [54, F("700.06"), F("8.5"), 6000]
sol(E, 4, ["Fila 2: 5 dam = 50 m; 4 m → 54 m.", "Fila 3: 7 hm = 700 m; 6 cm = 0,06 m → 700,06 m.", "Fila 4: 8 m; 5 dm = 0,5 m → 8,5 m. Fila 5: 6 km = 6000 m."],
    "54 m; 700,06 m; 8,5 m; 6000 m.")
lanz, enc = [12, 10, 8, 14, 16], [9, 7, 5, 10, 12]
p = F(sum(enc), sum(lanz))
assert p == F(43, 60)
sol(E, 5, ["Tiros lanzados: 12 + 10 + 8 + 14 + 16 = 60. Encestados: 9 + 7 + 5 + 10 + 12 = 43.", "Probabilidad estimada = frecuencia relativa = encestados / lanzados."],
    "43/60 (≈ 0,72).")
assert 1920 * F(35, 100) == 672
sol(E, 6, ["35 % de 1920 = 1920 × 0,35.", "(El número de entradas, 240, no es necesario.)"], "672 €.")
total = 6 * 8 + 4 * 3
cesped = total - F("3.14") * 2 ** 2
assert cesped == F("47.44")
sol(E, 7, ["Zona en L: rectángulo de (10 − 4) × 8 = 48 m² más rectángulo de 4 × 3 = 12 m² → 60 m².", "Círculo (margaritas): 3,14 × 2² = 12,56 m².",
           "Césped: 60 − 12,56."], "47,44 m².")
divs = [2, 3, 5, 9, 10]
tab = {n: ["SÍ" if n % d == 0 else "NO" for d in divs] for n in (246, 315, 540, 913, 720)}
assert tab[246] == ["SÍ", "SÍ", "NO", "NO", "NO"] and tab[913] == ["NO"] * 5
sol(E, 8, ["Criterios: 2 (termina en cifra par); 3 y 9 (la suma de cifras es múltiplo de 3 o de 9); 5 (termina en 0 o 5); 10 (termina en 0).",
           "Sumas de cifras: 246 → 12; 315 → 9; 540 → 9; 913 → 13; 720 → 9."],
    " · ".join(f"{n}: " + ", ".join(f"{d} {v}" for d, v in zip(divs, fila)) for n, fila in tab.items()) + ".")
assert F(4, 20) == F("0.2") and F("0.30") * 20 == 6 and F(5, 20) == F("0.25")
sol(E, 9, ["Frecuencia relativa = absoluta / 20.", "Teatro: 4/20 = 0,20. Baloncesto: 0,30 × 20 = 6. Música: 5/20 = 0,25.",
           "Comprobación: 5 + 4 + 6 + 5 = 20; 0,25 + 0,20 + 0,30 + 0,25 = 1."], "Teatro 0,20; Baloncesto 6; Música 0,25.")
esc = [(F("2.5"), 200, "cm"), (8, 50, "cm"), (F("4.2"), 1000, "cm"), (35, 20, "mm")]
reales = [F(v) * e / (100 if u == "cm" else 1000) for v, e, u in esc]
assert reales == [5, 4, 42, F("0.7")]
sol(E, 10, ["Medida real = medida en el plano × denominador de la escala.", "2,5 × 200 = 500 cm; 8 × 50 = 400 cm; 4,2 × 1000 = 4200 cm; 35 × 20 = 700 mm.",
            "En metros: ÷100 (cm) o ÷1000 (mm)."], "5 m; 4 m; 42 m; 0,7 m.")

# ------------------------------------------------------------------ 2026 A
E = "OF.2026.A"
l = 360 * F(1, 6); q1 = 360 - l; m_ = q1 * F(1, 5); q2 = q1 - m_; x = q2 * F(1, 4); q3 = q2 - x
assert (l, m_, x, q3) == (60, 60, 60, 180)
sol(E, 1, ["Lunes: 1/6 de 360 = 60; quedan 300.", "Martes: 1/5 de 300 = 60; quedan 240.", "Miércoles: 1/4 de 240 = 60; quedan 180."], "180 libros.")
A, B, C = 2 * 3600 + 45 * 60 + 30, 165 * 60 + 900, 3600 + 95 * 60 + 120
assert (A, B, C) == (9930, 10800, 9420) and A + B + C == 30150
sol(E, 2, ["A: 7200 + 2700 + 30 = 9930 s.", "B: 9900 + 900 = 10.800 s. C: 3600 + 5700 + 120 = 9420 s.", "Total: 9930 + 10.800 + 9420."], "30.150 segundos (8 h 22 min 30 s).")
assert F(10404, 36) == 289 and F(28560, 84) == 340
sol(E, 3, ["a = 10.404 : 36 = 289 (36 × 289 = 10.404).", "b = 28.560 : 84 = 340 (84 × 340 = 28.560)."], "a = 289; b = 340.")
txt, _ = orden([("5/4", F(5, 4)), ("1,18", F("1.18")), ("7/6", F(7, 6)), ("1,205", F("1.205"))])
sol(E, 4, ["5/4 = 1,25; 7/6 = 1,1666…", "Se comparan: 1,25 > 1,205 > 1,18 > 1,166…"], txt + ".")
k = F(15, 6)
assert 450 * k == 1125 and F("1.2") * k == 3 and 180 * k == 450
sol(E, 5, ["Razón: 15 : 6 = 2,5.", "Se multiplica cada cantidad por 2,5."], "1125 ml (1,125 l) de zumo de limón; 3 l de agua; 450 g de azúcar.")
primos = [n for n in range(1, 13) if n > 1 and all(n % d for d in range(2, n))]
assert primos == [2, 3, 5, 7, 11]
sol(E, 6, ["12 casos posibles; regla de Laplace.", "Par: 6/12 = 1/2. Primo (2, 3, 5, 7, 11): 5/12. Mayor que 10 (11, 12): 2/12 = 1/6. Menor que 13: 12/12 = 1 (suceso seguro)."],
    "Par 1/2; primo 5/12; mayor que 10 1/6; menor que 13 1.")
v = F("2.5") * F("1.2") * F("0.8")
assert v == F("2.4")
sol(E, 7, ["V = largo × ancho × alto = 2,5 × 1,2 × 0,8.", "1 m³ = 1000 l."], "2,4 m³ = 2400 litros.")
d = [6, 7, 7, 8, 9, 11]
assert mean(d) == 8 and median(d) == F(15, 2) and multimode(d) == [7]
sol(E, 8, ["Media: 48 : 6 = 8.", "Mediana: número par de datos → (7 + 8) : 2 = 7,5.", "Moda: 7. Rango: 11 − 6 = 5."], "Media 8; mediana 7,5; moda 7; rango 5.")
vals = [arabigo(x) for x in ("MDXLVIII", "CMXCIV", "MMCDLIII")]
assert vals == [1548, 994, 2453]
sol(E, 9, ["MDXLVIII = 1000 + 500 + 40 + 8.", "CMXCIV = 900 + 90 + 4.", "MMCDLIII = 2000 + 400 + 50 + 3."], "1548; 994; 2453.")
r = ((24 // 3) + 5) * 2 - 3 * (7 - (9 - 5))
assert r == 17
sol(E, 10, ["Paréntesis interiores: 24 : 3 = 8; 9 − 5 = 4.", "Corchetes: 8 + 5 = 13; 7 − 4 = 3.", "Llaves: 13 × 2 = 26; 3 × 3 = 9; 26 − 9."], "17.")


if __name__ == "__main__":
    for (e, n), t in sorted(SOLUCIONES.items()):
        print(f"{e} · M{n}: {t}")
    print(f"\n{len(SOLUCIONES)} soluciones calculadas; todas las comprobaciones (assert) se han cumplido.")
