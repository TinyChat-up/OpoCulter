import Foundation
import Testing
@testable import Educulter

// Recuperación (25/11/2026), §4.3: plantillas de ortografía sobre frases.json (lote 02b).
// Condiciones de aprobación: una sola opción correcta por frase y distractores = las otras formas
// de su familia; explicación con el `uso` de la forma correcta; dificultad 1–6 no decreciente con
// el nivel pedido; ninguna frase repetida en una misma ronda.

private let bancoFrases = try! CargadorContenido.desdeBundle().cargar(politica: .todos)
private var frases: BancoFrases { bancoFrases.recursos.frases }

/// Texto de la frase de un ítem: en `eleccion` va en el enunciado; en `construir`, en la plantilla.
private func fraseDe(_ item: Item) -> String {
    // Desde la 05H, el hueco y el Editor declaran la frase del banco de la que salen.
    if let origen = item.origen { return origen }
    if case .construir(let c) = item.payload { return c.plantilla }
    return item.enunciado
}

@Suite("Frases con hueco (lote 02b): condiciones de aprobación")
struct FrasesHuecoTests {
    static let plantillas = bancoFrases.plantillas.filter { $0.tipo == "fraseHueco" }

    @Test("Las 4 plantillas existen con sus familias y los datos son coherentes")
    func datos() {
        #expect(Set(Self.plantillas.map(\.id)) == ["LEN.ORT.DIA.G01", "LEN.ORT.PQ.G01", "LEN.ORT.HOM.G01", "LEN.ORT.HOM.G02"])
        #expect(frases.familias.count == 28 && frases.frases.count == 100)
        for f in frases.frases {
            #expect((1...6).contains(f.dificultad), "\(f.id): dificultad \(f.dificultad)")
            #expect(f.texto.contains("___"), "\(f.id) sin hueco")
            let familia = frases.familias.first { $0.id == f.familia }
            // La correcta es exactamente una forma de su familia (con la mayúscula del inicio de frase).
            let coincidencias = familia?.formas.filter { $0.texto.lowercased() == f.correcta.lowercased() } ?? []
            #expect(coincidencias.count == 1, "\(f.id): «\(f.correcta)» en \(familia?.formas.map(\.texto) ?? [])")
            #expect(coincidencias.allSatisfy { !$0.uso.isEmpty }, "\(f.id): forma sin uso")
        }
        #expect(Set(frases.frases.map(\.id)).count == frases.frases.count, "ids de frase únicos")
    }

