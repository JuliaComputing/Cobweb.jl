#-----------------------------------------------------------------------------# HTMLTokenIterator
@enum(TokenType,
    UNKNOWNTOKEN,           # ???
    DOCTYPETOKEN,               # <!DOCTYPE ...>
    COMMENTTOKEN,           # <!-- ... -->
    ELEMENTTOKEN,           # <NAME attributes... >
    ELEMENTSELFCLOSEDTOKEN, # <NAME attributes... />
    ELEMENTCLOSETOKEN,      # </NAME>
    TEXTTOKEN               # text between a '>' and a '<'
)


mutable struct HTMLTokenIterator{IOT <: IO}
    io::IOT
    start_pos::Int64  # position(io) always returns Int64?
    buffer::IOBuffer
end
HTMLTokenIterator(io::IO) = HTMLTokenIterator(io, position(io), IOBuffer())

readchar(o::HTMLTokenIterator) = (c = Base.read(o.io, Char); write(o.buffer, c); c)
reset(o::HTMLTokenIterator) = seek(o.io, o.start_pos)

function readuntil(o::HTMLTokenIterator, char::Char)
    c = readchar(o)
    while c != char
        c = readchar(o)
    end
end
function readuntil(o::HTMLTokenIterator, pattern::String)
    chars = collect(pattern)
    last_chars = similar(chars)
    while last_chars != chars
        for i in 1:(length(chars) - 1)
            last_chars[i] = last_chars[i+1]
        end
        last_chars[end] = readchar(o)
    end
end

function Base.iterate(o::HTMLTokenIterator, state=0)
    state == 0 && seek(o.io, o.start_pos)
    pair = next_token(o)
    isnothing(pair) ? nothing : (pair, state+1)
end

function next_token(o::HTMLTokenIterator)
    io = o.io
    buffer = o.buffer
    skipchars(isspace, io)
    eof(io) && return nothing
    foreach(_ -> readchar(o), 1:3)
    s = String(take!(buffer))
    skip(io, -3)
    pair = if startswith(s, "<!D") || startswith(s, "<!d")
        readuntil(o, '>')
        DOCTYPETOKEN => String(take!(buffer))
    elseif startswith(s, "<!-")
        readuntil(o, "-->")
        COMMENTTOKEN => String(take!(buffer))
    elseif startswith(s, "</")
        readuntil(o, '>')
        ELEMENTCLOSETOKEN => String(take!(buffer))
    elseif startswith(s, "<")
        readuntil(o, '>')
        s = String(take!(buffer))
        t = endswith(s, "/>") ? ELEMENTSELFCLOSEDTOKEN : ELEMENTTOKEN
        t => s
    else
        readuntil(o, '<')
        skip(io, -1)
        TEXTTOKEN => unescape(String(take!(buffer)[1:end-1]))
    end
    return pair
end


Base.eltype(::Type{<:HTMLTokenIterator}) = Pair{TokenType, String}

Base.IteratorSize(::Type{<:HTMLTokenIterator}) = Base.SizeUnknown()

Base.isdone(itr::HTMLTokenIterator, state...) = eof(itr.io)

#-----------------------------------------------------------------------------# read
read(path::AbstractString) = open(io -> read(HTMLTokenIterator(io)), path, "r")

function read(o::HTMLTokenIterator)
    siblings = []
    for (T, s) in o
        if T == DOCTYPETOKEN
            push!(siblings, Doctype())
        elseif T == COMMENTTOKEN
            push!(siblings, make_comment(s))
        elseif T == ELEMENTSELFCLOSEDTOKEN
            node = make_node(s)
            push!(siblings, node)
        elseif T == ELEMENTTOKEN
            node = make_node(s)
            add_children!(node, o, "</$(tag(node))>")
            push!(siblings, node)
        else
            error("should be unreachable: T=$T, s=$s")
        end
    end
    return siblings
end

function add_children!(node::Node, o::HTMLTokenIterator, until::String)
    s = ""
    c = children(node)
    while s != until
        next = iterate(o, -1)  # if state == 0, io will get reset to original position
        isnothing(next) && break
        T, s = next[1]
        if T == COMMENTTOKEN
            push!(c, Comment(replace(s, "<!-- " => "", " -->" => "")))
        elseif T == ELEMENTSELFCLOSEDTOKEN
            push!(c, make_node(s))
        elseif T == ELEMENTTOKEN
            node = make_node(s)
            add_children!(node, o, "</$(tag(node))>")
            push!(c, node)
        elseif T == TEXTTOKEN
            push!(c, s)
        end
    end
end

make_node(s) = Node(get_tag(s), get_attributes(s), [])

get_tag(x) = Symbol(x[findfirst(r"[a-zA-z][^\s>/]*", x)])

function get_attributes(x)
    out = OrderedDict{Symbol,String}()
    rng = findfirst(r"(?<=\s).*\"", x)
    isnothing(rng) && return out
    s = x[rng]
    kys = (m.match for m in eachmatch(r"[a-zA-Z][a-zA-Z\.-_]*(?=\=)", s))
    vals = (m.match for m in eachmatch(r"(?<=(\=\"))[^\"]*", s))
    foreach(zip(kys,vals)) do (k,v)
        out[Symbol(k)] = v
    end
    out
end
