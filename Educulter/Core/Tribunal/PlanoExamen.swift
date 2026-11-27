import Foundation

/// Plano del examen (05I §2, D-133): cuántas preguntas de cada competencia trae la prueba A1,
/// calculado de las 139 preguntas oficiales con más peso para las convocatorias recientes
/// (peso = año − 2016: 2017 pesa 1 y 2026 pesa 10). Las anuladas no cuentan.
struct PlanoExamen: Codable, Sendable, Equatable {
    struct Entrada: Codable, Sendable, Equatable {
        var competencia: String
        var area: String
        /// Peso relativo dentro del área (0…1).
        var peso: Double
        /// Preguntas de esta competencia en un examen de 10 por área (como mucho 2).
        var preguntas: Int
        var formato: FormatoPregunta
    }

    static let maximoPorCompetencia = 2
    var duracionMin = 90
    var preguntasPorArea: [String: Int]
    /// Por área, de más a menos peso.
    var entradas: [Entrada]

    func entradas(area: String) -> [Entrada] { entradas.filter { $0.area == area } }

    static func peso(anio: Int) -> Double { Double(max(anio - 2016, 1)) }

    static func calcular(_ datos: DatosTribunal) -> PlanoExamen {
        var pesos: [String: [String: Double]] = [:]           // área → competencia → peso
        var formatos: [String: [FormatoPregunta: Double]] = [:]
        var porArea: [String: Int] = [:]
        for e in datos.examenes {
            for q in e.preguntas where !q.esAnulada {
                porArea[q.area, default: 0] += 1
                let c = datos.competencia(examen: e.id, numero: q.numero) ?? q.competencias.first ?? "?"
                pesos[q.area, default: [:]][c, default: 0] += peso(anio: e.anio)
                formatos[c, default: [:]][q.formato, default: 0] += peso(anio: e.anio)
            }
        }
        let examenes = Double(max(datos.examenes.count, 1))
        var preguntasPorArea: [String: Int] = [:]
        var entradas: [Entrada] = []
        for area in pesos.keys.sorted() {
            let n = Int((Double(porArea[area] ?? 0) / examenes).rounded())
            preguntasPorArea[area] = n
            let total = pesos[area]!.values.reduce(0, +)
            let ordenadas = pesos[area]!.sorted { ($0.value, $1.key) > ($1.value, $0.key) }
            // Reparto de mayores restos con tope de 2 por competencia.
            let cuotas = ordenadas.map { (c: $0.key, cuota: $0.value / total * Double(n)) }
            var asignadas = cuotas.map { min(maximoPorCompetencia, Int($0.cuota)) }
            var faltan = n - asignadas.reduce(0, +)
            let porResto = cuotas.indices.sorted { (cuotas[$0].cuota - Double(Int(cuotas[$0].cuota)), -$0) > (cuotas[$1].cuota - Double(Int(cuotas[$1].cuota)), -$1) }
            for i in porResto + Array(cuotas.indices) where faltan > 0 && asignadas[i] < maximoPorCompetencia {
                asignadas[i] += 1
                faltan -= 1
            }
            for (i, c) in cuotas.enumerated() {
                let f = formatos[c.c]?.max { $0.value < $1.value }?.key ?? (area == "MAT" ? .calculo : .redactar)
                entradas.append(Entrada(competencia: c.c, area: area, peso: c.cuota / Double(max(n, 1)), preguntas: asignadas[i], formato: f))
            }
        }
        return PlanoExamen(preguntasPorArea: preguntasPorArea, entradas: entradas)
    }
}

/// Simulacro original (05I §2): 10 preguntas de Lengua y 10 de Matemáticas según el plano, con
/// contenido aprobado de dificultad 4–5. Reproducible con la misma semilla.
struct GeneradorSimulacro: Sendable {
    let banco: BancoContenido

    struct Simulacro: Sendable, Equatable {
        var preguntas: [SesionExamen.Pregunta]
        /// Competencias del plano sin contenido aprobado (se sustituyen por la siguiente más frecuente).
        var noIncluye: [String]
        var porCompetencia: [String: Int]
    }

    /// Ítems aprobados de una competencia en dificultad 4–5 (variantes de sus plantillas aprobadas
    /// ajustadas a 4 y 5, y estáticos aprobados de dificultad ≥ 4).
    func candidatos(_ competencia: String) -> [Item] {
        let estaticos = banco.itemsEstaticos.filter { $0.competencia == competencia && $0.dificultad >= 4 && $0.validacion.estado == .aprobado }
        let generados = banco.plantillas.filter { $0.competencia == competencia && $0.validacion.estado == .aprobado }.flatMap { p in
            [4, 5].flatMap { banco.variantes(de: MotorGeneradores.ajustada(p, dificultad: $0)) }
        }
        return (estaticos + generados).filter { $0.validacion.estado == .aprobado }
    }

    func generar(semilla: UInt64, plano: PlanoExamen, vistos: Set<String> = []) -> Simulacro {
        var rng = GeneradorConSemilla(semilla: semilla)
        var preguntas: [SesionExamen.Pregunta] = []
        var noIncluye: [String] = []
        var porCompetencia: [String: Int] = [:]
        var huellas = Set<String>()
        for area in ["LEN", "MAT"] {
            let entradas = plano.entradas(area: area)
            let objetivo = plano.preguntasPorArea[area] ?? 10
            var elegidas: [Item] = []
            var cache: [String: [Item]] = [:]
            func tomar(_ e: PlanoExamen.Entrada, _ n: Int) -> Int {
                if cache[e.competencia] == nil { cache[e.competencia] = candidatos(e.competencia) }
                var lista = cache[e.competencia]!.sorted { $0.id < $1.id }
                lista = rng.barajar(lista)
                // Las que piden redactar usan el patrón recuerdo, si hay; las demás, formato cerrado.
                lista.sort { a, b in
                    let pa = (e.formato == .redactar) == (a.mecanica == .recuerdo), pb = (e.formato == .redactar) == (b.mecanica == .recuerdo)
                    let va = vistos.contains(a.id), vb = vistos.contains(b.id)
                    return (pa ? 0 : 1, va ? 1 : 0) < (pb ? 0 : 1, vb ? 1 : 0)
                }
                var puestas = 0
                for i in lista where puestas < n && (porCompetencia[e.competencia] ?? 0) < PlanoExamen.maximoPorCompetencia {
                    guard huellas.insert(i.huella).inserted else { continue }
                    elegidas.append(i)
                    porCompetencia[e.competencia, default: 0] += 1
                    puestas += 1
                }
                return puestas
            }
            var deficit = 0
            for e in entradas where e.preguntas > 0 {
                let puestas = tomar(e, e.preguntas)
                if puestas < e.preguntas {
                    deficit += e.preguntas - puestas
                    if puestas == 0 { noIncluye.append(e.competencia) }
                }
            }
            // Lo que falta, con las siguientes más frecuentes (también las que el plano deja a 0).
            // De una en una, para no alejarse del plano más de una pregunta por competencia.
            for e in entradas where deficit > 0 && elegidas.count < objetivo {
                deficit -= tomar(e, 1)
            }
            preguntas += elegidas.map { .item(id: $0.id, area: area) }
        }
        return Simulacro(preguntas: preguntas, noIncluye: noIncluye, porCompetencia: porCompetencia)
    }
}
