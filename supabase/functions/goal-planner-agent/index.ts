import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const PROMPT_BASE_VERSION = 'goal_planner_v3_2026_05_23';
const PROMPT_VERSION = PROMPT_BASE_VERSION;
const ALLOWED_TABUNG_TYPES = ['electronic device', 'food', 'growth fund', 'sport and art', 'travel'] as const;
const ALLOWED_DURATION_UNITS = ['days', 'weeks', 'months'] as const;
const ALLOWED_RECURRING_TYPES = ['daily', 'weekly', 'monthly'] as const;

type PlannerInput = {
  idempotencyKey?: string;
  userId?: string;
  familyId?: string;
  tabungId?: string;
  userRole: 'parent' | 'child';
  tabungType: (typeof ALLOWED_TABUNG_TYPES)[number];
  tabungName: string;
  tabungDescription: string;
};

type PlannerOutput = {
  suggestedGoalAmount: {
    amount: number;
    reason: string;
  };
  contributionRatioSuggestion: {
    childContributionPercentage: number;
    parentContributionPercentage: number;
    childContributionAmount: number;
    parentContributionAmount: number;
    reason: string;
  };
  endPeriodSuggestion: {
    durationValue: number;
    durationUnit: (typeof ALLOWED_DURATION_UNITS)[number];
    reason: string;
  };
  recurringTargetSuggestion: {
    recurringType: (typeof ALLOWED_RECURRING_TYPES)[number];
    amount: number;
    reason: string;
  };
  milestoneRewardSuggestions: Array<{
    targetAmount: number;
    milestoneLabel: string;
    rewardSuggestion: string;
    reason: string;
  }>;
  summary: string;
};

type PlannerResponse = PlannerOutput & {
  promptVersion: string;
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

async function sha256Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  const hashArray = Array.from(new Uint8Array(hash));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function getIdempotentResponse(idempotencyKey: string) {
  const headers = adminHeaders();
  const url = restUrl(`agent_idempotency_keys?idempotency_key=eq.${encodeURIComponent(idempotencyKey)}&select=response_body&limit=1`);
  if (!headers || !url) return null;

  const response = await fetch(url, { headers });
  if (!response.ok) return null;
  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length === 0) return null;
  return rows[0]?.response_body ?? null;
}

async function persistIdempotency({ idempotencyKey, requestHash, payload, plan }: {
  idempotencyKey: string;
  requestHash: string;
  payload: PlannerInput;
  plan: PlannerResponse;
}) {
  const headers = adminHeaders();
  const url = restUrl('agent_idempotency_keys');
  if (!headers || !url) return;

  await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      idempotency_key: idempotencyKey,
      agent_type: 'goal_planner',
      request_hash: requestHash,
      request_body: payload,
      response_body: plan,
    }),
  });
}

async function insertAiLog(payload: PlannerInput, plan: PlannerResponse, prompt: string, rawResponse: string) {
  const headers = adminHeaders();
  const url = restUrl('ai_logs');
  if (!headers || !url) {
    console.error('ai_logs insert skipped: missing admin headers or rest URL');
    return;
  }

  const asUuidOrNull = (value?: string | null) => {
    if (!value) return null;
    const v = value.trim();
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(v) ? v : null;
  };

  const response = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      user_id: asUuidOrNull(payload.userId),
      family_id: asUuidOrNull(payload.familyId),
      tabung_id: asUuidOrNull(payload.tabungId),
      agent_type: 'goal_planner',
      prompt,
      response: rawResponse,
      structured_response: plan,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    console.error('ai_logs insert failed', response.status, errText);
  }
}

function isAllowedTabungType(value: unknown): value is PlannerInput['tabungType'] {
  return typeof value === 'string' && ALLOWED_TABUNG_TYPES.includes(value as PlannerInput['tabungType']);
}

function isAllowedDurationUnit(value: unknown): value is PlannerOutput['endPeriodSuggestion']['durationUnit'] {
  return typeof value === 'string' && ALLOWED_DURATION_UNITS.includes(value as PlannerOutput['endPeriodSuggestion']['durationUnit']);
}

