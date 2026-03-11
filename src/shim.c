/*
 * bun-shim.so — LD_PRELOAD shim for Bun on Termux
 *
 * Intercepts filesystem and exec syscalls to work around Android's
 * restricted directory access and missing FHS paths:
 *
 *   - openat/openat64: redirect /proc/stat (fake CPU info for os.cpus()),
 *     redirect O_DIRECTORY reads of /, /data, /storage to a safe dir
 *   - open/open64: legacy glibc codepaths that bypass openat
 *   - stat/lstat/fstatat: intercept for fs.existsSync, fs.statSync on
 *     restricted paths
 *   - access/faccessat: intercept permission checks (fs.accessSync)
 *   - execve/execveat: parse shebangs and translate /usr/bin, /bin paths
 *     to $PREFIX/bin equivalents
 *
 * Adapted from refbun/loader2/shim.c with enhancements per plan.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include <sys/mman.h>
#include <errno.h>
#include <linux/version.h>

#define PREFIX_DEFAULT "/data/data/com.termux/files/usr"
#define SHEBANG_MAX 256

/* --- Global state --- */
static const char *SAFE_DIR = NULL;
static int safe_dir_fd = -1;
static const char *PREFIX = NULL;

/* --- Real function pointers (resolved via dlsym) --- */
static int (*real_openat)(int, const char *, int, ...) = NULL;
static int (*real_openat64)(int, const char *, int, ...) = NULL;
static int (*real_open)(const char *, int, ...) = NULL;
static int (*real_open64)(const char *, int, ...) = NULL;
static int (*real_execve)(const char *, char *const[], char *const[]) = NULL;
static int (*real_stat)(const char *, struct stat *) = NULL;
static int (*real_lstat)(const char *, struct stat *) = NULL;
static int (*real_fstatat)(int, const char *, struct stat *, int) = NULL;
static int (*real_access)(const char *, int) = NULL;
static int (*real_faccessat)(int, const char *, int, int) = NULL;

