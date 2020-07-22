module GtkExtensions

# nice exports !
export show_iter,
    get_iter_at_position, text_view_window_to_buffer_coords, get_current_page_idx,
    set_current_page_idx, get_tab, set_position!, text_buffer_copy_clipboard, set_tab_label_text,
    MutableGtkTextIter, GtkTextIters,GtkEventBox, GtkCssProviderFromData!, GtkIconThemeAddResourcePath,
    GtkIconThemeGetDefault, index, style_css, text, PROPAGATE, INTERRUPT,
    end_iter, line_count,
    cursor_locations, gdk_window_get_origin, g_timeout_add, g_idle_add, delete_text, insert_text, insert,
    response, GdkKeySyms, offset, mutable, nonmutable, text_view_buffer_to_window_coords,
    line, show, scroll_to_iter, css_provider,
    push!, GtkCssProviderLeaf, GtkCssProvider, getbuffer, iter_nth_child, GtkIconThemeLoadIconForScale,
    expand_root, model, set_cursor_on_cell, expand, treepath, foreach, selection, selected, select_value

using Gtk

import ..Gtk: suffix, GtkCssProviderLeaf, GtkCssProvider
import Gtk: GtkTextIter, libgtk, iter_nth_child, selected
import Base: foreach, push!

const PROPAGATE = convert(Cint,false)
const INTERRUPT = convert(Cint,true)

import Gtk.GConstants: GdkModifierType
import Gtk.GdkKeySyms

include("MenuUtils.jl")

## TextIters

const MutableGtkTextIter = Gtk.GLib.MutableTypes.Mutable{GtkTextIter}
const GtkTextIters = Union{MutableGtkTextIter,GtkTextIter}
mutable(it::GtkTextIter) = Gtk.GLib.MutableTypes.mutable(it)

offset(it::GtkTextIters) = get_gtk_property(it,:offset,Integer)
line(it::GtkTextIters) = get_gtk_property(it,:line,Integer)+1#Gtk counts from zero
nonmutable(buffer::GtkTextBuffer,it::MutableGtkTextIter) = GtkTextIter(buffer,offset(it)+1)#this allows to convert to GtkTextBuffer without the -1 definition in Gtk.jl

getbuffer(it::GtkTextIter) = convert(GtkTextBuffer,
    ccall((:gtk_text_iter_get_buffer, libgtk),Ptr{GtkTextBuffer},(Ref{GtkTextIter},),it)
)
getbuffer(it::MutableGtkTextIter) = convert(GtkTextBuffer,
    ccall((:gtk_text_iter_get_buffer, libgtk),Ptr{GtkTextBuffer},(Ptr{GtkTextIter},),it)
)

function show_iter(it::MutableGtkTextIter,buffer::GtkTextBuffer,color::Int)
    Gtk.apply_tag(buffer, color > 0 ? "debug1" : "debug2",it, it+1)
end

function end_iter(buffer::Gtk.GtkTextBuffer)
    iter = Gtk.mutable(GtkTextIter)
    ccall((:gtk_text_buffer_get_end_iter,libgtk),Cvoid,(Ptr{Gtk.GObject},Ptr{GtkTextIter}),buffer,iter)
    return iter
end

line_count(buffer::GtkTextBuffer) = ccall((:gtk_text_buffer_get_line_count,libgtk),Cint,(Ptr{GObject},),buffer)

## TextView

get_iter_at_position(text_view::Gtk.GtkTextView,iter::MutableGtkTextIter,trailing,x::Int32,y::Int32) = ccall((:gtk_text_view_get_iter_at_position,libgtk),Cvoid,
	(Ptr{Gtk.GObject},Ptr{GtkTextIter},Ptr{Cint},Cint,Cint),text_view,iter,trailing,x,y)

function get_iter_at_position(text_view::Gtk.GtkTextView,x::Integer,y::Integer)
    buffer = get_gtk_property(text_view,:buffer,GtkTextBuffer)
    iter = mutable(GtkTextIter(buffer))
    get_iter_at_position(text_view::Gtk.GtkTextView,iter,C_NULL,Int32(x),Int32(y))
    return nonmutable(buffer,iter)
