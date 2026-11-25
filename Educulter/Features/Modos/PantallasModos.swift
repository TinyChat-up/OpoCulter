import SwiftUI

// MARK: - Supervivencia

/// Cabecera de la partida: salir, vidas (corazones), nivel y puntos en vivo.
struct CabeceraSupervivencia<Salir: View>: View {
    let estado: EstadoSupervivencia
    let puntosUltimo: Int
    @ViewBuilder let salir: () -> Salir
    @Environment(\.dynamicTypeSize) private var tamano

    var body: some View {
        let disposicion = tamano.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espacio.xs)) : AnyLayout(HStackLayout(spacing: Espacio.m))
        disposicion {
            HStack(spacing: Espacio.s) {
                salir()
                HStack(spacing: 4) {
                    ForEach(0..<estado.reglas.vidas, id: \.self) { i in
                        Image(systemName: i < estado.vidas ? "heart.fill" : "heart")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(i < estado.vidas ? Paleta.fallo : Paleta.textoSecundario)
                            .estiramiento(estado.vidas)
                    }
                }
                .frame(minHeight: Medidas.tactilMinimo)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Vidas")
                .accessibilityValue("\(estado.vidas) de \(estado.reglas.vidas)")
                .accessibilityIdentifier("vidas")
            }
            if !tamano.isAccessibilitySize { Spacer(minLength: 0) }
            HStack(spacing: Espacio.s) {
                Text("Nivel \(estado.dificultad)\(estado.dificultad == 6 ? " · Experto" : "")")
                    .font(.redondeada(.subheadline))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .padding(.horizontal, Espacio.m)
                    .frame(minHeight: Medidas.tactilMinimo)
                    .background(Paleta.superficie, in: Capsule())
                    .overlay(Capsule().strokeBorder(Paleta.contorno, lineWidth: Trazo.fino))
                    .accessibilityIdentifier("nivelSupervivencia")
                Text("\(estado.puntos)")
                    .font(.redondeada(.headline))
                    .foregroundStyle(Paleta.textoSobreRecompensa)
                    .contentTransition(.numericText(value: Double(estado.puntos)))
                    .padding(.horizontal, Espacio.m)
                    .frame(minHeight: Medidas.tactilMinimo)
                    .background(Paleta.recompensa, in: Capsule())
                    .overlay(Capsule().strokeBorder(Paleta.contorno, lineWidth: Trazo.fino))
                    .animacionApp(estado.puntos)
                    .accessibilityLabel("Puntos")
                    .accessibilityValue("\(estado.puntos)")
                    .accessibilityIdentifier("puntosSupervivencia")
            }
        }
    }
}

/// Hoja de inicio de Supervivencia: reglas, área y récords.
struct PantallaInicioSupervivencia: View {
    let servicio: ServicioSesion
    let jugar: (String?) -> Void
    @State private var area = "MIX"
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        let records = (try? servicio.recordsSupervivencia()) ?? RecordsSupervivencia(partidas: [])
        let selector = SelectorSupervivencia(banco: servicio.banco)
        let areas = ["MIX", "LEN", "MAT"].filter { $0 == "MIX" || !selector.bloques(area: $0).isEmpty }
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    HStack(spacing: Espacio.m) {
                        VistaPersonaje(companero: .cuarto, estado: .neutral)
                        Text("Supervivencia").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal)
                            .accessibilityAddTraits(.isHeader)
                    }
                    TarjetaSuperficie {
                        VStack(alignment: .leading, spacing: Espacio.s) {
                            regla("heart.fill", "Tienes 3 vidas: cada fallo quita una.")
                            regla("arrow.up.right", "Cada 4 aciertos seguidos subes un nivel, hasta el 6 «Experto». Un fallo te baja uno.")
                            regla("star.fill", "Cada acierto vale 10 × el nivel, con hasta ×2 por combo.")
                            regla("clock.badge.xmark", "Sin cronómetro: piensa con calma.")
                            regla("lifepreserver", "Los errores van a Rescate y todo cuenta para tu progreso.")
                        }
                    }
                    if areas.count > 1 {
                        Picker("Área", selection: $area) {
                            ForEach(areas, id: \.self) { a in Text(a == "MIX" ? "Todo" : (a == "LEN" ? "Lengua" : "Matemáticas")).tag(a) }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("areaSupervivencia")
                    }
                    VStack(alignment: .leading, spacing: Espacio.xs) {
                        Text("Récords").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                        filaRecord("Global", records.global)
                        filaRecord(area == "MIX" ? "Todo mezclado" : (area == "LEN" ? "Lengua" : "Matemáticas"), records.porArea[area] ?? nil)
                    }
                }
                .padding(Espacio.l)
            }
            BotonPrincipal(titulo: "Jugar", icono: "play.fill", acento: Paleta.recompensa) {
                jugar(area == "MIX" ? nil : area)
                cerrar()
            }
            .padding(Espacio.l)
            .accessibilityIdentifier("botonJugarSupervivencia")
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaInicioSupervivencia")
    }

    private func regla(_ icono: String, _ texto: String) -> some View {
        Label { Text(texto).fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: icono).foregroundStyle(Paleta.textoPrincipal) }
            .font(.subheadline)
            .foregroundStyle(Paleta.textoPrincipal)
    }

    private func filaRecord(_ titulo: String, _ p: PartidaSupervivencia?) -> some View {
        HStack {
            Text(titulo).foregroundStyle(Paleta.textoPrincipal)
            Spacer()
            Text(p.map { "\($0.puntos) puntos · nivel \($0.nivelMaximo)" } ?? "Sin partidas todavía")
                .font(.redondeada(.subheadline))
                .foregroundStyle(Paleta.textoSecundario)
        }
        .frame(minHeight: Medidas.tactilMinimo)
        .accessibilityElement(children: .combine)
    }
}

