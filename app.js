(async function () {
  const params = new URLSearchParams(window.location.search);
  const requested = (params.get("look") || "01").padStart(2, "0");
  const viewer = document.getElementById("viewer");
  const errorBox = document.getElementById("error");
  const deviceNote = document.getElementById("deviceNote");
  const isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
  const isAndroid = /Android/i.test(navigator.userAgent);
  try {
    const res = await fetch("looks.json", { cache: "no-store" });
    if (!res.ok) throw new Error("No se pudo leer looks.json");
    const data = await res.json();
    const look = data.looks.find(item => String(item.id).padStart(2, "0") === requested) || data.looks[0];
    document.getElementById("pieceNumber").textContent = String(look.id).padStart(2, "0");
    document.getElementById("title").textContent = look.title;
    document.getElementById("student").textContent = look.student;
    document.getElementById("technique").textContent = look.technique;
    document.getElementById("year").textContent = look.year;
    document.getElementById("concept").textContent = look.concept || "";
    viewer.setAttribute("src", look.model);
    viewer.setAttribute("scale", look.scale || "1 1 1");
    viewer.setAttribute("ar-placement", look.placement || "floor");
    viewer.setAttribute("alt", `Prenda digital ${look.title} de ${look.student}`);
    if (look.iosModel) viewer.setAttribute("ios-src", look.iosModel);
    document.title = `${look.title} · CLO3D Museum AR`;
    if (isIOS && !look.iosModel) {
      deviceNote.textContent = "En iPhone: la previsualización 3D funciona, pero para colocar la prenda en AR de forma nativa necesitas añadir también el archivo USDZ de esta pieza.";
    } else if (isAndroid) {
      deviceNote.textContent = "En Android compatible: toca “Ver en realidad aumentada”, mueve lentamente el teléfono para detectar el piso y coloca la prenda en el espacio.";
    } else {
      deviceNote.textContent = "Abre esta misma página desde un celular compatible para activar la colocación de la prenda en realidad aumentada.";
    }
    viewer.addEventListener("error", () => {
      errorBox.hidden = false;
      errorBox.textContent = "No se encontró el modelo de esta pieza. Revisa el nombre del archivo en models/ y en looks.json.";
    });
    viewer.addEventListener("ar-status", (event) => {
      if (event.detail.status === "failed") {
        errorBox.hidden = false;
        errorBox.textContent = "Este dispositivo o navegador no pudo iniciar AR. Prueba Chrome en Android o Safari en iPhone.";
      }
    });
  } catch (err) {
    errorBox.hidden = false;
    errorBox.textContent = "La exposición no pudo cargar sus datos. Revisa looks.json y vuelve a publicar el sitio.";
  }
})();
