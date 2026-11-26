import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Educulter

// Fase 05E parte 2, §2.2: personajes v3 (Tilde, Cuarto y Mimo) y marca «libro vivo».

@MainActor
enum RenderPersonaje {
    /// Render estático (sin animación) a 400 × 420 pt y escala 1, sobre el papel claro.
    static func imagen(_ c: Companero, _ e: EstadoPersonaje) -> UIImage? {
        let vista = FiguraV3(companero: c, estado: e, animar: false)
            .frame(width: 400, height: 420)
            .background(Color(hex: 0xFFF6EC))
            .environment(\.colorScheme, .light)
        let r = ImageRenderer(content: vista)
        r.scale = 1
        return r.uiImage
    }

    /// Diferencia media por canal (0–1) entre dos imágenes del mismo tamaño.
    static func diferencia(_ a: UIImage, _ b: UIImage) -> Double? {
        guard let pa = pixeles(a), let pb = pixeles(b), pa.count == pb.count else { return nil }
        var suma = 0.0
        for i in pa.indices { suma += abs(Double(pa[i]) - Double(pb[i])) }
        return suma / Double(pa.count) / 255
    }

    static func pixeles(_ i: UIImage) -> [UInt8]? {
        guard let cg = i.cgImage else { return nil }
        let w = cg.width, h = cg.height
        var datos = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &datos, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return datos
    }

    static var bundleTests: Bundle { Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") } ?? .main }
}

@Suite("Fase 05E parte 2 · Personajes v3")
struct PersonajesV3Tests {
    @Test("Reglas: cada evento da su personaje y estado (o ninguno), y VoiceOver solo cuando transmite un estado")
    func reglas() {
        let r = ReglasPersonaje.aparicion
        #expect(r(.acierto(area: "LEN")) == AparicionPersonaje(companero: .tilde, estado: .alegre))
        #expect(r(.acierto(area: "MAT")) == AparicionPersonaje(companero: .cuarto, estado: .alegre))
        #expect(r(.fallo) == nil)
        #expect(r(.errorRepetido) == AparicionPersonaje(companero: .mimo, estado: .animo))
        #expect(r(.pistaAbierta(area: "LEN")) == AparicionPersonaje(companero: .tilde, estado: .pensando))
        #expect(r(.record) == AparicionPersonaje(companero: .cuarto, estado: .guino) && r(.logro)?.estado == .guino)
        #expect(r(.modoDescanso) == AparicionPersonaje(companero: .mimo, estado: .descanso))
        #expect(r(.bienvenida)?.companero == .mimo && r(.primerDia)?.companero == .mimo)
        #expect(r(.subePeldano(area: "MAT"))?.estado == .alegre && r(.finSesion(area: nil))?.estado == .alegre)
        #expect(ReglasPersonaje.etiqueta(AparicionPersonaje(companero: .mimo, estado: .animo)) == "Mimo te anima")
        #expect(ReglasPersonaje.etiqueta(AparicionPersonaje(companero: .tilde, estado: .alegre)) == nil)
        var rng = GeneradorConSemilla(semilla: 3)
        for _ in 0..<200 { #expect((4...6).contains(ReglasPersonaje.intervaloParpadeo(&rng))) }
    }

    @Test("El intérprete SVG reproduce las cajas de las piezas")
    func trazado() {
        let corazon = TrazadoSVG.path("M200 352 C 160 320, 132 296, 134 270 C 136 248, 168 240, 200 266 C 232 240, 264 248, 266 270 C 268 296, 240 320, 200 352 Z").boundingRect
        #expect(abs(corazon.minY - 248) < 4 && abs(corazon.maxY - 352) < 0.5 && abs(corazon.midX - 200) < 0.5)
        let chispa = TrazadoSVG.path("M86 92 l14 22 -6 4 -14 -22 z").boundingRect
        #expect(chispa == CGRect(x: 80, y: 92, width: 20, height: 26))
        let pierna = TrazadoSVG.path("M150 330 L146 392 Q146 400 136 401 L108 404 Q92 404 96 392 Q100 384 118 382 L124 330 Z").boundingRect
        #expect(abs(pierna.maxY - 404) < 0.5 && abs(pierna.minY - 330) < 0.5)
    }

    @Test("Renders de todos los estados (se guardan para revisarlos)")
    @MainActor func renders() throws {
        // En el simulador se guardan en build/personajes_v3 del proyecto (para revisarlos a mano).
        let raiz = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"].map { URL(fileURLWithPath: $0).appendingPathComponent("Desktop/OpoCulter/build") }
        let carpeta = (raiz ?? FileManager.default.temporaryDirectory).appendingPathComponent("personajes_v3")
        try FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
        for c in Companero.allCases {
            for e in EstadoPersonaje.allCases {
                let img = try #require(RenderPersonaje.imagen(c, e))
                #expect(img.size == CGSize(width: 400, height: 420))
                try img.pngData()!.write(to: carpeta.appendingPathComponent("\(c.rawValue)_\(e.rawValue).png"))
            }
        }
        print("RENDERS \(carpeta.path)")
    }

    @Test("Prueba instantánea: cada personaje en estado neutro coincide con su referencia revisada", arguments: Companero.allCases)
    @MainActor func instantanea(_ c: Companero) throws {
        let url = try #require(RenderPersonaje.bundleTests.url(forResource: "referencia_\(c.rawValue)_neutro", withExtension: "png"))
        let referencia = try #require(UIImage(contentsOfFile: url.path))
        let actual = try #require(RenderPersonaje.imagen(c, .neutro))
        let d = try #require(RenderPersonaje.diferencia(actual, referencia))
        #expect(d < 0.01, "\(c.rawValue): diferencia media \(d)")
    }
}

@Suite("Fase 05E parte 2 · Avatares por datos")
struct AvatarCatalogoTests {
    @Test("Los avatares salen de avatares.json; sin archivo, el respaldo; la migración id % 6 sigue")
    func catalogo() throws {
        #expect(Avatar.todos.count == 6 && Avatar.todos.map(\.recurso) == (1...6).map { String(format: "avatar_%02d", $0) })
        #expect(AvatarCatalogo.cargar(nil).avatares == AvatarCatalogo.respaldo)
        let carpeta = try Fx.carpetaContenido(["avatares.json": #"{"avatares": [{"id": 0, "recurso": "personaje_01", "nombre": "brote azul"}]}"#])
        let otro = AvatarCatalogo.cargar(carpeta)
        #expect(otro.avatares == [Avatar(id: 0, nombre: "brote azul", recurso: "personaje_01")])
        #expect(Avatar.migrar(9) == 3 && Avatar.con(id: 2)?.nombre == "cinta deportiva")
    }
}
