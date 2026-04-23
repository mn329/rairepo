// Deno/Edge 用（https URL インポート、Deno グローバル）。本番の Supabase Edge では正しく解決される。
// エディタが Node 向け tsserver の場合、ここに赤線が出ることがある。実行・デプロイ内容には影響しない。
// 代替: Deno 拡張 + https://deno.land/manual/getting_started/setup_your_environment
// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!supabaseUrl || !anonKey || !serviceKey) {
      throw new Error("Server configuration error")
    }

    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "未認証です" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: userError?.message ?? "未認証です" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      )
    }

    if (user.is_anonymous) {
      return new Response(
        JSON.stringify({
          error: "アカウント登録前の匿名IDは、ここから削除の対象にできません。",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const admin = createClient(supabaseUrl, serviceKey)
    const bucket = "ticket-images"
    const { data: files, error: listError } = await admin.storage
      .from(bucket)
      .list(user.id, { limit: 1000, offset: 0 })

    if (listError) {
      throw new Error(`Storage list: ${listError.message}`)
    }

    if (files && files.length > 0) {
      const paths = files
        .map((f) => (f.name ? `${user.id}/${f.name}` : null))
        .filter((p): p is string => p != null)
      if (paths.length > 0) {
        const { error: rmError } = await admin.storage.from(bucket).remove(
          paths,
        )
        if (rmError) {
          throw new Error(`Storage remove: ${rmError.message}`)
        }
      }
    }

    const { error: recErr } = await admin.from("records").delete().eq(
      "user_id",
      user.id,
    )
    if (recErr) {
      throw new Error(`records: ${recErr.message}`)
    }

    const { error: delUserErr } = await admin.auth.admin.deleteUser(
      user.id,
    )
    if (delUserErr) {
      throw new Error(`auth delete: ${delUserErr.message}`)
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
