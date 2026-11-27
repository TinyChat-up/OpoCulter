import SwiftUI
import UIKit

/// Sala del simulacro escrito (05J §2). En la app: una cuenta atrás que no se detiene al salir
/// (se calcula desde la hora de inicio) y entrega sola a 0, botón para ocultar el reloj, mapa con
/// estados, campo de varias líneas con fila de símbolos, texto base desde cualquier pregunta de
/// Lengua, borrador y marca para revisar. En papel: solo la cuenta atrás y las marcas. Sin pistas,
/// XP, anuncios ni soluciones hasta entregar.
struct PantallaEscrito: View {
    @Bindable var modelo: ModeloEscrito
    let cerrar: () -> Void
    /// Hoja abierta al entrar (capturas): «mapa».
    var hojaInicial: String?
    @Environment(\.scenePhase) private var fase
    @State private var verMapa = false
    @State private var verBorrador = false
    @State private var verTexto = false
    @State private var confirmarEntrega = false

    var body: some View {
        Group {
            if modelo.intento.entregado {
                PantallaCorreccionEscrito(modelo: modelo, cerrar: cerrar)
            } else {
                sala
            }
        }
        .onChange(of: fase) { _, nueva in if nueva != .active { modelo.segundoPlano() } else { modelo.tic(modelo.servicio.reloj.ahora) } }
        .onAppear { if hojaInicial == "mapa" { verMapa = true } }
    }

