# Goal Planner Agent Function

## Deploy

```bash
supabase functions deploy goal-planner-agent
```

## Invoke from Flutter

- Function name: `goal-planner-agent`
- Body: GoalPlannerInput JSON with `idempotencyKey`
- Returns: strict GoalPlannerOutput JSON or `{ error: { code, message } }`

## Error Codes

- `invalid_input`
- `agent_timeout`
- `schema_invalid`
- `service_unavailable`
