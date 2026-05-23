-- Goal Planner Agent v3 rollout
-- Safe additive migration:
-- 1. expands tabung_type enum with the new planner-facing categories
-- 2. documents the v3 AI payload contract in schema comments

alter type public.tabung_type add value if not exists 'electronic device';
alter type public.tabung_type add value if not exists 'food';
alter type public.tabung_type add value if not exists 'growth fund';
alter type public.tabung_type add value if not exists 'sport and art';

comment on table public.ai_logs is
'Stores AI agent prompts and responses. Goal Planner Agent v3 uses early-flow input (userRole, tabungType, tabungName, tabungDescription) and stores a normalized structured response.';

comment on column public.tabung_goals.ai_plan is
'Full Goal Planner Agent response JSON. Goal Planner Agent v3 shape includes suggestedGoalAmount, contributionRatioSuggestion, endPeriodSuggestion, recurringTargetSuggestion, milestoneRewardSuggestions, summary, and promptVersion.';

comment on column public.tabung_goals.ai_plan_summary is
'Human-readable summary from Goal Planner Agent output.';

comment on column public.tabung_goals.period_suggestion_months is
'Legacy month-oriented period field. Goal Planner Agent v3 may use endPeriodSuggestion.durationUnit other than months; month values are only populated when applicable.';

comment on column public.tabung_goals.suggested_deadline is
'Derived deadline date used by the app after combining end period suggestion with user-confirmed schedule details.';

comment on column public.milestones.reward_description is
'Reward suggestion text. Goal Planner Agent v3 milestone payload includes rewardSuggestion per milestone.';
