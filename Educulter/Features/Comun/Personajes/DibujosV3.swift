import SwiftUI

/// Dibujos de los personajes (05E parte 2, D-105; recoloreados con la paleta editorial, D-109): los tres
/// personajes del propietario redibujados en SVG por la dirección (`docs/arte/v3/tilde.svg`, `cuarto.svg`, `mimo.svg`). Cada grupo conserva
/// el `id` del SVG y sus datos exactos; el orden es el de pintado del SVG.
enum DibujosV3 {
    static let lienzoPersonaje = CGSize(width: 400, height: 420)

    static let tilde: [GrupoSVG] = [
        GrupoSVG(id: "piernas", piezas: [
            PiezaSVG(forma: .trazado("M150 330 L146 392 Q146 400 136 401 L108 404 Q92 404 96 392 Q100 384 118 382 L124 330 Z"), relleno: 0xA9BD9F, silueta: true),
            PiezaSVG(forma: .trazado("M232 330 L236 382 Q258 384 262 394 Q264 404 248 404 L222 402 Q212 400 212 392 L208 330 Z"), relleno: 0xA9BD9F, silueta: true),
        ], ancla: CGPoint(x: 180, y: 404)),
        GrupoSVG(id: "cuerpo", piezas: [
            PiezaSVG(forma: .trazado("M196 110 C 270 108, 330 190, 332 270 C 334 330, 280 350, 196 350 C 116 350, 72 326, 74 262 C 76 180, 128 112, 196 110 Z"), relleno: 0xA9BD9F, silueta: true),
        ], ancla: CGPoint(x: 200, y: 350)),
        GrupoSVG(id: "brazoDer", piezas: [
            PiezaSVG(forma: .trazado("M318 220 C 340 196, 346 160, 350 140 C 354 122, 380 124, 382 146 C 384 180, 362 216, 330 246 Z"), relleno: 0xA9BD9F, silueta: true),
        ], ancla: CGPoint(x: 324, y: 234)),
        GrupoSVG(id: "brote", piezas: [
            PiezaSVG(forma: .trazado("M196 112 C 194 100, 194 92, 196 84"), relleno: nil, trazo: 0xC98A2E, grosor: 9),
            PiezaSVG(forma: .trazado("M195 88 C 172 88, 142 78, 138 54 C 134 30, 156 18, 174 26 C 192 34, 198 60, 195 88 Z"), relleno: 0xC98A2E),
            PiezaSVG(forma: .trazado("M198 86 C 206 64, 222 44, 246 44 C 266 44, 274 66, 262 80 C 250 94, 222 94, 198 86 Z"), relleno: 0xC98A2E),
        ], ancla: CGPoint(x: 196, y: 112)),
        GrupoSVG(id: "ojoDer", piezas: [
            PiezaSVG(forma: .elipse(cx: 246, cy: 208, rx: 30, ry: 34), relleno: 0xF4F8F0),
            PiezaSVG(forma: .elipse(cx: 248, cy: 212, rx: 17, ry: 19), relleno: 0x16241F),
            PiezaSVG(forma: .circulo(242, 204, 6), relleno: 0xFFFFFF),
        ], ancla: CGPoint(x: 246, y: 208)),
        GrupoSVG(id: "lupa", piezas: [
            PiezaSVG(forma: .trazado("M112 262 L 72 352"), relleno: nil, trazo: 0x16241F, grosor: 18),
            PiezaSVG(forma: .circulo(140, 196, 60), relleno: 0xE7F0E0, trazo: 0x16241F, grosor: 16),
            PiezaSVG(forma: .elipse(cx: 146, cy: 196, rx: 34, ry: 38), relleno: 0xF4F8F0),
            PiezaSVG(forma: .elipse(cx: 150, cy: 200, rx: 21, ry: 23), relleno: 0x16241F),
            PiezaSVG(forma: .circulo(143, 190, 7), relleno: 0xFFFFFF),
        ], ancla: CGPoint(x: 140, y: 196)),
        GrupoSVG(id: "brazoIzq", piezas: [
            PiezaSVG(forma: .trazado("M120 270 C 96 262, 70 270, 66 292 C 62 312, 84 320, 104 310 C 118 302, 126 290, 120 270 Z"), relleno: 0x93A889),
        ], ancla: CGPoint(x: 120, y: 270)),
        GrupoSVG(id: "boca", piezas: [
            PiezaSVG(forma: .trazado("M178 262 C 196 270, 214 270, 226 260 C 224 292, 212 306, 200 306 C 186 306, 178 290, 178 262 Z"), relleno: 0x16241F),
        ], ancla: CGPoint(x: 202, y: 280)),
    ]

