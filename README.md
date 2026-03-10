# Backoffice de Gestión de Categorias, Productos y Tarifas

Este proyecto es una solución completa para la gestión de productos, categorías y tarifas, desarrollada con **Nuxt 4**, **Bootstrap 5** y **Supabase**.

## 🚀 Requisitos Previos

Antes de lanzar el proyecto, es necesario configurar la base de datos:

1. **Base de Datos**: 
   - Cree un proyecto en [Supabase](https://supabase.com/).
   - Ejecute el contenido del archivo `database_schema.sql` en el SQL Editor de su panel de Supabase. Este script creará las tablas, índices y las políticas de seguridad **RLS**.

2. **Variables de Entorno**:
   - Renombre el archivo `.env_example` a `.env`.
   - Rellene las variables `SUPABASE_URL` y `SUPABASE_KEY` con las credenciales de su proyecto.

## 🛠️ Instalación y Uso

```bash
# Instalar dependencias
npm install

# Modo desarrollo (http://localhost:3000)
npm run dev