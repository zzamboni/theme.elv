# DO NOT EDIT THIS FILE DIRECTLY
# This is a file generated from a literate programing source file located at
# https://github.com/zzamboni/elvish-themes/blob/master/chain.org.
# You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

prompt-segments-defaults = [ su dir git-branch git-combined arrow ]
rprompt-segments-defaults = [ ]

use re

use github.com/href/elvish-gitstatus/gitstatus

prompt-segments = $prompt-segments-defaults
rprompt-segments = $rprompt-segments-defaults

default-glyph = [
  &git-branch=    "⎇"
  &git-dirty=     "●"
  &git-ahead=     "⬆"
  &git-behind=    "⬇"
  &git-staged=    "✔"
  &git-untracked= "+"
  &git-deleted=   "-"
  &su=            "⚡"
  &chain=         "─"
  &session=       "▪"
  &arrow=         ">"
]

default-segment-style = [
  &git-branch=    [ blue         ]
  &git-dirty=     [ yellow       ]
  &git-ahead=     [ red          ]
  &git-behind=    [ red          ]
  &git-staged=    [ green        ]
  &git-untracked= [ red          ]
  &git-deleted=   [ red          ]
  &git-combined=  [ default      ]
  &git-timestamp= [ cyan         ]
  &su=            [ yellow       ]
  &chain=         [ default      ]
  &arrow=         [ green        ]
  &dir=           [ cyan         ]
  &session=       [ session      ]
  &timestamp=     [ bright-black ]
]

glyph = [&]
segment-style = [&]

prompt-pwd-dir-length = 1

timestamp-format = "%R"

root-id = 0

bold-prompt = $false

git-get-timestamp = { git log -1 --date=short --pretty=format:%cd }

prompt-segment-delimiters = "[]"
# prompt-segment-delimiters = [ "<<" ">>" ]

fn -session-color {
  valid-colors = [ black red green yellow blue magenta cyan white bright-black bright-red bright-green bright-yellow bright-blue bright-magenta bright-cyan bright-white ]
  put $valid-colors[(% $pid (count $valid-colors))]
}

fn -colorized [what @color]{
  if (and (not-eq $color []) (eq (kind-of $color[0]) list)) {
    color = [(explode $color[0])]
  }
  if (and (not-eq $color [default]) (not-eq $color [])) {
    if (eq $color [session]) {
      color = [(-session-color)]
    }
    if $bold-prompt {
      color = [ $@color bold ]
    }
    styled $what $@color
  } else {
    put $what
  }
}

fn -glyph [segment-name]{
  if (has-key $glyph $segment-name) {
    put $glyph[$segment-name]
  } else {
    put $default-glyph[$segment-name]
  }
}

fn -segment-style [segment-name]{
  if (has-key $segment-style $segment-name) {
    put $segment-style[$segment-name]
  } else {
    put $default-segment-style[$segment-name]
  }
}

fn -colorized-glyph [segment-name @extra-text]{
  -colorized (-glyph $segment-name)(joins "" $extra-text) (-segment-style $segment-name)
}

fn prompt-segment [segment-or-style @texts]{
  style = $segment-or-style
  if (has-key $default-segment-style $segment-or-style) {
    style = (-segment-style $segment-or-style)
  }
  if (has-key $default-glyph $segment-or-style) {
    texts = [ (-glyph $segment-or-style) $@texts ]
  }
  text = $prompt-segment-delimiters[0](joins ' ' $texts)$prompt-segment-delimiters[1]
  -colorized $text $style
}

segment = [&]

last-status = [&]

fn -parse-git {
  last-status = (gitstatus:query $pwd)
}

segment[git-branch] = {
  branch = $last-status[local-branch]
  if (not-eq $branch $nil) {
    if (eq $branch '') {
      branch = $last-status[commit][0:7]
    }
    prompt-segment git-branch $branch
  }
}

segment[git-timestamp] = {
  ts = ($git-get-timestamp)
  prompt-segment git-timestamp $ts
}

