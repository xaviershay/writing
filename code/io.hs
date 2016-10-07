main =
  putStrLn "What is your name?" >>=
    \_ -> getLine >>=
      \name -> putStrLn("hello " ++ name)

