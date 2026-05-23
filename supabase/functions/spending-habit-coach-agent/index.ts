import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const PROMPT_VERSION = 'spending_habit_coach_v1_2026_05_23';
const ALLOWED_DELAY_UNITS = ['days', 'weeks', 'months'] as const;
const ALLOWED_SPENDING_CATEGORIES = [
  'cafe / drink shop',
  'restaurant / food stall',
  'online game store',
  'clothing shop',
  'bookstore / stationery shop',
  'entertainment venue',
  'transport service',
  'electronics shop',
  'grocery / convenience store',
  'health / pharmacy',
  'school / education',
  'sports / hobby',
  'general purchase',
] as const;
const KEYWORD_CATEGORY_MAP: Array<{ keywords: string[]; category: string }> = [
  { keywords: ['drink', 'coffee', 'tea', 'boba', 'milo', 'air', 'tealive'], category: 'cafe / drink shop' },
  { keywords: ['nasi', 'lunch', 'dinner', 'food', 'snack', 'mamak', 'ayam'], category: 'restaurant / food stall' },
  { keywords: ['game', 'topup', 'skin', 'robux', 'ml', 'pubg'], category: 'online game store' },
  { keywords: ['shirt', 'shoes', 'clothes', 'baju', 'kasut'], category: 'clothing shop' },
  { keywords: ['book', 'pen', 'stationery', 'buku', 'alat tulis'], category: 'bookstore / stationery shop' },
  { keywords: ['movie', 'ticket', 'cinema'], category: 'entertainment venue' },
  { keywords: ['grab', 'bus', 'train', 'petrol', 'lrt', 'mrt'], category: 'transport service' },
  { keywords: ['phone', 'cable', 'charger', 'laptop'], category: 'electronics shop' },
  { keywords: ['7e', 'kk', 'mart', 'grocery'], category: 'grocery / convenience store' },
  { keywords: ['ubat', 'medicine', 'pharmacy', 'panadol'], category: 'health / pharmacy' },
  { keywords: ['sekolah', 'school', 'tuition', 'class'], category: 'school / education' },
  { keywords: ['gym', 'football', 'badminton', 'sport'], category: 'sports / hobby' },
];

type DelayUnit = (typeof ALLOWED_DELAY_UNITS)[number];
type SpendingCategory = (typeof ALLOWED_SPENDING_CATEGORIES)[number];

type RequestLocationContext = {
  latitude?: number;
  longitude?: number;
  locationAccuracy?: number;
  locationPermissionStatus: string;
};

type CoachRequest = {
  userId: string;
  familyId: string;
  tabungId: string;
  paymentAmount: number;
  buyingPurpose: string;
  locationContext?: RequestLocationContext;
};

type LoadedTabung = {
  tabungName: string;
  goalAmount: number;
  currentAmount: number;
  remainingAmount: number;
  recurringPeriod: 'daily' | 'weekly' | 'monthly' | null;
  recurringAmount: number | null;
  currentPeriodSaved: number;
  recurringStartDate: string | null;
  deadline: string | null;
};

type PromptPayload = {
  userId: string;
  familyId: string;
  tabungId: string;
  paymentAmount: number;
  buyingPurpose: string;
  selectedTabung: LoadedTabung;
  locationContext: {
    latitude?: number;
    longitude?: number;
    locationPermissionStatus: string;
    guessedPlaceName: string;
    guessedPlaceCategory: SpendingCategory;
    confidence: 'low' | 'medium' | 'high';
    categoryReason?: string;
  };
};

type CategoryGuess = {
  placeCategory: SpendingCategory;
  confidence: 'low' | 'medium' | 'high';
  reason: string;
};

type CoachResponse = {
  guessedSpendingPlace: {
    placeName: string;
    placeCategory: string;
    confidence: 'low' | 'medium' | 'high';
    reason: string;
  };
  tabungReminder: {
    message: string;
    currentProgressPercentage: number;
  };
  recurringTargetReminder: {
    message: string;
    recurringAmount: number;
    currentPeriodSaved: number;
    remainingForThisPeriod: number;
  };
  spendingImpact: {
    impactWarning: string;
    estimatedDelayValue: number;
    estimatedDelayUnit: DelayUnit;
    newEstimatedEndDate: string;
  };
  alternativeSuggestions: Array<{
    title: string;
    description: string;
    estimatedSaving: number;
  }>;
  recommendation: {
    shouldProceed: boolean;
    message: string;
  };
  summary: string;
  promptVersion?: string;
};

