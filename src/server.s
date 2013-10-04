

# This is a simple HTTP server
# more than a server its just a
# program that listens in port 8083
# and sends back an HTTP response


# This is where we declare 
# data (strings, ints, etc) we'll be
# using in our program
.data

# The program prints this
# message on startup
listen_s:
  .ascii "\033[35mServer listening in port 8083...\033[0m\n"

# The size of the 
# startup message
listen_st:
  .long . - listen_s

# This is what the program 
# sends back upon request
response:
  .ascii "HTTP/1.1 200 OK\nContent-Type: text/html\n\nHola mundo!"

# This is the size
# of the response in bytes
response_size:
  .long . - response

# some macros for
# more code legibility

# System call numbers (OSX and apparently BSD)
.set SYS_socket, 0x2000061
.set SYS_bind,   0x2000068
.set SYS_listen, 0x200006a
.set SYS_accept, 0x200001e
.set SYS_read,   0x2000003
.set SYS_close,  0x2000006
.set SYS_write,  0x2000004
.set SYS_exit,   0x2000001

# Where our sockets
# we'll be in the stack
.set SRV_SOCKET, -8
.set CLI_SOCKET, -32

# Where the structs
# needed for socket creation
# we'll be in the stack
.set SRV_ADDR, -24
.set CLI_ADDR, -48

# The size of the 
# sockaddr_in struct is 16 bytes
.set ADDR_SIZE, 0x10
.set CLI_SIZE,  -56

# The offset in the stack
# for our buffer 
# and its size
.set BUFFER, -184
.set BUFFER_SIZE, 0x80


# here the code
# start (the executable code)
.text

.globl start

start:
  # This is the C calling convention
  # save the current value of %rbp
  # %rsp is a pointer to the top 
  # of the stack, we move the value
  # to %rbp to use it as a "base" pointer
  pushq %rbp
  movq %rsp, %rbp

  # make room for our local
  # variables
  subq $0xb8, %rsp

  # This is the "server" socket,
  # the listening socket 
  movq $SYS_socket, %rax
  movq $0x2, %rdi # AF_INET 
  movq $0x1, %rsi # SOCK_STREAM
  movq $0x0, %rdx
  syscall 

  # check the return value
  # of the syscall
  # negative values mean error
  cmpq $0x0, %rax
  jl exit

  # push the value to the stack
  # TODO: this should probably be "pushq"
  movq %rax, SRV_SOCKET(%rbp)

  # This create the struct
  # the port needs to be in 
  # network byte order: http://en.wikipedia.org/wiki/Endianness
  # 0, AF_INET, 8083, 0, 0
  movq $0x931f0200, %rax
  movq %rax, -24(%rbp)
  movl $0x0, %eax
  movq %rax, -16(%rbp)

  # This binds the socket 
  # to 0.0.0.0:8083
  movq $SYS_bind, %rax 
  movq SRV_SOCKET(%rbp), %rdi
  leaq SRV_ADDR(%rbp), %rsi
  movq $ADDR_SIZE, %rdx
  syscall

  # Check return code
  cmpq $0x0, %rax
  jne cleanup

  # This tells how many
  # waiting connection the
  # server can have
  movq $SYS_listen, %rax
  movq SRV_SOCKET(%rbp), %rdi
  movq $0x5, %rsi
  syscall

  # show startup message (yei!)
  movq $SYS_write, %rax
  movq $0x1, %rdi
  movq listen_s@GOTPCREL(%rip), %rsi
  movq listen_st(%rip), %rdx
  syscall

# This is the main loop
# It'll keep accepting 
# requests
loop:
  # This is the sockaddr_in struct
  # filled with 0s
  movq $0x0, %rax
  movq %rax, -40(%rbp)
  movq $0x0, %rax
  movq %rax, -48(%rbp)

  movq $ADDR_SIZE, %rax
  movq %rax, CLI_SIZE(%rbp)

  # This blocks excecution 
  # until we get a request
  movq $SYS_accept, %rax 
  movq SRV_SOCKET(%rbp), %rdi 
  leaq CLI_ADDR(%rbp), %rsi
  leaq CLI_SIZE(%rbp), %rdx
  syscall

  # Always check for errors
  cmpq $0x0, %rax
  jl cleanup

  # Save the file descriptor
  # you'll need it later for reading
  # and writing
  movq %rax, CLI_SOCKET(%rbp) 

  # read the request
  movq $SYS_read, %rax 
  movq CLI_SOCKET(%rbp), %rdi 
  leaq BUFFER(%rbp), %rsi 
  movq $BUFFER_SIZE, %rdx
  syscall

  # write the response
  # to the socket 
  movq $SYS_write, %rax
  movq CLI_SOCKET(%rbp), %rdi
  movq response@GOTPCREL(%rip), %rsi
  movq response_size(%rip), %rdx
  syscall

  # close the client
  movq $SYS_close, %rax
  movq CLI_SOCKET(%rbp), %rdi
  syscall

  # print socket contents
  # to std_out
  movq $SYS_write, %rax 
  movq $0x1, %rdi 
  leaq BUFFER(%rbp), %rsi
  movq $BUFFER_SIZE, %rdx
  syscall

  # let's start all over :P
  jmp loop


# This just closes
# The server socket
cleanup:
  movq $SYS_close, %rax
  movq SRV_SOCKET(%rbp), %rdi
  syscall

exit:
  movq %rbp, %rsp
  popq %rbp

  # exit(0) \o/
  movq $SYS_exit, %rax
  movq $0x0, %rdi
  syscall