end

function text_view_window_to_buffer_coords(text_view::Gtk.GtkTextView,wintype::Integer,window_x::Integer,window_y::Integer)

	buffer_x = Gtk.mutable(Cint)
	buffer_y = Gtk.mutable(Cint)

	ccall((:gtk_text_view_window_to_buffer_coords,libgtk),Cvoid,
		(Ptr{Gtk.GObject},Cint,Cint,Cint,Ptr{Cint},Ptr{Cint}),text_view,Int32(wintype),window_x,window_y,buffer_x,buffer_y)

	return (buffer_x[],buffer_y[])
end
text_view_window_to_buffer_coords(text_view::Gtk.GtkTextView,window_x::Integer,window_y::Integer) = text_view_window_to_buffer_coords(text_view,2,window_x,window_y)

function text_view_buffer_to_window_coords(text_view::Gtk.GtkTextView,wintype::Integer,buffer_x::Integer,buffer_y::Integer)

	window_x = Gtk.mutable(Cint)
	window_y = Gtk.mutable(Cint)

	ccall((:gtk_text_view_buffer_to_window_coords,libgtk),Cvoid,
		(Ptr{Gtk.GObject},Cint,Cint,Cint,Ptr{Cint},Ptr{Cint}),text_view,Int32(wintype),buffer_x,buffer_y,window_x,window_y)

	return (window_x[],window_y[])
end
text_view_buffer_to_window_coords(text_view::Gtk.GtkTextView,buffer_x::Integer,buffer_y::Integer) = text_view_window_to_buffer_coords(text_view,0,buffer_x,buffer_y)

function cursor_locations(text_view::Gtk.GtkTextView)
    weak = Gtk.mutable(Gtk.GdkRectangle)
    strong = Gtk.mutable(Gtk.GdkRectangle)
    buffer = get_gtk_property(text_view,:buffer,GtkTextBuffer)
    iter = mutable( GtkTextIter(buffer, get_gtk_property(buffer,:cursor_position,Int)) )

    ccall((:gtk_text_view_get_cursor_locations,libgtk),Cvoid,(Ptr{Gtk.GObject},Ptr{GtkTextIter},Ptr{Gtk.GdkRectangle},Ptr{Gtk.GdkRectangle}),text_view,iter,strong,weak)
    return (iter,strong[],weak[])
end

scroll_to_iter(text_view::Gtk.GtkTextView,iter::GtkTextIter,within_margin::Number,use_align::Bool,xalign::Number,yalign::Number) = ccall((:gtk_text_view_scroll_to_iter,libgtk),Cint,
	(Ptr{Gtk.GObject},Ref{GtkTextIter},Cdouble,Cint,Cdouble,Cdouble),
    text_view,iter,within_margin,use_align,xalign,yalign)

scroll_to_iter(text_view::Gtk.GtkTextView,iter::MutableGtkTextIter,within_margin::Number,use_align::Bool,xalign::Number,yalign::Number) = ccall((:gtk_text_view_scroll_to_iter,libgtk),Cint,
	(Ptr{Gtk.GObject},Ptr{GtkTextIter},Cdouble,Cint,Cdouble,Cdouble),
    text_view,iter,within_margin,use_align,xalign,yalign)

scroll_to_iter(text_view::Gtk.GtkTextView,iter::GtkTextIters) = scroll_to_iter(text_view,iter,0.0,true,1.0,0.1)

# notebook
get_current_page_idx(notebook::Gtk.GtkNotebook) = ccall((:gtk_notebook_get_current_page,libgtk),Cint,
    (Ptr{Gtk.GObject},),notebook)+1
set_current_page_idx(notebook::Gtk.GtkNotebook,page_num::Int) = ccall((:gtk_notebook_set_current_page,libgtk),Cvoid,
    (Ptr{Gtk.GObject},Cint),notebook,page_num-1)