function fail(code: string, message: string, status = 400) {
  return new Response(JSON.stringify({ error: { code, message } }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status,
  });
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

function isUuid(value: unknown) {
  return typeof value === 'string'
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function isPositiveNumber(value: unknown) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0;
}

function isNonEmptyString(value: unknown) {
  return typeof value === 'string' && value.trim().length > 0;
}

function roundToCents(value: number) {
  return Math.round(value * 100) / 100;
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}

function normalizeDate(date: Date) {
  return date.toISOString().slice(0, 10);
}

function addDays(baseDate: string | null, days: number) {
  if (!baseDate) return '';
  const date = new Date(`${baseDate}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime())) return '';
  date.setUTCDate(date.getUTCDate() + days);
  return normalizeDate(date);
}

async function fetchRows(path: string) {
  const headers = adminHeaders();
  const url = restUrl(path);
  if (!headers || !url) {
    throw new Error('Missing Supabase admin environment for spending agent.');
  }

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Supabase fetch failed (${response.status})`);
  }

  return response.json();
}

async function insertAiLog(promptPayload: PromptPayload, responsePayload: CoachResponse, prompt: string, rawResponse: string) {
  const headers = adminHeaders();
  const url = restUrl('ai_logs');
  if (!headers || !url) {
    console.error('ai_logs insert skipped: missing admin headers or rest URL');
    return;
  }

  const response = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      user_id: promptPayload.userId,
      family_id: promptPayload.familyId,
      tabung_id: promptPayload.tabungId,
      agent_type: 'spending_habit_coach',
      prompt,
      response: rawResponse,
      structured_response: responsePayload,
    }),
  });

  if (!response.ok) {
    console.error('ai_logs insert failed', response.status, await response.text());
  }
}

function guessPlaceCategory(purpose: string): SpendingCategory {
  const normalized = purpose.toLowerCase();
  for (const entry of KEYWORD_CATEGORY_MAP) {
    if (entry.keywords.some((keyword) => normalized.includes(keyword))) {
      return entry.category as SpendingCategory;
    }
  }
  return 'general purchase';
}

function buildCategoryMapperPrompt(
  purpose: string,
  locationContext?: RequestLocationContext,
) {
  return `You are a spending category classifier for I-Tabung, a Malaysian parent-child savings app.

The user is about to make a fake payment.

Your job is to classify the likely spending place category based on the buying purpose and optional location context.

INPUT:
- Buying Purpose: ${purpose}
- Latitude: ${locationContext?.latitude ?? 'unknown'}
- Longitude: ${locationContext?.longitude ?? 'unknown'}
- Location Accuracy: ${locationContext?.locationAccuracy ?? 'unknown'}
- Location Permission: ${locationContext?.locationPermissionStatus ?? 'unknown'}

Allowed categories:
- cafe / drink shop
- restaurant / food stall
- online game store
- clothing shop
- bookstore / stationery shop
- entertainment venue
- transport service
- electronics shop
- grocery / convenience store
- health / pharmacy
- school / education
- sports / hobby
- general purchase

Rules:
- Return strict JSON only.
- Do not include markdown.
- Choose only one category from the allowed categories.
- If unsure, choose "general purchase".
- Use "low", "medium", or "high" confidence.
- Do not claim exact shop name unless it is directly provided.
- The user may write in English, Bahasa Melayu, Manglish, or short informal text.
- Location may be approximate and should only support the guess, not become the main evidence.
- Use words like "likely", "possibly", or "may be" in the reason.

Output schema:
{
  "placeCategory": "",
  "confidence": "low",
  "reason": ""
}`;
}

