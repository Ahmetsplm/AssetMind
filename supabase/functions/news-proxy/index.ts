import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { category } = await req.json()
    let results = []

    if (category === 'global') {
      const apiKey = Deno.env.get('TIINGO_API_KEY')
      if (!apiKey) throw new Error('Missing TIINGO_API_KEY')
      
      const response = await fetch(`https://api.tiingo.com/tiingo/news?token=${apiKey}&limit=50`)
      const data = await response.json()
      
      if (Array.isArray(data)) {
        results = data.map((item: any) => ({
          title: item.title,
          url: item.url,
          source: item.source || 'Tiingo News',
          publishedAt: item.publishedDate,
          category: 'global'
        }))
      }
    }
    else {
      throw new Error(`Unsupported category: ${category}`)
    }

    return new Response(
      JSON.stringify(results),
      { 
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    )
  }
})
