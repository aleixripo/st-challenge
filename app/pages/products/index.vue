<script setup>
import Swal from 'sweetalert2'
import * as XLSX from 'xlsx'

const supabase = useSupabaseClient()
const products = ref([])
const categories = ref([])
const loading = ref(true)
const isSubmitting = ref(false)
const isEditing = ref(false)

// Estado del formulario según campos mínimos 
const form = ref({
    id: null,
    code: '',
    name: '',
    description: '',
    photos: [],
    category_ids: []
})

let modalInstance = null

const fetchData = async () => {
    loading.value = true
    // Cargar categorías para el select múltiple 
    const { data: catData } = await supabase.from('categories').select('id, name')
    categories.value = catData || []

    // Cargar productos con sus categorías asociadas
    const { data: prodData, error } = await supabase
        .from('products')
        .select(`
            *,
            product_categories(category_id, categories(name)),
            rates(*)
        `)
        .order('created_at', { ascending: false })

    if (error) Swal.fire('Error', error.message, 'error')
    else products.value = prodData
    loading.value = false
}

const openModal = (prod = null) => {
    if (prod) {
        isEditing.value = true
        form.value = {
            id: prod.id,
            code: prod.code,
            name: prod.name,
            description: prod.description,
            photos: prod.photos || [],
            category_ids: prod.product_categories.map(pc => pc.category_id)
        }
    } else {
        isEditing.value = false
        form.value = { id: null, code: '', name: '', description: '', photos: [], category_ids: [] }
    }
    modalInstance.show()
}

const handleSave = async () => {
    isSubmitting.value = true
    const productPayload = {
        code: form.value.code,
        name: form.value.name,
        description: form.value.description,
        photos: form.value.photos
    }

    let product_id = form.value.id
    const { data, error } = isEditing.value
        ? await supabase.from('products').update(productPayload).eq('id', product_id).select().single()
        : await supabase.from('products').insert([productPayload]).select().single()

    if (error) {
        Swal.fire('Error', error.message, 'error')
    } else {
        product_id = data.id
        // Actualizar relación de categorías 
        await supabase.from('product_categories').delete().eq('product_id', product_id)
        if (form.value.category_ids.length > 0) {
            const rels = form.value.category_ids.map(id => ({ product_id, category_id: id }))
            await supabase.from('product_categories').insert(rels)
        }

        await fetchData()
        modalInstance.hide()
        Swal.fire({ title: 'Guardado', icon: 'success', timer: 1500, showConfirmButton: false })
    }
    isSubmitting.value = false
}

const exportXLS = () => {
    const today = new Date().toLocaleDateString('sv-SE');

    console.log(today);
    const sheetData = products.value.map(p => {
        const currentRate = p.rates?.find(r => today >= r.start_date && today <= r.end_date)

        return {
            CODIGO: p.code,
            NOMBRE: p.name,
            CATEGORIAS: p.product_categories.map(pc => pc.categories?.name).join(', '),
            DESCRIPCION: p.description,
            'PRECIO ACTUAL': currentRate ? `${currentRate.price}€` : 'Sin tarifa vigente',
        }
    })

    const ws = XLSX.utils.json_to_sheet(sheetData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, "Inventario")
    XLSX.writeFile(wb, `Productos_${today}.xlsx`)
}

const deleteProduct = async (id) => {
    const result = await Swal.fire({
        title: '¿Eliminar producto?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Sí, borrar'
    })
    if (result.isConfirmed) {
        await supabase.from('products').delete().eq('id', id)
        fetchData()
    }
}

onMounted(async () => {
    await fetchData()
    const { Modal } = await import('bootstrap')
    modalInstance = new Modal(document.getElementById('productModal'))
})
</script>

<template>
    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2><i class="bi bi-box-seam me-2"></i>Gestión de Productos</h2>
            <div class="d-flex gap-2">
                <button @click="exportXLS" class="btn btn-outline-success">
                    <i class="bi bi-file-earmark-excel me-1"></i> Excel
                </button>
                <button @click="openModal()" class="btn btn-primary">
                    <i class="bi bi-plus-lg"></i> Nuevo
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
                            <th>Producto</th>
                            <th>Categorías</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="p in products" :key="p.id">
                            <td><span class="badge bg-secondary">{{ p.code }}</span></td>
                            <td class="fw-bold">{{ p.name }}</td>
                            <td>
                                <span v-for="pc in p.product_categories" :key="pc.category_id"
                                    class="badge bg-info text-dark me-1 fw-normal">
                                    {{ pc.categories?.name }}
                                </span>
                            </td>
                            <td class="text-end">
                                <div class="btn-group">
                                    <NuxtLink :to="`/products/${p.id}`" class="btn btn-sm btn-outline-dark"
                                        title="Ver Ficha y Tarifas">
                                        <i class="bi bi-calendar-range"></i>
                                    </NuxtLink>
                                    <button @click="openModal(p)" class="btn btn-sm btn-outline-primary"><i
                                            class="bi bi-pencil"></i></button>
                                    <button @click="deleteProduct(p.id)" class="btn btn-sm btn-outline-danger"><i
                                            class="bi bi-trash"></i></button>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="products.length === 0">
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

        <div class="modal fade" id="productModal" tabindex="-1">
            <div class="modal-dialog modal-lg">
                <div class="modal-content shadow border-0">
                    <form @submit.prevent="handleSave">
                        <div class="modal-header bg-light">
                            <h5 class="modal-title fw-bold">{{ isEditing ? 'Editar Producto' : 'Nuevo Producto' }}</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="row g-3">
                                <div class="col-md-4">
                                    <label class="form-label small fw-bold">Código *</label>
                                    <input v-model="form.code" type="text" class="form-control" required>
                                </div>
                                <div class="col-md-8">
                                    <label class="form-label small fw-bold">Nombre *</label>
                                    <input v-model="form.name" type="text" class="form-control" required>
                                </div>
                                <div class="col-12">
                                    <label class="form-label small fw-bold">Categorías</label>
                                    <div class="border rounded p-3 bg-white"
                                        style="max-height: 150px; overflow-y: auto;">
                                        <div v-for="c in categories" :key="c.id" class="form-check">
                                            <input class="form-check-input" type="checkbox" :id="'cat-' + c.id"
                                                :value="c.id" v-model="form.category_ids">
                                            <label class="form-check-label small" :for="'cat-' + c.id">
                                                {{ c.name }}
                                            </label>
                                        </div>
                                        <div v-if="categories.length === 0" class="text-muted small italic">
                                            No hay categorías creadas.
                                        </div>
                                    </div>
                                    <div class="form-text small text-info">
                                        <i class="bi bi-info-circle"></i> Selecciona todas las que apliquen.
                                    </div>
                                </div>
                                <div class="col-12">
                                    <label class="form-label small fw-bold">Descripción</label>
                                    <textarea v-model="form.description" class="form-control" rows="3"></textarea>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer bg-light">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="submit" class="btn btn-primary px-4" :disabled="isSubmitting">Guardar</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>