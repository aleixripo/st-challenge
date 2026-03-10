import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
  const client = await serverSupabaseClient(event);

  // Obtenemos el nombre de la tabla de la URL (ej: 'products', 'categories')
  const table = getRouterParam(event, "table");

  // Definimos qué tablas están permitidas para evitar accesos no deseados
  const allowedTables = ["products", "categories", "rates", "orders"];

  if (!table || !allowedTables.includes(table)) {
    throw createError({
      statusCode: 400,
      statusMessage: `La tabla '${table}' no es válida o no está disponible en la API.`,
    });
  }

  // Consulta dinámica
  const { data, error } = await client
    .from(table)
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    throw createError({
      statusCode: 500,
      statusMessage: error.message,
    });
  }

  return {
    table,
    count: data?.length || 0,
    data,
  };
});