function isAllowedRecurringType(value: unknown): value is PlannerOutput['recurringTargetSuggestion']['recurringType'] {
  return typeof value === 'string' && ALLOWED_RECURRING_TYPES.includes(value as PlannerOutput['recurringTargetSuggestion']['recurringType']);
}

function isNonEmptyString(value: unknown) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isFinitePositiveNumber(value: unknown) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0;
}

function isCloseTo(a: number, b: number, tolerance: number) {
  return Math.abs(a - b) <= tolerance;
}

function roundToWholeRm(value: number) {
  return Math.max(1, Math.round(value));
}

function roundToNearestStep(value: number, step: number) {
  return Math.max(step, Math.round(value / step) * step);
}

function normalizePercentages(childPercentage: number) {
  const normalizedChild = Math.min(100, Math.max(0, Math.round(childPercentage * 100) / 100));
  const normalizedParent = Math.round((100 - normalizedChild) * 100) / 100;
  return {
    childContributionPercentage: normalizedChild,
    parentContributionPercentage: normalizedParent,
  };
}

function normalizeContributionAmounts(goalAmount: number, childPercentage: number) {
  const childContributionAmount = roundToWholeRm(goalAmount * (childPercentage / 100));
  const parentContributionAmount = Math.max(0, goalAmount - childContributionAmount);
  return {
    childContributionAmount,
    parentContributionAmount,
  };
}

function convertDurationToDays(durationValue: number, durationUnit: PlannerOutput['endPeriodSuggestion']['durationUnit']) {
  if (durationUnit === 'days') return durationValue;
  if (durationUnit === 'weeks') return durationValue * 7;
  return durationValue * 30;
}

function convertDurationToWeeks(durationValue: number, durationUnit: PlannerOutput['endPeriodSuggestion']['durationUnit']) {
  if (durationUnit === 'weeks') return durationValue;
  if (durationUnit === 'days') return Math.max(1, Math.round(durationValue / 7));
  return durationValue * 4;
}

function convertDurationToMonths(durationValue: number, durationUnit: PlannerOutput['endPeriodSuggestion']['durationUnit']) {
  if (durationUnit === 'months') return durationValue;
  if (durationUnit === 'weeks') return Math.max(1, Math.round(durationValue / 4));
  return Math.max(1, Math.round(durationValue / 30));
}

function normalizeMilestones(
  goalAmount: number,
  milestones: PlannerOutput['milestoneRewardSuggestions'],
): PlannerOutput['milestoneRewardSuggestions'] {
  const sorted = [...milestones]
    .map((milestone) => ({
      targetAmount: roundToWholeRm(milestone.targetAmount),
      milestoneLabel: milestone.milestoneLabel?.trim() || 'Milestone',
      rewardSuggestion: milestone.rewardSuggestion?.trim() || 'Family encouragement reward',
      reason: milestone.reason?.trim() || 'Milestone generated for steady goal progress.',
    }))
    .sort((a, b) => a.targetAmount - b.targetAmount);

  const fallbackTargets = [0.25, 0.5, 0.8, 1];
  const normalized = sorted.map((milestone, index) => {
    const ratio = fallbackTargets[index] ?? ((index + 1) / sorted.length);
    return {
      ...milestone,
      targetAmount: index === sorted.length - 1 ? goalAmount : roundToWholeRm(goalAmount * ratio),
    };
  });

  for (let i = 0; i < normalized.length; i += 1) {
    const minimum = i === 0 ? 1 : normalized[i - 1].targetAmount + 1;
    if (normalized[i].targetAmount < minimum) {
      normalized[i].targetAmount = minimum;
    }
  }

  if (normalized.length > 0) {
    normalized[normalized.length - 1].targetAmount = goalAmount;
  }

  return normalized;
}

