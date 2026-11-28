import Foundation

/// Exámenes oficiales de la prueba A1 (Fase 05I, D-130): 7 convocatorias y 139 preguntas en
/// `Content/tribunal/`, aprobadas por la dirección el 24/11/2026. Se reproducen sin alteraciones;
/// los textos protegidos (Salinas, Laforet) y las figuras se remiten al cuadernillo oficial.
struct ExamenOficial: Codable, Sendable, Equatable, Identifiable {
    struct TextoBaseExamen: Codable, Sendable, Equatable {
        var texto: String?
        var autor: String
        var obra: String
        var protegido: Bool
        var anioMuerteAutor: Int?
    }

    struct Rubrica: Codable, Sendable, Equatable {
        var bien: String
        var regular: String
        var mal: String
    }

    struct Pregunta: Codable, Sendable, Equatable, Identifiable {
        var numero: Int
        var numeroEnArea: Int
        var area: String
        var enunciado: String
        var competencias: [String]
        var solucionModelo: String
        var rubrica: Rubrica
        var fuenteSolucion: String
        var fuenteRubrica: String
        var puntos: Double
        var validacion: Validacion
        var notaRubrica: String?
        var anulada: Bool?
        /// Página de la figura en el cuadernillo oficial, si consta (05K: las 4 figuras, comprobadas en los PDF).
        var paginaFigura: Int?
        /// Tabla del enunciado como tabla real (05J): mismos valores que el texto plano «(A | B: …)».
        var tabla: Tabla?

        var id: Int { numero }
        var codigo: String { "\(area == "LEN" ? "L" : "M")\(numeroEnArea)" }
        var esAnulada: Bool { anulada == true }

        /// Descripción textual de la figura («[Figura: …]» en el enunciado), si la pregunta la necesita.
        var figura: String? {
            guard let r = enunciado.range(of: "[Figura:"), let fin = enunciado[r.upperBound...].firstIndex(of: "]") else { return nil }
            return enunciado[r.upperBound..<fin].trimmingCharacters(in: .whitespaces)
        }

