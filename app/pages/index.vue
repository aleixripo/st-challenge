<template>
    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center border-bottom pb-3">
            <h1 class="h2">Backoffice</h1>
            <div>
                <span class="me-3 text-muted small d-none d-md-inline">{{ user?.email }}</span>
                <button @click="logout" class="btn btn-outline-danger btn-sm">Cerrar Sesión</button>
            </div>
        </div>

        <div class="mt-4">
            <p class="lead">Bienvenido al gestor de contenidos. Selecciona una sección para comenzar:</p>

            <div class="row g-4 mt-2">
                <div class="col-md-4">
                    <div class="card h-100 shadow-sm">
                        <div class="card-body text-center">
                            <h5 class="card-title">Categorías</h5>
                            <p class="card-text text-muted small">Gestión de categorías y subcategorías jerárquicas.</p>
                            <NuxtLink to="/categories" class="btn btn-primary w-100">Administrar</NuxtLink>
                        </div>
                    </div>
                </div>

                <div class="col-md-4">
                    <div class="card h-100 shadow-sm">
                        <div class="card-body text-center">
                            <h5 class="card-title">Productos</h5>
                            <p class="card-text text-muted small">Mantenimiento de productos, fotos y tarifas por
                                fechas.</p>
                            <NuxtLink to="/products" class="btn btn-primary w-100">Administrar</NuxtLink>
                        </div>
                    </div>
                </div>

                <div class="col-md-4">
                    <div class="card h-100 shadow-sm">
                        <div class="card-body text-center">
                            <h5 class="card-title">Calendario</h5>
                            <p class="card-text text-muted small">Visualización de pedidos y citas programadas.</p>
                            <NuxtLink to="/calendar" class="btn btn-primary w-100">Administrar</NuxtLink>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
const user = useSupabaseUser()
const supabase = useSupabaseClient()

const logout = async () => {
    await supabase.auth.signOut()
    navigateTo('/login')
}
</script>