function normalizeOutput(plan: unknown): PlannerOutput {
  const source = (plan && typeof plan === 'object' ? plan : {}) as Record<string, unknown>;
  const suggestedGoalAmount = (source.suggestedGoalAmount ?? {}) as Record<string, unknown>;
  const contribution = (source.contributionRatioSuggestion ?? {}) as Record<string, unknown>;
  const endPeriod = (source.endPeriodSuggestion ?? {}) as Record<string, unknown>;
  const recurring = (source.recurringTargetSuggestion ?? {}) as Record<string, unknown>;
  const rawMilestones = Array.isArray(source.milestoneRewardSuggestions) ? source.milestoneRewardSuggestions : [];

  const goalAmount = roundToWholeRm(
    typeof suggestedGoalAmount.amount === 'number' && Number.isFinite(suggestedGoalAmount.amount)
      ? suggestedGoalAmount.amount
      : 0,
  );

  const childPercentageCandidate =
    typeof contribution.childContributionPercentage === 'number' && Number.isFinite(contribution.childContributionPercentage)
      ? contribution.childContributionPercentage
      : 50;
  const percentages = normalizePercentages(childPercentageCandidate);
  const amounts = normalizeContributionAmounts(goalAmount, percentages.childContributionPercentage);

  const durationUnit = isAllowedDurationUnit(endPeriod.durationUnit) ? endPeriod.durationUnit : 'months';
  const durationValue = Math.max(
    1,
    Math.round(
      typeof endPeriod.durationValue === 'number' && Number.isFinite(endPeriod.durationValue)
        ? endPeriod.durationValue
        : 1,
    ),
  );

  const recurringType = isAllowedRecurringType(recurring.recurringType) ? recurring.recurringType : 'weekly';
  let fallbackRecurringAmount = 0;
  if (recurringType === 'daily') {
    fallbackRecurringAmount = roundToWholeRm(goalAmount / convertDurationToDays(durationValue, durationUnit));
  } else if (recurringType === 'weekly') {
    fallbackRecurringAmount = roundToWholeRm(goalAmount / convertDurationToWeeks(durationValue, durationUnit));
  } else {
    fallbackRecurringAmount = roundToWholeRm(goalAmount / convertDurationToMonths(durationValue, durationUnit));
  }
  const recurringAmount = isFinitePositiveNumber(recurring.amount)
    ? roundToWholeRm(recurring.amount)
    : fallbackRecurringAmount;

  const milestones = normalizeMilestones(
    goalAmount,
    rawMilestones.map((milestone) => {
      const raw = (milestone ?? {}) as Record<string, unknown>;
      return {
        targetAmount:
          typeof raw.targetAmount === 'number' && Number.isFinite(raw.targetAmount) ? raw.targetAmount : goalAmount,
        milestoneLabel: typeof raw.milestoneLabel === 'string' ? raw.milestoneLabel : '',
        rewardSuggestion: typeof raw.rewardSuggestion === 'string' ? raw.rewardSuggestion : '',
        reason: typeof raw.reason === 'string' ? raw.reason : '',
      };
    }),
  );

  return {
    suggestedGoalAmount: {
      amount: goalAmount,
      reason: isNonEmptyString(suggestedGoalAmount.reason)
        ? suggestedGoalAmount.reason.trim()
        : 'Suggested based on the selected tabung type and description.',
    },
    contributionRatioSuggestion: {
      childContributionPercentage: percentages.childContributionPercentage,
      parentContributionPercentage: percentages.parentContributionPercentage,
      childContributionAmount: amounts.childContributionAmount,
      parentContributionAmount: amounts.parentContributionAmount,
      reason: isNonEmptyString(contribution.reason)
        ? contribution.reason.trim()
        : 'Split balances child ownership with practical parent support.',
    },
    endPeriodSuggestion: {
      durationValue,
      durationUnit,
      reason: isNonEmptyString(endPeriod.reason)
        ? endPeriod.reason.trim()
        : 'Suggested to keep the goal practical for a family saving journey.',
    },
    recurringTargetSuggestion: {
      recurringType,
      amount: recurringAmount,
      reason: isNonEmptyString(recurring.reason)
        ? recurring.reason.trim()
        : 'Recurring amount is paced to make the goal easier to maintain.',
    },
    milestoneRewardSuggestions: milestones,
    summary: isNonEmptyString(source.summary)
      ? String(source.summary).trim()
      : 'This plan suggests a practical target, shared contribution split, and milestone rewards for the goal.',
  };
}