        /// Enunciado sin la descripción de la figura ni la tabla en texto plano (se muestran aparte).
        var enunciadoVisible: String {
            var e = enunciado
            if tabla != nil, let r = e.range(of: "\n("), e.hasSuffix(")") { e = String(e[..<r.lowerBound]) }
            guard let r = e.range(of: "[Figura:"), let fin = e[r.upperBound...].firstIndex(of: "]") else { return e }
            return (e[..<r.lowerBound] + e[e.index(after: fin)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// Tabla escrita en texto plano («A | B») que aún no tiene su tabla real.
        var tablaSinEstructura: Bool { tabla == nil && enunciado.contains(" | ") }

        /// Cita un pasaje del texto base protegido (se consulta en el PDF oficial).
        var citaProtegida: Bool { enunciado.contains("[Cita del texto base protegido") }

        /// Formato de la respuesta, deducido del enunciado: las de Lengua que piden redactar se
        /// autoevalúan; las cerradas (marcar, relacionar, clasificar) también, porque el dato
        /// oficial no trae clave estructurada; las de Matemáticas piden valor y unidad.
        var formato: FormatoPregunta {
            if area == "MAT" { return .calculo }
            let e = enunciado.lowercased()
            let cerradas = ["marque", "relacione", "clasifique", "indique si", "rellene", "complete", "subraye", "ordene", "separe", "agrupe", "señale"]
            return cerradas.contains { e.hasPrefix($0) || e.contains(". \($0)") } ? .cerrada : .redactar
        }
    }

    var id: String
    var anio: Int
    var convocatoria: String
    var duracionMin: Int
    var fuente: String
    var fechaConsulta: String
    var aviso: String
    var textoBase: TextoBaseExamen
    var preguntas: [Pregunta]
    var validacion: Validacion
    var notas: String?
    var fuentePlantilla: String?
    /// Pesos oficiales por pregunta («L1» → puntos), si la convocatoria los documenta. Hoy no los
    /// documenta ninguna: se reparte por igual dentro de cada área (D-131).
    var pesos: [String: Double]?

    var nombre: String { "\(anio) · \(convocatoria == "ordinaria" ? "ordinaria" : "aplazada")" }
    /// Cita de la cabecera del cuadernillo.
    var cita: String { "Comunidad de Madrid, prueba A1, \(anio). Fuente: \(fuente). Reproducción literal sin alteraciones." }
    /// La penalización ortográfica de las bases de 2026 se aplica en 2026 y en los simulacros; en el
    /// resto es orientativa (D-131).
    var penalizacionAplicable: Bool { anio >= 2026 }

    /// Se puede hacer en modo examen (05J §1): texto base reproducido, sin figuras ni citas
    /// protegidas que remitan al cuadernillo y con las tablas estructuradas. Si no, solo repaso.
    var completo: Bool {
        textoBase.texto != nil && !textoBase.protegido
            && preguntas.allSatisfy { $0.figura == nil && !$0.citaProtegida && !$0.tablaSinEstructura }
    }

    /// Por qué una convocatoria queda solo para repaso.
    var motivoSoloRepaso: String? {
        if textoBase.texto == nil || textoBase.protegido { return "El texto base está protegido y se consulta en el cuadernillo oficial." }
        if let q = preguntas.first(where: { $0.figura != nil }) { return "La pregunta \(q.codigo) necesita una figura del cuadernillo oficial." }
        if let q = preguntas.first(where: { $0.citaProtegida }) { return "La pregunta \(q.codigo) cita un texto protegido." }
        if let q = preguntas.first(where: { $0.tablaSinEstructura }) { return "La tabla de la pregunta \(q.codigo) está pendiente de estructurar." }
        return nil
    }
}

/// Tabla de un enunciado oficial (cabecera y filas, con los mismos valores del cuadernillo).
struct Tabla: Codable, Sendable, Equatable {
    var cabecera: [String]
    var filas: [[String]]
}

enum FormatoPregunta: String, Codable, Sendable {
    case redactar, cerrada, calculo
}

/// Penalización ortográfica (BOCM nº 36, 12/02/2026, Anexo V, C.1).
struct ReglasOrtografia: Codable, Sendable, Equatable {
    var palabraIncorrecta: Double
    var tilde: Double
    var unirSepararPalabras: Double?
    var abreviatura: Double?
    var limite: Double?
    var fuente: String
    var notas: [String]

    static let bases2026 = ReglasOrtografia(palabraIncorrecta: 0.5, tilde: 0.25, unirSepararPalabras: 0.25, abreviatura: 0.1, limite: nil,
                                            fuente: "BOCM nº 36, 12/02/2026, Anexo V, C.1, págs. 96-97", notas: [])
}

/// Equivalencia de una pregunta oficial con la competencia de la app (`equivalencias.json`).
struct EquivalenciaOficial: Codable, Sendable, Equatable {
    var examen: String
    var numero: Int
    var area: String
    var competencia: String
    var entrena: String
}

/// Todo lo del Tribunal que carga el banco.
struct DatosTribunal: Sendable, Equatable {
    var examenes: [ExamenOficial] = []
    var reglas: ReglasOrtografia = .bases2026
    var equivalencias: [EquivalenciaOficial] = []
    /// Simulacros originales escritos (05J), en el orden del catálogo, y su mapa de repaso.
    var originales: [SimulacroOriginal] = []
    var mapaRepaso: [String: String] = [:]

    func examen(_ id: String) -> ExamenOficial? { examenes.first { $0.id == id } }
    func original(_ id: String) -> SimulacroOriginal? { originales.first { $0.id == id } }

    func competencia(examen: String, numero: Int) -> String? {
        equivalencias.first { $0.examen == examen && $0.numero == numero }?.competencia
    }
}

/// Error ortográfico contado en la autoevaluación.
struct ErrorOrtografico: Codable, Sendable, Equatable, Hashable {
    var palabra: String
    /// Solo la tilde (0,25) o la palabra mal escrita (0,5).
    var tilde: Bool
}

enum Penalizacion {
    /// Penalización de una lista de errores: −0,5 por palabra y −0,25 por tilde, sin límite; un mismo
    /// error en la misma palabra cuenta una vez.
    static func calcular(_ errores: [ErrorOrtografico], reglas: ReglasOrtografia = .bases2026) -> Double {
        let unicos = Set(errores.map { ErrorOrtografico(palabra: $0.palabra.lowercased(), tilde: $0.tilde) })
        let total = unicos.reduce(0.0) { $0 + ($1.tilde ? reglas.tilde : reglas.palabraIncorrecta) }
        return reglas.limite.map { min($0, total) } ?? total
    }

    /// Con recuentos de palabras distintas (la autoevaluación cuenta cada palabra una vez).
    static func calcular(palabras: Int, tildes: Int, reglas: ReglasOrtografia = .bases2026) -> Double {
        let total = Double(palabras) * reglas.palabraIncorrecta + Double(tildes) * reglas.tilde
        return reglas.limite.map { min($0, total) } ?? total
    }
}

