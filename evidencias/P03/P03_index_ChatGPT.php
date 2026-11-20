<?php
// Variables para guardar los errores
$errores = [];

// Variable para saber si la reserva es correcta
$reservaCorrecta = false;

// Comprobar si se ha enviado el formulario
if ($_SERVER["REQUEST_METHOD"] == "POST") {

    // Recoger los datos del formulario
    $nombre = trim($_POST["nombre"] ?? "");
    $email = trim($_POST["email"] ?? "");
    $fecha = $_POST["fecha"] ?? "";
    $hora = $_POST["hora"] ?? "";
    $personas = $_POST["personas"] ?? "";

    // 1. VALIDAR NOMBRE
    if (empty($nombre)) {
        $errores[] = "El nombre es obligatorio.";
    } elseif (strlen($nombre) < 3) {
        $errores[] = "El nombre debe tener al menos 3 caracteres.";
    }

    // 2. VALIDAR EMAIL
    if (empty($email)) {
        $errores[] = "El correo electrónico es obligatorio.";
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errores[] = "El correo electrónico no es válido.";
    }

    // 3. VALIDAR FECHA
    $fechaActual = date("Y-m-d");

    if (empty($fecha)) {
        $errores[] = "La fecha es obligatoria.";
    } elseif ($fecha < $fechaActual) {
        $errores[] = "No puedes reservar en una fecha pasada.";
    }

    // 4. VALIDAR HORA
    if (empty($hora)) {
        $errores[] = "La hora es obligatoria.";
    } elseif ($hora < "13:00" || $hora > "22:00") {
        $errores[] = "El horario debe estar entre las 13:00 y las 22:00.";
    }

    // 5. VALIDAR NUMERO DE PERSONAS
    if ($personas === "") {
        $errores[] = "Debes indicar el número de personas.";
    } elseif (filter_var($personas, FILTER_VALIDATE_INT) === false ||
              $personas < 1 || $personas > 10) {
        $errores[] = "El número de personas debe estar entre 1 y 10.";
    }

    // Comprobar si no existen errores
    if (empty($errores)) {
        $reservaCorrecta = true;
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Formulario de reservas PHP</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f2f2f2;
            padding: 30px;
        }

        .contenedor {
            background: white;
            max-width: 450px;
            margin: auto;
            padding: 25px;
            border-radius: 10px;
        }

        label {
            display: block;
            margin-top: 15px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 10px;
            margin-top: 5px;
            box-sizing: border-box;
        }

        button {
            margin-top: 20px;
            padding: 12px;
            width: 100%;
            background: #2878c8;
            color: white;
            border: none;
            cursor: pointer;
        }

        .correcto {
            background: #d4edda;
            padding: 15px;
            color: #155724;
            margin-top: 20px;
        }

        .incorrecto {
            background: #f8d7da;
            padding: 15px;
            color: #721c24;
            margin-top: 20px;
        }
    </style>
</head>

<body>

<div class="contenedor">

    <h2>Reserva de restaurante</h2>

    <form method="POST" action="">

        <label>Nombre y apellidos:</label>
        <input type="text" name="nombre"
        value="<?= htmlspecialchars($nombre ?? '') ?>">

        <label>Correo electrónico:</label>
        <input type="text" name="email"
        value="<?= htmlspecialchars($email ?? '') ?>">

        <label>Fecha de reserva:</label>
        <input type="date" name="fecha"
        value="<?= htmlspecialchars($fecha ?? '') ?>">

        <label>Hora de reserva:</label>
        <input type="time" name="hora"
        value="<?= htmlspecialchars($hora ?? '') ?>">

        <label>Número de personas:</label>
        <input type="number" name="personas" min="1" max="10"
        value="<?= htmlspecialchars($personas ?? '') ?>">

        <button type="submit">Comprobar reserva</button>

    </form>

    <?php if ($reservaCorrecta): ?>

        <div class="correcto">
            <h3>¡Reserva realizada correctamente!</h3>

            <p>Nombre: <?= htmlspecialchars($nombre) ?></p>
            <p>Email: <?= htmlspecialchars($email) ?></p>
            <p>Fecha: <?= htmlspecialchars($fecha) ?></p>
            <p>Hora: <?= htmlspecialchars($hora) ?></p>
            <p>Personas: <?= htmlspecialchars($personas) ?></p>
        </div>

    <?php elseif (!empty($errores)): ?>

        <div class="incorrecto">
            <h3>Se han encontrado errores:</h3>

            <ul>
                <?php foreach ($errores as $error): ?>
                    <li><?= htmlspecialchars($error) ?></li>
                <?php endforeach; ?>
            </ul>
        </div>

    <?php endif; ?>

</div>

</body>
</html>
