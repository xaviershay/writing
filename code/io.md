    puts("What is your name?")
    name = gets()
    puts("hello " + name)

main = putStrLn "What is your name?" >> getLine >>= \x -> putStrLn "hello " ++ x
