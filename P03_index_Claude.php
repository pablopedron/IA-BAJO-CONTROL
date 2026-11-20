<?php
declare(strict_types=1);

/**
 * Valida los datos de una reserva.
 * Devuelve un array de errores (vacío = todo correcto).
 */
function validarReserva(array $datos): array
{
    $errores = [];

    // Nombre: obligatorio y mínimo 3 caracteres
    $nombre = trim($datos['nombre'] ?? '');
    if ($nombre === '') {
        $errores['nombre'] = 'El nombre es obligatorio.';
    } elseif (mb_strlen($nombre) < 3) {
        $errores['nombre'] = 'El nombre debe tener al menos 3 caracteres.';
    }

    // Email: formato válido
    $email = trim($datos['email'] ?? '');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errores['email'] = 'El email no tiene un formato válido.';
    }

    // Personas: entero entre 1 y 10
    $personas = filter_var(
        $datos['personas'] ?? null,
        FILTER_VALIDATE_INT,
        ['options' => ['min_range' => 1, 'max_range' => 10]]
    );
    if ($personas === false) {
        $errores['personas'] = 'El número de personas debe ser un entero entre 1 y 10.';
    }

    // Fecha: formato real AAAA-MM-DD y no puede ser pasada
    $fecha = trim($datos['fecha'] ?? '');
    $d = DateTime::createFromFormat('Y-m-d', $fecha);
    if (!$d || $d->format('Y-m-d') !== $fecha) {
        $errores['fecha'] = 'La fecha no es válida.';
    } elseif ($fecha < date('Y-m-d')) {
        $errores['fecha'] = 'La fecha no puede ser anterior a hoy.';
    }

    return $errores;
}

function e(string $texto): string
{
    return htmlspecialchars($texto, ENT_QUOTES, 'UTF-8');
}

// ---------- Casos de prueba para comparar ----------
$casos = [
    'Entrada VÁLIDA' => [
        'nombre'   => 'Laura Gómez',
        'email'    => 'laura@ejemplo.com',
        'personas' => '4',
        'fecha'    => date('Y-m-d', strtotime('+7 days')),
    ],
    'Entrada INCORRECTA' => [
        'nombre'   => 'Al',
        'email'    => 'laura@@ejemplo',
        'personas' => '25',
        'fecha'    => '2020-02-31',
    ],
];

// ---------- Formulario real ----------
$errores = [];
$enviado = $_SERVER['REQUEST_METHOD'] === 'POST';
if ($enviado) {
    $errores = validarReserva($_POST);
}
$val = fn(string $campo): string => e((string)($_POST[$campo] ?? ''));
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Validación de reservas en PHP</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; }
        .caso { border: 2px solid #ccc; padding: 1rem; margin-bottom: 1rem; border-radius: 8px; }
        .ok { border-color: #2e7d32; background: #e8f5e9; }
        .ko { border-color: #c62828; background: #ffebee; }
        .error { color: #c62828; font-size: .9rem; }
        label { display: block; margin-top: .8rem; }
        input { padding: .4rem; width: 100%; max-width: 300px; }
    </style>
</head>
<body>

<h1>Comparativa: entrada válida vs incorrecta</h1>
<?php foreach ($casos as $titulo => $datos):
    $errs = validarReserva($datos); ?>
    <div class="caso <?= $errs ? 'ko' : 'ok' ?>">
        <h3><?= e($titulo) ?> → <?= $errs ? '❌ Rechazada' : '✅ Aceptada' ?></h3>
        <p>Datos: <code><?= e(json_encode($datos, JSON_UNESCAPED_UNICODE)) ?></code></p>
        <?php foreach ($errs as $campo => $msg): ?>
            <p class="error"><strong><?= e($campo) ?>:</strong> <?= e($msg) ?></p>
        <?php endforeach; ?>
    </div>
<?php endforeach; ?>

<h1>Prueba tú mismo el formulario</h1>
<?php if ($enviado && !$errores): ?>
    <p style="color:#2e7d32"><strong>✅ Reserva registrada correctamente.</strong></p>
<?php endif; ?>

<form method="post" novalidate>
    <label>Nombre
        <input type="text" name="nombre" value="<?= $val('nombre') ?>">
    </label>
    <span class="error"><?= e($errores['nombre'] ?? '') ?></span>

    <label>Email
        <input type="text" name="email" value="<?= $val('email') ?>">
    </label>
    <span class="error"><?= e($errores['email'] ?? '') ?></span>

    <label>Personas (1-10)
        <input type="text" name="personas" value="<?= $val('personas') ?>">
    </label>
    <span class="error"><?= e($errores['personas'] ?? '') ?></span>

    <label>Fecha (AAAA-MM-DD)
        <input type="text" name="fecha" value="<?= $val('fecha') ?>">
    </label>
    <span class="error"><?= e($errores['fecha'] ?? '') ?></span>

    <p><button type="submit">Reservar</button></p>
</form>

</body>
</html>
