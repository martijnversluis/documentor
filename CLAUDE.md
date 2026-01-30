# Documentor - Project Instructions

## After View Changes

Always run Tailwind rebuild after making changes to views that add new Tailwind classes:

```bash
bin/rails tailwindcss:build
```

## Turbo

Use Turbo Streams for form submissions instead of disabling Turbo with `data: { turbo: false }`. Create proper turbo_stream response templates.