    @Test("Una sola opción correcta, distractores de la familia y explicación con el uso (1000 semillas por nivel)",
          arguments: plantillas, 1...6)
    func reglas(_ base: Plantilla, _ dificultad: Int) throws {
        var p = base
        p.dificultad = dificultad
        let familiasPlantilla = Set(base.textos("familias", porDefecto: []))
        // Nivel de frase esperado: el pedido o, si no hay frases de ese nivel, el inferior más próximo.
        let delasFamilias = frases.frases.filter { familiasPlantilla.contains($0.familia) }
        // (si no hay ninguno, el más fácil disponible).
        let esperado = stride(from: dificultad, through: 1, by: -1).first { d in delasFamilias.contains { $0.dificultad == d } }
            ?? delasFamilias.map(\.dificultad).min()
        var fallos: [String] = []
        for semilla in UInt64(0)..<1000 {
            let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoFrases.recursos)
            let item = MotorGeneradores.item(p, semilla: semilla, muestra: m)
            guard let f = frases.frases.first(where: { $0.id == m.datos["frase"] }),
                  let familia = frases.familias.first(where: { $0.id == f.familia }) else { fallos.append("frase desconocida"); continue }
            if !familiasPlantilla.contains(f.familia) { fallos.append("\(f.id): familia \(f.familia) ajena a la plantilla") }
            if f.dificultad != esperado { fallos.append("\(f.id): dificultad \(f.dificultad) en el nivel \(dificultad) (esperada \(esperado ?? 0))") }
            let mayuscula = f.correcta.first?.isUppercase == true
            let formas = familia.formas.map { mayuscula ? $0.texto.prefix(1).uppercased() + $0.texto.dropFirst() : $0.texto }
            switch item.payload {
            case .eleccion(let e):
                let textos = e.opciones.map(\.texto)
                if Set(textos) != Set(formas) || textos.count != formas.count { fallos.append("\(f.id): opciones \(textos) ≠ familia \(formas)") }
                if textos.filter({ $0 == f.correcta }).count != 1 { fallos.append("\(f.id): la correcta no aparece una sola vez") }
                if e.opciones.first(where: { $0.id == e.correcta })?.texto != f.correcta { fallos.append("\(f.id): opción correcta mal marcada") }
            case .construir(let c):
                let piezas = c.piezas.map(\.texto)
                if Set(piezas) != Set(formas) { fallos.append("\(f.id): piezas \(piezas) ≠ familia \(formas)") }
                if c.huecos.count != 1 || c.piezas.first(where: { $0.id == c.huecos[0].correcta })?.texto != f.correcta { fallos.append("\(f.id): hueco mal resuelto") }
                if piezas.filter({ $0 == f.correcta }).count != 1 { fallos.append("\(f.id): la correcta no aparece una sola vez") }
            default: fallos.append("mecánica inesperada \(item.mecanica)")
            }
            // Explicación: el uso de la forma correcta (campo `uso`).
            let uso = familia.formas.first { $0.texto.lowercased() == f.correcta.lowercased() }!.uso
            if !item.explicacion.contains(uso) { fallos.append("\(f.id): la explicación no da el uso «\(uso)»") }
            if !(1...6).contains(item.dificultad) { fallos.append("dificultad del ítem \(item.dificultad)") }
            if fallos.count >= 5 { break }
        }
        #expect(fallos.isEmpty, "\(fallos)")
    }

    @Test("La dificultad de la frase no decrece con el nivel pedido", arguments: plantillas)
    func dificultadNoDecreciente(_ base: Plantilla) throws {
        var medias: [Double] = []
        for d in 1...6 {
            var p = base
            p.dificultad = d
            var suma = 0
            for semilla in UInt64(0)..<300 {
                let m = try MotorGeneradores.muestra(p, semilla: semilla, recursos: bancoFrases.recursos)
                suma += frases.frases.first { $0.id == m.datos["frase"] }!.dificultad
            }
            medias.append(Double(suma) / 300)
        }
        for d in 1..<6 { #expect(medias[d] >= medias[d - 1], "\(base.id): \(medias)") }
        #expect(medias[5] > medias[0], "\(base.id): \(medias)")
    }

    @Test("Ninguna frase se repite en una misma ronda (práctica, ronda del motor, Reto y Supervivencia)")
    @MainActor
    func sinRepetidas() throws {
        let banco = bancoFrases
        var rng = GeneradorConSemilla(semilla: 21)
        func sinRepetir(_ items: [Item], _ contexto: String) {
            let competencias: Set<String> = ["LEN.ORT.DIA", "LEN.ORT.PQ", "LEN.ORT.HOM"]
            let deFrases = items.filter { $0.id.contains(".G") && competencias.contains($0.competencia) }
            let textos = deFrases.map(fraseDe)
            #expect(Set(textos).count == textos.count, "\(contexto): \(textos)")
            #expect(Set(items.map(\.huella)).count == items.count, "\(contexto): pregunta repetida")
        }
        // Práctica de cada competencia en cada peldaño, con varias semillas.
        for competencia in ["LEN.ORT.DIA", "LEN.ORT.PQ", "LEN.ORT.HOM"] {
            for peldano in 1...4 {
                for semilla in UInt64(0)..<40 {
                    let repo = RepositorioEnMemoria()
                    var estado = EstadoCompetencia(competenciaId: competencia)
                    estado.escalera = EstadoEscalera(peldano: peldano, ventana: [])
                    try repo.guardar(estado)
                    let s = ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, 24, 10)),
                                           calendario: Fx.madrid, rng: GeneradorConSemilla(semilla: semilla))
                    let practica = try s.prepararRonda(.competencia(competencia))
                    sinRepetir(practica.items.compactMap { banco.item(id: $0.itemId) }, "práctica \(competencia) p\(peldano)")
                    let ronda = ConstructorRondas(banco: banco).construir(estados: [competencia: estado], rescate: ColaRescate(), enCurso: competencia,
                                                                          vistos: [:], ahora: Fx.fecha(2026, 11, 24, 10), calendario: Fx.madrid, rng: &rng)
                    sinRepetir(ronda.items.compactMap { banco.item(id: $0.itemId) }, "ronda \(competencia) p\(peldano)")
                }
            }
        }
        // Reto del bloque (dificultad 4–5: pocas frases de ese nivel y dos plantillas de HOM que recurren a las mismas).
        let camino = ConstructorCamino(banco: banco)
        for _ in 0..<60 { sinRepetir(camino.itemsReto("LEN.ORT", rng: &rng), "Reto LEN.ORT") }
        // Supervivencia de Lengua: partidas largas a dificultad alta.
        let selector = SelectorSupervivencia(banco: banco)
        for semilla in UInt64(0)..<10 {
            var r = GeneradorConSemilla(semilla: semilla)
            var partida: [Item] = []
            for k in 0..<40 {
                guard let item = selector.siguiente(dificultad: 3 + k % 4, area: "LEN", debilidades: ["LEN.ORT": 1], usados: Set(partida.map(\.id)),
                                                    huellasUsadas: Set(partida.map(\.huella)), rng: &r) else { break }
                partida.append(item)
            }
            sinRepetir(partida, "Supervivencia \(semilla)")
        }
    }
}