/// Final de la partida: puntos, nivel máximo, aciertos, récords y comparación con la mejor partida.
struct PantallaFinPartida: View {
    let resultado: ResultadoPartida
    let servicio: ServicioSesion
    let otraPartida: () -> Void
    let terminar: () -> Void

    var body: some View {
        let p = resultado.partida
        let records = (try? servicio.recordsSupervivencia()) ?? RecordsSupervivencia(partidas: [])
        let estadoPersonaje: EstadoPersonaje = resultado.esRecord
            ? ReglasPersonaje.estado(para: .recordSupervivencia)
            : ReglasPersonaje.estado(para: .resumenRonda(aciertos: p.aciertos, total: max(p.aciertos + p.fallos, 1)))
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Espacio.l) {
                    VistaPersonaje(companero: p.area == "LEN" ? .tilde : .cuarto, estado: estadoPersonaje, tamano: 80)
                        .accessibilityIdentifier("personajeFinPartida_\(estadoPersonaje.rawValue)")
                    Text(resultado.esRecord ? "¡Nuevo récord!" : "Fin de la partida")
                        .font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    HStack(spacing: Espacio.m) {
                        dato("\(p.puntos)", "Puntos")
                        dato("\(p.nivelMaximo)", "Nivel máximo")
                        dato("\(p.aciertos)", "Aciertos")
                    }
                    .padding(Espacio.m)
                    .background(Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                    .contornoTinta(radio: Radio.tarjeta)
                    .accessibilityIdentifier("datosFinPartida")
                    VStack(alignment: .leading, spacing: Espacio.s) {
                        Text("Comparación").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                        if let mejor = resultado.mejorAnterior {
                            Text(resultado.esRecord
                                 ? "Superas tu mejor partida anterior (\(mejor.puntos) puntos) por \(p.puntos - mejor.puntos)."
                                 : "Tu mejor partida: \(mejor.puntos) puntos (nivel \(mejor.nivelMaximo)). Te faltan \(max(mejor.puntos - p.puntos + 1, 0)) para superarla.")
                                .foregroundStyle(Paleta.textoPrincipal)
                        } else {
                            Text("Es tu primera partida terminada: la próxima ya tendrá con qué compararse.").foregroundStyle(Paleta.textoPrincipal)
                        }
                        Text("Récord global: \(records.global.map { "\($0.puntos) puntos" } ?? "—"). Récord de \(p.area == nil ? "todo mezclado" : (p.area == "LEN" ? "Lengua" : "Matemáticas")): \((records.porArea[p.area ?? "MIX"] ?? nil).map { "\($0.puntos) puntos" } ?? "—").")
                            .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                        ForEach(resultado.logrosNuevos, id: \.id) { logro in
                            Label("Logro: \(logro.titulo)", systemImage: "trophy.fill").foregroundStyle(Paleta.recompensaTexto)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("comparacionFinPartida")
                }
                .padding(Espacio.l)
            }
            VStack(spacing: Espacio.s) {
                BotonPrincipal(titulo: "Otra partida", icono: "arrow.clockwise", acento: Paleta.recompensa, accion: otraPartida)
                    .accessibilityIdentifier("botonOtraPartida")
                Button("Terminar", action: terminar).buttonStyle(EstiloBotonSecundario())
                    .accessibilityIdentifier("botonTerminar")
            }
            .padding(Espacio.l)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("finPartida")
    }

    private func dato(_ valor: String, _ titulo: String) -> some View {
        VStack(spacing: Espacio.xs) {
            Text(valor).font(.redondeada(.title2)).foregroundStyle(Paleta.textoPrincipal).lineLimit(1).minimumScaleFactor(0.6)
            Text(titulo).font(.caption).foregroundStyle(Paleta.textoSecundario).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Plan del diagnóstico

struct PantallaPlan: View {
    let plan: PlanDiagnostico
    let servicio: ServicioSesion
    let terminar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    HStack(spacing: Espacio.m) {
                        VistaPersonaje(companero: .tilde, estado: .celebra)
                        Text("Tu plan").font(.exhibicion(.largeTitle)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                    }
                    if !plan.bloques.isEmpty {
                        Text("Resultado por bloque").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                        ForEach(plan.bloques) { b in
                            HStack(spacing: Espacio.m) {
                                AnilloDominio(fraccion: b.nivel == .fuerte ? 1 : (b.nivel == .medio ? 0.5 : 0.08),
                                              acento: Paleta.acento(area: Catalogo.area(de: b.id)))
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.bloque.nombre).font(.headline).foregroundStyle(Paleta.textoPrincipal)
                                    Text("\(b.nivel == .fuerte ? "Fuerte" : (b.nivel == .medio ? "Medio" : "Débil")) · \(b.aciertos) de \(b.respondidos)")
                                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("planBloque_\(b.id)")
                        }
                    }
                    if !plan.recomendadas.isEmpty {
                        TarjetaSuperficie {
                            VStack(alignment: .leading, spacing: Espacio.s) {
                                Text("Empezamos por…").font(.exhibicion(.title3)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                                ForEach(plan.recomendadas, id: \.id) { c in
                                    Label(c.nombre, systemImage: SimboloBloque.de(competencia: c.id))
                                        .font(.body.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                                }
                            }
                        }
                        .accessibilityIdentifier("planRecomendadas")
                    }
                    if !plan.sinDatos.isEmpty {
                        Label {
                            Text("Sin datos todavía: \(plan.sinDatos.count) bloques del temario aún no tienen contenido (\(plan.sinDatos.prefix(4).map(\.nombre).joined(separator: ", "))\(plan.sinDatos.count > 4 ? "…" : "")). Los evaluaremos cuando lleguen.")
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: { Image(systemName: "info.circle") }
                        .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                        .accessibilityIdentifier("planSinDatos")
                    }
                }
                .padding(Espacio.l)
            }
            BotonPrincipal(titulo: "Ir a Hoy", icono: "arrow.right", acento: Paleta.matematicas, accion: terminar)
                .padding(Espacio.l)
                .accessibilityIdentifier("botonIrAHoy")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaPlan")
    }
}

// MARK: - Rescate

/// Rescate de errores: lista por competencia, "Rescatar todo" o una competencia, y ver de nuevo cada ítem.
struct PantallaRescate: View {
    let servicio: ServicioSesion
    let lanzar: (TipoRonda) -> Void
    @State private var grupos: [GrupoRescate] = []
    @State private var itemVisto: Item?
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera propia: los botones de la barra del sistema no escalan con Dynamic Type ni
            // cumplen el contraste (como en Perfil, D-048).
            HStack {
                Text("Rescate").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Cerrar") { cerrar() }
                    .buttonStyle(EstiloBotonSecundario())
                    .frame(maxWidth: 140)
                    .accessibilityIdentifier("botonCerrarRescate")
            }
            .padding(.horizontal, Espacio.l)
            .padding(.top, Espacio.l)
            Group {
                if grupos.isEmpty {
                    VStack(spacing: Espacio.l) {
                        VistaPersonaje(companero: .tilde, estado: .celebra)
                        Text("Sin errores pendientes").font(.exhibicion(.title2)).foregroundStyle(Paleta.textoPrincipal)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Text("Cuando falles un ítem aparecerá aquí para que lo rescates con otra variante.")
                            .font(.body).foregroundStyle(Paleta.textoSecundario).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Espacio.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("rescateVacio")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Espacio.l) {
                            BotonPrincipal(titulo: "Rescatar todo (\(grupos.map(\.cantidad).reduce(0, +)))", icono: "lifepreserver", acento: Paleta.recompensa) {
                                lanzar(.rescate); cerrar()
                            }
                            .accessibilityIdentifier("botonRescatarTodo")
                            ForEach(grupos) { g in grupo(g) }
                        }
                        .padding(Espacio.l)
                    }
                }
            }
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .sheet(item: $itemVisto) { item in
            let texto = servicio.banco.texto(de: item)
            VistaItemRepaso(item: item, nombre: nombre(item.competencia), texto: texto, anio: texto.flatMap { servicio.banco.anio(de: $0) })
        }
        .onAppear { grupos = (try? servicio.gruposRescate()) ?? [] }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pantallaRescate")
    }

    private func nombre(_ id: String) -> String {
        servicio.banco.catalogo.todasLasCompetencias.first { $0.id == id }?.nombre ?? id
    }

    private func grupo(_ g: GrupoRescate) -> some View {
        TarjetaSuperficie {
            VStack(alignment: .leading, spacing: Espacio.s) {
                // El área va en su propia línea, encima del nombre: en la misma fila, con nombres
                // largos, se partía sílaba a sílaba (visto en el iPhone).
                Text(g.area == "LEN" ? "Lengua" : "Matemáticas")
                    .font(.caption.weight(.semibold)).foregroundStyle(Paleta.textoSobreAcento)
                    .padding(.horizontal, Espacio.s).padding(.vertical, 2)
                    .background(Paleta.acento(area: g.area), in: Capsule())
                Label(g.competencia.nombre, systemImage: SimboloBloque.de(competencia: g.id))
                    .font(.headline).foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(g.cantidad == 1 ? "1 error pendiente" : "\(g.cantidad) errores pendientes") · último el \(g.ultimo.formatted(.dateTime.day().month(.wide)))")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                ForEach(Array(g.entradas.enumerated()), id: \.offset) { _, e in
                    if let item = servicio.banco.item(id: e.itemId) {
                        Button { itemVisto = item } label: {
                            HStack {
                                Text(item.enunciado).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: Espacio.s)
                                Image(systemName: "eye").accessibilityHidden(true)
                            }
                            .font(.subheadline).foregroundStyle(Paleta.textoPrincipal)
                            .frame(minHeight: Medidas.tactilMinimo)
                        }
                        .accessibilityLabel("Ver de nuevo: \(item.enunciado)")
                        .accessibilityIdentifier("verItem_\(e.itemId)")
                    }
                }
                Button("Rescatar esta competencia") { lanzar(.rescateCompetencia(g.id)); cerrar() }
                    .buttonStyle(EstiloBotonSecundario())
                    .accessibilityIdentifier("rescatar_\(g.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("grupoRescate_\(g.id)")
    }
}

/// Un ítem fallado, de nuevo: enunciado, solución y explicación (los generados se reproducen con su semilla).
struct VistaItemRepaso: View {
    let item: Item
    let nombre: String
    /// Texto base del ítem (comprensión), que se muestra entero encima del enunciado.
    var texto: TextoBase? = nil
    var anio: Int? = nil
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Cerrar") { cerrar() }
                    .buttonStyle(EstiloBotonSecundario())
                    .frame(maxWidth: 140)
                    .accessibilityIdentifier("botonCerrarItem")
            }
            .padding([.horizontal, .top], Espacio.l)
            ScrollView {
                VStack(alignment: .leading, spacing: Espacio.l) {
                    Text(nombre.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(Paleta.tinta(competencia: item.competencia))
                    if let texto {
                        VistaTextoBase(texto: texto, anio: anio, plegado: .constant(false), plegable: false)
                    }
                    Text(item.enunciado).font(.title3.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
                    TarjetaSuperficie {
                        VStack(alignment: .leading, spacing: Espacio.s) {
                            Text("**Solución:** \(DescripcionSolucion.texto(item.payload))").foregroundStyle(Paleta.textoPrincipal)
                            Text(item.explicacion).font(.subheadline).foregroundStyle(Paleta.textoSecundario)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Espacio.l)
            }
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("itemRepaso")
    }
}