function normalizeCategoryGuess(
  raw: unknown,
  purpose: string,
  locationContext?: RequestLocationContext,
): CategoryGuess {
  const allowedCategories = new Set<string>(ALLOWED_SPENDING_CATEGORIES);
  const obj = raw && typeof raw === 'object' ? raw as Record<string, unknown> : {};
  const fallbackCategory = guessPlaceCategory(purpose);
  const placeCategory = typeof obj.placeCategory === 'string' && allowedCategories.has(obj.placeCategory)
    ? obj.placeCategory as SpendingCategory
    : fallbackCategory;
  const confidence = obj.confidence === 'high' || obj.confidence === 'medium' || obj.confidence === 'low'
    ? obj.confidence
    : guessConfidence(locationContext);

  return {
    placeCategory,
    confidence,
    reason: obj.reason?.toString()
      || 'Category was inferred from the payment purpose.',
  };
}

async function guessPlaceCategoryWithGemini(
  purpose: string,
  locationContext?: RequestLocationContext,
): Promise<CategoryGuess> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';

  if (!apiKey) {
    throw new Error('Gemini API key is missing.');
  }

  const prompt = buildCategoryMapperPrompt(purpose, locationContext);
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: 'application/json',
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini category mapping failed (${response.status})`);
  }

  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== 'string') {
    throw new Error('Gemini category mapper returned empty content.');
  }

  return normalizeCategoryGuess(JSON.parse(text), purpose, locationContext);
}

async function guessPlaceCategorySmart(
  purpose: string,
  locationContext?: RequestLocationContext,
): Promise<CategoryGuess> {
  try {
    return await guessPlaceCategoryWithGemini(purpose, locationContext);
  } catch (_error) {
    const fallbackCategory = guessPlaceCategory(purpose);
    return {
      placeCategory: fallbackCategory,
      confidence: fallbackCategory === 'general purchase' ? 'low' : guessConfidence(locationContext),
      reason: fallbackCategory === 'general purchase'
        ? 'The category could not be confidently inferred, so a general purchase category was used.'
        : 'Fallback keyword-based category guess was used because the AI classifier was unavailable.',
    };
  }
}

function guessConfidence(locationContext: RequestLocationContext | undefined): 'low' | 'medium' | 'high' {
  if (!locationContext) return 'low';
  if (typeof locationContext.latitude === 'number' && typeof locationContext.longitude === 'number') {
    return locationContext.locationAccuracy && locationContext.locationAccuracy <= 50 ? 'medium' : 'low';
  }
  return 'low';
}

function startOfCurrentPeriod(period: LoadedTabung['recurringPeriod']) {
  const now = new Date();
  const utcDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  if (period === 'monthly') {
    return new Date(Date.UTC(utcDate.getUTCFullYear(), utcDate.getUTCMonth(), 1));
  }

  if (period === 'weekly') {
    const day = utcDate.getUTCDay();
    const offset = day === 0 ? 6 : day - 1;
    utcDate.setUTCDate(utcDate.getUTCDate() - offset);
    return utcDate;
  }

  return utcDate;
}

async function loadSelectedTabung(input: CoachRequest): Promise<LoadedTabung> {
  const rows = await fetchRows(
    `tabung_goals?id=eq.${encodeURIComponent(input.tabungId)}&family_id=eq.${encodeURIComponent(input.familyId)}&select=tabung_name,goal_amount,current_amount,recurring_period,recurring_amount,created_at,deadline&limit=1`,
  );

  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error('Selected tabung could not be found.');
  }

  const row = rows[0] as Record<string, unknown>;
  const recurringPeriod = row.recurring_period === 'daily' || row.recurring_period === 'weekly' || row.recurring_period === 'monthly'
    ? row.recurring_period
    : null;

  let currentPeriodSaved = 0;
  if (recurringPeriod) {
    const start = startOfCurrentPeriod(recurringPeriod);
    const end = new Date();
    const savingsRows = await fetchRows(
      `savings_entries?tabung_id=eq.${encodeURIComponent(input.tabungId)}&saved_at=gte.${encodeURIComponent(start.toISOString())}&saved_at=lte.${encodeURIComponent(end.toISOString())}&select=amount`,
    );
    const savingsEntryTotal = Array.isArray(savingsRows)
      ? savingsRows.reduce((sum, item) => sum + (((item as Record<string, unknown>).amount as number | null) ?? 0), 0)
      : 0;

    const paymentRows = await fetchRows(
      `payment_transactions?tabung_id=eq.${encodeURIComponent(input.tabungId)}&status=eq.confirmed&created_at=gte.${encodeURIComponent(start.toISOString())}&created_at=lte.${encodeURIComponent(end.toISOString())}&select=amount,purpose`,
    );
    const depositTransactionTotal = Array.isArray(paymentRows)
      ? paymentRows.reduce((sum, item) => {
          const row = item as Record<string, unknown>;
          const purpose = row.purpose?.toString().trim().toLowerCase() ?? '';
          if (!purpose.startsWith('deposit to ')) {
            return sum;
          }
          return sum + ((row.amount as number | null) ?? 0);
        }, 0)
      : 0;

    currentPeriodSaved = Math.max(savingsEntryTotal, depositTransactionTotal);
  }

  const goalAmount = ((row.goal_amount as number | null) ?? 0);
  const currentAmount = ((row.current_amount as number | null) ?? 0);

  return {
    tabungName: row.tabung_name?.toString() ?? 'Tabung',
    goalAmount,
    currentAmount,
    remainingAmount: roundToCents(Math.max(goalAmount - currentAmount, 0)),
    recurringPeriod,
    recurringAmount: typeof row.recurring_amount === 'number' ? row.recurring_amount : null,
    currentPeriodSaved: roundToCents(currentPeriodSaved),
    recurringStartDate: row.created_at?.toString()?.slice(0, 10) ?? null,
    deadline: row.deadline?.toString()?.slice(0, 10) ?? null,
  };
}

async function buildPromptPayload(input: CoachRequest, selectedTabung: LoadedTabung): Promise<PromptPayload> {
  const categoryGuess = await guessPlaceCategorySmart(
    input.buyingPurpose,
    input.locationContext,
  );
  return {
    userId: input.userId,
    familyId: input.familyId,
    tabungId: input.tabungId,
    paymentAmount: roundToCents(input.paymentAmount),
    buyingPurpose: input.buyingPurpose.trim(),
    selectedTabung,
    locationContext: {
      latitude: input.locationContext?.latitude,
      longitude: input.locationContext?.longitude,
      locationPermissionStatus: input.locationContext?.locationPermissionStatus ?? 'unknown',
      guessedPlaceName: 'Unknown',
      guessedPlaceCategory: categoryGuess.placeCategory,
      confidence: categoryGuess.confidence,
      categoryReason: categoryGuess.reason,
    },
  };
}

function deriveDelay(paymentAmount: number, recurringAmount: number | null, recurringPeriod: LoadedTabung['recurringPeriod']) {
  if (!recurringAmount || !recurringPeriod || recurringAmount <= 0) {
    return { value: 0, unit: 'days' as DelayUnit, days: 0 };
  }

  const ratio = paymentAmount / recurringAmount;
  if (recurringPeriod === 'daily') {
    const days = Math.max(1, Math.ceil(ratio));
    return { value: days, unit: 'days' as DelayUnit, days };
  }
  if (recurringPeriod === 'weekly') {
    const days = Math.max(1, Math.ceil(ratio * 7));
    return { value: days, unit: 'days' as DelayUnit, days };
  }

  const weeks = Math.max(1, Math.ceil(ratio * 4));
  return { value: weeks, unit: 'weeks' as DelayUnit, days: weeks * 7 };
}

function buildNeutralRecurringReminder(selectedTabung: LoadedTabung) {
  return {
    message: 'This tabung does not have a recurring saving target yet, so this spending will only affect the overall goal balance.',
    recurringAmount: selectedTabung.recurringAmount ?? 0,
    currentPeriodSaved: selectedTabung.currentPeriodSaved,
    remainingForThisPeriod: 0,
  };
}

function buildLocalResponse(payload: PromptPayload): CoachResponse {
  const progress = payload.selectedTabung.goalAmount <= 0
    ? 0
    : roundToCents((payload.selectedTabung.currentAmount / payload.selectedTabung.goalAmount) * 100);

  const recurringAmount = payload.selectedTabung.recurringAmount;
  const currentPeriodSaved = payload.selectedTabung.currentPeriodSaved;
  const remainingForThisPeriod = recurringAmount
    ? roundToCents(Math.max(recurringAmount - currentPeriodSaved, 0))
    : 0;
  const delay = deriveDelay(payload.paymentAmount, recurringAmount, payload.selectedTabung.recurringPeriod);
  const shouldProceed = recurringAmount == null
    ? payload.paymentAmount <= payload.selectedTabung.currentAmount * 0.1
    : remainingForThisPeriod <= 0 || payload.paymentAmount < remainingForThisPeriod * 0.5;

  const recurringTargetReminder = recurringAmount == null || payload.selectedTabung.recurringPeriod == null
    ? buildNeutralRecurringReminder(payload.selectedTabung)
    : {
        message:
          `Your ${payload.selectedTabung.recurringPeriod} saving target is RM${recurringAmount.toFixed(0)}. You have saved RM${currentPeriodSaved.toFixed(0)} this ${payload.selectedTabung.recurringPeriod === 'daily' ? 'period' : payload.selectedTabung.recurringPeriod === 'weekly' ? 'week' : 'month'}, so you still need RM${remainingForThisPeriod.toFixed(0)} to stay on track.`,
        recurringAmount,
        currentPeriodSaved,
        remainingForThisPeriod,
      };

  const alternatives = [
    {
      title: 'Choose a cheaper option',
      description: `Spend RM${Math.max(1, Math.round(payload.paymentAmount * 0.5)).toString()} instead and keep the rest in ${payload.selectedTabung.tabungName}.`,
      estimatedSaving: roundToCents(payload.paymentAmount * 0.5),
    },
    {
      title: 'Delay the purchase',
      description: recurringAmount == null
        ? `Wait until you add more savings into ${payload.selectedTabung.tabungName} before buying this item.`
        : `Complete this ${payload.selectedTabung.recurringPeriod} target first before buying ${payload.buyingPurpose.toLowerCase()}.`,
      estimatedSaving: roundToCents(payload.paymentAmount),
    },
    {
      title: 'Set a fun budget',
      description: 'Save first, then spend only from a smaller fun budget for this kind of purchase.',
      estimatedSaving: roundToCents(Math.max(payload.paymentAmount * 0.33, 5)),
    },
  ];

  return {
    guessedSpendingPlace: {
      placeName: 'Unknown',
      placeCategory: payload.locationContext.guessedPlaceCategory,
      confidence: payload.locationContext.confidence,
      reason: payload.locationContext.categoryReason
        || `The buying purpose mentions ${payload.buyingPurpose.toLowerCase()}, so this may be a ${payload.locationContext.guessedPlaceCategory} purchase.`,
    },
    tabungReminder: {
      message: `Your ${payload.selectedTabung.tabungName} target is RM${payload.selectedTabung.goalAmount.toFixed(0)} and you have saved RM${payload.selectedTabung.currentAmount.toFixed(0)} so far.`,
      currentProgressPercentage: progress,
    },
    recurringTargetReminder,
    spendingImpact: {
      impactWarning: delay.value <= 0
        ? `If you spend RM${payload.paymentAmount.toFixed(0)} now, your overall tabung balance will drop and your goal may feel harder to reach.`
        : `If you spend RM${payload.paymentAmount.toFixed(0)} now, your ${payload.selectedTabung.tabungName} may take around ${delay.value} more ${delay.unit} to complete.`,
      estimatedDelayValue: delay.value,
      estimatedDelayUnit: delay.unit,
      newEstimatedEndDate: addDays(payload.selectedTabung.deadline, delay.days),
    },
    alternativeSuggestions: alternatives,
    recommendation: {
      shouldProceed,
      message: shouldProceed
        ? 'You can proceed, but keep your savings target in mind and choose the most budget-friendly option.'
        : remainingForThisPeriod > 0
          ? `It is better to save RM${remainingForThisPeriod.toFixed(0)} first to stay on track before spending on this item.`
          : 'It may be better to wait a little longer so your tabung progress stays strong.',
    },
    summary: shouldProceed
      ? `This spending looks manageable, but it still reduces progress on ${payload.selectedTabung.tabungName}.`
      : `This spending may slow down ${payload.selectedTabung.tabungName} because your current savings target is not complete yet.`,
    promptVersion: PROMPT_VERSION,
  };
}

function normalizeResponse(raw: unknown, fallback: CoachResponse): CoachResponse {
  const local = fallback;
  const source = raw && typeof raw === 'object' ? raw as Record<string, unknown> : {};
  const guessedSpendingPlace = source.guessedSpendingPlace && typeof source.guessedSpendingPlace === 'object'
    ? source.guessedSpendingPlace as Record<string, unknown>
    : {};
  const tabungReminder = source.tabungReminder && typeof source.tabungReminder === 'object'
    ? source.tabungReminder as Record<string, unknown>
    : {};
  const recurringTargetReminder = source.recurringTargetReminder && typeof source.recurringTargetReminder === 'object'
    ? source.recurringTargetReminder as Record<string, unknown>
    : {};
  const spendingImpact = source.spendingImpact && typeof source.spendingImpact === 'object'
    ? source.spendingImpact as Record<string, unknown>
    : {};
  const recommendation = source.recommendation && typeof source.recommendation === 'object'
    ? source.recommendation as Record<string, unknown>
    : {};
  const alternatives = Array.isArray(source.alternativeSuggestions) ? source.alternativeSuggestions : [];

  return {
    guessedSpendingPlace: {
      placeName: guessedSpendingPlace.placeName?.toString() || local.guessedSpendingPlace.placeName,
      placeCategory: guessedSpendingPlace.placeCategory?.toString() || local.guessedSpendingPlace.placeCategory,
      confidence: guessedSpendingPlace.confidence === 'medium' || guessedSpendingPlace.confidence === 'high'
        ? guessedSpendingPlace.confidence
        : 'low',
      reason: guessedSpendingPlace.reason?.toString() || local.guessedSpendingPlace.reason,
    },
    tabungReminder: {
      message: tabungReminder.message?.toString() || local.tabungReminder.message,
      currentProgressPercentage: clamp(Number(tabungReminder.currentProgressPercentage ?? local.tabungReminder.currentProgressPercentage), 0, 100),
    },
    recurringTargetReminder: {
      message: recurringTargetReminder.message?.toString() || local.recurringTargetReminder.message,
      recurringAmount: roundToCents(Number(recurringTargetReminder.recurringAmount ?? local.recurringTargetReminder.recurringAmount)),
      currentPeriodSaved: roundToCents(Number(recurringTargetReminder.currentPeriodSaved ?? local.recurringTargetReminder.currentPeriodSaved)),
      remainingForThisPeriod: roundToCents(Math.max(0, Number(recurringTargetReminder.remainingForThisPeriod ?? local.recurringTargetReminder.remainingForThisPeriod))),
    },
    spendingImpact: {
      impactWarning: spendingImpact.impactWarning?.toString() || local.spendingImpact.impactWarning,
      estimatedDelayValue: Math.max(0, Math.round(Number(spendingImpact.estimatedDelayValue ?? local.spendingImpact.estimatedDelayValue))),
      estimatedDelayUnit: spendingImpact.estimatedDelayUnit === 'weeks' || spendingImpact.estimatedDelayUnit === 'months'
        ? spendingImpact.estimatedDelayUnit
        : 'days',
      newEstimatedEndDate: spendingImpact.newEstimatedEndDate?.toString() || local.spendingImpact.newEstimatedEndDate,
    },
    alternativeSuggestions: (alternatives.slice(0, 3).map((item) => {
      const entry = item && typeof item === 'object' ? item as Record<string, unknown> : {};
      return {
        title: entry.title?.toString() || '',
        description: entry.description?.toString() || '',
        estimatedSaving: roundToCents(Math.max(0, Number(entry.estimatedSaving ?? 0))),
      };
    })).filter((item) => item.title && item.description).slice(0, 3),
    recommendation: {
      shouldProceed: Boolean(recommendation.shouldProceed ?? local.recommendation.shouldProceed),
      message: recommendation.message?.toString() || local.recommendation.message,
    },
    summary: source.summary?.toString() || local.summary,
    promptVersion: source.promptVersion?.toString() || PROMPT_VERSION,
  };
}

function validateResponse(response: CoachResponse) {
  return (
    isNonEmptyString(response.guessedSpendingPlace.placeCategory)
    && isNonEmptyString(response.tabungReminder.message)
    && isNonEmptyString(response.recurringTargetReminder.message)
    && isNonEmptyString(response.spendingImpact.impactWarning)
    && response.alternativeSuggestions.length === 3
    && response.alternativeSuggestions.every((item) => isNonEmptyString(item.title) && isNonEmptyString(item.description))
    && isNonEmptyString(response.recommendation.message)
    && isNonEmptyString(response.summary)
  );
}

function buildPrompt(payload: PromptPayload) {
  return `You are the "Spending Habit Coach Agent" for I-Tabung, a Malaysian parent-child savings app.

