# Default implementation forcing specific definitions of interface methods

struct MissingImplementationError <: Exception
    method::Symbol
    whatfor::String
end

Base.showerror(io::IO, e::MissingImplementationError) =
    print(io, "$(e.method) need to be implemented for $(e.whatfor).")


"""
    bisect(::BPSearch, elem)

Return two new elements built by bisecting `elem`.

Returned elements must have the same type as the bisected element.

Must be implemented by the user for custom search types, default implementation
throw a `MissingImplementationError`.
"""
bisect(::BPSearch, elem) = throw(MissingImplementationError(:bisect, "custom search types"))


"""
    get_leaf_id!(::BPSearch, wt::BPTree)

Return the `id` of the next leaf that must be processed and remove this leaf
from the list of working leaves of the working tree `wt`.
"""
get_leaf_id!(::BPSearch, wt) = throw(MissingImplementationError(:get_leaf_id, "custom search types"))


"""
    insert_leaf!(::BPSearch, wt::BPTree, leaf::BPLeaf)

Insert a leaf in the list of working leaves in the tree `wt`.

Must be implemented by the user for custom search types, default implementation
throw a `MissingImplementationError`.
"""
insert_leaf!(::BPSearch, wt) = throw(MissingImplementationError(:insert_leaf!, "custom search types"))


"""
    keyfunc(::KeyBPSearch, elem)

Return the key associated with element `elem` for a `KeyBPSearch`.

The `KeyBPSearch` processes elements with the largest key first.

Must be implemented by the user, default implementation throw a
`MissingImplementationError`.
"""
keyfunc(::KeyBPSearch, elem) = throw(MissingImplementationError(:keyfunc, "KeyBPSearch"))


"""
    process(::BPSearch, elem)`

Return a symbol representing the action to perform with the element `elem` and
an object (of the same type) representing the state of the element after
processing (may return `elem` unchanged).

# Valid symbols returned by the process function
  - `:store`: the element is considered as final and is stored, it will not be
        further processed
  - `:bisect`: the element is bisected and each of the two resulting part will
        be processed
  - `:discard`: the element is discarded from the tree, allowing to free memory

Must be implemented by the user for custom search types, default implementation
throw a `MissingImplementationError`.
"""
process(::BPSearch, wt) = throw(MissingImplementationError(:process, "custom search types"))