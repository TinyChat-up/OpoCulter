import json, pathlib
p = pathlib.Path("Educulter/Content/literatura/literatura.json")
d = json.loads(p.read_text(encoding="utf-8"))
A = {a["id"]: a for a in d["autores"]}; M = {m["id"]: m for m in d["movimientos"]}
A["frayluis"]["generos"] = ["poesia", "ensayo"]
A["lope"]["generos"] = ["teatro", "poesia", "narrativa", "ensayo"]
A["teresa"]["generos"] = ["narrativa", "ensayo"]
for o in A["teresa"]["obras"]:
    if o["titulo"] == "Las moradas": o["genero"] = "ensayo"
d["movimientos"] += [
 {"id":"TEATRO1900","nombre":"Teatro de principios del siglo XX","periodo":"siglo_xx","inicio":1900,"fin":1936,
  "rasgos":["Alta comedia burguesa (Benavente)","Teatro cómico popular: sainete, astracán y tragedia grotesca (Arniches, Muñoz Seca)"]},
 {"id":"G36","nombre":"Generación del 36","periodo":"siglo_xx","inicio":1936,"fin":1950,
  "rasgos":["Poetas que empiezan a publicar en torno a la Guerra Civil","Poesía humana y comprometida, cercana al 27"]}]
for i in ("benavente", "arniches", "munozseca"): A[i]["movimiento"] = "TEATRO1900"
A["mhernandez"]["movimiento"] = "G36"
A["mhernandez"]["rasgo"] = "Amor, vida y muerte; poesía comprometida. Cercano a la Generación del 27"
A["goethe"]["rasgo"] = "Del Sturm und Drang al clasicismo de Weimar; cumbre de la literatura alemana"
A["marse"]["movimiento"] = "POSGUERRA"
A["hierro"]["obras"] = [{"titulo": "Quinta del 42", "anio": 1952, "genero": "poesia"}]
A["gilbiedma"]["obras"] = [{"titulo": "Moralidades", "anio": 1966, "genero": "poesia"}]
for o in A["lorca"]["obras"]:
    if o["titulo"] == "La casa de Bernarda Alba": o["anio"] = 1936
M["REALISMO"]["fin"] = 1905
for a in d["autores"]:
    if a["pais"] in ("Inglaterra", "Escocia"): a["pais"] = "Reino Unido"
    if a["pais"] == "Roma": a["pais"] = "Italia"
A["grimm"]["rasgo"] = "Jacob (1785-1863) y Wilhelm (1786-1859) recopilaron cuentos populares alemanes"
for a in d["autores"]:
    a["fragmentosPermitidos"] = bool(a["dominioPublico"] and a["ambito"] in ("espanola", "hispanoamericana"))
d["version"] = 2
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("OK", len(d["autores"]), "autores,", len(d["movimientos"]), "movimientos,",
      sum(a["fragmentosPermitidos"] for a in d["autores"]), "con fragmentos permitidos")
