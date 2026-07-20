import { createClient } from "@supabase/supabase-js";

// La clave anon es pública por diseño (RLS protege los datos); se deja
// aquí como valor por defecto para que el build de Netlify no dependa
// de variables de entorno. Se puede sobreescribir con NEXT_PUBLIC_*.
const SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL || "https://vaefzheeuvpzmospjiee.supabase.co";
const SUPABASE_ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhZWZ6aGVldXZwem1vc3BqaWVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1MTAzODIsImV4cCI6MjEwMDA4NjM4Mn0.zlxyTb8OSngIKFotCZtt-HCEb-t7H4iX9Kjo-a1fv14";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false },
});

export const FUNCTIONS_URL = `${SUPABASE_URL}/functions/v1`;

/** Llama una RPC y devuelve el dato o lanza el mensaje de error de Postgres. */
export async function rpc<T>(fn: string, args?: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.rpc(fn, args);
  if (error) throw new Error(error.message || "Error de conexión");
  return data as T;
}
