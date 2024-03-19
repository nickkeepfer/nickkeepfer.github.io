function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function hfun_pub()
    read(`pandoc -f markdown+yaml_metadata_block+citations+raw_html _assets/pub.md --citeproc --csl=_assets/ieee.csl --bibliography=_assets/mypapers.bib --mathjax`, String)
end


function hfun_thumbnails()
    # Assuming fixed content for demonstration; for dynamic content, modify accordingly.
    images = "/assets/" .* ["logo.png", "logo.png", "logo.png", "logo.png"]
    titles = [
        "Machine Learning",
        "Quantum Vortices",
        "Quantum Droplets",
        "Other",
    ]
    texts = [
        "Machine Learning projects",
        "Projects focusing on quantum vortex dynamics",
        "Projects focused on Quantum Droplets",
        "Other",
    ]
    times = ["9 mins", "5 mins", "15 mins", "9 mins"]

    links = ["/myprojects/machinelearning/","/myprojects/quantumvortices/","/myprojects/quantumdroplets/","/myprojects/other/"] 

    generated_html = """
    <div class=\"card-columns\">"""

    for i in 1:length(images)
        generated_html *= """
        <div class=\"card shadow-sm\">
          <img src=\"$(images[i])\" class=\"card-img-top\" alt=\"...\">
          <div class=\"card-body\">
          <h5 class=\"card-title\">$(titles[i])</h5>
            <p class=\"card-text\">$(texts[i])</p>
            <div class=\"d-flex justify-content-between align-items-center\">
              <div class=\"btn-group\">
              <a href=\"$(links[i])\" role=\"button\" class=\"btn btn-primary\">View</a>
              </div>
              <small class=\"text-muted\">$(times[i])</small>
            </div>
          </div>
        </div>
        """
    end

    generated_html *= """
    </div>
    """
    
    return generated_html
end


function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

function html_docstring(fname)
    doc = Base.doc(getfield(Makie, Symbol(fname)))
    body = Markdown.html(doc)

    # body = fd2html(replace(txt, raw"$" => raw"\$"), internal = true)

    return """
    <div class="docstring">
    <div class="doc-header" id="$fname">
    <a href="#$fname">$fname</a>
    </div>
    <div class="doc-content">$body</div>
    </div>
    """
end

function env_showhtml(com, _)
    content = Franklin.content(com)
    lang, ex_name, code = Franklin.parse_fenced_block(content, false)
    name = "example_$(hash(code))"
    str = """
    ```julia:$name
    using Makie.LaTeXStrings: @L_str # hide
    __result = begin # hide
        $code
    end # hide
    println("~~~") # hide
    show(stdout, MIME"text/html"(), __result) # hide
    println("~~~") # hide
    nothing # hide
    ```
    \\textoutput{$name}
    """
    return str
end

function env_examplefigure(com, _)
    content = Franklin.content(com)
    lang, ex_name, code = Franklin.parse_fenced_block(content, false)
    if lang != "julia"
        error("Code block needs to be julia. Found: $(lang), $(typeof(lang))")
    end

    kwargs = eval(Meta.parse("Dict(pairs((;" * Franklin.content(com.braces[1]) * ")))"))

    hash_8 = repr(hash(content))[3:10]
    name = pop!(kwargs, :name, "example_" * hash_8)
    svg = pop!(kwargs, :svg, false)

    rest_kwargs_str = join(("$key = $(repr(val))" for (key, val) in kwargs), ", ")

    pngfile = "$name.png"
    svgfile = "$name.svg"

    # add the generated png name to the list of examples for this page, which
    # can later be used to assemble an overview page
    # for some reason franklin needs a pair as the content?
    pngsvec, _ = get!(Franklin.LOCAL_VARS, "examplefigures_png", String[] => Vector{String})
    push!(pngsvec, pngfile)

    str = """
    ```julia:$name
    using Makie.LaTeXStrings: @L_str                       # hide
    __result = begin                                       # hide
        $code
    end                                                    # hide
    sz = size(Makie.parent_scene(__result))                # hide
    open(joinpath(@OUTPUT, "$(name)_size.txt"), "w") do io # hide
        print(io, sz[1], " ", sz[2])                       # hide
    end                                                    # hide
    save(joinpath(@OUTPUT, "$pngfile"), __result; px_per_unit = 2, pt_per_unit = 0.75, $rest_kwargs_str) # hide
    $(svg ? "save(joinpath(@OUTPUT, \"$svgfile\"), __result; px_per_unit = 2, pt_per_unit = 0.75, $rest_kwargs_str)" : "") # hide
    nothing # hide
    ```
    ~~~
    <a id="$name">
    ~~~
    {{examplefig $name.$(svg ? "svg" : "png")}}
    ~~~
    </a>
    ~~~
    """
    return str
end

# this function inserts an image generated within `env_examplefigure` and annotates
# the img tag with the size of the source figure, which it reads from a text file that
# `env_examplefigure` writes into the output folder when running the code.
# this is a bit convoluted but we don't have direct access to Franklin's code running mechanism.
# Maybe in the future, it wouldn't be too hard to just run the code ourselves from within `env_examplefigure`
# and then we could use the resulting size directly
@delay function hfun_examplefig(params)
    if length(params) != 1
        error("\\examplefig needs exactly one argument, got $params")
    end
    filename = only(params)
    name, ext = splitext(filename)

    file_location = locvar("fd_rpath")
    pathparts = split(file_location, r"\\|/")
    relative_site_path, _ = splitext(joinpath(pathparts))
    relative_asset_path = joinpath("assets", relative_site_path, "code", "output")
    asset_path = joinpath(Franklin.path(:site), relative_asset_path)
    size_file = joinpath(asset_path, name * "_size.txt")
    width, height = parse.(Int, split(read(size_file, String)))
    relative_figure_path = joinpath(relative_asset_path, filename)
    
    """
    <img width="$width" height="$height" src="/$relative_figure_path">
    """
end


