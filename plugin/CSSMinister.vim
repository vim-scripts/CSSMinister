" =============================================================================
" File:          CSSMinister.vim
" Maintainer:    Kuroi Kenshi <kuroi_keshi96 at yahoo dot com>
" Description:   Easy modification of colors in CSS stylesheets. Change colors
"                from one format to another. Currently supported formats include
"                hex, RGB and HSL.
" Last Modified: March 07, 2010
" License:       GPL (see http://www.gnu.org/licenses/gpl.txt)
"
" TODO: named colors (i.e white, black, cyan, etc)
" TODO: rgba and hsla conversions
" TODO: conversions in visual mode
" TODO: alt. delimeters for mappings
" =============================================================================

" Script init stuff {{{1
if exists("g:CSSMinister_version") || &cp
    finish
endif

let g:CSSMinister_version = "0.1.0"

" Constants {{{1
let s:RGB_NUM_RX    = '\v\crgb\(([01]?\d\d?|2[0-4]\d|25[0-5]),\s*([01]?\d\d?|2[0-4]\d|25[0-5]),\s*([01]?\d\d?|2[0-4]\d|25[0-5])\);?'
let s:RGB_PERC_RX   = '\v\crgb\((\d\%|[1-9]{1}[0-9]\%|100\%),\s*(\d\%|[1-9]{1}[0-9]\%|100\%),\s*(\d\%|[1-9]{1}[0-9]\%|100\%)\);?'
let s:RGB_DISCOVERY = '\v\crgb\(\d+.*,\s*\d+.*,\s*\d+.*\);?'
let s:HSL           = '\vhsl\((-?\d+),\s*(\d\%|[1-9][0-9]\%|100\%),\s*(\d\%|[1-9][0-9]\%|100\%)\);?'
let s:HEX           = '\v([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})'
let s:HEX_DISCOVERY = '\v#[0-9a-fA-F]{3,6}'

let g:CSSMinisterCreateMappings = 1

" Public API {{{1
" Mappings {{{2
function! s:CreateMappings(target, mapping)
    if !hasmapto(a:mapping, 'n')
        exec 'nmap ' . a:mapping . ' ' . a:target
    endif
endfunction


if g:CSSMinisterCreateMappings
   call s:CreateMappings('<Plug>CSSMinisterHexToRGB',    ',xr')
   call s:CreateMappings('<Plug>CSSMinisterHexToRGBAll', ',axr')
   call s:CreateMappings('<Plug>CSSMinisterHexToHSL',    ',xh')
   call s:CreateMappings('<Plug>CSSMinisterHexToHSLAll', ',axh')
   call s:CreateMappings('<Plug>CSSMinisterRGBToHex',    ',rx')
   call s:CreateMappings('<Plug>CSSMinisterRGBToHexAll', ',arx')
   call s:CreateMappings('<Plug>CSSMinisterRGBToHSL',    ',rh')
   call s:CreateMappings('<Plug>CSSMinisterRGBToHSLAll', ',arh')
   call s:CreateMappings('<Plug>CSSMinisterHSLToHex',    ',hx')
   call s:CreateMappings('<Plug>CSSMinisterHSLToHexAll', ',ahx')
   call s:CreateMappings('<Plug>CSSMinisterHSLToRGB',    ',hr')
   call s:CreateMappings('<Plug>CSSMinisterHSLToRGBAll', ',ahr')

   let g:CSSMinisterCreateMappings = 0
endif


noremap <silent> <script> <Plug>CSSMinisterHexToRGB    :call Convert('hex', 'rgb')<CR>
noremap <silent> <script> <Plug>CSSMinisterHexToRGBAll :call Convert('hex', 'rgb', 'all')<CR>
noremap <silent> <script> <Plug>CSSMinisterHexToHSL    :call Convert('hex', 'hsl')<CR>
noremap <silent> <script> <Plug>CSSMinisterHexToHSLAll :call Convert('hex', 'hsl', 'all')<CR>
noremap <silent> <script> <Plug>CSSMinisterRGBToHex    :call Convert('rgb', 'hex')<CR>
noremap <silent> <script> <Plug>CSSMinisterRGBToHexAll :call Convert('rgb', 'hex', 'all')<CR>
noremap <silent> <script> <Plug>CSSMinisterRGBToHSL    :call Convert('rgb', 'hsl')<CR>
noremap <silent> <script> <Plug>CSSMinisterRGBToHSLAll :call Convert('rgb', 'hsl', 'all')<CR>
noremap <silent> <script> <Plug>CSSMinisterHSLToHex    :call Convert('hsl', 'hex')<CR>
noremap <silent> <script> <Plug>CSSMinisterHSLToHexAll :call Convert('hsl', 'hex', 'all')<CR>
noremap <silent> <script> <Plug>CSSMinisterHSLToRGB    :call Convert('hsl', 'rgb')<CR>
noremap <silent> <script> <Plug>CSSMinisterHSLToRGBAll :call Convert('hsl', 'rgb', 'all')<CR>
"}}}2


