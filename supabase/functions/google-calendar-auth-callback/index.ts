import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

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

function redirect(url: string) {
  return new Response(null, {
    status: 302,
    headers: { Location: url },
  });
}

serve(async (req) => {
  const requestUrl = new URL(req.url);
  const code = requestUrl.searchParams.get('code');
  const state = requestUrl.searchParams.get('state');
  const error = requestUrl.searchParams.get('error');

  if (!state) {
    return new Response('Missing state.', { status: 400 });
  }

  const headers = adminHeaders();
  const statesUrl = rpcUrl('get_google_oauth_state');
  if (!headers || !statesUrl) {
    return new Response('Missing Supabase admin environment.', { status: 500 });
  }

  const stateResponse = await fetch(statesUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({ p_state: state }),
  });
  if (!stateResponse.ok) {
    const details = await stateResponse.text();
    return new Response(`Unable to load OAuth state. ${details}`, { status: 500 });
  }

  const rows = await stateResponse.json();
  if (!Array.isArray(rows) || rows.length == 0) {
    return new Response('OAuth state not found.', { status: 400 });
  }
  const savedState = rows[0] as Record<string, unknown>;
  const appRedirect = savedState.redirect_uri?.toString() ?? 'itabung://google-calendar-auth';
  const expiresAt = savedState.expires_at?.toString();
  if (expiresAt && Number.isFinite(Date.parse(expiresAt)) && Date.parse(expiresAt) < Date.now()) {
    await fetch(rpcUrl('delete_google_oauth_state')!, {
      method: 'POST',
      headers,
      body: JSON.stringify({ p_state: state }),
    });
    return redirect(
      `${appRedirect}?status=error&message=${encodeURIComponent(
        'Google sign-in session expired. Please try connecting again.',
      )}`,
    );
  }

  if (error) {
    await fetch(rpcUrl('delete_google_oauth_state')!, {
      method: 'POST',
      headers,
      body: JSON.stringify({ p_state: state }),
    });
    return redirect(`${appRedirect}?status=error&message=${encodeURIComponent(error)}`);
  }

  if (!code) {
    return redirect(`${appRedirect}?status=error&message=${encodeURIComponent('Missing Google auth code.')}`);
  }

  const clientId = Deno.env.get('GOOGLE_CLIENT_ID');
  const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET');
  const callbackUri = Deno.env.get('GOOGLE_OAUTH_REDIRECT_URI');
  if (!clientId || !clientSecret || !callbackUri) {
    return redirect(`${appRedirect}?status=error&message=${encodeURIComponent('Google OAuth is not configured.')}`);
  }

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: callbackUri,
      grant_type: 'authorization_code',
    }),
  });

  if (!tokenResponse.ok) {
    const text = await tokenResponse.text();
    return redirect(`${appRedirect}?status=error&message=${encodeURIComponent(text)}`);
  }

  const tokenPayload = await tokenResponse.json();
  const userId = savedState.user_id?.toString() ?? '';
  const expiresIn = Number(tokenPayload.expires_in ?? 3600);

  const tokenStoreResponse = await fetch(rpcUrl('upsert_google_calendar_token')!, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      p_user_id: userId,
      p_access_token: tokenPayload.access_token?.toString() ?? '',
      p_refresh_token: tokenPayload.refresh_token?.toString() ?? null,
      p_token_expiry: new Date(Date.now() + expiresIn * 1000).toISOString(),
      p_scope: tokenPayload.scope?.toString() ?? 'https://www.googleapis.com/auth/calendar.events',
    }),
  });
  if (!tokenStoreResponse.ok) {
    const details = await tokenStoreResponse.text();
    return redirect(
      `${appRedirect}?status=error&message=${encodeURIComponent(
        `Unable to store Google calendar tokens. ${details}`,
      )}`,
    );
  }

  const connectionResponse = await fetch(restUrl('calendar_connections')!, {
    method: 'POST',
    headers: {
      ...adminHeaders()!,
      Prefer: 'resolution=merge-duplicates,return=representation',
    },
    body: JSON.stringify({
      user_id: userId,
      provider: 'google',
      is_connected: true,
      google_calendar_id: 'primary',
      connected_at: new Date().toISOString(),
      revoked_at: null,
    }),
  });
  if (!connectionResponse.ok) {
    const details = await connectionResponse.text();
    return redirect(
      `${appRedirect}?status=error&message=${encodeURIComponent(
        `Unable to update calendar connection. ${details}`,
      )}`,
    );
  }

  await fetch(rpcUrl('delete_google_oauth_state')!, {
    method: 'POST',
    headers,
    body: JSON.stringify({ p_state: state }),
  });

  return redirect(`${appRedirect}?status=success`);
});
