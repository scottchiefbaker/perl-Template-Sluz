# Template::Sluz — Agent Guide

## Build & test
```sh
perl Makefile.PL
make
make test
```

Or skip Makefile and run tests directly (faster):

```sh
perl -lrf
```

## Key facts
- Single-file CPAN-style Perl module: `lib/Template/Sluz.pm` (963 lines, zero deps)
- Smarty-like `{...}` template syntax; `{$var}`, `{if}`, `{foreach}`, `{include}`, modifiers via `|`, comments `{* *}`
- Requires Perl 5.16+; no CPAN prereqs at runtime (only `Test::More` for testing)
- Module version in `$VERSION` at `Sluz.pm:27`

## Testing quirks
- Single test file `t/tests.t` (409 lines, uses `Test::More`)
- Test helper functions injected into `Template::Sluz` namespace via `BEGIN` block (line 16-23)
- Test sets `$sluz->{php_file_dir}` manually (line 52) — needed for template file resolution
- Template files live in `t/tpls/` (test fixtures) and `tpls/` (examples)
- Several tests wrapped in `local $TODO = "..."` blocks — features not yet implemented (PHP bracket syntax, chaining modifiers, negated hash lookup)
- `sluz_test()` and `sluz_fetch_test()` are custom test helpers; check their definitions before adding new tests

## Architecture notes
- `fetch(file, [parent])` — main entry point; also aliased as `parse()` and `display()` (prints output)
- `parse_string(string)` — parse a template string directly
- `parent_tpl(path)` — set parent template for inheritance
- Template inheritance: pass `child_file, parent_file` to `fetch()`, or set `parent_tpl()` beforehand
- Modifiers call any Perl built-in or function in the `Template::Sluz` namespace
- `$__FOREACH_FIRST`, `$__FOREACH_LAST`, `$__FOREACH_INDEX` available in foreach loops
- `$__CHILD_TPL` variable available in parent templates for inheritance

## Code conventions
- Uses `use constant SLUZ_INLINE => 'INLINE_TEMPLATE'` for inline template loading
- Private methods prefixed with `_` (underscore)
- `croak` for error reporting with numeric error codes
- No strict refs used in modifier dispatch (`no strict 'refs'` in a small block)
