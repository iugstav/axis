open Core

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
          | c when is_text c -> (
              let scanner, data = read_string s in
              let result =
                match List.hd scanner.tokens with
                | Some token -> (
                    match token with
                    | Lbrace -> Ok (Value data)
                    | Value v ->
                        let err =
                          {
                            at = scanner.pos;
                            cause =
                              Format.sprintf
                                "invalid pattern syntax ::: %s followed by %s" v
                                data;
                          }
                        in
                        Error err
                    | Rbrace | Text _ -> Ok (Text data))
                | None -> Ok (Text data)
              in
              match result with
              | Ok tok -> add_token scanner tok
              | Error e -> add_error scanner e)
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
    (scanner, chopped_data)
end

module Parser = struct
  type error_position = { tok : Scanner.token; pos : int } [@@deriving show]
  type error = { at : error_position; cause : string } [@@deriving show]

  type pattern_values =
    | Text of string
    | Variable of string
    | UserMessage of string
  [@@deriving show]

  type t = {
    variables : (string * string) list;
    template : Config.template;
    tokens : Scanner.token list;
    values : pattern_values list;
    errors : error list;
    pos : int;
    actual : Scanner.token option;
  }
  [@@deriving show]

  let init tokens (config : Config.t) =
    let tokens = List.rev tokens in
    {
      tokens;
      values = [];
      variables = config.variables;
      template = config.template;
      errors = [];
      actual = List.nth tokens 0;
      pos = 0;
    }

  let rec parse p =
    match p.actual with
    | Some tk ->
        let parser =
          match tk with
          | Lbrace -> next p
          | Rbrace -> next p
          | Text t -> add_text p t |> next
          | Value v -> (
              let variable =
                List.find p.variables ~f:(fun var ->
                    let name, _ = var in
                    String.equal name v)
              in
              match variable with
              | Some (_, value) -> add_variable p value |> next
              | None ->
                  {
                    at = { tok = tk; pos = p.pos };
                    cause = Format.sprintf "Unknown variable with name '%s'" v;
                  }
                  |> add_error p |> next)
        in
        parse parser
    | None -> p

  and add_variable p v = { p with values = Variable v :: p.values }
  and add_text p t = { p with values = Text t :: p.values }
  and add_error p err = { p with errors = err :: p.errors }
  and has_errors p = List.length p.errors > 0

  and next ?(skip = 1) p =
    if p.pos + skip >= List.length p.tokens - 1 then { p with actual = None }
    else
      let position = p.pos + skip in
      { p with pos = position; actual = List.nth p.tokens position }
end
