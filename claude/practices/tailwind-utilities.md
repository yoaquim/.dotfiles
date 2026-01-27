Use Tailwind CSS v4 utility classes following the Rimas design system.

## Rimas Color Palette

### Background Colors
```html
bg-rimas-black        <!-- #1a1a1a - Header, dark panels -->
bg-rimas-darker       <!-- #0f0f0f - Body background -->
bg-rimas-panel        <!-- #2a2a2a - Cards, panels -->
bg-rimas-border       <!-- #3a3a3a - Borders -->
```

### Primary Accent (Red)
```html
bg-rimas-red          <!-- #E31C23 - Primary buttons, links -->
hover:bg-rimas-red-hover    <!-- #ff2730 - Hover state -->
active:bg-rimas-red-active  <!-- #c01a1f - Active/pressed -->
```

### Text Colors
```html
text-rimas-text              <!-- #ffffff - Primary text -->
text-rimas-text-secondary    <!-- #cccccc - Secondary text -->
text-rimas-text-muted        <!-- #999999 - Muted/disabled -->
```

## Common UI Patterns

### Card Component
```html
<div class="bg-rimas-panel rounded-lg p-6 border border-rimas-border shadow-lg">
  <h2 class="text-2xl font-semibold mb-4">Title</h2>
  <p class="text-rimas-text-secondary">Content</p>
</div>
```

### Primary Button
```html
<button class="px-4 py-2 bg-rimas-red hover:bg-rimas-red-hover text-white rounded font-medium transition-colors">
  Action
</button>
```

### Secondary Button
```html
<button class="px-4 py-2 bg-rimas-panel hover:bg-white/[0.05] text-white border border-rimas-border rounded font-medium transition-colors">
  Cancel
</button>
```

### Link
```html
<a href="#" class="text-rimas-red hover:text-rimas-red-hover transition-colors">
  Link Text
</a>
```

### Table Pattern
```html
<table class="w-full border-collapse">
  <thead>
    <tr class="bg-rimas-black">
      <th class="px-4 py-3 text-left font-semibold">Header</th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-t border-rimas-border hover:bg-white/[0.03] transition-colors">
      <td class="px-4 py-3">Data</td>
    </tr>
  </tbody>
</table>
```

### Form Input
```html
<input
  type="text"
  class="w-full px-4 py-2 bg-rimas-panel border border-rimas-border rounded text-white focus:outline-none focus:border-rimas-red transition-colors"
/>
```

## Typography
- **Font**: Public Sans (300, 400, 500, 600, 700)
- **Base Size**: 16px (1rem)
- Use `font-medium` or `font-semibold` for emphasis

## ⛔ CRITICAL: NO CUSTOM CSS - EVER

**NEVER write custom CSS classes or `<style>` blocks. This is NON-NEGOTIABLE.**

### ❌ FORBIDDEN:
```html
<style>
.my-class { ... }  /* NO! */
.queue-item { ... }  /* NO! */
</style>
```

### ✅ REQUIRED - Tailwind utilities directly in HTML:
```html
<div class="bg-white p-4 border-b border-gray-200">...</div>
```

**If you think you need custom CSS, you're wrong. Tailwind can do it.**

## Other Rules
- **Mobile-first** - Use responsive prefixes: `md:`, `lg:`
- **Transitions** - Add `transition-colors` for hover effects
- **Spacing** - Use standard Tailwind spacing: `p-4`, `mb-6`, etc.

## Build Process
Tailwind v4 rebuilds automatically in Docker:
```bash
docker compose up web  # Watches for changes
```

See `.agent/SOP/tailwind-development.md` for detailed patterns.
