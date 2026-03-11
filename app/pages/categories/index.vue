<script setup>

// Importar librerías y variables globales
import Swal from 'sweetalert2'

// Obtener la instancia de Supabase para realizar consultas a la base de datos.
const supabase = useSupabaseClient()

// Variables para almacenar las categorías, estado de carga y edición y envío del formulario
const categories = ref([])
const loading = ref(true)
const isSubmitting = ref(false)
const isEditing = ref(false)

// Formulario para crear o editar categorías
const form = ref({
    id: null,
    code: '',
    name: '',
    description: '',
    parent_id: null
})

// Instancia de la ventana modal para mostrar el formulario
let modalInstance = null

/**
 * Obtener categorías con sus respectivas categorías padre.
 * Establece `loading` en `true` mientras se obtienen los datos.
 * Establece `categories` en los datos obtenidos.
 * Establece `loading` en `false` cuando se han obtenido los datos.
 * Muestra un mensaje de error con `Swal` si ocurre un error.
 */
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

/**
 * Abre la ventana modal para crear o editar una categoría.
 * Si `cat` es proporcionado, se establecerá en modo de edición y se
 * completará el formulario con los datos de la categoría.
 * De lo contrario, se establecerá en modo de creación y se
 * limpiará el formulario.
 * Se muestra la ventana modal al finalizar.
 * @param {Object} [cat] - La categoría a editar, o null para crear una nueva.
 */
const openModal = (cat = null) => {
    if (cat) {
        isEditing.value = true
        form.value = {
            id: cat.id,
            code: cat.code,
            name: cat.name,
            description: cat.description,
            parent_id: cat.parent_id
        }
        modalInstance.show()
    } else {
        isEditing.value = false
        form.value = { id: null, code: '', name: '', description: '', parent_id: null }
        modalInstance.show()
    }
}

/**
 * Envía una solicitud para crear o actualizar una categoría.
 * Si se produce un error, se muestra un mensaje de error con `Swal`.
 * Si se completa con éxito, se muestra un mensaje de confirmación con `Swal` y se
 * oculta la ventana modal.
 * Se establece `isSubmitting` en `true` mientras se envía la solicitud y en
 * `false` cuando se completa.
 */
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

/**
 * Elimina una categoría si no tiene subcategorías.
 * Antes de eliminar, se muestra un mensaje de confirmación con `Swal`.
 * Si se produce un error, no se hará nada.
 * Si se completa con éxito, se recarga la tabla de categorías con `fetchCategories`.
 * @param {Object} category - La categoría a eliminar.
 */
const deleteCategory = async (category) => {
    const hasChildren = categories.value.some(c => c.parent_id === category.id)

    if (hasChildren) {
        await Swal.fire({
            title: 'No se puede eliminar',
            text: `La categoría "${category.name}" contiene subcategorías. Debes eliminarlas o moverlas primero.`,
            icon: 'error'
        })
        return
    }

    const result = await Swal.fire({
        title: '¿Estás seguro?',
        text: `Vas a eliminar la categoría "${category.name}".`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc3545',
        confirmButtonText: 'Sí, eliminar'
    })

    if (result.isConfirmed) {
        await supabase.from('categories').delete().eq('id', category.id)
        fetchCategories()
    }
}

/**
 * Se ejecuta cuando se monta el componente.
 * Se encarga de inicializar la instancia de la modal de Bootstrap y de cargar los datos de las categorías.
 */
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
            <div class="d-flex gap-2">
                <NuxtLink to="/" class="btn btn btn-outline-secondary btn-smtext-decoration-none">
                    <i class="bi bi-house-door me-1"></i> Volver al Dashboard
                </NuxtLink>
                <button @click="openModal()" class="btn btn-primary shadow-sm">
                    <i class="bi bi-plus-lg me-1"></i> Nueva Categoría
                </button>
            </div>
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
                                    <button @click="openModal(cat)" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <button @click="deleteCategory(cat)" class="btn btn-sm btn-outline-danger">
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
                                    <option v-for="c in categories.filter(c => c.id !== form.id && !c.parent_id)"
                                        :key="c.id" :value="c.id">
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