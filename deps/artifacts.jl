using Dates, JSON3, ArtifactUtils

version = JSON3.read(read(download("https://api.github.com/repos/mdn/browser-compat-data/releases/latest"))).name

dir = mktempdir()
path = download("https://github.com/mdn/browser-compat-data/releases/download/$version/data.json", joinpath(dir, "data.json"))

artifact_id = artifact_from_directory(dir)
gist = upload_to_gist(artifact_id)
add_artifact!("Artifacts.toml", "mdn_data", gist; force=true)


# #-----------------------------------------------------------------------------# Cobweb.jl copies
# escape_chars = ('&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")

# escape(x::AbstractString) = replace(x, escape_chars...)
# unescape(x::AbstractString) = replace(x, reverse.(escape_chars)...)

# struct AttributeSpec
#     name::Symbol
#     is_deprecated::Bool
#     is_experimental::Bool
#     is_global::Bool
#     description::String
#     elements::Vector{Symbol}
# end
# struct ElementSpec
#     name::Symbol
#     is_deprecated::Bool
#     is_experimental::Bool
#     description::String
#     attributes::Vector{Symbol}
# end

# #-----------------------------------------------------------------------------# Scrape Attributes
# url_attrs = "https://raw.githubusercontent.com/mdn/content/refs/heads/main/files/en-us/web/html/attributes/index.md"
# url_global_attrs = "https://raw.githubusercontent.com/mdn/browser-compat-data/refs/heads/main/html/global_attributes.json"
# url_elements = "https://developer.mozilla.org/en-US/docs/Web/HTML/Element"
# url_css = "https://raw.githubusercontent.com/mdn/data/refs/heads/main/css/properties.json"

# path = download(url_attrs)
# path2 = download(url_elements)
# path3 = download(url_css)

# s = read(path, String)
# s2 = read(path2, String)

# s3 = read(path3, String)
# i = findfirst("<div class=\"index\">", s3).stop + 1
# s3 = s3[i:findnext("</div>", s3, i).start - 1]

# x = filter!(x -> !occursin(r"<th>", only(x)), collect(eachmatch(r"<tr>(.*?)</tr>", s)))
# x2 = filter!(x -> !occursin(r"<th>", only(x)), collect(eachmatch(r"<tr>(.*?)</tr>", s2)))
# x3 = collect(eachmatch(r"<li><a href(.*?)</a></li>", s3))

# process_css_match(m::RegexMatch) = Symbol(replace(only(m), r"(.*?)<code>" => "", r"\s.*" => "", r"</code>(.*?)" => ""))
# css_properties = process_css_match.(x3)

# function process_name_match(m::RegexMatch)
#     is_deprecated = occursin("Deprecated", only(m))
#     is_experimental = occursin("Experimental", only(m))
#     name = Symbol(replace(only(m),  r"(.*?)<code>"=>"", r"</code>(.*)" => "", "&lt;" => "", "&gt;" => "",
#                 r"<.*?>"=>""))
#     (;name, is_deprecated, is_experimental)
# end
# function process_description_match(m::RegexMatch)
#     unescape(String(strip(replace(only(m), r"<.*?>"=>"", "\\n" => "", "\\\"" => "\"", r"\s{2,}" => ' '))))
# end
# function process_elements_match(m::RegexMatch)
#     elements = Symbol.(only.(eachmatch(r"&lt;(.*?)&gt;", only(m))))
#     is_global = occursin("Global", only(m))
#     (; elements, is_global)
# end

# function AttributeSpec(m::RegexMatch)
#     m_name, m_elements, m_description = collect(eachmatch(r"<td>(.*?)</td>", only(m)))
#     name, is_deprecated, is_experimental = process_name_match(m_name)
#     description = process_description_match(m_description)
#     elements, is_global = process_elements_match(m_elements)
#     AttributeSpec(name, is_deprecated, is_experimental, is_global, description, elements)
# end

# function ElementSpec(m::RegexMatch)
#     m_name, m_description = collect(eachmatch(r"<td>(.*?)</td>", only(m)))
#     name, is_deprecated, is_experimental = process_name_match(m_name)
#     description = process_description_match(m_description)
#     ElementSpec(name, is_deprecated, is_experimental, description, [])
# end

# attrs = AttributeSpec.(x)
# elements = ElementSpec.(x2)

# i = findfirst(x -> x.name == :h6, elements)
# deleteat!(elements, i)

# h1 = ElementSpec(:h1, false, false, "The h1 element represents the highest level of a section heading.", [])
# h2 = ElementSpec(:h2, false, false, "The h2 element represents a section heading.", [])
# h3 = ElementSpec(:h3, false, false, "The h3 element represents a section heading.", [])
# h4 = ElementSpec(:h4, false, false, "The h4 element represents a section heading.", [])
# h5 = ElementSpec(:h5, false, false, "The h5 element represents a section heading.", [])
# h6 = ElementSpec(:h6, false, false, "The h6 element represents the lowest level of a section heading.", [])

# append!(elements, [h1, h2, h3, h4, h5, h6])



# for attr in attrs
#     for e in attr.elements
#         for element in elements
#             if element.name == e
#                 push!(element.attributes, attr.name)
#                 unique!(element.attributes)
#             end
#         end
#     end
# end

# GLOBAL_ATTRIBUTES = map(x -> x.name, filter(x -> x.is_global, attrs))


# open(joinpath(@__DIR__, "..", "src", "generated.jl"), "w") do io
#     println(io, """
#     # This file was generated by deps/generate.jl at $(Dates.now())
#     # Do not edit it manually
#     # Attribute data is scraped from: $url
#     # Element data is scraped from: $url_elements

#     const CSS_PROPERTIES = $css_properties

#     const GLOBAL_ATTRIBUTES = $GLOBAL_ATTRIBUTES

#     const ATTRIBUTES = sort(LittleDict{Symbol,AttributeSpec}(
#         $(["Symbol(\"$(attr.name)\") => $attr,\n    " for attr in attrs]...)
#     ))

#     const ELEMENTS = sort(LittleDict{Symbol,ElementSpec}(
#         $(["Symbol(\"$(el.name)\") => $el,\n    " for el in elements]...)
#     ))
#     """)
# end

# # struct AttributeSpec
# #     name::Symbol
# #     deprecated::Bool

# # end

# # struct Tag
# #     name::Symbol
# #     deprecated::Bool
# #     experimental::Bool
# #     attributes::Vector{Symbol}
