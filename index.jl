### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 90cbbc18-9485-4f22-8b19-bd4e0b259873
## Header designed by Fons van der Plas :)

html"""
<div style="
position: absolute;
width: calc(100% - 30px);
border: 50vw solid hsl(15deg 80% 85%);
border-top: 500px solid hsl(15deg 80% 85%);
border-bottom: none;
box-sizing: content-box;
left: calc(-50vw + 15px);
top: -500px;
height: 200px;
pointer-events: none;
"></div>
<div style="
height: 200px;
width: 100%;
background: hsl(15deg 80% 85%);
color: #fff;
padding-top: 10px;
">
<span style="
font-family: Vollkorn, serif;
font-weight: 700;
font-feature-settings: 'lnum', 'pnum';
"> 
<p style="text-align: center; font-size: 2rem; background: hsl(344deg 29% 63%); border-radius: 20px; margin-block-end: 0px; margin-left: 0.5em; margin-right: 0.5em;">
The influence of subjectivity on adjective order
</p>
<p style="text-align: center; font-size: 2rem; color: #1f2a4896; margin-top: 0px;">
<em>Repository index</em>
</p>
</div>
<style>
body {
overflow-x: hidden;
}
</style>
"""

# ╔═╡ 3ab2051a-c6e3-4443-a516-2331de77bb92
md"""
This page serves as a table of contents for the files in the repository for my thesis. Files with the 📖 icon are Pluto notebooks: the link leads to a static rendered version of the notebook. The 📘 is used for all other files, and the link leads to the github page of the file.

### Index
"""

# ╔═╡ df6800d9-6094-4779-b757-a946f6e10442
function format_link(text, url)
	"<a style=\"font-weight:normal; color: hsl(344deg 29% 50%); text-decoration: none\" href='$(url)'>$(text)</a>"
end ;

# ╔═╡ ac8b9f5c-a9f3-4c79-93bf-42707f3b8787
function format_notebook(path, filename)
	stripped_path = path[3:end] #remove "./"
	stripped_filename = filename[1:end-3] #remove ".jl"
	
	prefix = "https://lukavdplas.github.io/adjective-order/"
	suffix = ".html"
	
	url = prefix * stripped_path *  "/" * stripped_filename * suffix
	
	format_link("📖 " * filename, url)
end ;

# ╔═╡ 49b388ae-62f0-4166-8611-3bcadddbb4f6
function format_other_file(path, filename)
	stripped_path = path[3:end] #remove "./"
	
	prefix = "https://github.com/lukavdplas/adjective-order/blob/main/"
	
	url = prefix * stripped_path *  "/" * filename
	
	format_link("📘 " * filename, url)
end ;

# ╔═╡ 0ee61c5c-cde8-4d96-ad51-cf8ea2acf35a
function is_notebook(path, filename)
	if endswith(filename, ".jl")
		text = open(path * "/" * filename) do file
			read(file, String)
		end
		startswith(text, "### A Pluto.jl notebook ###")
	else
		false
	end
end ;

# ╔═╡ 6b726751-b760-4e43-b31c-1a39c2d41457
function format_directory(path)	
	root, dirs, files = (first ∘ walkdir)(path)
	
	directory = last(split(root, "/"))
	header = directory == "." ? "" : "<b>📁 $(directory)</b>"
	
	dir_representations = map(dirs) do dir
		if dir == ".git" || dir == ".github"
			""
		else
			"<li> " * format_directory(root * "/" * dir) * "</li>"
		end
	end
	
	dir_block = let
		items = join(dir_representations)
		"<ul style=\"list-style-type:disc\"> $(items)</ul>"
	end
	
	file_representations = map(files) do filename
		link = if is_notebook(path, filename)
			format_notebook(root, filename)
		else
			format_other_file(root, filename)
		end
		
		"<li> $(link)</li>"
	end
	
	file_block = let
		items = join(file_representations)
		"<ul style=\"list-style-type:circle\"> $(items) </ul>"
	end
	
	header * dir_block * file_block
end ;

# ╔═╡ 7d3f46d3-98c8-46b7-a8e3-dbe487ba1405
HTML(format_directory("."))

# ╔═╡ Cell order:
# ╟─90cbbc18-9485-4f22-8b19-bd4e0b259873
# ╟─3ab2051a-c6e3-4443-a516-2331de77bb92
# ╟─7d3f46d3-98c8-46b7-a8e3-dbe487ba1405
# ╟─ac8b9f5c-a9f3-4c79-93bf-42707f3b8787
# ╟─df6800d9-6094-4779-b757-a946f6e10442
# ╟─49b388ae-62f0-4166-8611-3bcadddbb4f6
# ╟─0ee61c5c-cde8-4d96-ad51-cf8ea2acf35a
# ╟─6b726751-b760-4e43-b31c-1a39c2d41457