" -----------------------------------------------------------------------------
" Convert: Wrapper for all conversion functions
" Args:
"   from:  format we're converting from
"   to:    format we're converting to
"   {all}: specify whether to convert the next matching color or all colors in 
"          buffer
function! Convert(from, to, ...)
    if a:from == a:to | return | endif
    let all = a:0 >= 1 ? a:1 : ''

    if a:from =~ '\vhex|rgb|hsl'
        if all == 'all'
            call s:ReplaceAll(a:from, a:to)
        else 
            call s:ReplaceNext(a:from, a:to)
        endif
    endif
endfunction


" -----------------------------------------------------------------------------
" ToRGB: Converts colors in hex or hsl format to rgb
function! ToRGB(from_format)
    if s:IsHex(a:from_format)
        return s:HexToRGB(a:from_format)
    elseif s:IsHSL(a:from_format)
        return s:HSLToRGB(a:from_format)
    endif
endfunction


" -----------------------------------------------------------------------------
" ToHSL: Converts colors in hex or rgb format to hsl
function! ToHSL(from_format)
    if s:IsHex(a:from_format)
        let rgb = s:HexToRGB(a:from_format)
        return s:RGBToHSL(rgb)
    elseif s:IsRGB(a:from_format)
        return s:RGBToHSL(a:from_format)
    endif
endfunction


" -----------------------------------------------------------------------------
" ToHex: Converts colors in rgb or hsl format to hex
function! ToHex(from_format)
    if s:IsRGB(a:from_format)
        return s:RGBToHex(a:from_format)
    elseif s:IsHSL(a:from_format)
        let rgb = s:HSLToRGB(a:from_format)
        return s:RGBToHex(rgb)
    endif
endfunction


" Format verification functions {{{1
" -----------------------------------------------------------------------------
" Assumes the color being passed in is of the these formats:
"   rgb(0, 70, 255); 
"   rgb(0%, 50%, 100%);
function! s:IsRGB(color)
    return a:color =~ s:RGB_NUM_RX || a:color =~ s:RGB_PERC_RX
endfunction

function! s:IsHSL(color)
    return a:color =~ s:HSL
endfunction

function! s:IsHex(color)
    return a:color =~ s:HEX_DISCOVERY
endfunction


" -----------------------------------------------------------------------------
" Color to RGB conversion {{{1
function! s:HexToRGB(hex)
    if strlen(a:hex) == 7
        let color = matchlist(a:hex, '\v([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})')
        return s:OutputRGB(color[1], color[2], color[3])
    elseif strlen(a:hex) == 4
        let color = split(a:hex, '\zs')
        return s:OutputRGB(repeat(color[1], 2), repeat(color[2],2), repeat(color[3], 2))
    endif
endfunction


" -----------------------------------------------------------------------------
" s:HSLToRGB: http://www.easyrgb.com/index.php?X=MATH&H=19#text19 
function! s:HSLToRGB(hsl)
    let match = matchlist(a:hsl, s:HSL)
    " the next expression normalizes the angle into the 0-360 range
    " see: http://www.w3.org/TR/css3-color/#hsl-color
    let h = match[1] >= 0 && match[1] <= 360 ? match[1]/360.0 : (((match[1] % 360) + 360) % 360)/360.0
    let s = match[2]/100.0
    let l = match[3]/100.0

    let rgb = {}
    if s == 0
        let [rgb.r, rgb.g, rgb.b] = map([l, l, l], 'v:val * 255')
    else
        let var_2 = l < 0.5 ? l * (1.0 + s) : (l + s) - (s * l)
        let var_1 = 2 * l - var_2

        let rgb.r = s:Hue2RGB(var_1, var_2, h + (1.0/3))
        let rgb.g = s:Hue2RGB(var_1, var_2, h)
        let rgb.b = s:Hue2RGB(var_1, var_2, h - (1.0/3))

        let rgb = map(rgb, 'v:val * 255')
    endif

    return 'rgb(' . float2nr(rgb.r) . ', ' . float2nr(rgb.g) . ', ' . float2nr(rgb.b) . ')'