index(notebook::GtkNotebook) = get_current_page_idx(notebook)
index(notebook::GtkNotebook,i::Integer) = set_current_page_idx(notebook,i)
index(notebook::GtkNotebook, child::Gtk.GtkWidget) = pagenumber(notebook, child)+1

get_tab(notebook::Gtk.GtkNotebook,page_num::Int) = convert(Gtk.GtkWidget,ccall((:gtk_notebook_get_nth_page,libgtk),Ptr{Gtk.GObject},
	(Ptr{Gtk.GObject},Cint),notebook,page_num-1))

set_tab_label_text(notebook::Gtk.GtkNotebook,child,tab_text) = ccall((:gtk_notebook_set_tab_label_text,Gtk.libgtk),Cvoid,(Ptr{Gtk.GObject},
Ptr{Gtk.GObject},Ptr{UInt8}),notebook,child,tab_text)

popup_disble(notebook::Gtk.GtkNotebook) = ccall((:gtk_notebook_popup_disable ,Gtk.libgtk),
      Cvoid,
      (Ptr{Gtk.GObject},),
      notebook)
import Base.insert!
function insert!(w::Gtk.GtkNotebook, position::Integer, x::Union{Gtk.GtkWidget,Gtk.AbstractStringLike}, label::Union{Gtk.GtkWidget,Gtk.AbstractStringLike}, menu::Gtk.GtkWidget)
    ccall((:gtk_notebook_insert_page_menu,libgtk), Cint,
        (Ptr{GObject}, Ptr{Gtk.GObject}, Ptr{Gtk.GObject},Ptr{Gtk.GObject}, Cint),
        w, x, label, menu,position-1)+1
    w

end

## entry

function set_position!(editable::Gtk.Entry,position_)
    ccall((:gtk_editable_set_position,libgtk),Cvoid,(Ptr{Gtk.GObject},Cint),editable,position_)
end

#####  GtkClipboard #####

# Gtk.@gtktype GtkClipboard

# baremodule GdkAtoms
#     const NONE = 0x0000
#     const SELECTION_PRIMARY = 0x0001
#     const SELECTION_SECONDARY = 0x0002
#     const SELECTION_TYPE_ATOM = 0x0004
#     const SELECTION_TYPE_BITMAP = 0x0005
#     const SELECTION_TYPE_COLORMAP = 0x0007
#     const SELECTION_TYPE_DRAWABLE = 0x0011
#     const SELECTION_TYPE_INTEGER = 0x0013
#     const SELECTION_TYPE_PIXMAP = 0x0014
#     const SELECTION_TYPE_STRING = 0x001f
#     const SELECTION_TYPE_WINDOW = 0x0021
#     const SELECTION_CLIPBOARD = 0x0045
# end

# GtkClipboardLeaf(selection::UInt16) =  GtkClipboardLeaf(ccall((:gtk_clipboard_get,libgtk), Ptr{GObject},
#     (UInt16,), selection))
# GtkClipboardLeaf() = GtkClipboardLeaf(GdkAtoms.SELECTION_CLIPBOARD)
# clipboard_set_text(clip::GtkClipboard,text::AbstractString) = ccall((:gtk_clipboard_set_text,libgtk), Cvoid,
#     (Ptr{GObject}, Ptr{UInt8},Cint), clip, text, sizeof(text))
# clipboard_store(clip::GtkClipboard) = ccall((:gtk_clipboard_store,libgtk), Cvoid,
#     (Ptr{GObject},), clip)

# #note: this needs main_loops to run
# function clipboard_wait_for_text(clip::GtkClipboard)
#     ptr = ccall((:gtk_clipboard_wait_for_text,libgtk), Ptr{UInt8},
#         (Ptr{GObject},), clip)
#     return ptr == C_NULL ? "" : unsafe_string(ptr)
# end

# text_buffer_copy_clipboard(buffer::GtkTextBuffer,clip::GtkClipboard)  = ccall((:gtk_text_buffer_copy_clipboard, libgtk),Cvoid,
#     (Ptr{GObject},Ptr{GObject}),buffer,clip)


