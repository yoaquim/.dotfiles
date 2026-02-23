# React

Preferred patterns for React projects.

## Components

- Functional components only — no class components
- One component per file, named export matching filename
- Props destructured in function signature
- Keep components small — extract when a component does more than one thing

```tsx
export function UserCard({ name, email, onEdit }: UserCardProps) {
  return (
    <div>
      <h3>{name}</h3>
      <p>{email}</p>
      <button onClick={onEdit}>Edit</button>
    </div>
  )
}
```

## State

- `useState` for local UI state
- `useReducer` for complex state with multiple transitions
- Lift state to nearest common ancestor, not higher
- Avoid prop drilling beyond 2 levels — use context or composition

## Effects

- `useEffect` only for synchronization with external systems (API calls, subscriptions, DOM manipulation)
- Not for derived state — compute during render instead
- Always specify dependency arrays
- Clean up subscriptions and timers in the return function

## Custom Hooks

- Extract reusable logic into `use*` hooks
- One concern per hook
- Return the minimal API needed

## Data Fetching

- Prefer dedicated libraries (React Query / TanStack Query, SWR) over raw `useEffect` + `fetch`
- Handle loading, error, and empty states explicitly
- Cache and deduplicate requests

## TypeScript

- Define prop types as interfaces or types, not inline
- Use `React.FC` sparingly — prefer explicit return types or none
- Discriminated unions for component variants

## File Structure

```
src/
├── components/     # Shared/reusable components
├── hooks/          # Custom hooks
├── pages/          # Route-level components
├── utils/          # Pure utility functions
└── types/          # Shared type definitions
```

## Testing

- React Testing Library, not Enzyme
- Test behavior (what the user sees/does), not implementation
- `screen.getByRole` / `getByText` over `getByTestId`
- Mock API calls, not components
