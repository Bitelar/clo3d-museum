
(async function () {
  const params = new URLSearchParams(window.location.search);
  const requested = (params.get("look") || "01").padStart(2, "0");

  const viewer = document.getElementById("viewer");
  const errorBox = document.getElementById("error");

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
    viewer.setAttribute("alt", `Prenda digital ${look.title} de ${look.student}`);

    document.title = `${look.title} · CLO3D Museum`;

    viewer.addEventListener("error", () => {
      errorBox.hidden = false;
      errorBox.textContent = "No se encontró el modelo de esta pieza. Revisa que el archivo GLB exista y que el nombre coincida con looks.json.";
    });
  } catch (err) {
    errorBox.hidden = false;
    errorBox.textContent = "La exposición no pudo cargar sus datos. Revisa looks.json y vuelve a publicar el sitio.";
  }
})();
