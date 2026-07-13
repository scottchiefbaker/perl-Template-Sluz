# Template::Sluz — Agent Guide

## Build & test
```sh
perl Makefile.PL
make
make test
```
No CPAN runtime prereqs; only `Test::More` for testing. Perl 5.16+.
Run one test file: `make test TEST_FILES=t/10-delimiters.t`

## Key facts
- Single-file CPAN-style module: `lib/Template/Sluz.pm` (~1730 lines)
- Smarty-like `{...}` template syntax: `{$var}`, `{if}`, `{foreach}`, `{include}`, modifiers via `|`, comments `{* *}`
- Version string lives at `lib/Template/Sluz.pm:27` (`our $VERSION`)

## Test structure
- 10 test files `t/01-main.t` … `t/10-delimiters.t`; `t/07-get_blocks.t` exercises the private `_get_blocks` tokenizer
- Shared setup in `t/test_setup.pl`: helpers `setup_sluz()`, `sluz_test()`, `sluz_fetch_test()`
- Every test does `require "$FindBin::Bin/test_setup.pl"` at the top; `setup_sluz()` sets `$sluz->{perl_file_dir}` for template-file resolution
- `sluz_test()` accepts a regex string wrapped in `/pattern/` as expected output
- Test helper functions (`truncate`, `join_comma`, `hello_world`, `return_false`, `return_null`) are injected into `main::` via a `BEGIN` block so templates can call them
- Fixtures in `t/tpls/` (`child.stpl`, `parent.stpl`, `extra.stpl`, `nested_inc.stpl`, `var_scope.stpl`); runnable examples in root `tpls/`

## Architecture
- `fetch(file, [parent])` — main entry; aliased as `parse()` and `display()` (the latter prints). Defaults to inline template (`SLUZ_INLINE`) if no args
- `parse_string(string)` — parse a string directly (no file); primary test entrypoint
- `set_delimiters($open, $close)` — switch delimiters off the default `{` `}` (one char each, must differ); affects later calls
- `parent_tpl(path)` / passing `child_file, parent_file` to `fetch()` — template inheritance; parent reads the child via `{$__CHILD_TPL}`
- `auto_escape => 1` on `new()` HTML-escapes all `{$var}`; use `|noescape` to emit raw, `|escape` explicitly (wins over auto to avoid double-escaping)
- Modifiers resolve: `main::` → `Template::Sluz` built-ins → `CORE::`; the template var is passed as first arg
- Expression blocks `{func()}` try `main::` first, then fall back to `Template::Sluz`
- In `{foreach}`: `$__FOREACH_FIRST`, `$__FOREACH_LAST`, `$__FOREACH_INDEX` are set; handles ARRAY and HASH refs (hash keys iterated in sorted order)
- All errors go through a central `croak` with numeric codes (`#18933`, `#45821`, `#73467`, etc.)

## Performance / benchmarking
Changes to `lib/Template/Sluz.pm` can regress parse speed — verify with `bench.pl` before and after:
```sh
perl bench.pl                 # all templates, 5000 iters each
perl bench.pl -n 20000        # more iterations for stable numbers
perl bench.pl --filter foreach  # run only matching benchmarks
```

## Code conventions
- `use constant SLUZ_INLINE => 'INLINE_TEMPLATE'` signals inline-template loading
- `use autouse 'Carp' => qw(croak)` — no explicit `use Carp`; `croak` reports errors with numeric codes
- Private methods are underscore-prefixed
- Modifier dispatch uses a localized `no strict 'refs'` block — don't tighten strictness around it
