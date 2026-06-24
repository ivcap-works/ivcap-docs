# Pending Fixes

Items that are blocked on upstream repo changes. Once the listed repo(s) have been
updated, re-run `make fetch-examples` (or equivalent) and ask Cline to verify.

---

## 1. Migrate example READMEs from `jschema` to `@with_schema`

**Status:** Upstream repos not yet updated
**Affects:** Three fetched examples in `content/examples/` and `docs/content/examples/`

`@with_schema` (imported from `ivcap_service`) is the preferred modern way to
attach a schema URN to a Pydantic model. The old pattern:

```python
# OLD — deprecated, still works but not preferred
class Request(BaseModel):
    jschema: str = Field("urn:sd:schema:my-service.request.1", alias="$schema")
    ...
```

should be replaced with:

```python
# NEW — preferred
from ivcap_service import with_schema

@with_schema("urn:sd:schema:my-service.request.1")
class Request(BaseModel):
    ...
```

### Repos to update

| Example slug | GitHub repo | File(s) to update |
|---|---|---|
| `ai-tool-template` | [`ivcap-works/ivcap-python-ai-tool-template`](https://github.com/ivcap-works/ivcap-python-ai-tool-template) | `README.md` |
| `gene-ontology-mapper` | [`ivcap-works/gene-onology-term-mapper`](https://github.com/ivcap-works/gene-onology-term-mapper) | `README.md` |
| `markdown-conversion` | [`ivcap-works/ivcap-markdown-conversion-service`](https://github.com/ivcap-works/ivcap-markdown-conversion-service) | `README.md` |

### What to do once repos are updated

1. Re-fetch content (e.g. `make fetch-examples` or run `scripts/fetch_examples.py`)
2. Ask Cline: _"The three example repos from PENDING_FIXES.md have been updated —
   please verify the fetched `index.md` files now use `@with_schema` and the build is clean"_

---

*Created: 2026-06-25*