endfunction


" -----------------------------------------------------------------------------
" s:Hue2RGB: http://www.easyrgb.com/index.php?X=MATH&H=19#text19 
function! s:Hue2RGB(v1, v2, vH)
    let H = a:vH
    if H < 0 | let H += 1 | endif
    if H > 1 | let H -= 1 | endif
    if (6 * H) < 1 | return a:v1 + (a:v2 - a:v1) * 6 * H | endif
    if (2 * H) < 1 | return a:v2 | endif
    if (3 * H) < 2 | return a:v1 + (a:v2 - a:v1) * ((2.0/3) - H) * 6 | endif 
    return a:v1
endfunction

function! s:OutputRGB(r, g, b)
    return 'rgb(' . printf('%d', '0x' . a:r) . ', ' . printf('%d', '0x' . a:g) . ', ' . printf('%d', '0x' . a:b) . ')'
endfunction


" Color to HSL conversion {{{1
" -----------------------------------------------------------------------------
" s:RGBToHSL: http://www.easyrgb.com/index.php?X=MATH&H=18#text18
" Args:
"   rgb: A string representing a color in RGB format, i.e. 'hsl(0, 50%, 100%)'
function! s:RGBToHSL(rgb)
    " normalize rgb values - they can be in either the range 0-255 or 0-100%
    let norm_rgb = matchlist(a:rgb, s:RGB_PERC_RX)
    if empty(norm_rgb)
        let norm_rgb = matchlist(a:rgb, s:RGB_NUM_RX)
        let norm_rgb = map(norm_rgb, 'str2nr(v:val)')
    else 
        " strip off the %'s
        let norm_rgb = map(norm_rgb, 'str2nr(v:val)')
        let norm_rgb = map(norm_rgb, 'v:val*255')
    endif
    
    let rgb_dict = {}
    let [rgb_dict.r, rgb_dict.g, rgb_dict.b] = norm_rgb[1:3]

    let min = min(rgb_dict)/255.0
    let max = max(rgb_dict)/255.0
    let delta = (max - min)

    let rgb_dict = map(rgb_dict, 'v:val/255.0')

    let hsl = {}
    let hsl.l = ( max + min )/2.0

    if delta == 0
        let [hsl.h, hsl.s] = [0, 0]
    else 
        let hsl.s = hsl.l < 0.5 ? delta/(max + min + 0.0) : delta/(2.0 - max - min)

        let delta_rgb = {}
        let delta_r = (((max - rgb_dict.r)/6.0) + (delta/2.0))/delta
        let delta_g = (((max - rgb_dict.g)/6.0) + (delta/2.0))/delta
        let delta_b = (((max - rgb_dict.b)/6.0) + (delta/2.0))/delta

        if rgb_dict.r == max 
            let hsl.h = delta_b - delta_g
        elseif rgb_dict.g == max 
            let hsl.h = (1/3.0) + delta_r - delta_b
        elseif rgb_dict.b == max 
            let hsl.h = (2/3.0) + delta_g - delta_r
        endif

        if hsl.h < 0 | let hsl.h += 1 | endif
        if hsl.h > 1 | let hsl.h -= 1 | endif
    endif

    return s:OutputHSL(hsl)
endfunction


" -----------------------------------------------------------------------------
" s:OutputHSL: Outputs a formatted string in hsl format.
" Args:
"   hsl: Dictionary with h, s, l keys. Their values are normalized in order to
"        return a valid formatted string. 
function! s:OutputHSL(hsl)
    let temp_hsl = a:hsl
    let temp_hsl.h = float2nr( temp_hsl.h * 360.0 )
    let [temp_hsl.s, temp_hsl.l] = map([temp_hsl.s, temp_hsl.l], "float2nr(round(v:val * 100)) . '%'")
    return 'hsl(' . temp_hsl.h . ', ' . temp_hsl.s . ', ' . temp_hsl.l . ')'
endfunction