    static let cuarto: [GrupoSVG] = [
        GrupoSVG(id: "piernas", piezas: [
            PiezaSVG(forma: .trazado("M160 340 L150 388 Q130 390 124 398 Q120 406 134 406 L170 406 Q180 404 182 394 L190 340 Z"), relleno: 0x2F4A40, silueta: true),
            PiezaSVG(forma: .trazado("M222 340 L222 394 Q224 404 236 406 L270 406 Q284 404 278 396 Q272 388 252 388 L250 340 Z"), relleno: 0x2F4A40, silueta: true),
        ], ancla: CGPoint(x: 200, y: 406)),
        GrupoSVG(id: "brazos", piezas: [
            PiezaSVG(forma: .trazado("M110 250 C 74 252, 60 290, 80 312 C 98 330, 130 326, 136 310 Z M290 250 C 326 252, 340 290, 320 312 C 302 330, 270 326, 264 310 Z"), relleno: 0x2F4A40, silueta: true),
        ], ancla: CGPoint(x: 200, y: 280)),
        GrupoSVG(id: "cuerpo", piezas: [
            PiezaSVG(forma: .trazado("M200 96 C 270 96, 300 170, 300 250 C 300 320, 262 360, 200 360 C 138 360, 100 320, 100 250 C 100 170, 130 96, 200 96 Z"), relleno: 0x2F4A40, silueta: true),
        ], ancla: CGPoint(x: 200, y: 360)),
        GrupoSVG(id: "barriga", piezas: [
            PiezaSVG(forma: .trazado("M200 248 C 252 248, 282 286, 276 316 C 270 346, 236 354, 200 354 C 164 354, 128 348, 124 316 C 120 286, 150 248, 200 248 Z"), relleno: 0xE7F0E0),
        ], ancla: CGPoint(x: 200, y: 300)),
        GrupoSVG(id: "brote", piezas: [
            PiezaSVG(forma: .trazado("M200 98 C 198 86, 198 78, 200 70"), relleno: nil, trazo: 0xA9BD9F, grosor: 9),
            PiezaSVG(forma: .trazado("M199 74 C 176 74, 146 64, 142 40 C 138 16, 160 4, 178 12 C 196 20, 202 46, 199 74 Z"), relleno: 0xA9BD9F),
            PiezaSVG(forma: .trazado("M202 72 C 210 50, 226 30, 250 30 C 270 30, 278 52, 266 66 C 254 80, 226 80, 202 72 Z"), relleno: 0xA9BD9F),
        ], ancla: CGPoint(x: 200, y: 98)),
        GrupoSVG(id: "ojoIzq", piezas: [
            PiezaSVG(forma: .elipse(cx: 164, cy: 176, rx: 30, ry: 33), relleno: 0xF4F8F0),
            PiezaSVG(forma: .elipse(cx: 168, cy: 180, rx: 17, ry: 19), relleno: 0x16241F),
            PiezaSVG(forma: .circulo(162, 172, 6), relleno: 0xFFFFFF),
        ], ancla: CGPoint(x: 164, y: 176)),
        GrupoSVG(id: "ojoDerGuino", piezas: [
            PiezaSVG(forma: .trazado("M216 186 C 224 162, 252 160, 260 182"), relleno: nil, trazo: 0xF4F8F0, grosor: 9),
        ], ancla: CGPoint(x: 238, y: 176)),
        GrupoSVG(id: "boca", piezas: [
            PiezaSVG(forma: .trazado("M184 216 C 192 232, 214 232, 222 216"), relleno: nil, trazo: 0xF4F8F0, grosor: 7),
        ], ancla: CGPoint(x: 203, y: 224)),
        GrupoSVG(id: "chispas", piezas: [
            PiezaSVG(forma: .trazado("M86 92 l14 22 -6 4 -14 -22 z"), relleno: 0xC98A2E),
            PiezaSVG(forma: .trazado("M70 128 l26 4 -1 7 -26 -4 z"), relleno: 0xC98A2E),
            PiezaSVG(forma: .trazado("M60 104 l22 14 -4 6 -22 -14 z"), relleno: 0xC98A2E),
        ], ancla: CGPoint(x: 80, y: 110)),
    ]