    private var sala: some View {
        VStack(spacing: 0) {
            cabecera
            if modelo.enPapel {
                papel
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Espacio.l) {
                        pregunta
                        respuesta
                    }
                    .padding(Espacio.l)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Paleta.superficie)
            }
            pie
        }
        .background(Paleta.fondo.ignoresSafeArea())
        .task {
            // Un temporizador de 1 s mientras la sala está a la vista (05J: un TimelineView con
            // `from: .now` se recreaba en cada render y disparaba sin parar).
            while !Task.isCancelled {
                modelo.tic(.now)
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .sheet(isPresented: $verMapa) { mapa }
        .sheet(isPresented: $verBorrador) {
            HojaBorrador(enunciado: modelo.pregunta?.enunciado ?? "", dibujo: $modelo.borrador)
        }
        .sheet(isPresented: $verTexto) { textoBase }
        .confirmationDialog("¿Entregar el simulacro?", isPresented: $confirmarEntrega, titleVisibility: .visible) {
            Button("Entregar") { modelo.entregar() }
            Button("Seguir", role: .cancel) {}
        } message: {
            Text(modelo.enPapel
                 ? "Tienes \(modelo.intento.marcas.count) preguntas marcadas. Después corregirás tu hoja con los criterios."
                 : "Quedan \(modelo.sinResponder) preguntas sin responder y \(modelo.intento.marcas.count) marcadas para revisar.")
        }
    }

    // MARK: Cabecera

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: Espacio.xs) {
            HStack {
                Button { modelo.segundoPlano(); cerrar() } label: {
                    Image(systemName: "xmark").font(.headline)
                        .frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
                        .contentShape(Rectangle())
                }
                    .accessibilityLabel("Salir (se guarda y el tiempo sigue corriendo)")
                    .accessibilityIdentifier("botonSalirEscrito")
                Spacer()
                reloj
                Spacer()
                if !modelo.enPapel {
                    Button { verMapa = true } label: {
                        Label("Mapa", systemImage: "square.grid.3x3")
                            .frame(minWidth: Medidas.tactilMinimo, minHeight: Medidas.tactilMinimo)
                            .contentShape(Rectangle())
                    }
                        .accessibilityIdentifier("botonMapa")
                }
            }
            Text("\(modelo.simulacro.etiqueta) · «\(modelo.simulacro.entrada.titulo)»\(modelo.enPapel ? " · en papel" : "")")
                .font(.caption2).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Espacio.l)
        .padding(.vertical, Espacio.s)
        .foregroundStyle(Paleta.textoPrincipal)
    }

    private var reloj: some View {
        let s = modelo.restante
        return Button { modelo.alternarReloj() } label: {
            HStack(spacing: Espacio.xs) {
                Image(systemName: modelo.intento.relojOculto ? "eye.slash" : "clock").accessibilityHidden(true)
                Text(modelo.intento.relojOculto ? "Reloj oculto" : String(format: "%d:%02d", s / 60, s % 60))
                    .font(modelo.intento.relojOculto ? .subheadline : .numerica(.title3, peso: .semibold))
            }
            .frame(minHeight: Medidas.tactilMinimo)
        }
        .foregroundStyle(Paleta.textoPrincipal)
        .accessibilityLabel(modelo.intento.relojOculto ? "Reloj oculto" : "Quedan \(s / 60) minutos y \(s % 60) segundos")
        .accessibilityHint(modelo.intento.relojOculto ? "Mostrar el reloj" : "Ocultar el reloj")
        .accessibilityIdentifier("cuentaAtras")
    }

    // MARK: Pregunta (en la app)

    @ViewBuilder private var pregunta: some View {
        if let p = modelo.pregunta {
            HStack {
                Text("\(p.id) · \(modelo.indice + 1) de \(modelo.preguntas.count) · \(CorrectorEscrito.texto(p.maximo)) puntos")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Paleta.textoSecundario)
                Spacer()
                if modelo.intento.marcas.contains(p.id) {
                    Label("Marcada", systemImage: "flag.fill").font(.footnote).foregroundStyle(Paleta.recompensaTexto)
                }
            }
            Text(p.enunciado)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Paleta.textoPrincipal)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("enunciadoEscrito")
            if p.area == "LEN" {
                Button { verTexto = true } label: { Label("Texto base", systemImage: "doc.text") }
                    .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonTextoBase")
            }
        }
    }

    private var respuesta: some View {
        VStack(alignment: .leading, spacing: Espacio.s) {
            Text("Tu respuesta").font(.subheadline.weight(.semibold)).foregroundStyle(Paleta.textoPrincipal)
            EditorRespuesta(texto: $modelo.respuesta)
                .id(modelo.actual)
                .frame(minHeight: 180)
                .padding(Espacio.s)
                .background(Paleta.fondo, in: RoundedRectangle(cornerRadius: Radio.ficha))
                .contornoTinta(radio: Radio.ficha)
        }
    }

    // MARK: En papel

    private var papel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espacio.l) {
                Text("Responde en tu hoja impresa. Aquí solo corre el tiempo; marca las preguntas que quieras revisar.")
                    .font(.subheadline).foregroundStyle(Paleta.textoSecundario).fixedSize(horizontal: false, vertical: true)
                rejilla { p in modelo.alternarMarca(p) }
            }
            .padding(Espacio.l)
        }
        .background(Paleta.superficie)
    }

    // MARK: Pie

    private var pie: some View {
        VStack(spacing: Espacio.s) {
            if !modelo.enPapel {
                HStack(spacing: Espacio.s) {
                    Button { modelo.mover(-1) } label: { Image(systemName: "chevron.left") }
                        .buttonStyle(EstiloBotonSecundario()).disabled(modelo.indice == 0).accessibilityLabel("Anterior")
                    Button { modelo.alternarMarca() } label: {
                        Label(modelo.intento.marcas.contains(modelo.actual) ? "Desmarcar" : "Marcar", systemImage: "flag")
                    }
                    .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonMarcar")
                    Button { verBorrador = true } label: { Label("Borrador", systemImage: "pencil.and.scribble") }
                        .buttonStyle(EstiloBotonSecundario()).accessibilityIdentifier("botonBorrador")
                    Button { modelo.mover(1) } label: { Image(systemName: "chevron.right") }
                        .buttonStyle(EstiloBotonSecundario()).disabled(modelo.indice + 1 >= modelo.preguntas.count).accessibilityLabel("Siguiente")
                }
            }
            BotonPrincipal(titulo: "Entregar", icono: "tray.and.arrow.up", acento: Paleta.primario) { confirmarEntrega = true }
                .accessibilityIdentifier("botonEntregar")
        }
        .padding(Espacio.l)
        .background(Paleta.fondo)
    }

    // MARK: Mapa

    private func rejilla(_ accion: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: Espacio.m) {
            HStack(spacing: Espacio.l) {
                if !modelo.enPapel {
                    leyenda("Sin responder", "circle")
                    leyenda("Respondida", "checkmark")
                }
                leyenda("Marcada", "flag.fill")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espacio.s), count: 5), spacing: Espacio.s) {
                ForEach(modelo.preguntas) { p in
                    let estado = modelo.intento.estado(p.id)
                    Button { accion(p.id) } label: {
                        VStack(spacing: 2) {
                            Text(p.id).font(.subheadline.weight(.semibold))
                            Image(systemName: icono(estado)).font(.caption2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(estado == .respondida ? Paleta.primario.opacity(0.2) : Paleta.superficie, in: RoundedRectangle(cornerRadius: Radio.celda))
                        .overlay(RoundedRectangle(cornerRadius: Radio.celda)
                            .strokeBorder(p.id == modelo.actual && !modelo.enPapel ? Paleta.contorno : Paleta.borde, lineWidth: p.id == modelo.actual && !modelo.enPapel ? 2 : 1))
                    }
                    .foregroundStyle(Paleta.textoPrincipal)
                    .accessibilityLabel("Pregunta \(p.id): \(nombre(estado))")
                    .accessibilityIdentifier("mapa_\(p.id)")
                }
            }
        }
    }

    private func icono(_ e: IntentoEscrito.EstadoPregunta) -> String {
        switch e { case .sinResponder: "circle"; case .marcada: "flag.fill"; case .respondida: "checkmark" }
    }

    private func nombre(_ e: IntentoEscrito.EstadoPregunta) -> String {
        switch e { case .sinResponder: modelo.enPapel ? "sin marcar" : "sin responder"; case .marcada: "marcada para revisar"; case .respondida: "respondida" }
    }

    private func leyenda(_ t: String, _ icono: String) -> some View {
        Label(t, systemImage: icono).font(.caption).foregroundStyle(Paleta.textoSecundario)
    }

    private var mapa: some View {
        NavigationStack {
            ScrollView {
                rejilla { p in modelo.ir(a: p); verMapa = false }.padding(Espacio.l)
            }
            .background(Paleta.fondo.ignoresSafeArea())
            .navigationTitle("Mapa de preguntas")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var textoBase: some View {
        NavigationStack {
            ScrollView {
                Text(modelo.datos.texto)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Paleta.textoPrincipal)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Espacio.l)
                    .accessibilityIdentifier("textoBaseEscrito")
            }
            .background(Paleta.superficie.ignoresSafeArea())
            .navigationTitle("Texto base")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Volver a la pregunta") { verTexto = false } }
            }
        }
    }
}

