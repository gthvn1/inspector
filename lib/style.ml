let bold = "\027[1m"
let yellow = "\027[33m"
let reverse = "\027[7m"
let reset = "\027[0m"
let clear () = print_string "\027[2J\027[H"
let bold_text s = bold ^ s ^ reset
let yellow_text s = yellow ^ s ^ reset
let reverse_text s = reverse ^ s ^ reset
