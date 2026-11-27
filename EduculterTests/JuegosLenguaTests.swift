import Foundation
import Testing
@testable import Educulter

// Tests de la Fase 05H: Rayos X, Editor, Fábrica de palabras, recursos, glosario y decisiones de la 05G.

private let banco: BancoContenido = (try? CargadorContenido.desdeBundle().cargar(politica: .todos, semillaBase: 5))!
private let validador = ValidadorContenido(anioActual: 2026)
private let competencias = Set(banco.catalogo.todasLasCompetencias.map(\.id))

private func plantillas(_ tipo: String, _ mecanica: Mecanica? = nil) -> [Plantilla] {
    banco.plantillas.filter { $0.tipo == tipo && (mecanica == nil || $0.mecanica == mecanica) }
}

private func items(_ p: Plantilla) throws -> [Item] {
    try (UInt64(0)..<200).map { try MotorGeneradores.generar(p, semilla: $0, recursos: banco.recursos) }
}

private func sinTildes(_ s: String) -> String { s.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES")).lowercased() }

@Suite("05H · Lengua manipulativa")
struct JuegosLenguaTests {
    @Test("Rayos X: 200 semillas por plantilla; una sola solución por capa, la correcta acierta y el sujeto omitido se deduce del verbo")
    func rayosX() throws {
        let ps = plantillas("oracionSimple", .rayosX)
        #expect(ps.count == 6)
        var omitidos = 0
        for p in ps {
            for item in try items(p) {
                #expect(validador.validar(item: item, competencias: competencias).isEmpty, "\(item.id)")
                guard case .rayosX(let x) = item.payload else { Issue.record("\(item.id)"); continue }
                // Oráculo: la estructura de oracionSimple (tokens con su clase).
                let clases = (item.datosRayos ?? []).map(\.1)
                let verbos = x.tokens.indices.filter { clases.indices.contains($0) && clases[$0] == "verbo" }
                #expect(verbos.count == 1 && x.verbo == [x.tokens[verbos[0]].id], "\(item.id): el verbo es único")
                let pos = Dictionary(uniqueKeysWithValues: x.tokens.enumerated().map { ($1.id, $0) })
                if !x.sujeto.isEmpty {
                    let i = x.sujeto.compactMap { pos[$0] }.sorted()
                    #expect(i == Array(i.first!...i.last!), "\(item.id): sujeto seguido")
                }
                #expect(Set(x.grupos.map(\.funcion)).count == x.grupos.count, "\(item.id): una función por grupo")
                for capa in 1...x.capas { #expect(x.errores(capa: capa, x.respuestaCorrecta).isEmpty) }
                #expect(Evaluador.evaluar(.rayosX(x.respuestaCorrecta), para: item).correcto)
                #expect(!Evaluador.evaluar(RespuestaEjemplo.conUnError(item.payload), para: item).correcto)
                if let o = x.omitido {
                    omitidos += 1
                    #expect(p.dificultad >= 3)
                    let persona = try #require(GeneradorOracionSimple.personas.firstIndex(of: o))
                    let formas = Conjugador.formas(item.datosVerbo.0, tiempo: item.datosVerbo.1, modo: Conjugador.indicativo, irregulares: banco.recursos.verbos.irregulares)
                    #expect(formas?[persona].lowercased() == x.texto(x.verbo).lowercased().trimmingCharacters(in: .punctuationCharacters), "\(item.id)")
                    // Sin ambigüedad: la forma solo es de esa persona, y en las copulativas el número es el del sujeto.
                    #expect(formas?.filter { $0 == formas?[persona] }.count == 1, "\(item.id): «\(x.texto(x.verbo))» es de varias personas")
                    if x.predicado == "Predicado nominal" {
                        let numero = try MotorGeneradores.muestra(p, semilla: MotorGeneradores.partes(de: item.id)!.semilla, recursos: banco.recursos).datos["numero"]
                        #expect((persona >= 3) == (numero == "p"), "\(item.id): el atributo no concordaría")
                    }
                }
            }
        }
        #expect(omitidos > 20)
    }

    @Test("Editor: 200 semillas; la frase alterada difiere solo en las palabras sustituidas, de su misma familia")
    func editor() throws {
        let ps = plantillas("editor")
        #expect(ps.count == 7)
        let familias = banco.recursos.frases.familias
        for p in ps {
            let (_, nFaltas) = GeneradorEditor.forma(p.dificultad)
            for item in try items(p) {
                #expect(validador.validar(item: item, competencias: competencias).isEmpty, "\(item.id)")
                guard case .editor(let e) = item.payload else { Issue.record("\(item.id)"); continue }
                #expect(e.faltas.count == nFaltas && e.penalizacion == (p.dificultad >= 5))
                // Oráculo: la frase original. Al corregir las faltas, el texto es el original.
                let corregido = e.tokens.map { t in e.faltas.first { $0.token == t.id }?.correcta ?? t.texto }.joined(separator: " ")
                let original = try #require(item.datosEditor)
                #expect(corregido == original, "\(item.id)")
                for f in e.faltas {
                    let escrita = e.tokens.first { $0.id == f.token }!.texto
                    #expect(escrita != f.correcta)
                    let nucleo = { (s: String) in s.trimmingCharacters(in: CharacterSet(charactersIn: "¿¡?!.,;:")).lowercased() }
                    #expect(familias.contains { fam in
                        let formas = fam.formas.map { $0.texto.lowercased() }
                        return formas.contains(nucleo(escrita)) && formas.contains(nucleo(f.correcta))
                    }, "\(item.id): misma familia")
                    #expect(f.tilde == (sinTildes(nucleo(escrita)) == sinTildes(nucleo(f.correcta))))
                }
                #expect(Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item).correcto)
                #expect(!Evaluador.evaluar(RespuestaEjemplo.conUnError(item.payload), para: item).correcto)
            }
        }
    }

    @Test("Fábrica: 200 semillas; clasificación, piezas, morfemas y familias según el ANEXO A; ningún distractor forma una palabra real")
    func fabrica() throws {
        let datos = try #require(banco.recursos.formacion)
        let porPalabra = Dictionary(uniqueKeysWithValues: datos.palabras.map { ($0.palabra, $0) })
        let conocidas = GeneradorFormacion.conocidas(datos, lexico: banco.recursos.lexico)
        let ps = plantillas("formacion")
        #expect(ps.count == 6)
        for p in ps {
            for item in try items(p) {
                #expect(validador.validar(item: item, competencias: competencias).isEmpty, "\(item.id)")
                switch item.payload {
                case .clasificar(let c) where p.textos("modo", porDefecto: []).first == "familia":
                    let f = try #require(datos.familias.first { item.enunciado.contains("«\($0.primitiva)»") })
                    for ficha in c.fichas {
                        #expect(ficha.categoria == "si" ? f.miembros.contains(ficha.texto) : f.falsas.contains(ficha.texto), "\(item.id)")
                    }
                case .clasificar(let c):
                    #expect(c.fichas.count == 4)
                    for ficha in c.fichas { #expect(porPalabra[ficha.texto]?.tipo == ficha.categoria, "\(item.id): \(ficha.texto)") }
                case .construir(let c):
                    let porId = Dictionary(uniqueKeysWithValues: c.piezas.map { ($0.id, $0.texto) })
                    let palabra = c.huecosEnPlantilla.compactMap { id in c.huecos.first { $0.id == id }.flatMap { porId[$0.correcta] } }
                        .joined().replacingOccurrences(of: "-", with: "")
                    let w = try #require(datos.palabras.first { sinTildes($0.palabra) == sinTildes(palabra) }, "\(item.id): \(palabra)")
                    #expect(!w.soloClasificar && item.enunciado.contains(w.definicion))
                    let piezas = c.piezas.map { $0.texto.replacingOccurrences(of: "-", with: "") }
                    #expect(GeneradorFormacion.sinPalabraReal(piezas, n: c.huecos.count, objetivo: w.palabra, conocidas: conocidas), "\(item.id)")
                case .segmentar(let s):
                    let palabra = s.tokens.map(\.texto).joined()
                    let w = try #require(porPalabra[palabra])
                    let pos = Dictionary(uniqueKeysWithValues: s.tokens.enumerated().map { ($1.id, $0) })
                    let partes = s.segmentos.map { seg in s.tokens[pos[seg.desde]!...pos[seg.hasta]!].map(\.texto).joined() }
                    #expect(partes == w.piezas.map(\.texto) && s.segmentos.map(\.etiqueta) == w.piezas.map(\.clase), "\(item.id)")
                default: Issue.record("\(item.id): mecánica inesperada")
                }
                #expect(Evaluador.evaluar(RespuestaEjemplo.correcta(item.payload), para: item).correcto)
            }
        }
    }

    @Test("Recursos y glosario: 200 semillas; los recursos «también presentes» nunca son distractores y los términos se mezclan solo con su grupo")
    func recursosYGlosario() throws {
        let datos = try #require(banco.recursos.recursosLiterarios)
        let glosario = try #require(banco.recursos.glosario)
        for p in plantillas("recursos") + plantillas("glosario") {
            for item in try items(p) {
                #expect(validador.validar(item: item, competencias: competencias).isEmpty, "\(item.id)")
                switch (p.tipo, item.payload) {
                case ("recursos", .eleccion(let e)):
                    let r = try #require(datos.recursos.first { $0.ejemplos.contains { item.enunciado.contains($0.texto) } })
                    #expect(e.opciones.first { $0.id == e.correcta }?.texto == r.recurso)
                    #expect(!e.opciones.contains { r.tambien.contains($0.texto) }, "\(item.id)")
                case ("recursos", .marcarTexto(let m)):
                    let marcado = m.tokens.filter { m.correctos.contains($0.id) }.map(\.texto).joined(separator: " ")
                    let ejemplo = try #require(datos.recursos.flatMap(\.ejemplos).first { $0.texto == m.tokens.map(\.texto).joined(separator: " ") })
                    for marca in ejemplo.marcas { #expect(marcado.contains(marca.components(separatedBy: " ").first!), "\(item.id)") }
                case ("recursos", .emparejar(let e)), ("glosario", .emparejar(let e)):
                    for par in e.pares {
                        let izq = e.izquierda.first { $0.id == par[0] }!.texto, der = e.derecha.first { $0.id == par[1] }!.texto
                        #expect(datos.recursos.contains { $0.recurso == izq && $0.definicion == der } || glosario.terminos.contains { $0.termino == izq && $0.definicion == der })
                    }
                case (_, .recuerdo(let r)):
                    // Definir (05I): el modelo es la definición del anexo.
                    #expect(datos.recursos.contains { r.modelo.contains($0.definicion) } || glosario.terminos.contains { r.modelo.contains($0.definicion) }, "\(item.id)")
                case ("glosario", .eleccion(let e)):
                    let grupo = p.textos("grupo", porDefecto: []).first
                    let terminos = Set(glosario.terminos.filter { $0.grupo == grupo }.map(\.termino))
                    #expect(e.opciones.allSatisfy { terminos.contains($0.texto) }, "\(item.id)")
                    #expect(glosario.terminos.first { item.enunciado.contains($0.definicion) }?.termino == e.opciones.first { $0.id == e.correcta }?.texto)
                default: Issue.record("\(item.id): mecánica inesperada")
                }
            }
        }
    }

    @Test("Decisiones de la 05G: INFER.0003 y su variante no salen juntas ni en días seguidos; restar sin hueco es un fallo con pista")
    @MainActor
    func decisiones05G() throws {
        let a = try #require(banco.item(id: "LEN.COM.INFER.0003")), b = try #require(banco.item(id: "LEN.COM.INFER.0004"))
        #expect(a.huella == b.huella && [a, b].sinPreguntasRepetidas().count == 1)
        let repo = RepositorioEnMemoria()
        func servicio(_ dia: Int) -> ServicioSesion {
            ServicioSesion(banco: banco, repositorio: repo, reloj: RelojFijo(ahora: Fx.fecha(2026, 11, dia)), calendario: Fx.madrid,
                           rng: GeneradorConSemilla(semilla: 2))
        }
        _ = try servicio(26).registrar(item: a, resultado: Evaluador.evaluar(RespuestaEjemplo.correcta(a.payload), para: a),
                                       usoPista: false, combo: 1, motivo: .nuevo)
        #expect(try servicio(27).huellasBloqueadas() == [a.huella], "Al día siguiente, bloqueada")
        #expect(try servicio(28).huellasBloqueadas().isEmpty, "Pasado un día, libre")

        // J63: «Restar el hueco» en una figura sin hueco.
        let casa = try MotorGeneradores.generar(try #require(banco.plantilla(id: "MAT.GEO.AREA.G03")), semilla: 1, recursos: banco.recursos)
        guard case .figuraArea(let f) = casa.payload else { Issue.record("payload"); return }
        var r = f.respuestaCorrecta
        r.estrategia = .restar
        let resultado = Evaluador.evaluar(.figura(r), para: casa)
        #expect(!resultado.correcto && resultado.errores == ["sinHueco"])
        #expect(Evaluador.feedback(para: resultado, item: casa).first == "Aquí no hay hueco que quitar: la figura se forma sumando partes.")
    }
}

private extension Item {
    /// Tokens de la oración con su clase (datos del generador).
    var datosRayos: [(String, String)]? {
        guard let m = try? MotorGeneradores.muestra(banco.plantilla(id: MotorGeneradores.partes(de: id)!.plantilla)!,
                                                     semilla: MotorGeneradores.partes(de: id)!.semilla, recursos: banco.recursos) else { return nil }
        return (m.datos["tokensVistos"] ?? m.datos["tokens"])?.split(separator: " ").map { t in let p = t.split(separator: "/"); return (String(p[0]), String(p.last!)) }
    }

    var datosVerbo: (String, String) {
        let m = try! MotorGeneradores.muestra(banco.plantilla(id: MotorGeneradores.partes(de: id)!.plantilla)!,
                                               semilla: MotorGeneradores.partes(de: id)!.semilla, recursos: banco.recursos)
        return (m.datos["verbo"] ?? "", m.datos["tiempo"] ?? "Presente")
    }

    var datosEditor: String? {
        guard let p = MotorGeneradores.partes(de: id), let pl = banco.plantilla(id: p.plantilla),
              let m = try? MotorGeneradores.muestra(pl, semilla: p.semilla, recursos: banco.recursos) else { return nil }
        return m.datos["originales"]
    }
}