fn -show-git-indicator [segment]{
  status-name = [
    &git-dirty=  unstaged        &git-staged=    staged
    &git-ahead=  commits-ahead   &git-untracked= untracked
    &git-behind= commits-behind  &git-deleted=   unstaged
  ]
  value = $last-status[$status-name[$segment]]
  # The indicator must show if the element is >0 or a non-empty list
  if (eq (kind-of $value) list) {
    not-eq $value []
  } else {
    and (not-eq $value $nil) (> $value 0)
  }
}

fn -git-prompt-segment [segment]{
  if (-show-git-indicator $segment) {
    prompt-segment $segment
  }
}

#-git-indicator-segments = [untracked deleted dirty staged ahead behind]
-git-indicator-segments = [untracked dirty staged ahead behind]

each [ind]{
  segment[git-$ind] = { -git-prompt-segment git-$ind }
} $-git-indicator-segments

segment[git-combined] = {
  indicators = [(each [ind]{
        if (-show-git-indicator git-$ind) { -colorized-glyph git-$ind }
  } $-git-indicator-segments)]
  if (> (count $indicators) 0) {
    color = (-segment-style git-combined)
    put (-colorized '[' $color) $@indicators (-colorized ']' $color)
  }
}

fn -prompt-pwd {
  tmp = (tilde-abbr $pwd)
  if (== $prompt-pwd-dir-length 0) {
    put $tmp
  } else {
    re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
  }
}

segment[dir] = {
  prompt-segment dir (-prompt-pwd)
}

segment[su] = {
  uid = (id -u)
  if (eq $uid $root-id) {
    prompt-segment su
  }
}

segment[timestamp] = {
  prompt-segment timestamp (date +$timestamp-format)
}

segment[session] = {
  prompt-segment session
}

segment[arrow] = {
  -colorized-glyph arrow " "
}

fn -interpret-segment [seg]{
  k = (kind-of $seg)
  if (eq $k 'fn') {
    # If it's a lambda, run it
    $seg
  } elif (eq $k 'string') {
    if (has-key $segment $seg) {
      # If it's the name of a built-in segment, run its function
      $segment[$seg]
    } else {
      # If it's any other string, return it as-is
      put $seg
    }
  } elif (or (eq $k 'styled') (eq $k 'styled-text')) {
    # If it's a styled object, return it as-is
    put $seg
  }
}

fn -build-chain [segments]{
  if (eq $segments []) {
    return
  }
  first = $true
  output = ""
  -parse-git
  for seg $segments {
    output = [(-interpret-segment $seg)]
    if (> (count $output) 0) {
      if (not $first) {
        -colorized-glyph chain
      }
      put $@output
      first = $false
    }
  }
}

fn prompt {
  if (not-eq $prompt-segments []) {
    -build-chain $prompt-segments
  }
}

fn rprompt {
  if (not-eq $rprompt-segments []) {
    -build-chain $rprompt-segments
  }
}

fn init {
  edit:prompt = $prompt~
  edit:rprompt = $rprompt~
}

init

summary-repos = []

fn summary-status [@repos &all=$false]{
  prev = $pwd
  if $all {
    repos = [(glocate --basename --existing .git | fgrep ~ | grep '\.git$' | each [l]{
          re:replace '/\.git$' '' $l
    })]
  }
  if (eq $repos []) { repos = $summary-repos }
  each $echo~ $repos | sort | each [r]{
    try {
      cd $r
      -parse-git
      status = [($segment[git-combined])]
      if (eq $status []) {
        status = [(-colorized "[" session) (styled OK green) (-colorized "]" session)]
      }
      status = [($segment[git-timestamp]) ' ' $@status ' ' ($segment[git-branch])]
      echo &sep="" $@status ' ' (styled (tilde-abbr $r) blue)
    } except e {
      echo (styled '['(to-string $e)']' red) (styled (tilde-abbr $r) blue)
    }
  } | sort -r -k 1
  cd $prev
}
