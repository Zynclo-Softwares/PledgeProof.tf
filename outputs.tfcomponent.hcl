# Stack outputs are temporarily removed during the railway state reset: the
# `removed` block in components.tfcomponent.hcl means `component.railway` is not
# declared right now, so outputs that reference it would be invalid. These are
# restored in the same commit that re-adds the `component "railway"` block.
