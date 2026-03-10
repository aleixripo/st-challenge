<template>
    <div class="container vh-100 d-flex align-items-center justify-content-center">
        <div class="card shadow p-4" style="max-width: 400px; width: 100%;">
            <h2 class="text-center mb-4">Nueva Contraseña</h2>
            <p class="text-muted small text-center mb-4">Escribe tu nueva contraseña de acceso.</p>

            <form @submit.prevent="handleUpdate">
                <div class="mb-3">
                    <label class="form-label fw-bold">Nueva Contraseña</label>
                    <input v-model="password" type="password" class="form-control" placeholder="Mínimo 6 caracteres"
                        required minlength="6" />
                </div>
                <button type="submit" class="btn btn-success w-100 fw-bold" :disabled="loading">
                    <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
                    Actualizar Contraseña
                </button>
            </form>

            <div v-if="errorMsg" class="alert alert-danger mt-3 small">{{ errorMsg }}</div>
        </div>
    </div>
</template>

<script setup>
const supabase = useSupabaseClient()
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

const handleUpdate = async () => {
    loading.value = true
    errorMsg.value = ''

    const { error } = await supabase.auth.updateUser({
        password: password.value
    })

    if (error) {
        errorMsg.value = "Error al actualizar: " + error.message
        loading.value = false
    } else {
        await navigateTo('/')
    }
}
</script>