/* --- Path translation: /usr/bin/foo -> $PREFIX/bin/foo etc --- */
static const char *translate_path(const char *path, char *buf, size_t bufsize) {
    if (!path) return path;
    int n;

    /* /usr/bin/X -> $PREFIX/bin/X */
    if (strncmp(path, "/usr/bin/", 9) == 0) {
        n = snprintf(buf, bufsize, "%s/bin/%s", PREFIX, path + 9);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /bin/X -> $PREFIX/bin/X */
    if (strncmp(path, "/bin/", 5) == 0) {
        n = snprintf(buf, bufsize, "%s/bin/%s", PREFIX, path + 5);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /usr/sbin/X -> $PREFIX/bin/X */
    if (strncmp(path, "/usr/sbin/", 10) == 0) {
        n = snprintf(buf, bufsize, "%s/bin/%s", PREFIX, path + 10);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /sbin/X -> $PREFIX/bin/X */
    if (strncmp(path, "/sbin/", 6) == 0) {
        n = snprintf(buf, bufsize, "%s/bin/%s", PREFIX, path + 6);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /usr/lib/X -> $PREFIX/lib/X */
    if (strncmp(path, "/usr/lib/", 9) == 0) {
        n = snprintf(buf, bufsize, "%s/lib/%s", PREFIX, path + 9);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /usr/share/X -> $PREFIX/share/X */
    if (strncmp(path, "/usr/share/", 11) == 0) {
        n = snprintf(buf, bufsize, "%s/share/%s", PREFIX, path + 11);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /etc/X -> $PREFIX/etc/X */
    if (strncmp(path, "/etc/", 5) == 0) {
        n = snprintf(buf, bufsize, "%s/etc/%s", PREFIX, path + 5);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    /* /tmp -> $PREFIX/tmp */
    if (strcmp(path, "/tmp") == 0 || strncmp(path, "/tmp/", 5) == 0) {
        n = snprintf(buf, bufsize, "%s%s", PREFIX, path);
        if (n < 0 || (size_t)n >= bufsize) return path;
        return buf;
    }
    return path;
}

/* --- Constructor: resolve all real function pointers --- */
__attribute__((constructor))
static void init_shim(void) {
    real_openat = dlsym(RTLD_NEXT, "openat");
    real_openat64 = dlsym(RTLD_NEXT, "openat64");
    real_open = dlsym(RTLD_NEXT, "open");
    real_open64 = dlsym(RTLD_NEXT, "open64");
    real_execve = dlsym(RTLD_NEXT, "execve");
    real_stat = dlsym(RTLD_NEXT, "stat");
    real_lstat = dlsym(RTLD_NEXT, "lstat");
    real_fstatat = dlsym(RTLD_NEXT, "fstatat");
    real_access = dlsym(RTLD_NEXT, "access");
    real_faccessat = dlsym(RTLD_NEXT, "faccessat");

    if (!real_openat || !real_openat64 || !real_execve) {
        const char msg[] = "bun-shim: failed to resolve critical symbols\n";
        syscall(SYS_write, STDERR_FILENO, msg, sizeof(msg) - 1);
        _exit(1);
    }

    PREFIX = getenv("PREFIX");
    if (!PREFIX) PREFIX = PREFIX_DEFAULT;

    SAFE_DIR = getenv("BUN_FAKE_ROOT");
    if (!SAFE_DIR) SAFE_DIR = getenv("TMPDIR");
    if (!SAFE_DIR) SAFE_DIR = "/data/data/com.termux/files/usr/tmp";
    safe_dir_fd = real_openat(AT_FDCWD, SAFE_DIR,
                              O_RDONLY | O_DIRECTORY | O_CLOEXEC, 0);
}

/* --- Directory redirect: should this path be redirected to safe dir? --- */
static int should_redirect(const char *pathname) {
    if (!pathname) return 0;
    size_t len = strlen(pathname);

    /* Root directory */
    if (len == 1 && pathname[0] == '/') return 1;

    /* /data and its immediate children (not deep paths like /data/data/com.termux/...) */
    if (len == 5 && memcmp(pathname, "/data", 5) == 0) return 1;
    if (len == 6 && memcmp(pathname, "/data/", 6) == 0) return 1;
    if (len == 10 && memcmp(pathname, "/data/data", 10) == 0) return 1;
    if (len == 11 && memcmp(pathname, "/data/data/", 11) == 0) return 1;

    /* /storage hierarchy */
    if (len >= 8 && memcmp(pathname, "/storage", 8) == 0 &&
        (len == 8 || pathname[8] == '/')) {
        /* Allow deep paths under /storage/emulated/0/... */
        if (len > 20 && memcmp(pathname, "/storage/emulated/0/", 20) == 0) return 0;
        return 1;
    }

    return 0;
}

/* --- Fake /proc/stat generation for os.cpus() --- */
static int generate_proc_stat(char *buf, size_t size) {
    int ncpu = sysconf(_SC_NPROCESSORS_ONLN);
    if (ncpu < 1) ncpu = 1;
    if (ncpu > 256) ncpu = 256;

    int total = 0;
    int n;

    /* Aggregate CPU line */
    n = snprintf(buf + total, size - total, "cpu  0 0 0 0 0 0 0 0 0 0\n");
    if (n < 0) return n;
    total += n;

    /* Per-CPU lines */
    for (int i = 0; i < ncpu && total < (int)size - 48; i++) {
        n = snprintf(buf + total, size - total,
                     "cpu%d 0 0 0 0 0 0 0 0 0 0\n", i);
        if (n < 0) return n;
        total += n;
    }

    /* Footer fields */
    n = snprintf(buf + total, size - total,
                 "intr 0\nctxt 0\nbtime %ld\n"
                 "processes 1\nprocs_running 1\nprocs_blocked 0\n",
                 time(NULL));
    if (n < 0) return n;
    total += n;

    return total;
}

/* Create an fd backed by proc_stat content.
 * Tries memfd_create first (kernel >= 3.17), falls back to tmp file. */
static int create_proc_stat_fd(void) {
    char buf[4096];
    int n = generate_proc_stat(buf, sizeof(buf));
    if (n <= 0) return -1;

    /* Try memfd_create (available since Linux 3.17) */
    int fd = -1;
#ifdef __NR_memfd_create
    fd = syscall(__NR_memfd_create, "proc_stat", 1 /* MFD_CLOEXEC */);
#endif
    if (fd < 0) {
        /* Fallback: use a temp file */
        char tmppath[256];
        snprintf(tmppath, sizeof(tmppath), "%s/.bun-proc-stat-XXXXXX",
                 SAFE_DIR ? SAFE_DIR : "/data/data/com.termux/files/usr/tmp");
        fd = mkstemp(tmppath);
        if (fd < 0) return -1;
        unlink(tmppath); /* delete on close */
    }

    ssize_t written = write(fd, buf, n);
    if (written != n || lseek(fd, 0, SEEK_SET) != 0) {
        close(fd);
        return -1;
    }
    return fd;
}

/* --- openat/openat64 interception --- */
static int do_openat(int (*real_fn)(int, const char *, int, ...),
                     int dirfd, const char *pathname, int flags, va_list ap) {
    /* Intercept /proc/stat for fake CPU info */
    if (pathname && strcmp(pathname, "/proc/stat") == 0) {
        int fd = create_proc_stat_fd();
        if (fd >= 0) return fd;
        /* Fall through to real open on failure */
    }

    /* Redirect directory opens of restricted paths to safe dir */
    if ((flags & O_DIRECTORY) && should_redirect(pathname)) {
        if (safe_dir_fd >= 0) {
            return dup(safe_dir_fd);
        }
    }

    if (flags & O_CREAT) {
        mode_t mode = va_arg(ap, mode_t);
        return real_fn(dirfd, pathname, flags, mode);
    }
    return real_fn(dirfd, pathname, flags);
}

int openat(int dirfd, const char *pathname, int flags, ...) {
    va_list ap;
    va_start(ap, flags);
    int result = do_openat(real_openat, dirfd, pathname, flags, ap);
    va_end(ap);
    return result;
}

int openat64(int dirfd, const char *pathname, int flags, ...) {
    va_list ap;
    va_start(ap, flags);
    int result = do_openat(real_openat64, dirfd, pathname, flags, ap);
    va_end(ap);
    return result;
}

/* --- open/open64 interception (legacy glibc codepaths) --- */
int open(const char *pathname, int flags, ...) {
    if (!real_open) real_open = dlsym(RTLD_NEXT, "open");
    va_list ap;
    va_start(ap, flags);
    /* Delegate to openat logic for consistency */
    int result = do_openat(real_openat, AT_FDCWD, pathname, flags, ap);
    va_end(ap);
    return result;
}

int open64(const char *pathname, int flags, ...) {
    if (!real_open64) real_open64 = dlsym(RTLD_NEXT, "open64");
    va_list ap;
    va_start(ap, flags);
    int result = do_openat(real_openat64, AT_FDCWD, pathname, flags, ap);
    va_end(ap);
    return result;
}

/* --- stat/lstat/fstatat interception --- */

/* For restricted paths, synthesize a directory stat result */
static void fill_dir_stat(struct stat *buf) {
    memset(buf, 0, sizeof(*buf));
    buf->st_mode = S_IFDIR | 0755;
    buf->st_nlink = 2;
    buf->st_uid = getuid();
    buf->st_gid = getgid();
    buf->st_blksize = 4096;
}

int __xstat(int ver, const char *pathname, struct stat *buf) {
    (void)ver;
    if (should_redirect(pathname)) {
        fill_dir_stat(buf);
        return 0;
    }
    if (real_stat) return real_stat(pathname, buf);
    return syscall(SYS_newfstatat, AT_FDCWD, pathname, buf, 0);
}

int __lxstat(int ver, const char *pathname, struct stat *buf) {
    (void)ver;
    if (should_redirect(pathname)) {
        fill_dir_stat(buf);
        return 0;
    }
    if (real_lstat) return real_lstat(pathname, buf);
    return syscall(SYS_newfstatat, AT_FDCWD, pathname, buf, AT_SYMLINK_NOFOLLOW);
}

int fstatat(int dirfd, const char *pathname, struct stat *buf, int flags) {
    if (should_redirect(pathname)) {
        fill_dir_stat(buf);
        return 0;
    }
    if (real_fstatat) return real_fstatat(dirfd, pathname, buf, flags);
    return syscall(SYS_newfstatat, dirfd, pathname, buf, flags);
}

/* glibc may call stat/lstat directly instead of __xstat on newer versions */
int stat(const char *pathname, struct stat *buf) {
    if (should_redirect(pathname)) {
        fill_dir_stat(buf);
        return 0;
    }
    if (real_stat) return real_stat(pathname, buf);
    return syscall(SYS_newfstatat, AT_FDCWD, pathname, buf, 0);
}

int lstat(const char *pathname, struct stat *buf) {
    if (should_redirect(pathname)) {
        fill_dir_stat(buf);
        return 0;
    }
    if (real_lstat) return real_lstat(pathname, buf);
    return syscall(SYS_newfstatat, AT_FDCWD, pathname, buf, AT_SYMLINK_NOFOLLOW);
}

/* --- access/faccessat interception --- */
int access(const char *pathname, int mode) {
    if (should_redirect(pathname)) {
        /* Restricted paths exist and are readable/executable dirs */
        if (mode == F_OK || mode == R_OK || mode == X_OK ||
            mode == (R_OK | X_OK)) {
            return 0;
        }
        /* Write access to restricted paths: deny */
        if (mode & W_OK) {
            errno = EACCES;
            return -1;
        }
        return 0;
    }
    if (real_access) return real_access(pathname, mode);
    return syscall(SYS_faccessat, AT_FDCWD, pathname, mode, 0);
}

int faccessat(int dirfd, const char *pathname, int mode, int flags) {
    if (should_redirect(pathname)) {
        if (mode == F_OK || mode == R_OK || mode == X_OK ||
            mode == (R_OK | X_OK)) {
            return 0;
        }
        if (mode & W_OK) {
            errno = EACCES;
            return -1;
        }
        return 0;
    }
    if (real_faccessat) return real_faccessat(dirfd, pathname, mode, flags);
    return syscall(SYS_faccessat, dirfd, pathname, mode, flags);
}

/* --- link/linkat interception: fallback to copy on EACCES/EPERM/EXDEV --- */
/* Android f2fs blocks hardlinks; bun install uses link() by default.
 * Intercept and fall back to copying the file instead. */

static int (*real_link)(const char *, const char *) = NULL;
static int (*real_linkat)(int, const char *, int, const char *, int) = NULL;

static int copy_file(const char *src, const char *dst) {
    int src_fd = real_openat(AT_FDCWD, src, O_RDONLY | O_CLOEXEC, 0);
    if (src_fd < 0) return -1;

    struct stat st;
    if (fstat(src_fd, &st) < 0) {
        close(src_fd);
        return -1;
    }

    int dst_fd = real_openat(AT_FDCWD, dst,
                             O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC,
                             st.st_mode & 07777);
    if (dst_fd < 0) {
        close(src_fd);
        return -1;
    }

    /* Use sendfile for efficient kernel-space copy */
    off_t offset = 0;
    ssize_t remaining = st.st_size;
    while (remaining > 0) {
        ssize_t sent = syscall(SYS_sendfile, dst_fd, src_fd, &offset, remaining);
        if (sent <= 0) {
            /* sendfile failed — fall back to read/write loop */
            char buf[65536];
            lseek(src_fd, offset, SEEK_SET);
            while ((sent = read(src_fd, buf, sizeof(buf))) > 0) {
                ssize_t w = 0;
                while (w < sent) {
                    ssize_t n = write(dst_fd, buf + w, sent - w);
                    if (n < 0) {
                        close(src_fd);
                        close(dst_fd);
                        unlink(dst);
                        return -1;
                    }
                    w += n;
                }
            }
            break;
        }
        remaining -= sent;
    }

    close(src_fd);
    close(dst_fd);
    return 0;
}

int link(const char *oldpath, const char *newpath) {
    if (!real_link) real_link = dlsym(RTLD_NEXT, "link");
    int ret = real_link(oldpath, newpath);
    if (ret == 0) return 0;

    /* If hardlink fails with EACCES, EPERM, or EXDEV, fall back to copy */
    int e = errno;
    if (e == EACCES || e == EPERM || e == EXDEV || e == ENOSYS) {
        return copy_file(oldpath, newpath);
    }
    errno = e;
    return ret;
}

int linkat(int olddirfd, const char *oldpath, int newdirfd,
           const char *newpath, int flags) {
    if (!real_linkat) real_linkat = dlsym(RTLD_NEXT, "linkat");
    int ret = real_linkat(olddirfd, oldpath, newdirfd, newpath, flags);
    if (ret == 0) return 0;

    /* If hardlink fails, fall back to copy (only for AT_FDCWD simple paths) */
    int e = errno;
    if (e == EACCES || e == EPERM || e == EXDEV || e == ENOSYS) {
        /* For non-AT_FDCWD dirfds, construct absolute paths if possible */
        char src_buf[4096], dst_buf[4096];
        const char *src = oldpath;
        const char *dst = newpath;

        if (olddirfd != AT_FDCWD && oldpath[0] != '/') {
            /* Resolve via /proc/self/fd */
            char fd_path[64];
            snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", olddirfd);
            ssize_t n = readlink(fd_path, src_buf, sizeof(src_buf) - 1);
            if (n > 0) {
                src_buf[n] = '\0';
                size_t plen = strlen(src_buf);
                snprintf(src_buf + plen, sizeof(src_buf) - plen, "/%s", oldpath);
                src = src_buf;
            } else {
                errno = e;
                return ret;
            }
        }

        if (newdirfd != AT_FDCWD && newpath[0] != '/') {
            char fd_path[64];
            snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", newdirfd);
            ssize_t n = readlink(fd_path, dst_buf, sizeof(dst_buf) - 1);
            if (n > 0) {
                dst_buf[n] = '\0';
                size_t plen = strlen(dst_buf);
                snprintf(dst_buf + plen, sizeof(dst_buf) - plen, "/%s", newpath);
                dst = dst_buf;
            } else {
                errno = e;
                return ret;
            }
        }

        return copy_file(src, dst);
    }
    errno = e;
    return ret;
}

/* --- Shebang parsing for execve --- */
static int parse_shebang(const char *path, char *interp, size_t interp_size,
                         char *interp_arg, size_t arg_size) {
    int fd = real_openat(AT_FDCWD, path, O_RDONLY | O_CLOEXEC, 0);
    if (fd < 0) return -1;

    char buf[SHEBANG_MAX];
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);

    if (n < 2 || buf[0] != '#' || buf[1] != '!') return -1;

    /* Skip whitespace after #! */
    char *start = buf + 2;
    while (start < buf + n && (*start == ' ' || *start == '\t')) start++;
    if (start >= buf + n) return -1;

    /* Extract interpreter path */
    char *end = start;
    while (end < buf + n && *end != ' ' && *end != '\t' &&
           *end != '\n' && *end != '\r') end++;

    size_t interp_len = end - start;
    if (interp_len == 0 || interp_len >= interp_size) return -1;

    memcpy(interp, start, interp_len);
    interp[interp_len] = '\0';

    /* Extract optional argument */
    interp_arg[0] = '\0';
    char *arg_start = end;
    while (arg_start < buf + n && (*arg_start == ' ' || *arg_start == '\t'))
        arg_start++;

    if (arg_start < buf + n && *arg_start != '\n' && *arg_start != '\r') {
        char *arg_end = arg_start;
        while (arg_end < buf + n && *arg_end != ' ' && *arg_end != '\t' &&
               *arg_end != '\n' && *arg_end != '\r') arg_end++;
        size_t arg_len = arg_end - arg_start;
        if (arg_len > 0 && arg_len < arg_size) {
            memcpy(interp_arg, arg_start, arg_len);
            interp_arg[arg_len] = '\0';
        }
    }

    return 0;
}

/* --- execve interception: translate shebangs --- */
int execve(const char *pathname, char *const argv[], char *const envp[]) {
    char interp_buf[256], arg_buf[256], translated_buf[256];

    if (parse_shebang(pathname, interp_buf, sizeof(interp_buf),
                      arg_buf, sizeof(arg_buf)) == 0) {
        const char *translated = translate_path(interp_buf, translated_buf,
                                                 sizeof(translated_buf));

        int orig_argc = 0;
        while (argv[orig_argc]) orig_argc++;

        int has_arg = arg_buf[0] ? 1 : 0;
        int new_argc = 1 + has_arg + 1 + orig_argc;
        char **new_argv = malloc((new_argc + 1) * sizeof(char *));
        if (!new_argv) {
            errno = ENOMEM;
            return -1;
        }

        int i = 0;
        new_argv[i++] = (char *)translated;
        if (has_arg) new_argv[i++] = arg_buf;
        new_argv[i++] = (char *)(argv[0] ? argv[0] : pathname);
        for (int j = 1; j < orig_argc; j++) new_argv[i++] = argv[j];
        new_argv[i] = NULL;

        int ret = real_execve(translated, new_argv, envp);
        int saved_errno = errno;
        free(new_argv);
        errno = saved_errno;
        return ret;
    }

    return real_execve(pathname, argv, envp);
}