    /// Ojo derecho abierto de Cuarto (estados que no son el guiño): el izquierdo reflejado en el eje del
    /// cuerpo (x = 200) y desplazado al centro del guiño del SVG (x = 238). Derivado del original.
    static let cuartoOjoDerAbierto = GrupoSVG(id: "ojoDer", piezas: [
        PiezaSVG(forma: .elipse(cx: 238, cy: 176, rx: 30, ry: 33), relleno: 0xF4F8F0),
        PiezaSVG(forma: .elipse(cx: 234, cy: 180, rx: 17, ry: 19), relleno: 0x16241F),
        PiezaSVG(forma: .circulo(240, 172, 6), relleno: 0xFFFFFF),
    ], ancla: CGPoint(x: 238, y: 176))

    static let mimo: [GrupoSVG] = [
        GrupoSVG(id: "cuerpo", piezas: [
            PiezaSVG(forma: .trazado("M200 104 C 280 104, 318 190, 322 280 C 324 336, 320 370, 306 382 L 96 382 C 82 370, 78 336, 80 280 C 84 190, 120 104, 200 104 Z"), relleno: 0xE7F0E0, trazo: 0x9FB396, grosor: 3),
        ], ancla: CGPoint(x: 200, y: 382)),
        GrupoSVG(id: "brote", piezas: [
            PiezaSVG(forma: .trazado("M204 106 C 204 94, 206 86, 210 78"), relleno: nil, trazo: 0x2F4A40, grosor: 9),
            PiezaSVG(forma: .trazado("M207 82 C 184 82, 154 72, 150 48 C 146 24, 168 12, 186 20 C 204 28, 210 54, 207 82 Z"), relleno: 0x2F4A40),
            PiezaSVG(forma: .trazado("M210 80 C 218 58, 234 38, 258 38 C 278 38, 286 60, 274 74 C 262 88, 234 88, 210 80 Z"), relleno: 0x2F4A40),
        ], ancla: CGPoint(x: 204, y: 106)),
        GrupoSVG(id: "ojoIzq", piezas: [
            PiezaSVG(forma: .elipse(cx: 160, cy: 196, rx: 22, ry: 27), relleno: 0x16241F),
            PiezaSVG(forma: .circulo(154, 186, 6), relleno: 0xFFFFFF),
        ], ancla: CGPoint(x: 160, y: 196)),
        GrupoSVG(id: "ojoDer", piezas: [
            PiezaSVG(forma: .elipse(cx: 242, cy: 196, rx: 22, ry: 27), relleno: 0x16241F),
            PiezaSVG(forma: .circulo(236, 186, 6), relleno: 0xFFFFFF),
        ], ancla: CGPoint(x: 242, y: 196)),
        GrupoSVG(id: "mejillas", piezas: [
            PiezaSVG(forma: .elipse(cx: 126, cy: 232, rx: 17, ry: 11), relleno: 0xE2C48E),
            PiezaSVG(forma: .elipse(cx: 276, cy: 232, rx: 17, ry: 11), relleno: 0xE2C48E),
        ], ancla: CGPoint(x: 200, y: 232)),
        GrupoSVG(id: "boca", piezas: [
            PiezaSVG(forma: .trazado("M184 226 C 194 234, 210 234, 220 226 C 218 246, 210 254, 202 254 C 192 254, 186 246, 184 226 Z"), relleno: 0x16241F),
        ], ancla: CGPoint(x: 202, y: 240)),
        GrupoSVG(id: "lengua", piezas: [
            PiezaSVG(forma: .trazado("M190 244 C 196 238, 208 238, 214 244 C 210 252, 194 252, 190 244 Z"), relleno: 0xC98A2E),
        ], ancla: CGPoint(x: 202, y: 246)),
        GrupoSVG(id: "corazon", piezas: [
            PiezaSVG(forma: .trazado("M200 352 C 160 320, 132 296, 134 270 C 136 248, 168 240, 200 266 C 232 240, 264 248, 266 270 C 268 296, 240 320, 200 352 Z"), relleno: 0xC98A2E),
        ], ancla: CGPoint(x: 200, y: 296)),
        GrupoSVG(id: "manos", piezas: [
            PiezaSVG(forma: .elipse(cx: 142, cy: 300, rx: 22, ry: 15), relleno: 0xE7F0E0, trazo: 0x9FB396, grosor: 3),
            PiezaSVG(forma: .elipse(cx: 258, cy: 300, rx: 22, ry: 15), relleno: 0xE7F0E0, trazo: 0x9FB396, grosor: 3),
        ], ancla: CGPoint(x: 200, y: 300)),
        GrupoSVG(id: "pies", piezas: [
            PiezaSVG(forma: .elipse(cx: 132, cy: 376, rx: 40, ry: 34), relleno: 0xA9BD9F),
            PiezaSVG(forma: .elipse(cx: 268, cy: 376, rx: 40, ry: 34), relleno: 0xA9BD9F),
        ], ancla: CGPoint(x: 200, y: 376)),
        GrupoSVG(id: "chispas", piezas: [
            PiezaSVG(forma: .trazado("M300 92 l14 22 -6 4 -14 -22 z"), relleno: 0xC98A2E),
            PiezaSVG(forma: .trazado("M318 128 l26 4 -1 7 -26 -4 z"), relleno: 0xC98A2E),
        ], ancla: CGPoint(x: 314, y: 112)),
    ]

