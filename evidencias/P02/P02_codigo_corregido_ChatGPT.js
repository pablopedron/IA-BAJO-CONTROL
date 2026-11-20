const boton = document.querySelector("#cargar");
const salida = document.querySelector("#resultado");

// Comprobamos que los elementos existen en el DOM.
if (!boton || !salida) {
  throw new Error("No se encontraron los elementos necesarios en el DOM.");
}

// Función para obtener una publicación aleatoria.
async function cargarPublicacion() {
  const id = Math.floor(Math.random() * 10) + 1;

  salida.textContent = "Cargando publicación...";

  try {
    const respuesta = await fetch(
      `https://jsonplaceholder.typicode.com/posts/${id}`
    );

    // Comprobamos el estado HTTP.
    if (!respuesta.ok) {
      throw new Error(`Error HTTP: ${respuesta.status}`);
    }

    // Convertimos la respuesta a JSON.
    const datos = await respuesta.json();

    // Validamos los datos recibidos.
    if (!datos.title || !datos.body) {
      throw new Error("La respuesta del servidor no contiene datos válidos.");
    }

    // Creamos los elementos HTML de forma segura.
    const titulo = document.createElement("h3");
    const contenido = document.createElement("p");

    titulo.textContent = datos.title;
    contenido.textContent = datos.body;

    // Actualizamos el contenido del DOM.
    salida.replaceChildren(titulo, contenido);

  } catch (error) {
    console.error("Error al cargar la publicación:", error);

    salida.textContent = error.message.startsWith("Error HTTP:")
      ? error.message
      : "No se pudo cargar la publicación. Comprueba tu conexión e inténtalo de nuevo.";
  }
}

// Asociamos el evento al botón.
boton.addEventListener("click", cargarPublicacion);
