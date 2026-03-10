<script setup>

// Importar librerías y variables globales
import Swal from 'sweetalert2'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'

// Obtener la instancia de Supabase para realizar consultas a la base de datos.
const supabase = useSupabaseClient()

// Variables para almacenar los datos del producto, tarifas y estado de carga 
const route = useRoute()
const product = ref(null)
const rates = ref([])
const loading = ref(true)

// Formulario para crear una nueva tarifa
const newTariff = ref({
    price: 0,
    start_date: '',
    end_date: ''
})

/**
 * Obtiene el producto y sus categorías, y también sus tarifas.
 * Establece `loading` en `true` mientras se obtienen los datos.
 * Establece `product` y `rates` en los datos obtenidos.
 * Establece `loading` en `false` cuando se han obtenido los datos.
 * @return {Promise<void>} Una promesa que se resuelve cuando se han obtenido los datos.
 */
const fetchProductData = async () => {
    loading.value = true
    const { data: prod } = await supabase
        .from('products')
        .select('*, product_categories(categories(name))')
        .eq('id', route.params.id)
        .single()

    product.value = prod

    const { data: tf } = await supabase
        .from('rates')
        .select('*')
        .eq('product_id', route.params.id)
        .order('start_date', { ascending: true })

    rates.value = tf || []
    loading.value = false
}

/**
 * Añade una nueva tarifa para el producto actual.
 * Envía una solicitud a Supabase para insertar la tarifa en la tabla de tarifas.
 * Si se produce un error, se muestra un mensaje de error con `Swal`.
 * Si se completa con éxito, se muestra un mensaje de confirmación con `Swal`, se
 * resetea el formulario de la tarifa y se vuelve a obtener los datos del producto.
 * @return {Promise<void>} Una promesa que se resuelve cuando se ha completado
 * el proceso de agregar la tarifa.
 */
const addTariff = async () => {
    const { error } = await supabase.from('rates').insert([{
        product_id: route.params.id,
        ...newTariff.value
    }])

    if (error) {
        Swal.fire('Error', 'Rango de fechas inválido o error de conexión', 'error')
    } else {
        Swal.fire({ title: 'Tarifa añadida', icon: 'success', timer: 1500, showConfirmButton: false })
        newTariff.value = { price: 0, start_date: '', end_date: '' }
        fetchProductData()
    }
}

/**
 * Elimina una tarifa del producto actual.
 * Envía una solicitud a Supabase para eliminar la tarifa de la tabla de tarifas.
 * Luego se vuelve a obtener los datos del producto con `fetchProductData`.
 * @param {number} id - Identificador de la tarifa a eliminar.
 * @return {Promise<void>} Una promesa que se resuelve cuando se ha completado
 * el proceso de eliminar la tarifa.
 */
const deleteTariff = async (id) => {
    await supabase.from('rates').delete().eq('id', id)
    fetchProductData()
}


/**
 * Descarga un PDF con la ficha del producto actual.
 * La ficha contiene el nombre del producto, código, descripción y categorías.
 * También incluye una tabla con las tarifas del producto.
 * @return {void}
 */
const downloadPDF = () => {
    const doc = new jsPDF()

    doc.setFontSize(20)
    doc.text(`Ficha de Producto: ${product.value.name}`, 14, 22)

    doc.setFontSize(12)
    doc.text(`Código: ${product.value.code}`, 14, 35)
    doc.text(`Descripción: ${product.value.description || 'Sin descripción'}`, 14, 42)

    const categories = product.value.product_categories.map(pc => pc.categories.name).join(', ')
    doc.text(`Categorías: ${categories}`, 14, 49)

    // Tabla de tarifas en el PDF
    const tableRows = rates.value.map(t => [
        new Date(t.start_date).toLocaleDateString(),
        new Date(t.end_date).toLocaleDateString(),
        `${t.price.toFixed(2)}€`
    ])

    autoTable(doc, {
        startY: 60,
        head: [['Desde', 'Hasta', 'Precio']],
        body: tableRows,
    })

    doc.save(`Ficha_${product.value.code}.pdf`)
}

// Obtener los datos del producto al montar el componente
onMounted(() => {
    fetchProductData()
})
</script>

<template>
    <div class="container mt-4" v-if="product">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <NuxtLink to="/products" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-arrow-left"></i> Volver
            </NuxtLink>
            <button @click="downloadPDF" class="btn btn-danger">
                <i class="bi bi-file-pdf me-1"></i> Descargar Ficha PDF
            </button>
        </div>

        <div class="row">
            <div class="col-md-5">
                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-body">
                        <h4 class="fw-bold">{{ product.name }}</h4>
                        <p class="text-muted small">Código: {{ product.code }}</p>
                        <hr>
                        <h6>Descripción</h6>
                        <p class="small">{{ product.description }}</p>
                        <h6>Categorías</h6>
                        <div class="d-flex flex-wrap gap-1">
                            <span v-for="pc in product.product_categories" :key="pc.categories.id"
                                class="badge bg-info text-dark">
                                {{ pc.categories.name }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-7">
                <div class="card shadow-sm border-0">
                    <div class="card-header bg-white fw-bold">Historial de Tarifas</div>
                    <div class="card-body">
                        <form @submit.prevent="addTariff" class="row g-2 mb-4 p-3 bg-light rounded">
                            <div class="col-md-4">
                                <label class="form-label small fw-bold">Inicio</label>
                                <input v-model="newTariff.start_date" type="date" class="form-control form-control-sm"
                                    required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label small fw-bold">Fin</label>
                                <input v-model="newTariff.end_date" type="date" class="form-control form-control-sm"
                                    required>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-bold">Precio (€)</label>
                                <input v-model="newTariff.price" type="number" step="0.01"
                                    class="form-control form-control-sm" required>
                            </div>
                            <div class="col-md-1 d-flex align-items-end">
                                <button type="submit" class="btn btn-primary btn-sm w-100"><i
                                        class="bi bi-plus"></i></button>
                            </div>
                        </form>

                        <table class="table table-sm align-middle">
                            <thead>
                                <tr>
                                    <th>Desde</th>
                                    <th>Hasta</th>
                                    <th>Precio</th>
                                    <th class="text-end"></th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="t in rates" :key="t.id">
                                    <td class="small">{{ new Date(t.start_date).toLocaleDateString() }}</td>
                                    <td class="small">{{ new Date(t.end_date).toLocaleDateString() }}</td>
                                    <td class="fw-bold text-success">{{ t.price }}€</td>
                                    <td class="text-end">
                                        <button @click="deleteTariff(t.id)" class="btn btn-link text-danger p-0"><i
                                                class="bi bi-x-circle"></i></button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>