##
function GtkCssProviderFromData!(provider::GtkCssProvider;data=nothing,filename=nothing)
    source_count = (data!==nothing) + (filename!==nothing)
    @assert(source_count <= 1,
        "GtkCssProvider must have at most one data or filename argument")

    if data !== nothing
        Gtk.GError() do error_check

          ccall((:gtk_css_provider_load_from_data,libgtk), Bool,
            (Ptr{Gtk.GObject}, Ptr{UInt8}, Clong, Ptr{Ptr{Gtk.GError}}),
            provider, string(data), sizeof(data), error_check)
        end
    elseif filename !== nothing
        Gtk.GError() do error_check
          ccall((:gtk_css_provider_load_from_path,libgtk), Bool,
            (Ptr{Gtk.GObject}, Ptr{UInt8}, Ptr{Ptr{Gtk.GError}}),
            provider, string(filename), error_check)
        end
    end
    return provider
end

#TODO fix with Gtk.jl
GtkCssProviderLeaf() = GtkCssProviderLeaf(ccall((:gtk_css_provider_new,libgtk),Ptr{Gtk.GObject},()))

push!(context::GtkStyleContext, provider::GtkCssProvider, priority::Integer) =
  ccall((:gtk_style_context_add_provider, libgtk), Cvoid, (Ptr{GObject}, Ptr{GObject}, Cuint),
		 context, provider, priority)

function style_css(w::Gtk.GtkWidget,css::String)
    sc = Gtk.G_.style_context(w)
    provider = GtkCssProvider()
    push!(sc, GtkCssProviderFromData!(provider,data=css), 600)
end

function style_css(w::Gtk.GtkWidget,provider::GtkCssProvider)
    sc = Gtk.G_.style_context(w)
    push!(sc, provider, 600)
end

## Gdk

function gdk_window_get_origin(window)

	window_x = Gtk.mutable(Cint)
	window_y = Gtk.mutable(Cint)

	ccall((:gdk_window_get_origin,Gtk.libgdk),Cint,
		(Ptr{Gtk.GObject},Ptr{Cint},Ptr{Cint}),window,window_x,window_y)

	return (window_x[],window_y[])
end

gdk_keyval_name(val) = unsafe_string(
    ccall((:gdk_keyval_name,libgtk),Ptr{UInt8},(Cuint,),val),
true)


GtkIconThemeGetDefault() =  ccall((:gtk_icon_theme_get_default,Gtk.libgtk),Ptr{GObject},())

GtkIconThemeAddResourcePath(iconTheme,path::AbstractString) =  ccall(
                                                                   (:gtk_icon_theme_append_search_path,Gtk.libgtk),Cvoid,
                                                                   (Ptr{GObject}, Ptr{UInt8}),
                                                                   iconTheme,
                                                                   path);
function GtkIconThemeLoadIconForScale(iconTheme,icon_name::AbstractString, size::Integer, scale::Integer, flags::Integer)
    local pixbuf::Ptr{GObject}
    Gtk.GError() do error_check
        pixbuf = ccall((:gtk_icon_theme_load_icon_for_scale,Gtk.libgtk),
                   Ptr{GObject},
                   (Ptr{GObject},Ptr{UInt8},Cint,Cint,Cint,Ptr{Ptr{Gtk.GError}}),
                   iconTheme,string(icon_name),size,scale,flags,error_check)

        return pixbuf !== C_NULL
    end
    return convert(GdkPixbuf,pixbuf)
end

##GtkTreeStore
function insert(store::GtkTreeStore, it::GtkTreeIter, parent::GtkTreeIter, pos::Int)
    ccall((:gtk_tree_store_insert, Gtk.libgtk), Cvoid,  (Ptr{Gtk.GObject},Ptr{Gtk.GtkTreeIter},Ptr{Gtk.GtkTreeIter},Cint),
            store,it,parent,pos)
end

