import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const PROMPT_VERSION = 'recurring_goal_reminder_v1_2026_05_23';
const APP_TIMEZONE = 'Asia/Kuala_Lumpur';
const APP_OFFSET = '+08:00';

type ReminderMode = 'preview' | 'create';
type RecurringPeriod = 'daily' | 'weekly' | 'monthly';

type ReminderSettings = {
  reminderTime: string;
  reminderDayOfWeek?: string;
  reminderDayOfMonth?: number;
  calendarProvider: 'google';
  googleCalendarId: string;
};

type ReminderRequest = {
  mode?: ReminderMode;
  userId: string;
  familyId: string;
  tabungId: string;
  timezone: string;
  reminderSettings: ReminderSettings;
};

type SelectedTabung = {
  tabungName: string;
  goalAmount: number;
  currentAmount: number;
  recurringAmount: number;
  recurringPeriod: RecurringPeriod;
  recurringStartDate: string;
  deadline: string;
};

type ReminderResponse = {
  reminderPlan: {
    title: string;
    description: string;
    recurringAmount: number;
    recurringPeriod: RecurringPeriod;
    startDate: string;
    endDate: string;
    suggestedReminderDay: string;
    suggestedReminderTime: string;
    timezone: string;
  };
  googleCalendarEvent: {
    summary: string;
    description: string;
    startDateTime: string;
    endDateTime: string;
    recurrenceRule: string;
    googleEventId?: string;
    syncStatus?: string;
  };
  userMessage: string;
  promptVersion?: string;
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

function isUuid(value: unknown) {
  return typeof value === 'string'
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function isNonEmptyString(value: unknown) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPositiveNumber(value: unknown) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0;
}

function roundToCents(value: number) {
  return Math.round(value * 100) / 100;
}

function prettyDate(raw: string) {
  const date = new Date(`${raw}T00:00:00${APP_OFFSET}`);
  if (Number.isNaN(date.getTime())) return raw;
  return date.toLocaleDateString('en-MY', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: APP_TIMEZONE,
  });
}

function weekdayCode(day: string) {
  const normalized = day.trim().toLowerCase();
  return ({
    monday: 'MO',
    tuesday: 'TU',
    wednesday: 'WE',
    thursday: 'TH',
    friday: 'FR',
    saturday: 'SA',
    sunday: 'SU',
  } as Record<string, string>)[normalized] ?? 'MO';
}

function createUntil(deadline: string) {
  const date = new Date(`${deadline}T23:59:59${APP_OFFSET}`);
  return date.toISOString().replace(/[-:]/g, '').replace('.000', '');
}

function buildRecurrenceRule(tabung: SelectedTabung, settings: ReminderSettings) {
  const until = createUntil(tabung.deadline);
  if (tabung.recurringPeriod === 'daily') {
    return `RRULE:FREQ=DAILY;UNTIL=${until}`;
  }
  if (tabung.recurringPeriod === 'weekly') {
    return `RRULE:FREQ=WEEKLY;BYDAY=${weekdayCode(settings.reminderDayOfWeek ?? 'Monday')};UNTIL=${until}`;
  }
  return `RRULE:FREQ=MONTHLY;BYMONTHDAY=${settings.reminderDayOfMonth ?? 1};UNTIL=${until}`;
}

function buildStartDateTime(tabung: SelectedTabung, settings: ReminderSettings) {
  const start = new Date(`${tabung.recurringStartDate}T00:00:00${APP_OFFSET}`);
  const [hour, minute] = settings.reminderTime.split(':').map((part) => Number(part));
  start.setHours(Number.isFinite(hour) ? hour : 20, Number.isFinite(minute) ? minute : 0, 0, 0);

  if (tabung.recurringPeriod === 'weekly') {
    const targetDay = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'].indexOf(weekdayCode(settings.reminderDayOfWeek ?? 'Monday'));
    while (start.getDay() !== targetDay) {
      start.setDate(start.getDate() + 1);
    }
  }

  if (tabung.recurringPeriod === 'monthly' && settings.reminderDayOfMonth != null) {
    const year = start.getFullYear();
    const month = start.getMonth();
    const target = Math.min(settings.reminderDayOfMonth, 28);
    const adjusted = new Date(year, month, target, start.getHours(), start.getMinutes(), 0, 0);
    if (adjusted < start) {
      adjusted.setMonth(adjusted.getMonth() + 1);
    }
    return adjusted;
  }

  return start;
}

