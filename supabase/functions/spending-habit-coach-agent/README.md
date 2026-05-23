# Spending Habit Coach Agent Function

## Deploy

```bash
supabase functions deploy spending-habit-coach-agent
```

## Invoke from Flutter

- Function name: `spending-habit-coach-agent`
- Body: payment review request JSON
- Returns: strict payment coach JSON or `{ error: { code, message } }`