" -----------------------------------------------------------------------------
" Color to Hex conversion {{{1
" s:RGBToHex: Converts a color from functional notation to its hex equivalent.
" Args:
"   rgb: A color in RGB format
function! s:RGBToHex(rgb)
    let t_rgb = {}
    " figure out if 3 integer or 3 percent values are used
    let color = a:rgb =~ s:RGB_NUM_RX ? matchlist(a:rgb, s:RGB_NUM_RX) : matchlist(a:rgb, s:RGB_PERC_RX)
    let [t_rgb.r, t_rgb.g, t_rgb.b] = color[1:3]
    return s:ToHex(t_rgb)
endfunction


" -----------------------------------------------------------------------------
function! s:GetHexValue(val)
    let hex_values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'A', 'B', 'C', 'D', 'E', 'F']
    let n = max([0, a:val])
    let n = min([a:val, 255])
    let n = float2nr(round(n))
    return printf('%s', hex_values[(n-n%16)/16]) . printf('%s', hex_values[n%16])
endfunction


" -----------------------------------------------------------------------------
function! s:ToHex(rgb)
    return '#' . s:GetHexValue(a:rgb.r) . s:GetHexValue(a:rgb.g) . s:GetHexValue(a:rgb.b)
endfunction


" Replacement functions {{{1
" -----------------------------------------------------------------------------
" s:ReplaceAll: Replaces all colors in the current buffer to the requested
"               color format.
" Args:
"   from: the color format we're converting from
"   to:   the color format we're converting to
function! s:ReplaceAll(from, to)
    let lines = getbufline('%', 1, '$')
    let regex = ''
    if a:from == 'hex'
        let regex = s:HEX_DISCOVERY
    elseif a:from == 'rgb'
        let regex = s:RGB_DISCOVERY
    elseif a:from == 'hsl'
        let regex = s:HSL
    endif

    let matchingLines = filter(copy(lines), "v:val =~ regex")
    
    for line in matchingLines
        let lineNum = index(lines, line) + 1
        let convert = s:ReplacementPairings(a:from, a:to)

        let replace = substitute(line, convert.from_rx, '\=To' . convert.to . '(submatch(0))', 'g')

        " prevent replacing the first matching line if there are more than one 
        " identical color declarations on separate lines
        let lines[lineNum - 1] = ''

        call setline(lineNum, replace)
    endfor
endfunction


" -----------------------------------------------------------------------------
" s:ReplaceNext: Replaces the next matching color to one in the requested
"                format in the current buffer.
" Args:
"   from: the color format we're converting from
"   to:   the color format we're converting to
function! s:ReplaceNext(from, to)
    let lineNum = line('.')
    let line = getline('.')
    let convert = s:ReplacementPairings(a:from, a:to)

    let line = substitute(line, convert.from_rx, '\=To' . convert.to . '(submatch(0))', '')

    call setline(lineNum, line)
endfunction


" -----------------------------------------------------------------------------
" s:ReplacementPairings: Returns a dictionary with two regex's: one for
"                        retrieving matching colors according to the format 
"                        given, and another for replacing them to the 
"                        requested format.
" Args:
"   from: the color format we're converting from
"   to:   the color format we're converting to
function! s:ReplacementPairings(from, to)
    let pairings = {}

    if a:to == 'hex'
        let pairings.to = 'Hex'
        if       a:from == 'rgb' | let pairings.from_rx = s:RGB_NUM_RX . '|' . strpart(s:RGB_PERC_RX, 4, strlen(s:RGB_PERC_RX)) |
        \ elseif a:from == 'hsl' | let pairings.from_rx = s:HSL           | endif
    elseif a:to == 'rgb'
        let pairings.to = 'RGB'
        if       a:from == 'hex' | let pairings.from_rx = s:HEX_DISCOVERY | 
        \ elseif a:from == 'hsl' | let pairings.from_rx = s:HSL           | endif
    elseif a:to == 'hsl'
        let pairings.to = 'HSL'
        if       a:from == 'rgb' | let pairings.from_rx = s:RGB_NUM_RX . '|' . strpart(s:RGB_PERC_RX, 4, strlen(s:RGB_PERC_RX)) |
        \ elseif a:from == 'hex' | let pairings.from_rx = s:HEX_DISCOVERY | endif
    endif

    return pairings
endfunction


" vim:ft=vim foldmethod=marker sw=4
