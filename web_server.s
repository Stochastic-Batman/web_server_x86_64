.intel_syntax noprefix
.globl _start

.section .text
_start:
    # socket(AF_INET=2, SOCK_STREAM=1, 0)
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41
    syscall

    # bind(sockfd=3, {sa_family=AF_INET, sin_port=80, ...}, 16)
    mov rdi, 3
    lea rsi, [rip+sockaddr]
    mov rdx, 16
    mov rax, 49
    syscall

    # listen(sockfd=3, backlog=0)
    mov rdi, 3
    mov rsi, 0
    mov rax, 50
    syscall

Accept_Loop:
    # accept(sockfd=3, NULL, NULL)
    mov rdi, 3
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43
    syscall
    mov r12, rax        # r12 = client_fd

    # fork()
    mov rax, 57
    syscall

    cmp rax, 0
    je Child_process

Parent_process:
    # close(client_fd=r12)
    mov rdi, r12
    mov rax, 3
    syscall
    jmp Accept_Loop

Child_process:
    # close(listen_sock=3)
    mov rdi, 3
    mov rax, 3
    syscall

    # read(client_fd=r12, buf=rsp, count=2048)
    sub rsp, 2048
    mov rdi, r12
    mov rsi, rsp
    mov rdx, 2048
    mov rax, 0
    syscall
    mov r13, rax        # r13 = total_bytes_received

    # Inspect first byte of request
    mov al, [rsp]
    cmp al, 'G'         
    je Handle_GET
    cmp al, 'P'         
    je Handle_POST
    jmp Exit_Child

Handle_GET:
    # Parse path starting at [rsp + 4]
    lea r10, [rsp+4]
    mov r11, r10
Find_GET_Path_End:
    cmp byte ptr [r11], ' '
    je GET_Path_Parsed
    inc r11
    jmp Find_GET_Path_End
GET_Path_Parsed:
    mov byte ptr [r11], 0

    # open(path=r10, O_RDONLY=0)
    mov rdi, r10
    mov rsi, 0
    mov rax, 2
    syscall
    mov rbx, rax        # rbx = file_fd

    # read(file_fd=rbx, buf=rsp, count=1024)
    mov rdi, rbx
    mov rsi, rsp
    mov rdx, 1024
    mov rax, 0
    syscall
    mov r14, rax        # r14 = file_size

    # close(file_fd=rbx)
    mov rdi, rbx
    mov rax, 3
    syscall

    # write(client_fd=r12, buf="HTTP/1.0 200 OK...", count=19)
    mov rdi, r12
    lea rsi, [rip+response]
    mov rdx, 19
    mov rax, 1
    syscall

    # write(client_fd=r12, buf=rsp, count=r14)
    mov rdi, r12
    mov rsi, rsp
    mov rdx, r14
    mov rax, 1
    syscall
    jmp Exit_Child

Handle_POST:
    # Parse path starting at [rsp + 5]
    lea r10, [rsp+5]
    mov r11, r10
Find_POST_Path_End:
    cmp byte ptr [r11], ' '
    je POST_Path_Parsed
    inc r11
    jmp Find_POST_Path_End
POST_Path_Parsed:
    mov byte ptr [r11], 0

    # Search for "\r\n\r\n" (0x0a0d0a0d) to find start of body
    mov r14, rsp
Find_Body:
    cmp dword ptr [r14], 0x0a0d0a0d
    je Body_Found
    inc r14
    jmp Find_Body
Body_Found:
    add r14, 4
    
    # Calculate body_len = total_bytes_received - (body_ptr - buf_ptr)
    mov r15, r14
    sub r15, rsp
    mov rbx, r13
    sub rbx, r15

    # open(path=r10, O_WRONLY|O_CREAT=65, mode=0777)
    mov rdi, r10
    mov rsi, 65
    mov rdx, 0777
    mov rax, 2
    syscall
    mov r8, rax         # r8 = file_fd

    # write(file_fd=r8, buf=r14, count=rbx)
    mov rdi, r8
    mov rsi, r14
    mov rdx, rbx
    mov rax, 1
    syscall

    # close(file_fd=r8)
    mov rdi, r8
    mov rax, 3
    syscall

    # write(client_fd=r12, buf="HTTP/1.0 200 OK...", count=19)
    mov rdi, r12
    lea rsi, [rip+response]
    mov rdx, 19
    mov rax, 1
    syscall

Exit_Child:
    # exit(status=0)
    mov rdi, 0
    mov rax, 60
    syscall

.section .data
sockaddr:
    .2byte 2            
    .2byte 0x5000       
    .4byte 0            
    .8byte 0

response: 
    .string "HTTP/1.0 200 OK\r\n\r\n"
