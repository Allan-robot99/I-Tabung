import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type StartRequest = {
  redirectUri: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status,
  });
}

function fail(code: string, message: string, status = 400) {
  return jsonResponse({ error: { code, message } }, status);
}

function adminHeaders() {
  const key =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('APP_SUPABASE_SERVICE_ROLE_KEY');
  if (!key) return null;
  return {
    apikey: key,
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
    Prefer: 'return=representation',
  };
}

function restUrl(path: string) {
  const base = Deno.env.get('SUPABASE_URL') ?? Deno.env.get('APP_SUPABASE_URL');
  if (!base) return null;
  return `${base}/rest/v1/${path}`;
}

function rpcUrl(name: string) {
  const base = Deno.env.get('SUPABASE_URL') ?? Deno.env.get('APP_SUPABASE_URL');
  if (!base) return null;
  return `${base}/rest/v1/rpc/${name}`;
}

async function fetchCurrentUser(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? Deno.env.get('APP_SUPABASE_URL');
  const apikey = req.headers.get('apikey');
  const auth = req.headers.get('authorization');
  if (!supabaseUrl || !apikey || !auth) return null;

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey,
      Authorization: auth,
    },
  });
  if (!response.ok) return null;
  return response.json();
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return fail('invalid_input', 'Only POST is allowed.');
  }

  try {
    const currentUser = await fetchCurrentUser(req);
    if (!currentUser?.id) {
      return fail('unauthorized', 'User must be logged in.', 401);
    }

    const payload = (await req.json()) as StartRequest;
    if (!payload.redirectUri || !payload.redirectUri.startsWith('itabung://')) {
      return fail('invalid_input', 'A valid app redirect URI is required.');
    }

    const clientId = Deno.env.get('GOOGLE_CLIENT_ID');
    const callbackUri = Deno.env.get('GOOGLE_OAUTH_REDIRECT_URI');
    if (!clientId || !callbackUri) {
      return fail('service_unavailable', 'Google Calendar OAuth is not configured.', 500);
    }

    const state = crypto.randomUUID();
    const headers = adminHeaders();
    const url = rpcUrl('create_google_oauth_state');
    if (!headers || !url) {
      return fail('service_unavailable', 'Missing Supabase admin environment.', 500);
    }

    const stateInsertResponse = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        p_state: state,
        p_user_id: currentUser.id,
        p_provider: 'google',
        p_redirect_uri: payload.redirectUri,
        p_expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      }),
    });
    if (!stateInsertResponse.ok) {
      const details = await stateInsertResponse.text();
      return fail(
        'service_unavailable',
        `Unable to create OAuth state. ${details || 'Unknown storage error.'}`,
        500,
      );
    }

    const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
    authUrl.searchParams.set('client_id', clientId);
    authUrl.searchParams.set('redirect_uri', callbackUri);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('scope', 'https://www.googleapis.com/auth/calendar.events');
    authUrl.searchParams.set('access_type', 'offline');
    authUrl.searchParams.set('prompt', 'consent');
    authUrl.searchParams.set('state', state);

    return jsonResponse({ authUrl: authUrl.toString(), state });
  } catch (error) {
    return fail('service_unavailable', (error as Error).message, 500);
  }
});
