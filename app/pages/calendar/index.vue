<script setup>
import Swal from 'sweetalert2'

const supabase = useSupabaseClient()
const products = ref([])
const orders = ref([])
const loading = ref(true)
const isSubmitting = ref(false)

const todayLocal = new Date().toLocaleDateString('sv-SE')

const form = ref({
    product_id: '',
    order_date: todayLocal,
    units: 1,
    total_cost: 0
})

const fetchData = async () => {
    loading.value = true
    const { data: ord } = await supabase
        .from('orders')
        .select('*, products(name, code)')
        .order('order_date', { ascending: false })
    orders.value = ord || []

    const { data: prod } = await supabase.from('products').select('*, rates(*)')
    products.value = prod || []
    loading.value = false
}

const calculatePrice = () => {
    const selectedProd = products.value.find(p => p.id === form.value.product_id)
    if (!selectedProd || !form.value.order_date) {
        form.value.total_cost = 0
        return
    }

    const rate = selectedProd.rates.find(r =>
        form.value.order_date >= r.start_date &&
        form.value.order_date <= r.end_date
    )

    form.value.total_cost = rate ? (rate.price * form.value.units) : 0
}

const saveOrder = async () => {
    if (form.value.total_cost <= 0) {
        return Swal.fire('Error', 'No hay tarifa para esta fecha', 'error')
    }
    isSubmitting.value = true
    const { error } = await supabase.from('orders').insert([form.value])
    if (!error) {
        Swal.fire({ title: 'Pedido Guardado', icon: 'success', timer: 1500, showConfirmButton: false })
        form.value = { product_id: '', order_date: todayLocal, units: 1, total_cost: 0 }
        fetchData()
    }
    isSubmitting.value = false
}


const deleteOrder = async (id) => {
    const result = await Swal.fire({
        title: '¿Cancelar pedido?',
        text: "Esta acción no se puede deshacer.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc3545',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Sí, cancelar pedido',
        cancelButtonText: 'Cerrar'
    })

    if (result.isConfirmed) {
        const { error } = await supabase.from('orders').delete().eq('id', id)
        if (error) {
            Swal.fire('Error', 'No se pudo cancelar el pedido', 'error')
        } else {
            fetchData()
            Swal.fire({ title: 'Cancelado', icon: 'success', timer: 1000, showConfirmButton: false })
        }
    }
}

onMounted(() => fetchData())

watch(() => [form.value.product_id, form.value.order_date, form.value.units], calculatePrice)
</script>

<template>
    <div class="container mt-4">
        <h2 class="mb-4"><i class="bi bi-calendar-event me-2"></i>Agenda de Pedidos</h2>

        <div class="row g-4">
            <div class="col-md-4">
                <div class="card shadow-sm border-0 sticky-top" style="top: 20px;">
                    <div class="card-header bg-dark text-white fw-bold py-3">Programar Nuevo Pedido</div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label small fw-bold">Producto</label>
                            <select v-model="form.product_id" class="form-select shadow-none">
                                <option value="">Seleccione...</option>
                                <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold">Fecha de Pedido</label>
                            <input v-model="form.order_date" type="date" class="form-control shadow-none">
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold">Cantidad (Unidades)</label>
                            <input v-model="form.units" type="number" min="1" class="form-control shadow-none">
                        </div>

                        <div class="alert" :class="form.total_cost > 0 ? 'alert-success' : 'alert-light border'">
                            <div class="small text-muted mb-1">Precio calculado:</div>
                            <div class="h3 fw-bold mb-0">{{ form.total_cost.toFixed(2) }}€</div>
                            <small v-if="form.product_id && form.total_cost === 0" class="text-danger">
                                <i class="bi bi-exclamation-triangle"></i> Sin tarifa para esta fecha
                            </small>
                        </div>

                        <button @click="saveOrder" class="btn btn-primary w-100 py-2 fw-bold"
                            :disabled="isSubmitting || form.total_cost === 0">
                            Confirmar Pedido
                        </button>
                    </div>
                </div>
            </div>

            <div class="col-md-8">
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary"></div>
                </div>

                <div v-else class="card shadow-sm border-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Fecha</th>
                                    <th>Detalle del Producto</th>
                                    <th class="text-center">Uds.</th>
                                    <th class="text-end">Importe</th>
                                    <th class="text-center">Acción</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="order in orders" :key="order.id">
                                    <td class="text-nowrap">{{ new Date(order.order_date).toLocaleDateString('es-ES') }}
                                    </td>
                                    <td>
                                        <div class="fw-bold">{{ order.products?.name }}</div>
                                        <code class="x-small text-muted">{{ order.products?.code }}</code>
                                    </td>
                                    <td class="text-center">{{ order.units }}</td>
                                    <td class="text-end fw-bold text-primary">{{ order.total_cost }}€</td>
                                    <td class="text-center">
                                        <button @click="deleteOrder(order.id)"
                                            class="btn btn-sm btn-outline-danger border-0" title="Cancelar Pedido">
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr v-if="orders.length === 0">
                                    <td colspan="5" class="text-center py-5 text-muted">No hay pedidos registrados</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="mt-3">
                <NuxtLink to="/" class="btn btn-link btn-sm text-muted text-decoration-none">
                    <i class="bi bi-house-door me-1"></i> Volver al Dashboard
                </NuxtLink>
            </div>
        </div>
    </div>
</template>