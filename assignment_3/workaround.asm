.data

.globl  __progname
__progname:
        .int    0

.globl  environ
environ:
        .int   0

# Mark stack as non-executable
.section .note.GNU-stack,"",@progbits
