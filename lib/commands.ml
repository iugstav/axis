open Cmdliner

let templ_name =
  let doc = "name of the template" in
  Arg.(required & pos 0 (some string) None (info [] ~docv:"NAME" ~doc))

let user_message =
  let doc = "message to insert in the template" in
  Arg.(required & pos 1 (some string) None (info [] ~docv:"MESSAGE" ~doc))
