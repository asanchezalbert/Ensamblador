
#
# This is a simple program, it 
# the biggest number in the "items" array
#


# The data section contains our "global" variables
.data 

items:
  .long 1, 4, 5, 8, 2, 3, 0

# for counting "embeded" variables we could just
# use ". - items" which is a compiler instruction

# This is where we put the code
.text

# We declare that the "start" symbol should be exporteds
.globl start

start:
  # "local" variables initialization

  # we'll use %rdi register to store our count
  # something like "int index = 0"
  movq $0, %rdi 

  # we store the memory location of items in 
  # %rcx register, something like a c pointer
  # ej. int current[] = {1, 4, 5, ...}
  leaq items(%rip), %rcx 

  # %rbx contains the biggest number so far
  # since we are just starting the current 
  # number (at 0) is our biggest number
  movq (%rcx), %rbx

# label for the loop
# we'll keep jumping back here
# until we get 0
loop:
  # we check the current number
  # isnt 0, if its zero we jump 
  # to "exit" label
  cmpq $0, (%rcx) # if(current == 0)
  je exit

  # increasing the index
  # index++
  incq %rdi

  # get the next item
  # current = items[index]
  movq 0(%rcx, %rdi, 4), %rax

  # we compare current item 
  # with the biggest we have
  # at this point
  # if is biggest we store the
  # new biggest value 
  cmpq %rax, %rbx
  jl loop

  movq %rax, %rbx

exit:
  # we "return" the biggest value 
  # ("echo $?" will tell you )
  # with the exit system call
  # ej. exit(biggest)
  movq %rbx, %rdi
  movq $0x2000001, %rax
  syscall