function buildFallbackResponse(tabung: SelectedTabung, settings: ReminderSettings, timezone: string): ReminderResponse {
  const summary = `I-Tabung: Save RM${tabung.recurringAmount.toFixed(0)} for ${tabung.tabungName}`;
  const description =
    `Reminder to save RM${tabung.recurringAmount.toFixed(0)} into your ${tabung.tabungName}. ` +
    `Your goal is RM${tabung.goalAmount.toFixed(0)} and you have saved RM${tabung.currentAmount.toFixed(0)}.`;
  const start = buildStartDateTime(tabung, settings);
  const end = new Date(start.getTime() + 15 * 60 * 1000);
  const suggestedReminderDay = tabung.recurringPeriod === 'weekly'
    ? (settings.reminderDayOfWeek ?? 'Monday')
    : tabung.recurringPeriod === 'monthly'
      ? `Day ${settings.reminderDayOfMonth ?? 1}`
      : 'Every day';

  return {
    reminderPlan: {
      title: summary,
      description,
      recurringAmount: tabung.recurringAmount,
      recurringPeriod: tabung.recurringPeriod,
      startDate: tabung.recurringStartDate,
      endDate: tabung.deadline,
      suggestedReminderDay,
      suggestedReminderTime: settings.reminderTime,
      timezone,
    },
    googleCalendarEvent: {
      summary,
      description,
      startDateTime: start.toISOString().replace('Z', APP_OFFSET),
      endDateTime: end.toISOString().replace('Z', APP_OFFSET),
      recurrenceRule: buildRecurrenceRule(tabung, settings),
    },
    userMessage: `Your ${tabung.recurringPeriod} saving reminder has been prepared for Google Calendar.`,
    promptVersion: PROMPT_VERSION,
  };
}

function normalizeRecurringPeriod(value: unknown, fallback: RecurringPeriod): RecurringPeriod {
  if (value === 'daily' || value === 'weekly' || value === 'monthly') {
    return value;
  }
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'daily' || normalized === 'weekly' || normalized === 'monthly') {
      return normalized;
    }
  }
  return fallback;
}

function normalizeResponse(raw: unknown, fallback: ReminderResponse): ReminderResponse {
  if (!raw || typeof raw !== 'object') return fallback;
  const source = raw as Record<string, unknown>;
  const reminderPlan = (source.reminderPlan ?? {}) as Record<string, unknown>;
  const calendarEvent = (source.googleCalendarEvent ?? {}) as Record<string, unknown>;
  return {
    reminderPlan: {
      title: reminderPlan.title?.toString() ?? fallback.reminderPlan.title,
      description: reminderPlan.description?.toString() ?? fallback.reminderPlan.description,
      recurringAmount: isPositiveNumber(reminderPlan.recurringAmount)
          ? roundToCents(reminderPlan.recurringAmount as number)
          : fallback.reminderPlan.recurringAmount,
      recurringPeriod: normalizeRecurringPeriod(
        reminderPlan.recurringPeriod,
        fallback.reminderPlan.recurringPeriod,
      ),
      startDate: reminderPlan.startDate?.toString() ?? fallback.reminderPlan.startDate,
      endDate: reminderPlan.endDate?.toString() ?? fallback.reminderPlan.endDate,
      suggestedReminderDay: reminderPlan.suggestedReminderDay?.toString() ?? fallback.reminderPlan.suggestedReminderDay,
      suggestedReminderTime: reminderPlan.suggestedReminderTime?.toString() ?? fallback.reminderPlan.suggestedReminderTime,
      timezone: reminderPlan.timezone?.toString() ?? fallback.reminderPlan.timezone,
    },
    googleCalendarEvent: {
      summary: calendarEvent.summary?.toString() ?? fallback.googleCalendarEvent.summary,
      description: calendarEvent.description?.toString() ?? fallback.googleCalendarEvent.description,
      startDateTime: calendarEvent.startDateTime?.toString() ?? fallback.googleCalendarEvent.startDateTime,
      endDateTime: calendarEvent.endDateTime?.toString() ?? fallback.googleCalendarEvent.endDateTime,
      recurrenceRule: calendarEvent.recurrenceRule?.toString() ?? fallback.googleCalendarEvent.recurrenceRule,
    },
    userMessage: source.userMessage?.toString() ?? fallback.userMessage,
    promptVersion: PROMPT_VERSION,
  };
}

