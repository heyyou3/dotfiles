"=============================================================================
" init.vim --- Entry file for neovim
" Copyright (c) 2016-2019 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

execute 'source' fnamemodify(expand('<sfile>'), ':h').'/config/main.vim'
:set shellcmdflag=-ic

let vim_settings_dir = getcwd().'/.SpaceVim.d'

if isdirectory(vim_settings_dir)
  execute 'source '.vim_settings_dir.'/settings*.vim'
endif

let s:TOML = SpaceVim#api#import('data#toml')

function! s:get_str_candidate(val) abort
  return string(a:val)
endfunction

function! s:make_curl_headers(cd_headers) abort
  let res = []
  for k in keys(a:cd_headers)
    let res = add(res, '-H '.''''.k.':'.a:cd_headers[k].'''')
  endfor
  return join(res, ' ').' '
endfunction

function! s:make_curl_queries(cd_queries)
  let res = []
  let s:cnt = 0
  for k in keys(a:cd_queries)
    let s:cnt = s:cnt + 1

    if s:cnt == 1
      let res = add(res, '?'.k.'='.a:cd_queries[k])
      continue
    endif

    let res = add(res, '&'.k.'='.a:cd_queries[k])
  endfor
  return join(res, '')
endfunction

function! s:make_curl_body(cd_body) abort
  let json_body = json_encode(a:cd_body)
  return '-d '.''''.json_body.''''.' '
endfunction

function! s:make_curl_method(cd_method) abort
  return '-X '.a:cd_method.' '
endfunction

function! s:sink(candidate) abort
  let json_str = substitute(a:candidate, "'", '"', 'g')
  let dict_candidate = json_decode(json_str)
  let curl_method = s:make_curl_method(dict_candidate['method'])
  let curl_headers = has_key(dict_candidate, 'headers') ? s:make_curl_headers(dict_candidate['headers']) : ''
  let curl_queries = has_key(dict_candidate, 'queries') ? s:make_curl_queries(dict_candidate['queries']) : ''
  let curl_body = has_key(dict_candidate, 'body') ? s:make_curl_body(dict_candidate['body']) : ''
  let curl_path = dict_candidate['path']
  let curl_cmd = 'curl -vvv '.curl_method.curl_headers.curl_body.''''.s:global_conf['base_url'].curl_path.curl_queries.''''

  execute 'new '.strftime('%Y%m%d-%H%M%S', localtime())
  execute 'r!echo '.curl_cmd
  execute 'r!'.curl_cmd
endfunction

function! Lruc() abort
  let s:global_conf = s:TOML.parse_file(expand(getcwd() . '/.SpaceVim.d/api_list.toml'))
  let s:ref_get_str_candidate = function('s:get_str_candidate')
  let api_infos = map(s:global_conf['api_info'], string(s:ref_get_str_candidate).'(v:val)')
  call fzf#run({ 'source': api_infos,
        \ 'sink': function('s:sink')})
endfunction

call SpaceVim#custom#SPC('nnoremap', ['d', 'l'], 'call Lruc()', 'call Lruc', 1)

