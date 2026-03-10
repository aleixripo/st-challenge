<script setup>

// Obtener la instancia de Supabase para realizar consultas a la base de datos.
const supabase = useSupabaseClient()

// Variables para almacenar los datos de inicio de sesión y registro y mensajes de error y exito
const email = ref('')
const password = ref('')
const isRegistering = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

// Función para alternar entre el modo de inicio de sesión y el de registro de usuarios
function toggleMode() {
    isRegistering.value = !isRegistering.value
    email.value = ''
    password.value = ''
    errorMsg.value = ''
    successMsg.value = ''
}

/**
 * Maneja la autenticación de usuarios.
 * 
 * Si se está en modo de registro, se utiliza la función `signUp` de Supabase para crear una cuenta.
 * Si se produce un error, se muestra el mensaje del error en `errorMsg`.
 * Si se registra correctamente, se redirige a la ruta de confirmación de la cuenta.
 * 
 * Si se está en modo de inicio de sesión, se utiliza la función `signInWithPassword` de Supabase para iniciar sesión.
 * Si se produce un error, se muestra el mensaje "Credenciales inválidas" en `errorMsg`.
 * Si se inicia sesión correctamente, se redirige a la ruta principal.
 **/
const handleAuth = async () => {
    errorMsg.value = ''
    successMsg.value = ''

    const redirectTo = window.location.origin + '/confirm'

    if (isRegistering.value) {
        const { error } = await supabase.auth.signUp({
            email: email.value,
            password: password.value,
            options: { emailRedirectTo: redirectTo }
        })
        if (error) errorMsg.value = error.message
        else navigateTo('/')
    } else {
        const { error } = await supabase.auth.signInWithPassword({
            email: email.value,
            password: password.value,
        })
        if (error) errorMsg.value = 'Credenciales inválidas'
        else navigateTo('/')
    }
}
</script>

<template>
    <div class="container vh-100 d-flex align-items-center justify-content-center">
        <div class="card shadow p-4" style="max-width: 400px; width: 100%;">
            <h2 class="text-center mb-4">{{ isRegistering ? 'Registro' : 'Login' }}</h2>
            <form @submit.prevent="handleAuth">
                <div class="mb-3">
                    <label class="form-label">Email</label>
                    <input v-model="email" type="email" class="form-control" required />
                </div>
                <div class="mb-3">
                    <label class="form-label">Contraseña</label>
                    <input v-model="password" type="password" class="form-control" required />
                </div>
                <button type="submit" class="btn btn-primary w-100">
                    {{ isRegistering ? 'Crear cuenta' : 'Entrar' }}
                </button>
            </form>
            <div v-if="errorMsg" class="alert alert-danger mt-3 small">{{ errorMsg }}</div>
            <div v-if="successMsg" class="alert alert-success mt-3 small">{{ successMsg }}</div>
            <div class="text-center mt-3">
                <NuxtLink to="/passwords/forgot" class="small text-muted text-decoration-none">
                    ¿Olvidaste tu contraseña?
                </NuxtLink>
                <button @click="toggleMode" class="btn btn-link small text-decoration-none">
                    {{ isRegistering ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate' }}
                </button>
            </div>
        </div>
    </div>
</template>