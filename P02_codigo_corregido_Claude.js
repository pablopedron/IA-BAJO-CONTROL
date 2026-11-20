const API_URL = "https://jsonplaceholder.typicode.com/posts";
const TOTAL_POSTS = 100;
const TIMEOUT_MS = 8000;

const boton = document.querySelector("#cargar");
const salida = document.querySelector("#resultado");

if (!boton || !salida) {
  throw new Error("Faltan los elementos #cargar o #resultado en el HTML.");
}

// Devuelve un ID entre 1 y TOTAL_POSTS (ambos incluidos)
function obtenerIdAleatorio() {
  return Math.floor(Math.random() * TOTAL_POSTS) + 1;
}

async function obtenerPost(id) {
  const controlador = new AbortController();
  const temporizador = setTimeout(() => controlador.abort(), TIMEOUT_MS);

  try {
    const respuesta = await fetch(`${API_URL}/${id}`, {
      signal: controlador.signal,
    });

    if (!respuesta.ok) {
      throw new Error(`Error HTTP ${respuesta.status}`);
    }

    return await respuesta.json();
  } finally {
    clearTimeout(temporizador);
  }
}

// Usa textContent para evitar inyección de HTML (XSS)
function mostrarPost({ title, body }) {
  const titulo = document.createElement("h3");
  titulo.textContent = title;

  const cuerpo = document.createElement("p");
  cuerpo.textContent = body;

  salida.replaceChildren(titulo, cuerpo);
}

function mostrarError(mensaje) {
  const parrafo = document.createElement("p");
  parrafo.textContent = mensaje;
  parrafo.setAttribute("role", "alert");
  salida.replaceChildren(parrafo);
}

function obtenerMensajeError(error) {
  if (error.name === "AbortError") {
    return "La petición tardó demasiado. Inténtalo de nuevo.";
  }
  if (error instanceof TypeError) {
    return "No se pudo conectar. Revisa tu conexión a internet.";
  }
  if (error.message.startsWith("Error HTTP")) {
    return `El servidor respondió con un error (${error.message}).`;
  }
  return "Ocurrió un error inesperado.";
}

boton.addEventListener("click", async () => {
  boton.disabled = true;
  salida.textContent = "Cargando...";

  try {
    const post = await obtenerPost(obtenerIdAleatorio());
    mostrarPost(post);
  } catch (error) {
    console.error("Fallo al cargar el post:", error);
    mostrarError(obtenerMensajeError(error));
  } finally {
    boton.disabled = false;
  }
});