async function fetchRows(path: string) {
  const headers = adminHeaders();
  const url = restUrl(path);
  if (!headers || !url) {
    throw new Error('Missing Supabase admin environment for recurring reminder agent.');
  }
  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Supabase fetch failed (${response.status})`);
  }
  return response.json();
}

async function mutateRow(path: string, method: 'POST' | 'PATCH', body: unknown) {
  const headers = adminHeaders();
  const url = restUrl(path);
  if (!headers || !url) {
    throw new Error('Missing Supabase admin environment for recurring reminder agent.');
  }
  const response = await fetch(url, {
    method,
    headers,
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Supabase mutation failed (${response.status})`);
  }
  return response;
}

async function loadTabung(tabungId: string): Promise<SelectedTabung> {
  const rows = await fetchRows(
    `tabung_goals?id=eq.${encodeURIComponent(tabungId)}&select=tabung_name,goal_amount,current_amount,recurring_amount,recurring_period,recurring_start_date,created_at,deadline&limit=1`,
  );
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error('Selected tabung could not be found.');
  }
  const row = rows[0] as Record<string, unknown>;
  if (!isPositiveNumber(row.recurring_amount)) {
    throw new Error('Please setup recurring target first.');
  }
  if (!isNonEmptyString(row.recurring_period)) {
    throw new Error('Please setup recurring period first.');
  }
  const recurringStartDate = row.recurring_start_date?.toString()
    ?? row.created_at?.toString().slice(0, 10)
    ?? '';
  if (!isNonEmptyString(recurringStartDate)) {
    throw new Error('Please choose recurring start date first.');
  }
  if (!isNonEmptyString(row.deadline)) {
    throw new Error('Please setup Tabung end period first.');
  }

  return {
    tabungName: row.tabung_name?.toString() ?? 'Tabung',
    goalAmount: roundToCents((row.goal_amount as number) ?? 0),
    currentAmount: roundToCents((row.current_amount as number) ?? 0),
    recurringAmount: roundToCents((row.recurring_amount as number) ?? 0),
    recurringPeriod: row.recurring_period as RecurringPeriod,
    recurringStartDate,
    deadline: row.deadline?.toString() ?? '',
  };
}

async function loadCalendarConnection(userId: string) {
  const rows = await fetchRows(
    `calendar_connections?user_id=eq.${encodeURIComponent(userId)}&provider=eq.google&select=id,is_connected,google_calendar_id&limit=1`,
  );
  return Array.isArray(rows) && rows.length > 0 ? rows[0] as Record<string, unknown> : null;
}

async function loadGoogleTokens(userId: string) {
  const headers = adminHeaders();
  const url = rpcUrl('get_google_calendar_token');
  if (!headers || !url) {
    throw new Error('Missing Supabase admin environment for recurring reminder agent.');
  }
  const response = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({ p_user_id: userId }),
  });
  if (!response.ok) {
    throw new Error(`Supabase fetch failed (${response.status})`);
  }
  const rows = await response.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] as Record<string, unknown> : null;
}

async function refreshGoogleAccessToken(tokens: Record<string, unknown>) {
  const refreshToken = tokens.refresh_token?.toString();
  const clientId = Deno.env.get('GOOGLE_CLIENT_ID');
  const clientSecret = Deno.env.get('GOOGLE_CLIENT_SECRET');
  if (!refreshToken || !clientId || !clientSecret) {
    return tokens.access_token?.toString() ?? '';
  }

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });
  if (!response.ok) {
    return tokens.access_token?.toString() ?? '';
  }

  const payload = await response.json();
  const accessToken = payload.access_token?.toString() ?? tokens.access_token?.toString() ?? '';
  const expiresIn = Number(payload.expires_in ?? 3600);
  const headers = adminHeaders();
  const url = rpcUrl('upsert_google_calendar_token');
  if (headers && url) {
    await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        p_user_id: tokens.user_id?.toString() ?? '',
        p_access_token: accessToken,
        p_refresh_token: tokens.refresh_token?.toString() ?? null,
        p_token_expiry: new Date(Date.now() + expiresIn * 1000).toISOString(),
        p_scope: payload.scope?.toString() ?? tokens.scope?.toString() ?? '',
      }),
    });
  }
  return accessToken;
}