function isInputValid(payload: PlannerInput) {
  return !!(
    (payload.userRole === 'parent' || payload.userRole === 'child') &&
    isAllowedTabungType(payload.tabungType) &&
    isNonEmptyString(payload.tabungName) &&
    isNonEmptyString(payload.tabungDescription)
  );
}

function isOutputValid(plan: unknown): plan is PlannerOutput {
  if (!plan || typeof plan !== 'object') return false;

  const p = plan as Record<string, unknown>;
  const suggestedGoalAmount = p.suggestedGoalAmount as Record<string, unknown>;
  const contribution = p.contributionRatioSuggestion as Record<string, unknown>;
  const endPeriod = p.endPeriodSuggestion as Record<string, unknown>;
  const recurring = p.recurringTargetSuggestion as Record<string, unknown>;
  const milestones = p.milestoneRewardSuggestions as unknown[];

  if (!suggestedGoalAmount || !isFinitePositiveNumber(suggestedGoalAmount.amount) || !isNonEmptyString(suggestedGoalAmount.reason)) {
    return false;
  }

  if (
    !contribution ||
    typeof contribution.childContributionPercentage !== 'number' ||
    typeof contribution.parentContributionPercentage !== 'number' ||
    typeof contribution.childContributionAmount !== 'number' ||
    typeof contribution.parentContributionAmount !== 'number' ||
    !isNonEmptyString(contribution.reason)
  ) {
    return false;
  }

  const totalPercentage = contribution.childContributionPercentage + contribution.parentContributionPercentage;
  if (!isCloseTo(totalPercentage, 100, 0.01)) {
    return false;
  }

  const totalContributionAmount = contribution.childContributionAmount + contribution.parentContributionAmount;
  if (!isCloseTo(totalContributionAmount, suggestedGoalAmount.amount as number, 1)) {
    return false;
  }

  if (
    !endPeriod ||
    !isFinitePositiveNumber(endPeriod.durationValue) ||
    !isAllowedDurationUnit(endPeriod.durationUnit) ||
    !isNonEmptyString(endPeriod.reason)
  ) {
    return false;
  }

  if (
    !recurring ||
    !isAllowedRecurringType(recurring.recurringType) ||
    !isFinitePositiveNumber(recurring.amount) ||
    !isNonEmptyString(recurring.reason)
  ) {
    return false;
  }

  if (!Array.isArray(milestones) || milestones.length === 0) {
    return false;
  }

  let previousTarget = 0;
  for (const milestone of milestones) {
    const current = milestone as Record<string, unknown>;
    if (
      !isFinitePositiveNumber(current.targetAmount) ||
      !isNonEmptyString(current.milestoneLabel) ||
      !isNonEmptyString(current.rewardSuggestion) ||
      !isNonEmptyString(current.reason)
    ) {
      return false;
    }
    if ((current.targetAmount as number) <= previousTarget) {
      return false;
    }
    previousTarget = current.targetAmount as number;
  }

  const finalMilestone = milestones[milestones.length - 1] as Record<string, unknown>;
  if (!isCloseTo(finalMilestone.targetAmount as number, suggestedGoalAmount.amount as number, 1)) {
    return false;
  }

  return isNonEmptyString(p.summary);
}

