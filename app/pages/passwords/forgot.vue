<script setup>

// Importar la instancia de Supabase para realizar consultas a la base de datos
const supabase = useSupabaseClient()

// Variables para almacenar la nueva contraseña, estado de carga y mensajes de error
const email = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

/**
 * Maneja la solicitud de restablecer la contraseña de un usuario.
 * Envia una solicitud a Supabase para restablecer la contraseña del usuario con el email
 * proporcionado en `email.value`. Si se produce un error, se muestra el mensaje
 * del error en `errorMsg.value`. Si se completa correctamente, se muestra un mensaje de éxito
 * en `successMsg.value`. Establece `loading.value` en `true` mientras se completa la solicitud
 * y en `false` cuando se ha completado.
 */
const handleReset = async () => {
    loading.value = true
    errorMsg.value = ''
    successMsg.value = ''

    const { error } = await supabase.auth.resetPasswordForEmail(email.value, {
        redirectTo: 'http://localhost:3000/passwords/update',
    })

    if (error) {
        errorMsg.value = "Error: " + error.message
    } else {
        successMsg.value = "¡Enlace enviado! Revisa tu bandeja de entrada."
    }
    loading.value = false
}
</script>

<template>
    <div class="container vh-100 d-flex align-items-center justify-content-center">
        <div class="card shadow p-4" style="max-width: 400px; width: 100%;">
            <h2 class="text-center mb-4">Recuperar Contraseña</h2>
            <p class="text-muted small text-center mb-4">Te enviaremos un enlace para que puedas definir una nueva
                contraseña.</p>

            <form @submit.prevent="handleReset">
                <div class="mb-3">
                    <label class="form-label fw-bold">Email de tu cuenta</label>
                    <input v-model="email" type="email" class="form-control" placeholder="ejemplo@correo.com"
                        required />
                </div>
                <button type="submit" class="btn btn-primary w-100 fw-bold" :disabled="loading">
                    <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
                    Enviar enlace
                </button>
            </form>

            <div v-if="errorMsg" class="alert alert-danger mt-3 small">{{ errorMsg }}</div>
            <div v-if="successMsg" class="alert alert-success mt-3 small">{{ successMsg }}</div>

            <div class="text-center">
                <NuxtLink to="/login" class="btn btn-link small text-decoration-none">Volver al Login</NuxtLink>
            </div>
        </div>
    </div>
</template>