async function createGoogleCalendarEvent(accessToken: string, calendarId: string, responsePayload: ReminderResponse) {
  const eventPayload = {
    summary: responsePayload.googleCalendarEvent.summary,
    description: responsePayload.googleCalendarEvent.description,
    start: {
      dateTime: responsePayload.googleCalendarEvent.startDateTime,
      timeZone: responsePayload.reminderPlan.timezone,
    },
    end: {
      dateTime: responsePayload.googleCalendarEvent.endDateTime,
      timeZone: responsePayload.reminderPlan.timezone,
    },
    recurrence: [responsePayload.googleCalendarEvent.recurrenceRule],
  };

  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(eventPayload),
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Google Calendar event creation failed: ${text}`);
  }
  return response.json();
}

async function insertAiLog(payload: ReminderRequest, responsePayload: ReminderResponse, prompt: string, rawResponse: string) {
  const headers = adminHeaders();
  const url = restUrl('ai_logs');
  if (!headers || !url) return;
  await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      user_id: payload.userId,
      family_id: payload.familyId,
      tabung_id: payload.tabungId,
      agent_type: 'recurring_goal_reminder',
      prompt,
      response: rawResponse,
      structured_response: responsePayload,
    }),
  });
}

function buildPrompt(tabung: SelectedTabung, payload: ReminderRequest) {
  return `You are the "Recurring Goal Reminder Agent" for I-Tabung, a Malaysian parent-child savings app.

The user has enabled a goal reminder for a specific Tabung.

INPUT:
${JSON.stringify({
    userId: payload.userId,
    familyId: payload.familyId,
    tabungId: payload.tabungId,
    timezone: payload.timezone,
    reminderSettings: payload.reminderSettings,
    selectedTabung: tabung,
  })}

TASK:
Generate:
1. A friendly reminder title.
2. A clear reminder description.
3. The recurring amount and period.
4. The reminder start date and end date.
5. A Google Calendar event summary.
6. A Google Calendar event description.
7. A Google Calendar RRULE based on recurringPeriod.
8. A short user message.

RULES:
- Return strict JSON only.
- Do not include markdown.
- Use Malaysian Ringgit.
- Use friendly, encouraging language.
- Use the user timezone.
- Do not change the recurring amount.
- Do not change the Tabung deadline.
- If recurringPeriod is daily, create a daily RRULE.
- If recurringPeriod is weekly, create a weekly RRULE with the selected reminder day.
- If recurringPeriod is monthly, create a monthly RRULE with the selected day of month.
- Calendar event duration should be 15 minutes.
- The event should repeat until the Tabung deadline.`;
}

async function generateWithGemini(tabung: SelectedTabung, payload: ReminderRequest) {
  const prompt = buildPrompt(tabung, payload);
  const fallback = buildFallbackResponse(tabung, payload.reminderSettings, payload.timezone || APP_TIMEZONE);
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';

  if (!apiKey) {
    return { responsePayload: fallback, prompt, rawResponse: JSON.stringify(fallback) };
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
      }),
    },
  );
  if (!response.ok) {
    return { responsePayload: fallback, prompt, rawResponse: JSON.stringify(fallback) };
  }

  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!isNonEmptyString(text)) {
    return { responsePayload: fallback, prompt, rawResponse: JSON.stringify(fallback) };
  }

  try {
    const normalized = normalizeResponse(JSON.parse(text), fallback);
    return { responsePayload: normalized, prompt, rawResponse: text };
  } catch (_) {
    return { responsePayload: fallback, prompt, rawResponse: JSON.stringify(fallback) };
  }
}

function isRequestValid(payload: ReminderRequest) {
  const mode = payload.mode ?? 'preview';
  const settings = payload.reminderSettings;
  if (!isUuid(payload.userId) || !isUuid(payload.familyId) || !isUuid(payload.tabungId)) return false;
  if (!(mode === 'preview' || mode === 'create')) return false;
  if (!isNonEmptyString(payload.timezone)) return false;
  if (!settings || !isNonEmptyString(settings.reminderTime) || !isNonEmptyString(settings.googleCalendarId)) return false;
  return settings.calendarProvider === 'google';
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return fail('invalid_input', 'Only POST is allowed.');
  }

  try {
    const payload = (await req.json()) as ReminderRequest;
    if (!isRequestValid(payload)) {
      return fail('invalid_input', 'Missing or invalid reminder request fields.');
    }

    const selectedTabung = await loadTabung(payload.tabungId);
    if (selectedTabung.recurringPeriod === 'weekly' && !isNonEmptyString(payload.reminderSettings.reminderDayOfWeek)) {
      return fail('invalid_input', 'Please choose reminder day.');
    }
    if (selectedTabung.recurringPeriod === 'monthly' && !Number.isFinite(payload.reminderSettings.reminderDayOfMonth)) {
      return fail('invalid_input', 'Please choose reminder date.');
    }

    const calendarConnection = await loadCalendarConnection(payload.userId);
    if (!calendarConnection || calendarConnection.is_connected !== true) {
      return fail('calendar_not_connected', 'Please connect Google Calendar.', 412);
    }

    const generated = await generateWithGemini(selectedTabung, payload);
    const responsePayload = generated.responsePayload;

    if ((payload.mode ?? 'preview') === 'preview') {
      await insertAiLog(payload, responsePayload, generated.prompt, generated.rawResponse);
      return jsonResponse(responsePayload);
    }

    const tokens = await loadGoogleTokens(payload.userId);
    if (!tokens) {
      return fail('calendar_not_connected', 'Please connect Google Calendar.', 412);
    }

    try {
      const accessToken = await refreshGoogleAccessToken(tokens);
      const googleEvent = await createGoogleCalendarEvent(
        accessToken,
        payload.reminderSettings.googleCalendarId,
        responsePayload,
      );

      await mutateRow('calendar_events', 'POST', {
        user_id: payload.userId,
        tabung_id: payload.tabungId,
        event_type: 'recurring_target',
        title: responsePayload.googleCalendarEvent.summary,
        description: responsePayload.googleCalendarEvent.description,
        start_time: responsePayload.googleCalendarEvent.startDateTime,
        end_time: responsePayload.googleCalendarEvent.endDateTime,
        recurrence_rule: responsePayload.googleCalendarEvent.recurrenceRule,
        timezone: payload.timezone,
        google_event_id: googleEvent.id?.toString() ?? null,
        sync_status: 'synced',
      });

      await mutateRow(
        `tabung_goals?id=eq.${encodeURIComponent(payload.tabungId)}`,
        'PATCH',
        {
          reminder_enabled: true,
          reminder_time: payload.reminderSettings.reminderTime,
          reminder_day_of_week: payload.reminderSettings.reminderDayOfWeek ?? null,
          reminder_day_of_month: payload.reminderSettings.reminderDayOfMonth ?? null,
        },
      );

      const syncedPayload: ReminderResponse = {
        ...responsePayload,
        googleCalendarEvent: {
          ...responsePayload.googleCalendarEvent,
          googleEventId: googleEvent.id?.toString() ?? '',
          syncStatus: 'synced',
        },
      };

      await insertAiLog(payload, syncedPayload, generated.prompt, generated.rawResponse);
      return jsonResponse(syncedPayload);
    } catch (error) {
      await mutateRow('calendar_events', 'POST', {
        user_id: payload.userId,
        tabung_id: payload.tabungId,
        event_type: 'recurring_target',
        title: responsePayload.googleCalendarEvent.summary,
        description: responsePayload.googleCalendarEvent.description,
        start_time: responsePayload.googleCalendarEvent.startDateTime,
        end_time: responsePayload.googleCalendarEvent.endDateTime,
        recurrence_rule: responsePayload.googleCalendarEvent.recurrenceRule,
        timezone: payload.timezone,
        sync_status: 'failed',
        sync_error: (error as Error).message,
      });
      return fail('calendar_sync_failed', (error as Error).message, 502);
    }
  } catch (error) {
    return fail('service_unavailable', (error as Error).message, 500);
  }
});