function inferGoalAmount(payload: PlannerInput) {
  const text = `${payload.tabungName} ${payload.tabungDescription}`.toLowerCase();
  let amount = ({
    'electronic device': 2500,
    food: 300,
    'growth fund': 1000,
    'sport and art': 800,
    travel: 1500,
  } satisfies Record<PlannerInput['tabungType'], number>)[payload.tabungType];

  if (payload.tabungType === 'electronic device') {
    if (/(laptop|computer|macbook)/.test(text)) amount = 3500;
    if (/(phone|tablet)/.test(text)) amount = 2200;
  }

  if (payload.tabungType === 'travel') {
    if (/(overseas|japan|korea|europe)/.test(text)) amount = 4000;
    if (/(local|melaka|penang|langkawi)/.test(text)) amount = 1500;
  }

  if (payload.tabungType === 'sport and art' && /(class|lesson|competition|equipment)/.test(text)) {
    amount = 900;
  }

  if (payload.tabungType === 'food' && /(lunch|meal|snacks)/.test(text)) {
    amount = 300;
  }

  if (payload.tabungType === 'growth fund' && /(future|investment|education|university)/.test(text)) {
    amount = 1500;
  }

  return amount;
}

function inferContributionSplit(payload: PlannerInput) {
  const text = payload.tabungDescription.toLowerCase();
  let childPercentage = ({
    'electronic device': 70,
    food: 60,
    'growth fund': 40,
    'sport and art': 60,
    travel: 40,
  } satisfies Record<PlannerInput['tabungType'], number>)[payload.tabungType];

  if (payload.userRole === 'parent' && payload.tabungType === 'electronic device') {
    childPercentage = 60;
  }

  if (/(family|school|study|emergency|education)/.test(text)) {
    childPercentage = Math.max(30, childPercentage - 10);
  }

  const { childContributionPercentage, parentContributionPercentage } = normalizePercentages(childPercentage);
  return { childContributionPercentage, parentContributionPercentage };
}

function inferEndPeriod(goalAmount: number, payload: PlannerInput): PlannerOutput['endPeriodSuggestion'] {
  let durationValue = ({
    food: 4,
    'sport and art': 3,
    'growth fund': 6,
    'electronic device': 6,
    travel: 6,
  } satisfies Record<PlannerInput['tabungType'], number>)[payload.tabungType];

  let durationUnit: PlannerOutput['endPeriodSuggestion']['durationUnit'] =
    payload.tabungType === 'food' ? 'weeks' : 'months';

  if (goalAmount > 3000) {
    durationValue = goalAmount >= 4000 ? 12 : 9;
    durationUnit = 'months';
  }

  return {
    durationValue,
    durationUnit,
    reason: durationUnit === 'weeks'
      ? 'Shorter goals work better with a focused weekly timeline.'
      : 'This timeline keeps the goal achievable while maintaining steady family progress.',
  };
}

function inferRecurringPlan(
  goalAmount: number,
  endPeriod: PlannerOutput['endPeriodSuggestion'],
): PlannerOutput['recurringTargetSuggestion'] {
  let recurringType: PlannerOutput['recurringTargetSuggestion']['recurringType'] = 'weekly';

  if (goalAmount <= 500) {
    recurringType = goalAmount <= 300 ? 'daily' : 'weekly';
  } else if (goalAmount > 3000) {
    const months = convertDurationToMonths(endPeriod.durationValue, endPeriod.durationUnit);
    const tentativeMonthly = goalAmount / Math.max(1, months);
    recurringType = tentativeMonthly <= 700 ? 'monthly' : 'weekly';
  }

  let amount = 0;
  if (recurringType === 'daily') {
    amount = goalAmount / convertDurationToDays(endPeriod.durationValue, endPeriod.durationUnit);
  } else if (recurringType === 'weekly') {
    amount = goalAmount / convertDurationToWeeks(endPeriod.durationValue, endPeriod.durationUnit);
  } else {
    amount = goalAmount / convertDurationToMonths(endPeriod.durationValue, endPeriod.durationUnit);
  }

  const roundedAmount = amount <= 100 ? roundToNearestStep(amount, 1) : roundToNearestStep(amount, 5);

  return {
    recurringType,
    amount: roundedAmount,
    reason: recurringType === 'daily'
      ? 'A small daily target is easier to build into a child-friendly saving habit.'
      : recurringType === 'weekly'
        ? 'Weekly saving feels practical for regular family tracking and motivation.'
        : 'Monthly saving suits a larger goal with a steadier contribution rhythm.',
  };
}

