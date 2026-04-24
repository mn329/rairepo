// Deno/Edge 用（https URL インポート、Deno グローバル）。本番の Supabase Edge では正しく解決される。
// エディタが Node 向け tsserver の場合、ここに赤線が出ることがある。実行・デプロイ内容には影響しない。
// 代替: Deno 拡張 + https://deno.land/manual/getting_started/setup_your_environment
// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !RESEND_API_KEY) {
      throw new Error("サーバー設定（環境変数）が不足しています")
    }
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
    // Flutter アプリ（auth_service）と同じ。未指定のときのメールリンク先が https の Site URL になりアプリに戻らないのを防ぐ
    const DEFAULT_APP_REDIRECT = "io.supabase.recolle://login-callback"
    const { email, type, redirectTo: redirectToRaw } = await req.json()
    const redirectTo = redirectToRaw || DEFAULT_APP_REDIRECT

    if (!email || !type) {
      throw new Error('メールアドレスと送信タイプは必須です')
    }

    let subject = ''
    let html = ''
    let otpType: any = ''

    if (type === 'signup') {
      subject = '【recolle】アカウント登録の確認'
      otpType = 'magiclink'
    } else if (type === 'reset_password') {
      subject = '【recolle】パスワードリセットのご案内'
      otpType = 'recovery'
    } else {
      throw new Error('無効な送信タイプです')
    }

    const options: any = { redirectTo }

    // 認証用リンクを生成
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: otpType,
      email: email,
      options: options,
    })

    if (linkError) throw linkError

    const confirmationUrl = linkData.properties.action_link

    if (type === 'signup') {
      html = `
        <h1>recolleへようこそ！</h1>
        <p>アカウント登録を完了するには、以下のリンクをクリックしてください。</p>
        <p><a href="${confirmationUrl}">メールアドレスを認証する</a></p>
        <p>※このメールに心当たりがない場合は、破棄してください。</p>
      `
    } else if (type === 'reset_password') {
      html = `
        <h1>パスワードリセット</h1>
        <p>パスワードをリセットするには、以下のリンクをクリックしてください。</p>
        <p><a href="${confirmationUrl}">パスワードを再設定する</a></p>
        <p>※このメールに心当たりがない場合は、破棄してください。</p>
      `
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'recolle <onboarding@resend.dev>',
        to: [email],
        subject: subject,
        html: html,
      }),
    })

    const resData = await res.json()

    return new Response(JSON.stringify(resData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: res.ok ? 200 : 400,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})
