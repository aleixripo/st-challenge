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

<script setup>
const user = useSupabaseUser()
const route = useRoute()


watch(user, () => {
    if (user.value) {
        return navigateTo('/')
    }
}, { immediate: true })

onMounted(() => {
    if (!route.hash && !user.value) {
        navigateTo('/login')
    }
})
</script>