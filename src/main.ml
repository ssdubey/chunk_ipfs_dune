let f0 = Chunk.Simple.create
let item = Chunk.Simple.mk_item 1234
let key1 = `Text "key1"
let key2 = `Text "key2"
let intval = `Int 5
let arrval = `Array [`Int 5; `Int 7]
let sendval = `Map [(key1, intval);(key2,arrval)]
let f1 = Chunk.Simple.push_back sendval item
let f1 = Chunk.Simple.push_back sendval (Chunk.Simple.mk_item 1234)
(*let f2 = Chunk.Simple.push_back f1 (Chunk.Simple.mk_item 3322)*)




(*`Map [ (`Text "_weight_key", `Int 5);      (`Text "_contents_key", `Array [4]); ]*)

(*
to build:
 oasis setup -setup-update dynamic && ./configure --enable-tests && make clean && make  
 *)
                                
let hash = Chunk.Simple.ipfs_put_cbor sendval

let _ = Printf.printf "hash= %s\n" hash

let f3 = Chunk.Simple.ipfs_get_cbor hash
let _ = Printf.printf "f3 = %s\n" (CBOR.Simple.to_diagnostic f3)

(*)
let _ = Printf.printf "f2 = %s\n" (CBOR.Simple.to_diagnostic f2)
let f4 = Chunk.Simple.push_back sendval (Chunk.Simple.mk_link hash)

let hash4 = Chunk.Simple.ipfs_put_cbor f4 

let _ = Printf.printf "hash4 = %s\n" hash4
let _ = Printf.printf "f4 = %s\n" (CBOR.Simple.to_diagnostic f4) 
*)




(*let f0 = Chunk.Simple.create
let i = `Int 7
let j = `Int 8
let f1 = Chunk.Simple.push_back f0 (j)
let f2 = Chunk.Simple.push_back (i)

(*
to build:
 oasis setup -setup-update dynamic && ./configure --enable-tests && make clean && make  
 *)
                                
let hash = Chunk.Simple.ipfs_put_cbor f0

let _ = Printf.printf "hash= %s\n" hash

let f3 = Chunk.Simple.ipfs_get_cbor hash
let _ = Printf.printf "f3 = %s\n" (CBOR.Simple.to_diagnostic f3)
(*let _ = Printf.printf "f2 = %s\n" (CBOR.Simple.to_diagnostic f2)


let f4 = Chunk.Simple.push_back f0 (Chunk.Simple.mk_link hash)

let hash4 = Chunk.Simple.ipfs_put_cbor f4 

let _ = Printf.printf "hash4 = %s\n" hash4
let _ = Printf.printf "f4 = %s\n" (CBOR.Simple.to_diagnostic f4) *)
*)