function buildMilestones(goalAmount: number): PlannerOutput['milestoneRewardSuggestions'] {
  const rewardTemplates = [
    {
      milestoneLabel: 'First Step',
      rewardSuggestion: 'Choose a favourite snack or small outing.',
      reason: 'An early reward helps build momentum and excitement.',
    },
    {
      milestoneLabel: 'Halfway There',
      rewardSuggestion: 'Enjoy a simple family treat or extra playtime.',
      reason: 'Midway rewards keep the goal fun without being expensive.',
    },
    {
      milestoneLabel: 'Almost There',
      rewardSuggestion: 'Let the child pick a family activity for the weekend.',
      reason: 'A meaningful but affordable reward keeps focus strong near the finish.',
    },
    {
      milestoneLabel: 'Goal Completed',
      rewardSuggestion: 'Celebrate with a family meal, photo moment, or handwritten achievement note.',
      reason: 'The final reward should feel memorable and family-centered.',
    },
  ];
  const percentages = [0.25, 0.5, 0.8, 1];

  return percentages.map((pct, index) => ({
    targetAmount: roundToWholeRm(goalAmount * pct),
    milestoneLabel: rewardTemplates[index].milestoneLabel,
    rewardSuggestion: rewardTemplates[index].rewardSuggestion,
    reason: rewardTemplates[index].reason,
  }));
}

function buildLocalPlan(payload: PlannerInput): PlannerOutput {
  const goalAmount = inferGoalAmount(payload);
  const percentages = inferContributionSplit(payload);
  const amounts = normalizeContributionAmounts(goalAmount, percentages.childContributionPercentage);
  const endPeriodSuggestion = inferEndPeriod(goalAmount, payload);
  const recurringTargetSuggestion = inferRecurringPlan(goalAmount, endPeriodSuggestion);
  const milestoneRewardSuggestions = normalizeMilestones(goalAmount, buildMilestones(goalAmount));

  return normalizeOutput({
    suggestedGoalAmount: {
      amount: goalAmount,
      reason: 'Suggested from the selected tabung type and description details.',
    },
    contributionRatioSuggestion: {
      ...percentages,
      ...amounts,
      reason: 'Suggested to balance child responsibility with practical parent support.',
    },
    endPeriodSuggestion,
    recurringTargetSuggestion,
    milestoneRewardSuggestions,
    summary:
      `For ${payload.tabungName}, aim for ${goalAmount} RM with a ${recurringTargetSuggestion.recurringType} saving plan and shared parent-child support.`,
  });
}

function buildGeminiPrompt(payload: PlannerInput) {
  return `You are the "Goal Planner Agent" for I-Tabung, a Malaysian parent-child savings app.

I-Tabung helps parents and children create shared saving goals called Tabung. The user has selected a Tabung type, entered a Tabung name, and written a short Tabung description.

Your job is to suggest a complete saving plan.

The user does NOT need to provide:
- target amount
- contribution ratio
- end period
- recurring target
- milestone rewards

You must infer and suggest them.

INPUT:
${JSON.stringify(payload)}

TASK:
Based on the input, generate:
1. A suggested total goal amount in Malaysian Ringgit.
2. A parent-child contribution ratio.
3. The contribution amount for parent and child.
4. A suggested end period.
5. A recurring target type: daily, weekly, or monthly.
6. A recurring saving amount.
7. Milestone reward suggestions for each money target reached.
8. A short summary that explains the plan clearly.

RULES:
- Return strict JSON only.
- Do not include markdown.
- Use Malaysian Ringgit.
- Keep the tone friendly and practical.
- Make sure childContributionPercentage + parentContributionPercentage = 100.
- Make sure childContributionAmount + parentContributionAmount = suggestedGoalAmount.amount.
- Make sure milestone target amounts are increasing.
- The final milestone target amount must equal suggestedGoalAmount.amount.
- Choose recurringType from only: daily, weekly, monthly.
- Choose durationUnit from only: days, weeks, months.
- Keep milestone rewards practical and family-friendly.
- Do not make every reward expensive.
- For child-focused personal goals, the child should usually contribute more.
- For family, education, emergency, or growth-related goals, the parent may contribute more.
- Use Malaysian family context.
- Do not include difficultyLevel in the response.
- Do not generate recurringStartDate or recurring_start_date.
- The user will choose the recurring start date later in the UI.
- The agent should only suggest recurringType, recurring amount, and end period.

OUTPUT JSON SCHEMA:
{
  "suggestedGoalAmount": {
    "amount": 0,
    "reason": ""
  },
  "contributionRatioSuggestion": {
    "childContributionPercentage": 0,
    "parentContributionPercentage": 0,
    "childContributionAmount": 0,
    "parentContributionAmount": 0,
    "reason": ""
  },
  "endPeriodSuggestion": {
    "durationValue": 0,
    "durationUnit": "days",
    "reason": ""
  },
  "recurringTargetSuggestion": {
    "recurringType": "weekly",
    "amount": 0,
    "reason": ""
  },
  "milestoneRewardSuggestions": [
    {
      "targetAmount": 0,
      "milestoneLabel": "",
      "rewardSuggestion": "",
      "reason": ""
    }
  ],
  "summary": ""
}`;
}