I-Tabung helps children and parents build better money habits through shared saving goals called Tabung.

The user is about to make a fake bank-transfer-style payment.

Your job is to help the user pause before spending by explaining:
1. Which shop/place they might be spending at based on current location and buying purpose.
2. How this spending affects their selected Tabung.
3. Whether they are still on track with their recurring saving target.
4. How long the Tabung goal may be extended if they spend this money.
5. Three cheaper or healthier alternatives.

INPUT:
${JSON.stringify(payload)}

The spending category was automatically inferred before this step.

Category mapping result:
- Guessed category: ${payload.locationContext.guessedPlaceCategory}
- Category confidence: ${payload.locationContext.confidence}
- Category reason: ${payload.locationContext.categoryReason ?? 'No extra category reason provided.'}

Use this category to make the spending advice more specific.
Do not override the category unless it is clearly inconsistent with the buying purpose.

IMPORTANT:
- Location may be approximate.
- If location is unavailable, use buying purpose to guess the shop category.
- Do not claim the exact shop unless it is provided with confidence.
- Use words like "may be", "likely", or "possibly" when guessing.
- Keep the tone friendly and non-scolding.
- Use Malaysian Ringgit.
- Return strict JSON only.
- Do not include markdown.
- Do not include text outside JSON.

TASK:
Generate:
1. guessedSpendingPlace
2. tabungReminder
3. recurringTargetReminder
4. spendingImpact
5. exactly 3 alternativeSuggestions
6. recommendation
7. summary`;
}

async function generateWithGemini(promptPayload: PromptPayload): Promise<{ response: CoachResponse; raw: string; prompt: string }> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';
  const prompt = buildPrompt(promptPayload);

  if (!apiKey) {
    const response = buildLocalResponse(promptPayload);
    return { response, raw: JSON.stringify(response), prompt };
  }

  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const geminiResponse = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
    }),
  });

  if (!geminiResponse.ok) {
    throw new Error(`Gemini request failed (${geminiResponse.status})`);
  }

  const data = await geminiResponse.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== 'string') {
    throw new Error('Gemini returned empty content');
  }

  const normalized = normalizeResponse(JSON.parse(text), buildLocalResponse(promptPayload));
  return { response: normalized, raw: text, prompt };
}

function isValidInput(payload: CoachRequest) {
  return isUuid(payload.userId)
    && isUuid(payload.familyId)
    && isUuid(payload.tabungId)
    && isPositiveNumber(payload.paymentAmount)
    && isNonEmptyString(payload.buyingPurpose);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return fail('invalid_input', 'Only POST is allowed.');
  }

  try {
    const requestPayload = await req.json() as CoachRequest;
    if (!isValidInput(requestPayload)) {
      return fail('invalid_input', 'Missing or invalid spending review fields.');
    }

    const selectedTabung = await loadSelectedTabung(requestPayload);
    if (requestPayload.paymentAmount > selectedTabung.currentAmount) {
      return fail('invalid_input', 'Payment amount is higher than the current tabung balance.', 422);
    }

    const promptPayload = await buildPromptPayload(requestPayload, selectedTabung);

    let response: CoachResponse;
    let rawResponse = '';
    let prompt = '';

    try {
      const generated = await generateWithGemini(promptPayload);
      response = generated.response;
      rawResponse = generated.raw;
      prompt = generated.prompt;
    } catch (error) {
      response = buildLocalResponse(promptPayload);
      rawResponse = JSON.stringify(response);
      prompt = buildPrompt(promptPayload);
      if ((error as Error).message.toLowerCase().includes('timeout')) {
        console.error('Gemini timeout, using local spending coach fallback');
      } else {
        console.error('Gemini unavailable, using local spending coach fallback', (error as Error).message);
      }
    }

    response = normalizeResponse(response, buildLocalResponse(promptPayload));
    response.promptVersion = PROMPT_VERSION;
    if (!validateResponse(response)) {
      return fail('schema_invalid', 'Payment coach output validation failed.', 422);
    }

    await insertAiLog(promptPayload, response, prompt, rawResponse);

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return fail('service_unavailable', `Failed to review payment: ${(error as Error).message}`, 500);
  }
});
