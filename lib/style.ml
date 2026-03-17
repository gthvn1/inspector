(* some colors *)
let bold = "\027[1m"
let green = "\027[32m"
let yellow = "\027[33m"
let reverse = "\027[7m"

(* if we reset color it will break the reverse we are using for current line *)
let reset = "\027[0m"
let reset_foreground = "\027[39m"
let clear () = print_string "\027[2J\027[H"
let green_text s = green ^ s ^ reset_foreground
let yellow_text s = yellow ^ s ^ reset_foreground

(* reverse is used for the whole line like bold *)
let bold_text s = bold ^ s ^ reset
let reverse_text s = reverse ^ s ^ reset
