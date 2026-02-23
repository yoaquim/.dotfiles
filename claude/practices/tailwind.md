# Tailwind CSS

Preferred patterns for Tailwind CSS.

## Core Rule

**No custom CSS. Ever.** No `<style>` blocks, no custom classes, no CSS files. Tailwind utilities directly in markup. If you think you need custom CSS, you don't — Tailwind can do it.

## Approach

- Utility-first: compose styles from utility classes
- Mobile-first: base styles for mobile, `md:` / `lg:` for larger screens
- Add `transition-colors` on interactive elements for hover effects
- Use standard Tailwind spacing scale (`p-4`, `mb-6`, `gap-3`, etc.)

## Component Patterns

### Cards
```html
<div class="rounded-lg p-6 border border-gray-200 shadow-sm">
  <h2 class="text-xl font-semibold mb-2">Title</h2>
  <p class="text-gray-600">Content</p>
</div>
```

### Buttons
```html
<!-- Primary -->
<button class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded font-medium transition-colors">
  Action
</button>

<!-- Secondary -->
<button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 border border-gray-300 rounded font-medium transition-colors">
  Cancel
</button>
```

### Form Inputs
```html
<input class="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors" />
```

## Dark Mode

Use `dark:` variants. Define color scheme in project's `tailwind.config` or CSS variables — don't hardcode dark colors in utilities unless the project is dark-only.

## Project-Specific Colors

Define custom colors in the project's Tailwind config, not in practices. Reference them as `bg-brand`, `text-brand`, etc. Each project's CLAUDE.md should document its color palette.