## update iter pointing to nth child n in 1:nchildren)
## return boolean
function iter_nth_child(treeModel::Gtk.GtkTreeModel, iter::Gtk.Mutable{Gtk.GtkTreeIter}, piter, n::Int)
  if (piter==nothing)
    ret = ccall((:gtk_tree_model_iter_nth_child, Gtk.libgtk), Cint,
        (Ptr{Gtk.GObject}, Ptr{GtkTreeIter}, Ptr{Gtk.GtkTreeIter}, Cint),
        treeModel, iter, C_NULL, n - 1) # 0-based
  else
    ret = ccall((:gtk_tree_model_iter_nth_child, Gtk.libgtk), Cint,
        (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}, Ptr{Gtk.GtkTreeIter}, Cint),
        treeModel, iter, Gtk.mutable(piter), n - 1) # 0-based
  end
    ret != 0
end


#GtkTreeView

function model(tree_view::Gtk.GtkTreeView)
    return convert(Gtk.GtkTreeStore,
        ccall((:gtk_tree_view_get_model, Gtk.libgtk),
        Ptr{Gtk.GObject},
        (Ptr{Gtk.GObject},),
        tree_view))
end

function selection(tree_view::Gtk.GtkTreeView)
    return convert(Gtk.GtkTreeSelection,
        ccall((:gtk_tree_view_get_selection,Gtk.libgtk),
        Ptr{Gtk.GObject},
        (Ptr{Gtk.GObject},),
        tree_view))
end

function set_cursor_on_cell(tree_view::Gtk.GtkTreeView, path::Gtk.GtkTreePath)
    return  ccall((:gtk_tree_view_set_cursor_on_cell , Gtk.libgtk),
                   Cvoid,
                  (Ptr{Gtk.GObject},Ptr{Gtk.GtkTreePath},Ptr{Gtk.GObject},Ptr{Gtk.GObject},Cint),
                  tree_view,path,C_NULL,C_NULL,false)
end

import Base.expand
function expand(tree_view::GtkTreeView,path::GtkTreePath)
    return  ccall((:gtk_tree_view_expand_to_path,libgtk),Cvoid,
                  (Ptr{Gtk.GObject},Ptr{Gtk.GtkTreePath}),
                  tree_view,path)
end

function treepath(path::AbstractString)
    ptr = ccall((:gtk_tree_path_new_from_string,libgtk),Ptr{GtkTreePath},
                  (Ptr{UInt8},),
                  string(path))
    if ptr != C_NULL
        return convert(GtkTreePath,ptr)
    else
        return GtkTreePath()
    end
end
expand_root(tree_view::GtkTreeView) = expand(tree_view,treepath("0"))

function selected(tree_view::GtkTreeView,list::GtkTreeStore)
    selmodel = selection(tree_view)
    if hasselection(selmodel)
        iter = selected(selmodel)
        return list[iter]
    end
    return nothing
end

#select the first entry that is equal to v
function select_value(tree_view::GtkTreeView,list::GtkTreeStore,v)
    selmodel = Gtk.G_.selection(tree_view)
    for i = 1:length(list)
        if list[i] == v
            partialsort!(selmodel, Gtk.iter_from_index(list, i))
            return
        end
    end
end

#GtkTreeModel
function foreach(model::Gtk.GtkTreeModel, f::Function, data)
  foreach_function = @cfunction($f, Cint, (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreePath}, Ptr{Gtk.GtkTreeIter}, Ptr{Cvoid}))
   ccall((:gtk_tree_model_foreach, Gtk.libgtk),      Cvoid,
                (Ptr{Gtk.GObject},Ptr{Cvoid}, Ptr{Cvoid}),
                model,foreach_function,pointer_from_objref(data))
end

global default_css_provider = convert(Ptr{Gtk.GObject}, 0)
function __init__()
    global default_css_provider = GtkCssProviderLeaf(
        ccall((:gtk_css_provider_get_default,libgtk),Ptr{Gtk.GObject},())
    )

    #import Base.show
    #show(io::IO, it::GtkTextIter) = println("GtkTextIter($(offset(it)))")

end

end#module