async function generateWithGemini(payload: PlannerInput): Promise<{ plan: PlannerOutput; rawResponse: string; prompt: string }> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';
  const prompt = buildGeminiPrompt(payload);

  if (!apiKey) {
    const plan = buildLocalPlan(payload);
    return { plan, rawResponse: JSON.stringify(plan), prompt };
  }

  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini request failed (${response.status})`);
  }

  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== 'string') {
    throw new Error('Gemini returned empty content');
  }

  const parsed = JSON.parse(text);
  const normalized = normalizeOutput(parsed);
  if (!isOutputValid(normalized)) {
    throw new Error('Gemini response failed schema validation');
  }

  return { plan: normalized, rawResponse: text, prompt };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return fail('invalid_input', 'Only POST is allowed.');
  }

  try {
    const payload = (await req.json()) as PlannerInput;
    if (!isInputValid(payload)) {
      return fail('invalid_input', 'Missing or invalid required fields.');
    }

    const idempotencyKey = payload.idempotencyKey?.trim();
    let prompt = `GoalPlanner|${PROMPT_VERSION}|${JSON.stringify(payload)}`;

    if (idempotencyKey) {
      const existing = await getIdempotentResponse(idempotencyKey);
      if (existing) {
        const cachedPlan = existing as PlannerResponse;
        await insertAiLog(
          payload,
          cachedPlan,
          `${prompt}|idempotent_cache_hit`,
          JSON.stringify(existing),
        );
        return new Response(JSON.stringify(existing), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }
    }

    let plan: PlannerOutput;
    let rawResponse = '';
    try {
      const generated = await generateWithGemini(payload);
      plan = generated.plan;
      rawResponse = generated.rawResponse;
      prompt = generated.prompt;
    } catch (error) {
      if ((error as Error).message.includes('schema validation')) {
        return fail('schema_invalid', (error as Error).message, 422);
      }
      plan = buildLocalPlan(payload);
      rawResponse = JSON.stringify(plan);
    }

    const normalizedPlan = normalizeOutput(plan);
    if (!isOutputValid(normalizedPlan)) {
      return fail('schema_invalid', 'Output validation failed.', 422);
    }

    const responsePayload: PlannerResponse = {
      ...normalizedPlan,
      promptVersion: PROMPT_VERSION,
    };

    if (idempotencyKey) {
      const requestHash = await sha256Hex(JSON.stringify(payload));
      await persistIdempotency({ idempotencyKey, requestHash, payload, plan: responsePayload });
    }

    await insertAiLog(payload, responsePayload, prompt, rawResponse);

    return new Response(JSON.stringify(responsePayload), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    const message = (error as Error).message.toLowerCase();
    if (message.includes('timeout')) {
      return fail('agent_timeout', 'Agent request timed out.', 504);
    }
    return fail('service_unavailable', `Failed to generate plan: ${(error as Error).message}`, 500);
  }
});
