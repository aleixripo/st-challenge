<script setup>

// Obtener la instancia del usuario y la instancia de Supabase para realizar consultas a la base de datos.
const user = useSupabaseUser()
const route = useRoute()

// Si el usuario ya ha iniciado sesión, se redirige a la ruta principal.
watch(user, () => {
    if (user.value) {
        return navigateTo('/')
    }
}, { immediate: true })

// Si no hay un hash en la URL y el usuario no ha iniciado sesión, se redirige a la ruta de inicio de sesión.
onMounted(() => {
    if (!route.hash && !user.value) {
        navigateTo('/login')
    }
})
</script>

<template>
    <div class="container vh-100 d-flex align-items-center justify-content-center">
        <div class="text-center">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Cargando...</span>
            </div>
            <p class="mt-3 fw-bold text-secondary">Verificando sesión...</p>
        </div>
    </div>
</template>