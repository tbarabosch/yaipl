type expr =
  | Number of float
  | Variable of string
  | Binary of char * expr * expr
  | Call of string * expr list
  | Prototype of string * string list
  | Function of expr * expr

