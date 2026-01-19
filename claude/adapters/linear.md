# Linear Adapter

**System**: Linear
**MCP Tools**: `mcp__linear__*` (Linear MCP server required)
**Status**: Placeholder - Not yet implemented

This adapter will create issues in Linear for feature task breakdown.

---

## Prerequisites

- Linear MCP server running and configured
- Linear API key configured
- Team/project exists in Linear
- Feature document exists at `.agent/features/NNN-name/README.md`

---

## Implementation Status

This adapter is a **placeholder** for future implementation.

### To Implement

1. **check_prerequisites()**
   - Verify Linear MCP connection
   - List teams/projects
   - Confirm user has create permissions

2. **parse_feature(feature_arg)**
   - Standard feature parsing (same as other adapters)
   - See `interface.md` for details

3. **plan_tasks(feature)**
   - Similar to local adapter
   - Create task breakdown with Linear-compatible metadata
   - Map levels to Linear priorities or labels

4. **create_tasks(tasks, project_id)**
   - Create Linear issues via MCP
   - Set up parent-child relationships or dependencies
   - Apply labels for task levels (Level 0, Level 1, etc.)
   - Link issues to feature document

5. **report_completion(results)**
   - List created Linear issues with URLs
   - Show dependency relationships
   - Provide next steps

---

## Linear-Specific Considerations

### Issue Hierarchy

Linear supports:
- **Projects**: Container for related issues
- **Issues**: Individual work items
- **Sub-issues**: Nested under parent issues

**Mapping strategy:**
- Feature → Linear Project or Parent Issue
- Level 0 tasks → Issues with "Setup" label
- Level 1+ tasks → Issues with "Implementation" label
- Dependencies → Linear's blocking relationships

### Labels

Create/use labels for:
- `level-0`, `level-1`, `level-2`, etc.
- `feature-{num}` for grouping
- `dependencies`, `implementation`, `testing`

### Estimates

Map task points to Linear estimates:
- 1 point → 1 (small)
- 2 points → 2 (medium)

### Workflow States

Map to Linear states:
- Planned → Backlog
- In Progress → In Progress
- Testing → In Review
- Complete → Done

---

## Future MCP Tools (Expected)

```
mcp__linear__list_teams
mcp__linear__list_projects
mcp__linear__create_issue
mcp__linear__update_issue
mcp__linear__add_comment
mcp__linear__set_parent
mcp__linear__add_label
```

---

## Contributing

To implement this adapter:

1. Ensure Linear MCP server is available
2. Test MCP tool availability
3. Implement each contract phase following `interface.md`
4. Add integration tests
5. Update this placeholder with full implementation
6. Update `interface.md` adapter table

---

## Temporary Workaround

Until this adapter is implemented, you can:

1. Use `/plan local 001` to create local task documents
2. Manually create Linear issues from the task documents
3. Or use Linear's import features if available
