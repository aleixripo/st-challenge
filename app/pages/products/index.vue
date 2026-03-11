<script setup>

// Importar librerías y variables globales
import Swal from 'sweetalert2'
import * as XLSX from 'xlsx'

// Obtener la instancia de Supabase para realizar consultas a la base de datos.
const supabase = useSupabaseClient()

// Variables para almacenar los productos, categorías, estado de carga y envío del formulario
const products = ref([])
const categories = ref([])
const loading = ref(true)
const isSubmitting = ref(false)
const isEditing = ref(false)
const uploadingImg = ref(false)

// Formulario para crear o editar un producto.
const form = ref({
    id: null,
    code: '',
    name: '',
    description: '',
    photos: '',
    category_ids: []
})

// Instancia de la ventana modal de Bootstrap para mostrar el formulario de creación o edición de productos.
let modalInstance = null

/**
 * Carga los datos de productos y categorías desde Supabase y los almacena en las variables `products` y `categories`.
 * Muestra un mensaje de error con `Swal` si ocurre un error.
 * Establece `loading` en `true` mientras se cargan los datos y en `false` cuando se han cargado.
 */
const fetchData = async () => {
    loading.value = true

    const { data: catData } = await supabase.from('categories').select('id, name')
    categories.value = catData || []

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

/**
 * Sube una imagen para el producto.
 * @param {Event} event - Evento que contiene el archivo a subir.
 * @returns {Promise<void>}
 */

const uploadImage = async (event) => {
    const file = event.target.files[0]
    if (!file) return

    try {
        uploadingImg.value = true
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}.${fileExt}`

        const { error: uploadError } = await supabase.storage
            .from('product-photos')
            .upload(fileName, file)

        if (uploadError) throw uploadError

        const { data } = supabase.storage
            .from('product-photos')
            .getPublicUrl(fileName)

        const current = form.value.photos ? form.value.photos.trim() : ''
        form.value.photos = current ? `${current}, ${data.publicUrl}` : data.publicUrl

        Swal.fire({ title: 'Imagen subida', icon: 'success', timer: 1000, showConfirmButton: false })
    } catch (err) {
        Swal.fire('Error', 'No se pudo subir la imagen: ' + err.message, 'error')
    } finally {
        uploadingImg.value = false
        event.target.value = ''
    }
}

/**
 * Abre la ventana modal para crear o editar un producto.
 * Si se proporciona un objeto `prod`, se cargan los datos del producto en el formulario.
 * De lo contrario, se limpian los campos del formulario.
 * Se muestra la ventana modal al finalizar la función.
 */
const openModal = (prod = null) => {
    if (prod) {
        isEditing.value = true
        form.value = {
            id: prod.id,
            code: prod.code,
            name: prod.name,
            description: prod.description,
            photos: prod.photos ? prod.photos.join(', ') : '',
            category_ids: prod.product_categories.map(pc => pc.category_id)
        }
    } else {
        isEditing.value = false
        form.value = { id: null, code: '', name: '', description: '', photos: [], category_ids: [] }
    }
    modalInstance.show()
}

/**
 * Envía una solicitud para crear o actualizar un producto.
 * Si se produce un error, se muestra un mensaje de error con `Swal`.
 * Si se completa con éxito, se actualiza la relación de categorías del producto y se
 * muestra un mensaje de confirmación con `Swal` y se oculta la ventana modal.
 * Se establece `isSubmitting` en `true` mientras se envía la solicitud y en
 * `false` cuando se completa.
 */
const handleSave = async () => {
    isSubmitting.value = true
    const photosArray = form.value.photos
        ? form.value.photos.split(',').map(s => s.trim()).filter(s => s !== '')
        : []
    const productPayload = {
        code: form.value.code,
        name: form.value.name,
        description: form.value.description,
        photos: photosArray
    }

    let product_id = form.value.id
    const { data, error } = isEditing.value
        ? await supabase.from('products').update(productPayload).eq('id', product_id).select().single()
        : await supabase.from('products').insert([productPayload]).select().single()

    if (error) {
        Swal.fire('Error', error.message, 'error')
    } else {
        product_id = data.id
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

/**
 * Exporta los productos a un archivo Excel en formato XLSX.
 * Se utiliza la fecha actual en formato local 'sv-SE' (dd/mm/yyyy) para nombrar el archivo.
 * El archivo se guarda en la carpeta actual y se muestra un mensaje de confirmación con `console.log`.
 */
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

/**
 * Elimina un producto con su respectiva relación de categorías.
 * Se muestra un mensaje de confirmación con `Swal` antes de eliminar.
 * Si se produce un error, no se hará nada.
 * Si se completa con éxito, se recarga la tabla de productos con `fetchData`.
 * @param {number} id - Identificador del producto a eliminar.
 */
const deleteProduct = async (id) => {
    const result = await Swal.fire({
        title: '¿Eliminar producto?',
        icon: 'warning',
        cancelButtonText: 'Cancelar',
        showCancelButton: true,
        confirmButtonText: 'Sí, borrar'
    })
    if (result.isConfirmed) {
        await supabase.from('products').delete().eq('id', id)
        fetchData()
    }
}

/**
 * Se ejecuta cuando se monta el componente.
 * Se encarga de inicializar la instancia de la modal de Bootstrap y de cargar los datos de las categorías.
 */
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
                <NuxtLink to="/" class="btn btn btn-outline-secondary btn-smtext-decoration-none">
                    <i class="bi bi-house-door me-1"></i> Volver al Dashboard
                </NuxtLink>
                <button @click="exportXLS" class="btn btn-outline-success">
                    <i class="bi bi-file-earmark-excel me-1"></i> Exportar
                </button>
                <button @click="openModal()" class="btn btn-primary">
                    <i class="bi bi-plus-lg"></i> Nuevo Producto
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
                            <th>Foto</th>
                            <th>Código</th>
                            <th>Producto</th>
                            <th>Categorías</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="p in products" :key="p.id">
                            <td>
                                <img :src="p.photos?.[0] || ''" class="rounded object-fit-cover shadow-sm"
                                    style="width: 50px; height: 50px;">
                            </td>
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
                                        <i class="bi bi-eye"></i> Tarifas
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
                                No hay productos creados todavía.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- <div class="modal fade" id="productModal" tabindex="-1">
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
        </div> -->
        <div class="modal fade" id="productModal" tabindex="-1">
            <div class="modal-dialog modal-xl">
                <div class="modal-content shadow border-0">
                    <form @submit.prevent="handleSave">
                        <div class="modal-header bg-light">
                            <h5 class="modal-title fw-bold">{{ isEditing ? 'Editar Producto' : 'Nuevo Producto' }}</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="row g-4">
                                <div class="col-md-7">
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
                                                style="max-height: 120px; overflow-y: auto;">
                                                <div v-for="c in categories" :key="c.id" class="form-check">
                                                    <input class="form-check-input" type="checkbox" :id="'cat-' + c.id"
                                                        :value="c.id" v-model="form.category_ids">
                                                    <label class="form-check-label small" :for="'cat-' + c.id">
                                                        {{ c.name }}
                                                    </label>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-12">
                                            <label class="form-label small fw-bold">Descripción</label>
                                            <textarea v-model="form.description" class="form-control"
                                                rows="3"></textarea>
                                        </div>
                                    </div>
                                </div>

                                <div class="col-md-5 border-start bg-light rounded-end py-2">
                                    <label class="form-label small fw-bold text-primary px-2">IMÁGENES DEL
                                        PRODUCTO</label>

                                    <div class="p-2 mb-3">
                                        <label class="form-label x-small text-muted mb-1">Cargar desde
                                            ordenador:</label>
                                        <div class="input-group input-group-sm">
                                            <input type="file" @change="uploadImage" class="form-control"
                                                accept="image/*" :disabled="uploadingImg">
                                            <span v-if="uploadingImg" class="input-group-text bg-white">
                                                <div class="spinner-border spinner-border-sm text-primary"></div>
                                            </span>
                                        </div>
                                    </div>

                                    <div class="text-center mb-3">
                                        <hr class="my-0">
                                        <span class="badge bg-white text-muted small"
                                            style="position: relative; top: -10px;">o pegar enlaces</span>
                                    </div>

                                    <div class="p-2 pt-0">
                                        <label class="form-label x-small text-muted mb-1">Lista de URLs (separadas por
                                            comas):</label>
                                        <textarea v-model="form.photos" class="form-control form-control-sm" rows="6"
                                            placeholder="https://ejemplo.com/foto1.jpg, ..."></textarea>
                                        <div class="form-text x-small mt-2">
                                            <i class="bi bi-info-circle me-1"></i> La primera URL será la foto
                                            principal.
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer bg-light">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="submit" class="btn btn-primary px-4" :disabled="isSubmitting">
                                <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-2"></span>
                                {{ isEditing ? 'Actualizar' : 'Guardar' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>