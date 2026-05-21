import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Uygulamadan (Flutter) gelecek olan erişim sorunlarını önlemek için CORS ayarları
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // CORS Preflight (OPTIONS) isteğine olumlu yanıt ver
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Flutter'dan gönderdiğimiz JSON body'yi al
    const { symbols } = await req.json()

    if (!symbols) {
      return new Response(JSON.stringify({ error: 'Symbols parameter is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Supabase Vault / Secrets üzerinden güvenli API anahtarını çek
    const apiKey = Deno.env.get('TIINGO_API_KEY')
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'API key not configured in Supabase' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    // Tiingo'ya isteği sunucu (Edge) üzerinden atıyoruz
    const tiingoUrl = `https://api.tiingo.com/iex/?tickers=${symbols}&token=${apiKey}`
    const tiingoResponse = await fetch(tiingoUrl)
    const data = await tiingoResponse.json()

    // Gelen ham veriyi hiçbir şeye dokunmadan Flutter'a ilet
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})