    // MARK: Marca v5 (docs/arte/v5/marca.svg): cuadrícula de cuatro módulos

    /// Lienzo de `marca.svg` (viewBox 262 262 500 500).
    static let lienzoMarca = CGSize(width: 500, height: 500)

    /// Módulos en el orden en que entran en la bienvenida: arriba a la izquierda (cuarto de círculo
    /// salvia), arriba a la derecha (cuadrado tinta), abajo a la izquierda (cuadrado tinta) y abajo a
    /// la derecha (cuarto de círculo salvia). Coordenadas del SVG trasladadas al lienzo (−262).
    enum Modulo: Int, CaseIterable, Sendable {
        case arribaIzquierda, arribaDerecha, abajoIzquierda, abajoDerecha

        /// `true` en los módulos salvia; `false` en los de tinta.
        var salvia: Bool { self == .arribaIzquierda || self == .abajoDerecha }

        var path: Path {
            switch self {
            case .arribaIzquierda:
                var p = Path()
                p.move(to: CGPoint(x: 10, y: 230))
                p.addArc(center: CGPoint(x: 230, y: 230), radius: 220, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
                p.addLine(to: CGPoint(x: 230, y: 230))
                p.closeSubpath()
                return p
            case .arribaDerecha:
                return Path(roundedRect: CGRect(x: 270, y: 10, width: 220, height: 220), cornerRadius: 30, style: .circular)
            case .abajoIzquierda:
                return Path(roundedRect: CGRect(x: 10, y: 270, width: 220, height: 220), cornerRadius: 30, style: .circular)
            case .abajoDerecha:
                var p = Path()
                p.move(to: CGPoint(x: 270, y: 270))
                p.addLine(to: CGPoint(x: 490, y: 270))
                p.addArc(center: CGPoint(x: 270, y: 270), radius: 220, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                p.closeSubpath()
                return p
            }
        }
    }
}
