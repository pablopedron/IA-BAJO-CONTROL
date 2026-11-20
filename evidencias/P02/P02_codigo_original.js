const boton = document.querySelector("#cargar");
const salida = document.querySelector("#resultado");

boton.addEventListener("click", function () {
  fetch("https://jsonplaceholder.typicode.com/posts/" + Math.floor(Math.random() * 10))
    .then(r => r.json())
    .then(datos => {
      salida.innerHTML = "<h3>" + datos.title + "</h3><p>" + datos.body + "</p>";
    })
    .catch(() => {
      salida.innerHTML = "Error";
    });
}
