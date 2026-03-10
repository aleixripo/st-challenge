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

<script setup>
const supabase = useSupabaseClient()
const email = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

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