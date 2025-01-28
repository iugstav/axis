open Core

type pattern_values =
  | Text of string
  | Variable of (string * string)  (** name : value *)
  | UserMessage of string

module Scanner = struct
  type token = Lbrace | Rbrace | Value of string | Text of string
  [@@deriving show]

  type error = { at : int; cause : string } [@@deriving show]

  type t = {
    pattern : string;
    tokens : token list;
    errors : error list;
    ch : char option;
    pos : int;
  }
  [@@deriving show]

  let is_bracket ch = Char.equal ch '{' || Char.equal ch '}'
  let is_text ch = not (is_bracket ch)
  let add_token s tok = { s with tokens = tok :: s.tokens }
  let add_error s err = { s with errors = err :: s.errors }

  let init p =
    let state = { pattern = p; tokens = []; errors = []; ch = None; pos = 0 } in
    if String.length p = 0 then state else { state with ch = Some p.[0] }

  let rec scan s =
    match s.ch with
    | Some ch ->
        let scanner =
          match ch with
          | '{' -> add_token s Lbrace |> next
          | '}' -> add_token s Rbrace |> next
          | c when is_text c ->
              let scanner, token = read_string s in
              add_token scanner token
          | c ->
              {
                at = s.pos;
                cause = Format.sprintf "Unknown character %s" (Char.to_string c);
              }
              |> add_error s
        in
        scan scanner
    | None -> s

  and curr s =
    if s.pos < String.length s.pattern then Some s.pattern.[s.pos] else None

  and next s =
    if s.pos = String.length s.pattern - 1 then { s with ch = None }
    else
      let p = s.pos + 1 in
      { s with pos = p; ch = Some s.pattern.[p] }

  and search s condition =
    let rec loop s = if condition s.ch then loop (next s) else s in
    let scanner = loop s in
    (scanner, scanner.pos)

  and read_string s =
    let init_pos = s.pos in
    let scanner, end_pos =
      search s (fun ch -> match ch with Some c -> is_text c | None -> false)
    in
    let chopped_data =
      String.sub s.pattern ~pos:init_pos ~len:(end_pos - init_pos)
    in
    (scanner, Text chopped_data)
end

module Parser = struct end