/// Campo de respuesta de varias líneas con una fila de símbolos matemáticos sobre el teclado
/// normal (/, ×, ÷, ², ³, %, π y coma), que se insertan en el cursor.
struct EditorRespuesta: UIViewRepresentable {
    @Binding var texto: String
    static let simbolos = ["/", "×", "÷", "²", "³", "%", "π", ","]

    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.delegate = context.coordinator
        v.backgroundColor = .clear
        let base = UIFont.preferredFont(forTextStyle: .body)
        v.font = base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: 0) } ?? base
        v.adjustsFontForContentSizeCategory = true
        v.textColor = UIColor(Paleta.textoPrincipal)
        v.autocorrectionType = .default
        v.text = texto
        v.accessibilityLabel = "Tu respuesta"
        v.accessibilityIdentifier = "campoRespuesta"
        v.inputAccessoryView = filaSimbolos(context.coordinator)
        context.coordinator.vista = v
        return v
    }

    func updateUIView(_ v: UITextView, context: Context) {
        if v.text != texto { v.text = texto }
    }

    func makeCoordinator() -> Coordinador { Coordinador(texto: $texto) }

    private func filaSimbolos(_ c: Coordinador) -> UIView {
        let fila = UIInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 48), inputViewStyle: .keyboard)
        let pila = UIStackView()
        pila.axis = .horizontal
        pila.distribution = .fillEqually
        pila.spacing = 6
        pila.translatesAutoresizingMaskIntoConstraints = false
        for s in Self.simbolos {
            var conf = UIButton.Configuration.gray()
            conf.title = s
            conf.baseForegroundColor = .label
            let b = UIButton(configuration: conf, primaryAction: UIAction { [weak c] _ in c?.insertar(s) })
            b.accessibilityLabel = Self.nombre(s)
            pila.addArrangedSubview(b)
        }
        fila.addSubview(pila)
        NSLayoutConstraint.activate([
            pila.leadingAnchor.constraint(equalTo: fila.leadingAnchor, constant: 6),
            pila.trailingAnchor.constraint(equalTo: fila.trailingAnchor, constant: -6),
            pila.topAnchor.constraint(equalTo: fila.topAnchor, constant: 5),
            pila.bottomAnchor.constraint(equalTo: fila.bottomAnchor, constant: -5),
        ])
        return fila
    }

    static func nombre(_ s: String) -> String {
        switch s {
        case "/": "barra de fracción"
        case "×": "por"
        case "÷": "entre"
        case "²": "al cuadrado"
        case "³": "al cubo"
        case "%": "por ciento"
        case "π": "pi"
        default: "coma"
        }
    }

    @MainActor
    final class Coordinador: NSObject, UITextViewDelegate {
        var texto: Binding<String>
        weak var vista: UITextView?

        init(texto: Binding<String>) { self.texto = texto }

        func textViewDidBeginEditing(_ textView: UITextView) { vista = textView }
        func textViewDidChange(_ textView: UITextView) { vista = textView; texto.wrappedValue = textView.text }

        func insertar(_ s: String) {
            guard let v = vista else { return }
            v.insertText(s)
        }
    }
}
