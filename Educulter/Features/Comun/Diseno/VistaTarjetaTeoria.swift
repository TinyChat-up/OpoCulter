import SwiftUI

/// Tarjeta de teoría: texto, regla destacada, ejemplo y esquema maquetado (D-034).
struct VistaTarjetaTeoria: View {
    let tarjeta: TarjetaTeoria
    /// Tinta del área (texto y marcas con color de área; AA sobre fondo y superficie).
    var acento: Color = Paleta.lenguaTinta

    var body: some View {
        TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text(tarjeta.titulo)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(tarjeta.bloques.enumerated()), id: \.offset) { _, bloque in
                    vista(de: bloque)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tarjetaTeoria")
    }

    @ViewBuilder
    private func vista(de bloque: TarjetaTeoria.BloqueTeoria) -> some View {
        switch bloque.tipo {
        case .texto:
            Text(bloque.contenido)
                .font(.body)
                .foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
        case .regla:
            HStack(alignment: .top, spacing: Espacio.m) {
                Rectangle().fill(acento).frame(width: 4).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Espacio.xs) {
                    Text("Regla").font(.caption.weight(.semibold)).foregroundStyle(acento).textCase(.uppercase)
                    Text(bloque.contenido).font(.body.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        case .ejemplo:
            VStack(alignment: .leading, spacing: Espacio.xs) {
                Text("Ejemplo").font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario).textCase(.uppercase)
                Text(bloque.contenido).font(.body.italic()).foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espacio.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous))
            .accessibilityElement(children: .combine)
        case .esquema:
            VistaEsquema(filas: FilaEsquema.filas(de: bloque.contenido), acento: acento)
        }
    }
}

/// Maquetado visual de un esquema: filas de dos columnas, secuencias con flechas y texto.
struct VistaEsquema: View {
    let filas: [FilaEsquema]
    var acento: Color
    @Environment(\.dynamicTypeSize) private var tamano

    var body: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("Esquema").font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSecundario).textCase(.uppercase)
            ForEach(Array(filas.enumerated()), id: \.offset) { _, fila in
                switch fila {
                case .par(let etiqueta, let valor):
                    let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.xs)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Espacio.m))
                    disposicion {
                        Text(etiqueta).font(.subheadline.weight(.semibold)).foregroundStyle(acento)
                            .frame(minWidth: tamano.isAccessibilitySize ? nil : 90, alignment: .leading)
                        Text(valor).font(.subheadline).foregroundStyle(Paleta.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                case .flecha(let partes):
                    DisposicionFlujo(espacioH: Espacio.xs, espacioV: Espacio.xs) {
                        ForEach(Array(partes.enumerated()), id: \.offset) { i, parte in
                            if i > 0 {
                                Image(systemName: "arrow.right")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(acento)
                                    .frame(minHeight: 32)
                            }
                            Text(parte)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Paleta.textoPrincipal)
                                .padding(.horizontal, Espacio.s)
                                .padding(.vertical, Espacio.xs)
                                .background(acento.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(partes.joined(separator: ", y luego, "))
                case .texto(let texto):
                    Text(texto).font(.subheadline).foregroundStyle(Paleta.textoPrincipal)
                }
            }
        }
        .padding(Espacio.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Radio.ficha, style: .continuous).strokeBorder(Paleta.borde))
    }
}
