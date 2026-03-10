<script setup>
import Swal from 'sweetalert2'

const supabase = useSupabaseClient()
const categories = ref([])
const loading = ref(true)
const isSubmitting = ref(false)
const isEditing = ref(false) // Controla si el modal es para crear o editar

// Estado del formulario
const form = ref({
    id: null,
    code: '',
    name: '',
    description: '',
    parent_id: null
})

let modalInstance = null

const fetchCategories = async () => {
    loading.value = true
    const { data, error } = await supabase
        .from('categories')
        .select('*, parent:parent_id (name)')
        .order('created_at', { ascending: false })

    if (error) Swal.fire('Error', error.message, 'error')
    else categories.value = data
    loading.value = false
}

// Abre el modal para CREAR
const openCreateModal = () => {
    isEditing.value = false
    form.value = { id: null, code: '', name: '', description: '', parent_id: null }
    modalInstance.show()
}

// Abre el modal para EDITAR cargando los datos
const openEditModal = (cat) => {
    isEditing.value = true
    form.value = {
        id: cat.id,
        code: cat.code,
        name: cat.name,
        description: cat.description,
        parent_id: cat.parent_id
    }
    modalInstance.show()
}

const handleSubmit = async () => {
    isSubmitting.value = true

    const payload = {
        code: form.value.code,
        name: form.value.name,
        description: form.value.description,
        parent_id: form.value.parent_id
    }

    let error;
    if (isEditing.value) {
        const { error: err } = await supabase.from('categories').update(payload).eq('id', form.value.id)
        error = err
    } else {
        const { error: err } = await supabase.from('categories').insert([payload])
        error = err
    }

    if (error) {
        Swal.fire('Error', error.message, 'error')
    } else {
        await fetchCategories()
        Swal.fire({
            title: isEditing.value ? '¡Actualizado!' : '¡Creado!',
            icon: 'success',
            timer: 1500,
            showConfirmButton: false
        })
        modalInstance.hide()
    }
    isSubmitting.value = false
}

const deleteCategory = async (id) => {
    const result = await Swal.fire({
        title: '¿Estás seguro?',
        text: "Se borrarán también sus subcategorías.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc3545',
        confirmButtonText: 'Sí, eliminar'
    })

    if (result.isConfirmed) {
        const { error } = await supabase.from('categories').delete().eq('id', id)
        if (!error) fetchCategories()
    }
}

onMounted(async () => {
    await fetchCategories()
    const { Modal } = await import('bootstrap')
    modalInstance = new Modal(document.getElementById('categoryModal'))
})
</script>

<template>
    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2><i class="bi bi-tags me-2"></i>Gestión de Categorías</h2>
            <button @click="openCreateModal" class="btn btn-primary shadow-sm">
                <i class="bi bi-plus-lg me-1"></i> Nueva Categoría
            </button>
        </div>

        <div v-if="loading" class="text-center my-5">
            <div class="spinner-border text-primary"></div>
        </div>

        <div v-else class="card shadow-sm border-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Código</th>
                            <th>Nombre</th>
                            <th>Descripción</th>
                            <th>Jerarquía</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="cat in categories" :key="cat.id">
                            <td><span class="badge bg-secondary">{{ cat.code }}</span></td>
                            <td class="fw-bold">{{ cat.name }}</td>
                            <td class="fw-bold">{{ cat.description }}</td>
                            <td>
                                <span v-if="cat.parent" class="badge bg-info text-dark">{{ cat.parent.name }}</span>
                                <span v-else class="text-muted small">Principal</span>
                            </td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <button @click="openEditModal(cat)" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <button @click="deleteCategory(cat.id)" class="btn btn-sm btn-outline-danger">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="categories.length === 0">
                            <td colspan="5" class="text-center py-5 text-muted">
                                No hay categorías creadas todavía.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="mt-3">
            <NuxtLink to="/" class="btn btn-link btn-sm text-muted text-decoration-none">
                <i class="bi bi-house-door me-1"></i> Volver al Dashboard
            </NuxtLink>
        </div>

        <div class="modal fade" id="categoryModal" tabindex="-1">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content shadow border-0">
                    <form @submit.prevent="handleSubmit">
                        <div class="modal-header bg-light">
                            <h5 class="modal-title fw-bold">
                                {{ isEditing ? 'Editar Categoría' : 'Nueva Categoría' }}
                            </h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label small fw-bold">Código</label>
                                    <input v-model="form.code" type="text" class="form-control" required>
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label class="form-label small fw-bold">Nombre</label>
                                    <input v-model="form.name" type="text" class="form-control" required>
                                </div>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-bold">Categoría Padre</label>
                                <select v-model="form.parent_id" class="form-select">
                                    <option :value="null">Ninguna (Principal)</option>
                                    <option v-for="c in categories.filter(c => c.id !== form.id)" :key="c.id"
                                        :value="c.id">
                                        {{ c.name }}
                                    </option>
                                </select>
                            </div>
                            <div class="mb-0">
                                <label class="form-label small fw-bold">Descripción</label>
                                <textarea v-model="form.description" class="form-control" rows="3"></textarea>
                            </div>
                        </div>
                        <div class="modal-footer bg-light">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="submit" class="btn btn-primary px-4" :disabled="isSubmitting">
                                {{ isEditing ? 'Guardar Cambios' : 'Crear Categoría' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>