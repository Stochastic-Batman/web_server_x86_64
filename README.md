# HTTP_server_x86_64
![AssemblyScript](https://img.shields.io/badge/assembly%20script-%23000000.svg?style=for-the-badge&logo=assemblyscript&logoColor=white)

Simple HTTP Server in x86-64 Assembly

A concurrent web server (HTTP/1.0 interface) implemented from scratch in **x86-64 Assembly** (Intel Syntax with noprefix). This server interacts directly with the Linux kernel via system calls, bypassing standard libraries like `libc` to achieve maximum efficiency and minimal binary size.

Prerequisites:
- Linux OS (x86-64)
- GNU Binutils (as, ld)

## Concurrency Model
The server utilizes a **Multiprocessing Model** via the `fork()` system call:
- **Parent Process:** Continuously listens for new incoming connections. Upon a successful `accept()`, it spawns a child process and immediately returns to the listening state.
- **Child Process:** Inherits the client socket, parses the specific HTTP request (GET or POST), executes the corresponding file system operation, transmits the response, and terminates.

## Request Handling Logic
1.  **Method Inspection:** The server reads the first byte of the incoming buffer to determine the method: `G` for **GET** or `P` for **POST**.
2.  **Path Extraction:** The code iterates through the request header to isolate the target file path, null-terminating it dynamically for use in system calls.
3.  **GET Implementation:** The server opens the requested file in read-only mode, reads the content into a stack buffer, and transmits it to the client preceded by a standard `200 OK` header.
4.  **POST Implementation:** The server scans for the `\r\n\r\n` sequence to locate the request body. It then opens the target file with `O_WRONLY | O_CREAT` flags and writes the body content to the disk.

## System Calls Used
The implementation uses the following 10 out of 333 system calls ([Linux x86-64](https://x64.syscall.sh/)):

| Syscall | RAX | Description                        | Signature                             |
|---------|-----|------------------------------------|---------------------------------------|
| read    | 0   | Read data from socket or file      | read(fd, buf, count)                 |
| write   | 1   | Write data to socket or file       | write(fd, buf, count)                |
| open    | 2   | Access or create a file            | open(pathname, flags, mode)          |
| close   | 3   | Close a file descriptor             | close(fd)                             |
| socket  | 41  | Create communication endpoint       | socket(AF_INET, SOCK_STREAM, 0)      |
| accept  | 43  | Accept a connection                 | accept(sockfd, NULL, NULL)            |
| bind    | 49  | Bind socket to Port 80             | bind(sockfd, addr, addrlen)          |
| listen  | 50  | Listen for connections              | listen(sockfd, backlog)               |
| fork    | 57  | Create a child process             | fork()                                |
| exit    | 60  | Terminate child process            | exit(status)                          |


## Compilation and Linking
To build the server into a standalone, dependency-free executable:

```bash
# Assemble the source code & Link the object file
as -o web_server.o web_server.s && ld -o web_server web_server.o
```

## Running the Server
The server binds to Port 80, which requires elevated privileges:

```bash
sudo ./web_server
```
