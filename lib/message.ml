open Core

module Scanner = struct
  type token = Lbrace | Rbrace | Value of string | Text of string
  [@@deriving show]

  type error = { at : int; cause : string } [@@deriving show]

  type t = {
    pattern : string;
    p_length : int;
    tokens : token list;
    errors : error list;
    ch : char option;
    pos : int;
  }
  [@@deriving show]

  let[@inline] is_bracket ch = Char.equal ch '{' || Char.equal ch '}'
  let[@inline] is_text ch = not (is_bracket ch)
  let[@inline] add_token s tok = { s with tokens = tok :: s.tokens }
  let[@inline] add_error s err = { s with errors = err :: s.errors }

  let init p =
    let state =
      {
        pattern = p;
        p_length = String.length p;
        tokens = [];
        errors = [];
        ch = None;
        pos = 0;
      }
    in
    if state.p_length = 0 then state else { state with ch = Some p.[0] }

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

  and next s =
    if s.pos = s.p_length - 1 then { s with ch = None }
    else
      let p = s.pos + 1 in
      { s with pos = p; ch = Some s.pattern.[p] }

  (*and search s condition =*)
  (*  let rec loop s = if condition s.ch then loop (next s) else s in*)
  (*  let scanner = loop s in*)
  (*  (scanner, scanner.pos)*)

  and search_text s =
    let rec loop s =
      match s.ch with Some c when is_text c -> loop (next s) | _ -> s
    in
    let scanner = loop s in
    (scanner, scanner.pos)

  and read_string s =
    let init_pos = s.pos in
    let scanner, end_pos = search_text s in
    let chopped_data =
      String.sub s.pattern ~pos:init_pos ~len:(end_pos - init_pos)
    in
    (scanner, chopped_data)
end

module Parser = struct
  type error_position = { tok : Scanner.token; pos : int } [@@deriving show]
  type error = { at : error_position; cause : string } [@@deriving show]

  type pattern_values = Text of string | Variable of string | UserMessage
  [@@deriving show]

  let pattern_to_string um = function
    | Text t -> t
    | Variable v -> v
    | UserMessage -> um

  type t = {
    variables : (string * string) array;
    template : Config.template;
    tokens : Scanner.token array;
    values : pattern_values list;
    errors : error list;
    pos : int;
    actual : Scanner.token option;
  }
  [@@deriving show]

  let init tokens (config : Config.t) =
    let tokens = Array.rev tokens in
    {
      tokens;
      values = [];
      variables = Array.of_list config.variables;
      template = config.template;
      errors = [];
      actual = Some (Array.get tokens 0);
      pos = 0;
    }

  let parse_errors err_l =
    let f err =
      let token_name =
        match err.at.tok with
        | Rbrace -> "right brace"
        | Lbrace -> "left brace"
        | Value v -> Format.sprintf "value %s" v
        | Text t -> Format.sprintf "text %s" t
      in
      Format.sprintf "in %s at position %d ::: %s" token_name err.at.pos
        err.cause
    in
    List.map err_l ~f

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
                Array.find p.variables ~f:(fun var ->
                    let name, _ = var in
                    String.equal name v)
              in
              match variable with
              | Some (name, value) ->
                  if has_invalid_name name then
                    {
                      at = { tok = tk; pos = p.pos };
                      cause =
                        Format.sprintf
                          "your variable named '%s' conflicts with template \
                           field names. Please use another name."
                          name;
                    }
                    |> add_error p |> next ~skip:2
                  else add_variable p value |> next ~skip:2
              | None ->
                  if String.equal v "message" then
                    add_usermessage p |> next ~skip:2
                  else
                    {
                      at = { tok = tk; pos = p.pos };
                      cause = Format.sprintf "Unknown variable '%s'" v;
                    }
                    |> add_error p |> next)
        in
        parse parser
    | None -> p

  and add_usermessage p = { p with values = UserMessage :: p.values }
  and add_variable p v = { p with values = Variable v :: p.values }
  and add_text p t = { p with values = Text t :: p.values }
  and add_error p err = { p with errors = err :: p.errors }

  and has_invalid_name variable =
    let fields = [ "suffix"; "prefix"; "pattern" ] in
    List.exists fields ~f:(fun name -> String.equal variable name)

  and next ?(skip = 1) p =
    if p.pos + skip >= Array.length p.tokens - 1 then { p with actual = None }
    else
      let position = p.pos + skip in
      { p with pos = position; actual = Some (Array.get p.tokens position) }

  let build p user_message =
    let lst = List.map p.values ~f:(pattern_to_string user_message) in
    p.template.prefix :: List.rev (p.template.suffix :: lst)
    |> String.concat ~sep:""
end
